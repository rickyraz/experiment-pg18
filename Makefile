MIGRATION_DIR := db/migrations
DB_DSN := $(shell cat .env | grep DATABASE_URL | cut -d '=' -f2)

# Development
.PHONY: migrate-create
migrate-create:
ifndef name
	$(error Usage: make migrate-create name=your_migration_name)
endif
	goose -dir=$(MIGRATION_DIR) create $(name) sql

.PHONY: migrate-up migrate-down migrate-status
migrate-up:
	goose -dir=$(MIGRATION_DIR) postgres $(DB_DSN) up

migrate-down:
	goose -dir=$(MIGRATION_DIR) postgres $(DB_DSN) down

migrate-status:
	goose -dir=$(MIGRATION_DIR) postgres $(DB_DSN) status

# Production only
.PHONY: migrate-fix
migrate-fix:
	goose -dir=$(MIGRATION_DIR) fix