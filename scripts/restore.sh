#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"

# Load environment variables
if [ -f "${PROJECT_DIR}/.env" ]; then
    export $(grep -v '^#' "${PROJECT_DIR}/.env" | xargs)
else
    echo "Error: .env file not found"
    exit 1
fi

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file.sql.gz>"
    echo ""
    echo "Available backups:"
    if [ -d "$BACKUP_DIR" ]; then
        ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "  No backups found in $BACKUP_DIR"
    else
        echo "  Backup directory not found"
    fi
    exit 1
fi

BACKUP_FILE="$1"

# Check if file exists
if [ ! -f "$BACKUP_FILE" ]; then
    # Try looking in backups directory
    if [ -f "${BACKUP_DIR}/$BACKUP_FILE" ]; then
        BACKUP_FILE="${BACKUP_DIR}/$BACKUP_FILE"
    else
        echo "Error: Backup file not found: $BACKUP_FILE"
        exit 1
    fi
fi

echo "WARNING: This will overwrite the current database '${POSTGRES_DB}'!"
read -p "Are you sure you want to continue? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Restore cancelled"
    exit 0
fi

echo "Starting restore from: $BACKUP_FILE"

# Drop existing connections and recreate database
echo "Dropping existing database..."
docker exec postgres_db psql -U "$POSTGRES_USER" -d postgres -c "
    SELECT pg_terminate_backend(pg_stat_activity.pid)
    FROM pg_stat_activity
    WHERE pg_stat_activity.datname = '${POSTGRES_DB}'
    AND pid <> pg_backend_pid();" 2>/dev/null || true

docker exec postgres_db psql -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS ${POSTGRES_DB};"
docker exec postgres_db psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};"

# Restore from backup
echo "Restoring database..."
gunzip -c "$BACKUP_FILE" | docker exec -i postgres_db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"

if [ $? -eq 0 ]; then
    echo "Restore completed successfully!"
else
    echo "Error: Restore failed"
    exit 1
fi

echo "Done!"
