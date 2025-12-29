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

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/all_databases_${TIMESTAMP}.sql.gz"

echo "Starting backup of all databases..."

# Run pg_dumpall inside container and compress
docker exec postgres_db pg_dumpall -U "$POSTGRES_USER" | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "Backup completed successfully!"
    echo "File: $BACKUP_FILE"
    echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
else
    echo "Error: Backup failed"
    rm -f "$BACKUP_FILE"
    exit 1
fi

# Optional: Remove backups older than 7 days
find "$BACKUP_DIR" -name "all_databases_*.sql.gz" -type f -mtime +7 -delete 2>/dev/null || true

echo "Done!"
