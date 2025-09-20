-- users
-- name: CreateUser :one
INSERT INTO users (name, email, password_hash)
VALUES ($1, $2, $3)
    RETURNING *;

-- name: GetUser :one
SELECT * FROM users
WHERE id = $1;

-- name: GetAllUsers :many
SELECT * FROM users
ORDER BY created_at DESC;

-- name: UpdateUser :one
UPDATE users
SET name = $2, email = $3, password_hash = $4, is_active = $5, role = $6, updated_at = now()
WHERE id = $1
    RETURNING *;

-- name: DeleteUser :exec
DELETE FROM users
WHERE id = $1;


-- stores
-- name: CreateStore :one
INSERT INTO stores (name, domain, description, admin_id)
VALUES ($1, $2, $3, $4)
    RETURNING *;

-- name: GetStore :one
SELECT * FROM stores WHERE id = $1;

-- name: GetAllStores :many
SELECT * FROM stores ORDER BY created_at DESC;

-- name: UpdateStore :one
UPDATE stores
SET name = $2, domain = $3, description = $4, updated_at = now()
WHERE id = $1
    RETURNING *;

-- name: DeleteStore :exec
DELETE FROM stores WHERE id = $1;


-- products
-- name: CreateProduct :one
INSERT INTO products (name, description, price, stock, store_id)
VALUES ($1, $2, $3, $4, $5)
    RETURNING *;

-- name: GetProduct :one
SELECT * FROM products WHERE id = $1;

-- name: GetAllProducts :many
SELECT * FROM products ORDER BY created_at DESC;

-- name: UpdateProductStock :one
UPDATE products
SET stock = stock - $2, updated_at = now()
WHERE id = $1 AND stock >= $2
    RETURNING *;

-- name: UpdateProductStockAbsolute :one
UPDATE products
SET stock = $2, updated_at = now()
WHERE id = $1
    RETURNING *;

-- name: UpdateProduct :one
UPDATE products
SET name = $2, description = $3, price = $4, stock = $5, updated_at = now()
WHERE id = $1
    RETURNING *;

-- name: DeleteProduct :exec
DELETE FROM products WHERE id = $1;


-- orders
-- name: CreateOrder :one
INSERT INTO orders (quantity, total_price, user_id, product_id, store_id, idempotency_key_id)
VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING *;

-- name: GetOrder :one
SELECT * FROM orders WHERE id = $1;

-- name: GetAllOrders :many
SELECT * FROM orders ORDER BY created_at DESC;

-- name: UpdateOrderStatus :one
UPDATE orders
SET status = $2, updated_at = now()
WHERE id = $1
    RETURNING *;

-- name: DeleteOrder :exec
DELETE FROM orders WHERE id = $1;


-- order_items
-- name: CreateOrderItem :one
INSERT INTO order_items (order_id, product_id, quantity)
VALUES ($1, $2, $3)
    RETURNING *;

-- name: GetOrderItems :many
SELECT * FROM order_items WHERE order_id = $1;

-- name: DeleteOrderItems :exec
DELETE FROM order_items WHERE order_id = $1;


-- payments
-- name: CreatePayment :one
INSERT INTO payments (amount, method, order_id, idempotency_key_id)
VALUES ($1, $2, $3, $4)
    RETURNING *;

-- name: GetPayment :one
SELECT * FROM payments WHERE id = $1;

-- name: GetPaymentsForOrder :many
SELECT * FROM payments WHERE order_id = $1;

-- name: UpdatePaymentStatus :one
UPDATE payments
SET status = $2, updated_at = now()
WHERE id = $1
    RETURNING *;

-- name: DeletePayment :exec
DELETE FROM payments WHERE id = $1;

-- name: GetProductForUpdate :one
-- Get product details and lock the row for the duration of the transaction.
-- This is the query that PREVENTS the race condition.
-- "FOR NO KEY UPDATE" is a slightly less restrictive lock than "FOR UPDATE",
-- which is often sufficient and better for concurrency.
SELECT stock, price, store_id
FROM products
WHERE id = $1
    FOR NO KEY UPDATE;


-- idempotency_keys
-- name: CreateIdempotencyKey :one
INSERT INTO idempotency_keys (key, used_for, user_id)
VALUES ($1, $2, $3)
    RETURNING *;

-- name: GetIdempotencyKeyByKey :one
SELECT id, key, used_for, created_at, user_id
FROM idempotency_keys
WHERE key = $1;

-- name: GetIdempotencyKeyByID :one
SELECT id, key, used_for, created_at, user_id
FROM idempotency_keys
WHERE id = $1;

-- name: GetOrderByIdempotencyKeyID :one
SELECT id, quantity, total_price, status, created_at, updated_at, user_id, product_id, store_id, idempotency_key_id
FROM orders
WHERE idempotency_key_id = $1;

-- name: DeleteIdempotencyKey :exec
DELETE FROM idempotency_keys
WHERE id = $1;

-- name: CleanupOldIdempotencyKeys :exec
DELETE FROM idempotency_keys
WHERE created_at < NOW() - INTERVAL '24 hours'
  AND used_for = $1;