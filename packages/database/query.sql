-- name: GetProductsByStore :many
SELECT id, name, description, created_at, updated_at
FROM products
WHERE store_id = $1;

-- name: GetProductDetails :one
SELECT p.id, p.name, p.description, s.name AS store_name
FROM products p
         JOIN stores s ON p.store_id = s.id
WHERE p.id = $1;

-- name: CreateOrder :one
INSERT INTO orders (quantity, total_price, status, user_id, product_id, store_id, idempotency_key_id)
VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id;

-- name: ListOrdersByUser :many
SELECT o.id,
       o.quantity,
       o.total_price,
       o.status,
       o.created_at,
       o.updated_at,
       p.name AS product_name,
       s.name AS store_name
FROM orders o
         JOIN products p ON o.product_id = p.id
         JOIN stores s ON o.store_id = s.id
WHERE o.user_id = $1
ORDER BY o.created_at DESC;

-- name: FulfillOrder :exec
UPDATE orders
SET status     = 'fulfilled',
    updated_at = NOW()
WHERE id = $1;

-- name: CreatePayment :one
INSERT INTO payments (amount, method, status, order_id, idempotency_key_id)
VALUES ($1, $2, $3, $4, $5) RETURNING id;

-- name: CreateUser :one
INSERT INTO users (name, email, password_hash)
VALUES ($1, $2, $3) RETURNING id;

-- name: CreateStore :one
INSERT INTO stores (name, domain, description, admin_id)
VALUES ($1, $2, $3, $4) RETURNING id;

-- name: CreateProduct :one
INSERT INTO products (name, description, price, stock)
VALUES ($1, $2, $3, $4) RETURNING id;
