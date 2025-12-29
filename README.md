# PostgreSQL 18 + pgAdmin Docker Compose

Docker Compose setup for PostgreSQL 18 and pgAdmin 4.

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/hendisantika/postgres-pgadmin-compose.git
   cd postgres-pgadmin-compose
   ```

2. Create `.env` file from example:
   ```bash
   cp .env.example .env
   ```

3. Edit `.env` with your credentials:
   ```env
   POSTGRES_USER=your_username
   POSTGRES_PASSWORD=your_password
   POSTGRES_DB=postgres

   PGADMIN_DEFAULT_EMAIL=your_email@example.com
   PGADMIN_DEFAULT_PASSWORD=your_pgadmin_password
   ```

4. Start the services:
   ```bash
   docker compose up -d
   ```

5. Access the services:
   - **PostgreSQL**: `localhost:5432`
   - **pgAdmin**: http://localhost:5050

## Connecting pgAdmin to PostgreSQL

1. Open http://localhost:5050 in your browser
2. Login with your pgAdmin credentials from `.env`
3. Right-click **Servers** → **Register** → **Server**
4. In the **General** tab, enter a name (e.g., "Local PostgreSQL")
5. In the **Connection** tab:
   - Host: `postgres`
   - Port: `5432`
   - Username: your `POSTGRES_USER` value
   - Password: your `POSTGRES_PASSWORD` value
6. Click **Save**

## Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Stop services and remove volumes
docker compose down -v

# View logs
docker compose logs -f

# View PostgreSQL logs
docker compose logs -f postgres

# View pgAdmin logs
docker compose logs -f pgadmin
```

## Sample Data

The database is initialized with sample data on first startup:

**Schema:** `app`

| Table | Description |
|-------|-------------|
| `users` | Sample users with UUID primary keys |
| `categories` | Product categories (Electronics, Clothing, Books, etc.) |
| `products` | 12 sample products with prices and stock |
| `orders` | Sample orders with status tracking |
| `order_items` | Order line items |
| `order_summary` | View combining order details |

**Query examples:**

```sql
-- List all products
SELECT * FROM app.products;

-- Get order summary
SELECT * FROM app.order_summary;

-- Products by category
SELECT p.name, p.price, c.name as category
FROM app.products p
JOIN app.categories c ON p.category_id = c.id;
```

To reset sample data, remove volumes and restart:

```bash
docker compose down -v
docker compose up -d
```

## Backup and Restore

### Backup Single Database

```bash
./scripts/backup.sh
```

Creates a compressed backup in `backups/` directory with timestamp (e.g., `postgres_20251229_120000.sql.gz`).

### Backup All Databases

```bash
./scripts/backup-all.sh
```

Creates a full backup of all databases including roles and permissions.

### Restore Database

```bash
./scripts/restore.sh backups/postgres_20251229_120000.sql.gz
```

Or just the filename if it's in the backups directory:

```bash
./scripts/restore.sh postgres_20251229_120000.sql.gz
```

### Automated Backups (Cron)

Add to crontab for daily backups at 2 AM:

```bash
crontab -e
```

```cron
0 2 * * * /path/to/postgres-pgadmin-compose/scripts/backup.sh >> /var/log/pg_backup.log 2>&1
```

Backups older than 7 days are automatically deleted.

## Connecting from Applications

Use these connection details:

| Property | Value |
|----------|-------|
| Host | `localhost` |
| Port | `5432` |
| Database | Value of `POSTGRES_DB` |
| Username | Value of `POSTGRES_USER` |
| Password | Value of `POSTGRES_PASSWORD` |

Example connection string:
```
postgresql://your_username:your_password@localhost:5432/postgres
```

## License

MIT
