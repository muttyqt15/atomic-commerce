DB_DIR=./packages/database
DB_URL=postgres://postgres:qin123@localhost:5432/merchdrop?sslmode=disable

.PHONY: migrateup
migrateup:
	migrate -path $(DB_DIR)/migrations -database "$(DB_URL)" up
	$(MAKE) generate-schema
	$(MAKE) sqlc-generate

.PHONY: migratedown
migratedown:
	migrate -path $(DB_DIR)/migrations -database "$(DB_URL)" down
	$(MAKE) generate-schema
	$(MAKE) sqlc-generate

.PHONY: generate-schema
generate-schema:
	pg_dump --schema-only --no-owner --no-privileges "$(DB_URL)" > $(DB_DIR)/migrations/schema.sql

.PHONY: sqlc-generate
sqlc-generate:
	cd $(DB_DIR) && sqlc generate

.PHONY: dev-api
dev-api:
	@echo "🚀 Starting API Gateway in dev mode..."
	cd apps/api && air

.PHONY: dev-worker
dev-worker:
	@echo "🚀 Starting Worker Service in dev mode..."
	cd apps/worker && air