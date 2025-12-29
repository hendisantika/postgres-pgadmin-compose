.PHONY: help up down restart logs logs-postgres logs-pgadmin ps shell backup backup-all restore clean clean-all status

# Load environment variables
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Default target
help:
	@echo "PostgreSQL + pgAdmin Docker Compose"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  up            Start all services"
	@echo "  down          Stop all services"
	@echo "  restart       Restart all services"
	@echo "  ps            Show running containers"
	@echo "  status        Show detailed status"
	@echo ""
	@echo "  logs          View all logs"
	@echo "  logs-postgres View PostgreSQL logs"
	@echo "  logs-pgadmin  View pgAdmin logs"
	@echo ""
	@echo "  shell         Open PostgreSQL shell"
	@echo "  shell-bash    Open bash in PostgreSQL container"
	@echo ""
	@echo "  backup        Backup database"
	@echo "  backup-all    Backup all databases"
	@echo "  restore       Restore database (usage: make restore FILE=backup.sql.gz)"
	@echo ""
	@echo "  clean         Stop services and remove volumes"
	@echo "  clean-all     Remove everything including images and backups"
	@echo ""
	@echo "  init          Initialize environment (.env from .env.example)"

# Service management
up:
	docker compose up -d
	@echo ""
	@echo "Services started!"
	@echo "  PostgreSQL: localhost:5432"
	@echo "  pgAdmin:    http://localhost:5050"

down:
	docker compose down

restart:
	docker compose restart

ps:
	docker compose ps

status:
	@echo "=== Container Status ==="
	@docker compose ps
	@echo ""
	@echo "=== PostgreSQL Version ==="
	@docker exec postgres_db psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "SELECT version();" 2>/dev/null || echo "PostgreSQL not running"
	@echo ""
	@echo "=== Database Size ==="
	@docker exec postgres_db psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname)) AS size FROM pg_database ORDER BY pg_database_size(pg_database.datname) DESC;" 2>/dev/null || echo "PostgreSQL not running"

# Logs
logs:
	docker compose logs -f

logs-postgres:
	docker compose logs -f postgres

logs-pgadmin:
	docker compose logs -f pgadmin

# Database access
shell:
	@docker exec -it postgres_db psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

shell-bash:
	@docker exec -it postgres_db bash

# Backup and restore
backup:
	@./scripts/backup.sh

backup-all:
	@./scripts/backup-all.sh

restore:
ifndef FILE
	@echo "Usage: make restore FILE=backups/your_backup.sql.gz"
	@echo ""
	@echo "Available backups:"
	@ls -lh backups/*.sql.gz 2>/dev/null || echo "  No backups found"
else
	@./scripts/restore.sh $(FILE)
endif

# Cleanup
clean:
	docker compose down -v
	@echo "Volumes removed"

clean-all:
	docker compose down -v --rmi all
	rm -rf backups/*
	@echo "All resources removed"

# Initialize
init:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo ".env file created from .env.example"; \
		echo "Please edit .env with your credentials"; \
	else \
		echo ".env file already exists"; \
	fi
