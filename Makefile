DB_DIR=./packages/database

.PHONY: sqlc-generate
sqlc-generate:
	cd $(DB_DIR) && sqlc generate