-- name: GetUserByEmailAndStore :one
SELECT * FROM users
WHERE store_id = $1 AND email = $2;

-- name: CreateUser :one
INSERT INTO users (store_id, name, email, password_hash, role)
VALUES ($1, $2, $3, $4, $5)
    RETURNING *;
