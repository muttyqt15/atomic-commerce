package main

import (
	"context"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	db "github.com/muttyqt15/atomic-commerce/packages/database/generated"
)

func main() {
	router := gin.Default()
	ctx := context.Background()
	conn, err := pgxpool.New(ctx, "postgres://postgres:qin123@localhost:5432/merchdrop?sslmode=disable")
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	database := db.New(conn)

	router.GET("/health", func(c *gin.Context) {
		data := gin.H{"lang": "GO语言"}
		c.AsciiJSON(http.StatusOK, data)
	})

	router.GET("/users", func(c *gin.Context) {
		data, err := database.GetAllUsers(ctx)
		if err != nil {
			log.Fatal(err)
		}
		c.JSON(http.StatusOK, data)
	})

	router.POST("/users", func(c *gin.Context) {
		var req db.CreateUserParams

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		user, err := database.CreateUser(ctx, req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusCreated, user)
	})

	err = router.Run(":8080")
	if err != nil {
		log.Fatal("error on starting api")
	}
}
