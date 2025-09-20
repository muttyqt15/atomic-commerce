package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	db "github.com/muttyqt15/atomic-commerce/packages/database/generated"
)

// CheckoutRequest defines the expected JSON body for the /checkout endpoint.
type CheckoutRequest struct {
	UserID    string `json:"userId" binding:"required,uuid"`
	ProductID string `json:"productId" binding:"required,uuid"`
	Quantity  int32  `json:"quantity" binding:"required,gt=0"`
}

// APIServer holds the dependencies for our API handlers.
type APIServer struct {
	db   *db.Queries
	pool *pgxpool.Pool
}

func main() {
	router := gin.Default()
	ctx := context.Background()
	// NOTE: It's better practice to fetch this from an environment variable.
	connStr := "postgres://postgres:qin123@localhost:5432/merchdrop?sslmode=disable"
	conn, err := pgxpool.New(ctx, connStr)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer conn.Close()

	server := &APIServer{
		db:   db.New(conn),
		pool: conn,
	}

	// Health Check
	router.GET("/health", server.healthCheck)

	// User Routes
	router.GET("/users", server.getAllUsers)
	router.POST("/users", server.createUser)
	router.GET("/users/:id", server.getUser)

	// Store Routes
	router.POST("/stores", server.createStore)
	router.GET("/stores", server.getAllStores)
	router.GET("/stores/:id", server.getStore)

	// Product Routes
	router.POST("/products", server.createProduct)
	router.GET("/products", server.getAllProducts)
	router.GET("/products/:id", server.getProduct)
	router.PATCH("/products/:id/stock", server.UpdateStock)

	// The vulnerable checkout endpoint
	router.POST("/checkout", server.handleCheckout)

	log.Println("Starting server on :8080")
	if err := router.Run(":8080"); err != nil {
		log.Fatal("error on starting api")
	}
}

// handleCheckout contains the race condition.
func (s *APIServer) handleCheckout(c *gin.Context) {
	var req CheckoutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	productUUID := pgtype.UUID{}
	if err := productUUID.Scan(req.ProductID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product UUID format"})
		return
	}
	userUUID := pgtype.UUID{}
	if err := userUUID.Scan(req.UserID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user UUID format"})
		return
	}

	// TODO: Replace with client-provided idempotency key for proper duplicate prevention
	// Current implementation generates server-side key which is weaker
	idempotencyKey := fmt.Sprintf("checkout_%s_%s_%d_%d", req.UserID, req.ProductID, req.Quantity, time.Now().Unix()/300) // 5-minute window

	tx, err := s.pool.Begin(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not start transaction"})
		return
	}
	defer func(tx pgx.Tx, ctx context.Context) {
		err := tx.Rollback(ctx)
		if err != nil && !errors.Is(err, pgx.ErrTxClosed) {
			log.Printf("Error rolling back transaction: %v", err)
		}
	}(tx, c.Request.Context())

	qtx := s.db.WithTx(tx)

	// Check if idempotency key already exists
	existingKey, err := qtx.GetIdempotencyKeyByKey(c.Request.Context(), idempotencyKey)
	if err == nil {
		// Key exists, check if order was already created
		existingOrder, err := qtx.GetOrderByIdempotencyKeyID(c.Request.Context(), existingKey.ID)
		if err == nil {
			if err := tx.Commit(c.Request.Context()); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"message":   "Order already processed",
				"order_id":  existingOrder.ID,
				"duplicate": true,
			})
			return
		}
	}
	// Create idempotency key
	var idempotencyKeyID pgtype.UUID
	if err == nil {
		// Key exists but no order found, use existing key
		idempotencyKeyID = pgtype.UUID{Bytes: existingKey.ID.Bytes, Valid: true}
	} else {
		// Create new idempotency key
		createdKeyID, err := qtx.CreateIdempotencyKey(c.Request.Context(), db.CreateIdempotencyKeyParams{
			Key:     idempotencyKey,
			UsedFor: "order",
			UserID:  userUUID,
		})
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create idempotency key"})
			return
		}
		idempotencyKeyID = createdKeyID.ID
	}

	// 1. Read the current stock (NON-LOCKING READ - TODO: Fix race condition with SELECT FOR UPDATE)
	product, err := qtx.GetProduct(c.Request.Context(), productUUID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get product"})
		return
	}

	// 2. Check if there is enough stock.
	if product.Stock < req.Quantity {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Not enough stock"})
		return
	}

	// 3. Update the stock.
	_, err = qtx.UpdateProductStock(c.Request.Context(), db.UpdateProductStockParams{
		ID:    productUUID,
		Stock: req.Quantity,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update stock"})
		return
	}

	// 4. Create the order record.
	if !product.Price.Valid {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Product price is null"})
		return
	}

	priceFloat, err := product.Price.Float64Value()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse product price", "trace": err.Error()})
		return
	}

	totalPriceFloat := priceFloat.Float64 * float64(req.Quantity)

	var totalPrice pgtype.Numeric
	totalPriceStr := fmt.Sprintf("%.2f", totalPriceFloat)
	if err = totalPrice.Scan(totalPriceStr); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse total price", "trace": err.Error()})
		return
	}

	orderID, err := qtx.CreateOrder(c.Request.Context(), db.CreateOrderParams{
		UserID:           userUUID,
		ProductID:        productUUID,
		StoreID:          product.StoreID,
		Quantity:         req.Quantity,
		TotalPrice:       totalPrice,
		IdempotencyKeyID: idempotencyKeyID,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create order", "trace": err.Error()})
		return
	}

	if err := tx.Commit(c.Request.Context()); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":  "Checkout successful",
		"order_id": orderID,
	})
}

