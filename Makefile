DB_DIR=./packages/database
DB_URL=postgres://postgres:qin123@localhost:5432/merchdrop?sslmode=disable

.PHONY: migrateup
migrateup:
	migrate -path $(DB_DIR)/migrations -database "$(DB_URL)" up

.PHONY: migratedn
migratedown:
	migrate -path $(DB_DIR)/migrations -database "$(DB_URL)" down

.PHONY: sqlc-generate
sqlc-generate:
	cd $(DB_DIR) && sqlc generate