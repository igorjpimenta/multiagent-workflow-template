SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECT_ROOT := ~/agents/template

.PHONY: help up down destroy-postgres destroy-redis destroy-api destroy logs logs-api logs-redis logs-postgres build build-api build-redis build-postgres run run-api run-postgres run-redis migration-create migration-init migration-upgrade migration-current migration-history migration-check migration-copy clean

# Default target
help:
	@echo "Available commands:"
	@echo ""
	@echo "🐳 Docker Commands:"
	@echo "  up         - Start all Docker containers"
	@echo "  down       - Stop all Docker containers"
	@echo "  destroy-postgres - Destroy Postgres container"
	@echo "  destroy-redis - Destroy Redis container"
	@echo "  destroy-api - Destroy API container"
	@echo "  destroy    - Destroy Docker containers and volumes"
	@echo "  logs       - View logs for all services"
	@echo "  logs-api   - View API logs"
	@echo "  logs-redis - View Redis logs"
	@echo "  logs-postgres - View Postgres logs"
	@echo ""
	@echo "🏗️  Build Commands:"
	@echo "  build      - Build all Docker images"
	@echo "  build-api  - Build API Docker image"
	@echo "  build-redis - Build Redis Docker image"
	@echo "  build-postgres - Build Postgres Docker image"
	@echo ""
	@echo "💻 Development Commands:"
	@echo "  run        - Start development environment (all services)"
	@echo "  run-api    - Start API development server"
	@echo "  run-postgres - Start Postgres container"
	@echo "  run-redis  - Start Redis container"
	@echo ""
	@echo "🗄️  Database Migration Commands:"
	@echo "  migration-create MESSAGE=\"message\" - Create a new migration"
	@echo "  migration-init - Initialize database with all migrations"
	@echo "  migration-upgrade - Upgrade database to latest migration"
	@echo "  migration-current - Show current database revision"
	@echo "  migration-history - Show migration history"
	@echo "  migration-check - Check database migration status"
	@echo "  migration-copy - Copy migration files from environment to project"
	@echo ""
	@echo "🧹 Utility Commands:"
	@echo "  clean      - Clean up temporary files and Docker resources"

# Development commands
run:
	@echo "🚀 Starting all services..."
	cd $(SCRIPT_DIR) && ./bin/setup-workspace.sh && cd $(PROJECT_ROOT) && ./bin/local-run.sh

run-api:
	@echo "🚀 Starting API development server..."
	cd $(SCRIPT_DIR) && ./bin/setup-workspace.sh && cd $(PROJECT_ROOT) && ./bin/local-run.sh --no-postgres --no-redis

run-postgres:
	@echo "🚀 Starting Postgres container..."
	cd $(SCRIPT_DIR) && ./bin/local-run.sh --no-api --no-redis

run-redis:
	@echo "🚀 Starting Redis container..."
	cd $(SCRIPT_DIR) && ./bin/local-run.sh --no-api --no-postgres

# Build commands
build:
	@echo "🏗️  Building all Docker images..."
	docker compose -f docker-compose.yml --env-file .env build

build-api:
	@echo "🏗️  Building API Docker image..."
	docker compose -f docker-compose.yml --env-file .env build api

build-redis:
	@echo "🏗️  Building Redis Docker image..."
	docker compose -f docker-compose.yml --env-file .env build redis

build-postgres:
	@echo "🏗️  Building Postgres Docker image..."
	docker compose -f docker-compose.yml --env-file .env build postgres

up:
	@echo "🐳 Starting all Docker containers..."
	docker compose -f docker-compose.yml --env-file .env up --build --remove-orphans -d

down:
	@echo "🐳 Stopping Docker containers..."
	docker compose down

destroy-postgres:
	@echo "🐳 Destroying Postgres container..."
	docker compose down postgres -v

destroy-redis:
	@echo "🐳 Destroying Redis container..."
	docker compose down redis -v

destroy:
	@echo "🐳 Destroying Docker containers and volumes..."
	docker compose down -v

# Logs
logs:
	docker compose logs -f

logs-api:
	docker compose logs -f api

logs-redis:
	docker compose logs -f redis

logs-postgres:
	docker compose logs -f postgres

# Database Migration Commands
migration-create:
	@if [ -z "$(MESSAGE)" ]; then \
		echo "❌ Error: MESSAGE is required"; \
		echo "Usage: make migration-create MESSAGE=\"your migration message\""; \
		exit 1; \
	fi
	@echo "📝 Creating new migration: $(MESSAGE)"
	cd $(SCRIPT_DIR) && ./bin/setup-workspace.sh --build && cd $(PROJECT_ROOT) && ./bin/migrate.sh create "$(MESSAGE)"
	migration-copy
	@echo "🎉 Migration created successfully"
	@echo "🔍 To apply the migration, run: make migration-upgrade"

migration-init:
	@echo "🗄️  Initializing database with all migrations..."
	cd $(SCRIPT_DIR) && ./bin/setup-workspace.sh --build && cd $(PROJECT_ROOT) && ./bin/migrate.sh init

migration-upgrade:
	@echo "⬆️  Upgrading database to latest migration..."
	cd $(SCRIPT_DIR) && ./bin/setup-workspace.sh --build && cd $(PROJECT_ROOT) && ./bin/migrate.sh upgrade

migration-downgrade:
	@echo "⬇️  Downgrading database to previous migration..."
	cd $(SCRIPT_DIR) && ./bin/setup-workspace.sh --build && cd $(PROJECT_ROOT) && ./bin/migrate.sh downgrade $(REVISION)

migration-current:
	@echo "📍 Checking current database revision..."
	cd $(SCRIPT_DIR) && ./bin/setup-workspace.sh && cd $(PROJECT_ROOT) && ./bin/migrate.sh current

migration-history:
	@echo "📜 Showing migration history..."
	cd $(SCRIPT_DIR) && ./bin/setup-workspace.sh && cd $(PROJECT_ROOT) && ./bin/migrate.sh history

migration-check:
	@echo "🔍 Checking database migration status..."
	cd $(SCRIPT_DIR) && ./bin/setup-workspace.sh && cd $(PROJECT_ROOT) && ./bin/migrate.sh check

migration-copy:
	@echo "📋 Copying migration files from environment to project..."
	cd $(SCRIPT_DIR) && ./bin/copy-migrations.sh

clean:
	@echo "🧹 Cleaning up temporary files and Docker resources..."
	docker compose down -v
	docker compose rm -f
	rm -rf $(PROJECT_ROOT)