// --- Handler Implementations ---
func (s *APIServer) UpdateStock(c *gin.Context) {
	// Get product ID from URL path
	pId := c.Param("id")
	fmt.Println(pId)
	productUUID := pgtype.UUID{}
	if err := productUUID.Scan(pId); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product UUID format", "trace": err.Error()})
		return
	}

	// Bind JSON for new stock - use proper request struct
	var req db.UpdateProductStockAbsoluteParams
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if product exists first
	existingProduct, err := s.db.GetProduct(c.Request.Context(), productUUID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch product"})
		return
	}

	// Update stock in DB - use the productUUID from URL and stock from request body
	updatedProduct, err := s.db.UpdateProductStockAbsolute(c.Request.Context(), db.UpdateProductStockAbsoluteParams{
		ID:    productUUID, // From URL parameter
		Stock: req.Stock,   // From JSON request body
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update stock", "trace": err.Error()})
		fmt.Println(err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":   "Stock updated successfully",
		"productId": productUUID,
		"oldStock":  existingProduct.Stock,
		"newStock":  req.Stock,
		"updatedAt": updatedProduct.UpdatedAt,
	})
}

func (s *APIServer) healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// --- User Handlers ---
func (s *APIServer) getAllUsers(c *gin.Context) {
	data, err := s.db.GetAllUsers(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, data)
}

func (s *APIServer) createUser(c *gin.Context) {
	var req db.CreateUserParams
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	user, err := s.db.CreateUser(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, user)
}

func (s *APIServer) getUser(c *gin.Context) {
	id := c.Param("id")
	userUUID := pgtype.UUID{}
	if err := userUUID.Scan(id); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user UUID format"})
		return
	}
	user, err := s.db.GetUser(c.Request.Context(), userUUID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, user)
}

// --- Store Handlers ---

func (s *APIServer) createStore(c *gin.Context) {
	var req db.CreateStoreParams
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	store, err := s.db.CreateStore(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, store)
}

func (s *APIServer) getAllStores(c *gin.Context) {
	stores, err := s.db.GetAllStores(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stores)
}

func (s *APIServer) getStore(c *gin.Context) {
	id := c.Param("id")
	storeUUID := pgtype.UUID{}
	if err := storeUUID.Scan(id); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid store UUID format"})
		return
	}
	store, err := s.db.GetStore(c.Request.Context(), storeUUID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Store not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, store)
}

// --- Product Handlers ---

func (s *APIServer) createProduct(c *gin.Context) {
	var req db.CreateProductParams
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	product, err := s.db.CreateProduct(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, product)
}

func (s *APIServer) getAllProducts(c *gin.Context) {
	products, err := s.db.GetAllProducts(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, products)
}

func (s *APIServer) getProduct(c *gin.Context) {
	id := c.Param("id")
	productUUID := pgtype.UUID{}
	if err := productUUID.Scan(id); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product UUID format"})
		return
	}
	product, err := s.db.GetProduct(c.Request.Context(), productUUID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, product)
}
