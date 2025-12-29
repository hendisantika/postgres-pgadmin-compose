# PostgreSQL 18 + pgAdmin Docker Compose

[![Test Docker Compose](https://github.com/hendisantika/postgres-pgadmin-compose/actions/workflows/test.yml/badge.svg)](https://github.com/hendisantika/postgres-pgadmin-compose/actions/workflows/test.yml)

Docker Compose setup for PostgreSQL 18 and pgAdmin 4.

## Prerequisites

- Ubuntu 24.04 (or compatible Linux)
- Docker & Docker Compose

## Deploy to Ubuntu Server

One-command deployment:

```bash
curl -fsSL https://raw.githubusercontent.com/hendisantika/postgres-pgadmin-compose/main/scripts/deploy.sh | bash
```

The script will automatically:
- Update system packages
- Install Docker & Docker Compose
- Clone repository
- Setup environment file
- Configure UFW firewall
- Create SSL directory

**Firewall ports opened:**

| Port | Service |
|------|---------|
| 22/tcp | SSH |
| 80/tcp | HTTP |
| 443/tcp | HTTPS |
| 5433/tcp | PostgreSQL via Nginx |

After deployment, follow the on-screen instructions to:
1. Edit `.env` with your credentials
2. Add Cloudflare SSL certificates
3. Start services with `make up-nginx-ssl`

## Quick Start (Local)

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
   - **Monitor Dashboard**: http://localhost:8888

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

Use `make help` to see all available commands:

```bash
make help
```

### Quick Reference

| Command | Description |
|---------|-------------|
| `make up` | Start all services |
| `make down` | Stop all services |
| `make restart` | Restart all services |
| `make ps` | Show running containers |
| `make status` | Show detailed status with DB info |
| `make logs` | View all logs |
| `make logs-postgres` | View PostgreSQL logs |
| `make logs-pgadmin` | View pgAdmin logs |
| `make shell` | Open PostgreSQL shell |
| `make shell-bash` | Open bash in PostgreSQL container |
| `make backup` | Backup database |
| `make backup-all` | Backup all databases |
| `make restore FILE=<file>` | Restore from backup |
| `make clean` | Stop and remove volumes |
| `make clean-all` | Remove everything including images |
| `make init` | Create .env from .env.example |
| `make up-nginx` | Start with nginx (HTTP) |
| `make up-nginx-ssl` | Start with nginx (HTTPS) |
| `make generate-ssl` | Generate self-signed SSL cert |

### Without Make

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Stop services and remove volumes
docker compose down -v

# View logs
docker compose logs -f

# Open PostgreSQL shell
docker exec -it postgres_db psql -U yu71 -d postgres
```

## Remote Access with Nginx

For remote access, use nginx as a reverse proxy.

### HTTP (Development)

```bash
make up-nginx
```

Access services:
- **pgAdmin**: http://your-server/pgadmin/
- **Monitor**: http://your-server/monitor/
- **PostgreSQL**: your-server:5433

### HTTPS with Cloudflare SSL

**Domains:**
- `pgadmin.mnet.web.id` - pgAdmin interface
- `pg.mnet.web.id` - Monitor dashboard + PostgreSQL TCP

**Setup:**

1. Generate Cloudflare Origin Certificate:
   - Go to Cloudflare Dashboard → SSL/TLS → Origin Server
   - Click "Create Certificate"
   - Select your hostnames: `*.mnet.web.id` or specific domains
   - Choose validity period (15 years recommended)
   - Click "Create"

2. Save certificates to `nginx/ssl/`:
   ```bash
   mkdir -p nginx/ssl

   # Save the Origin Certificate as cloudfare.pem
   nano nginx/ssl/cloudfare.pem

   # Save the Private Key as cloudfare.key
   nano nginx/ssl/cloudfare.key

   # Set permissions
   chmod 600 nginx/ssl/cloudfare.key
   chmod 644 nginx/ssl/cloudfare.pem
   ```

3. Configure Cloudflare DNS:
   ```
   pgadmin.mnet.web.id  →  A  →  your-server-ip  (Proxied - orange cloud)
   pg.mnet.web.id       →  A  →  your-server-ip  (DNS only - grey cloud for TCP)
   ```

4. Set Cloudflare SSL/TLS mode to **Full (strict)**

5. Start services:
   ```bash
   make up-nginx-ssl
   ```

**Access services:**
- **pgAdmin**: https://pgadmin.mnet.web.id
- **Monitor**: https://pg.mnet.web.id
- **PostgreSQL**: pg.mnet.web.id:5433

### Remote PostgreSQL Connection

```bash
# Connect via psql
psql -h pg.mnet.web.id -p 5433 -U your_username -d your_database

# Connection string
postgresql://your_username:your_password@pg.mnet.web.id:5433/your_database
```

**Important:** For PostgreSQL TCP connections, set `pg.mnet.web.id` to **DNS only** (grey cloud) in Cloudflare. Cloudflare proxy only supports HTTP/HTTPS traffic.

### Custom Ports

Edit `.env` to change default ports:

```env
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
NGINX_POSTGRES_PORT=5433
```

## Monitoring Dashboard

Access the health monitoring dashboard at http://localhost:8888

**Features:**
- Real-time container health status
- CPU and memory usage per container
- Network and Block I/O statistics
- PostgreSQL connection status and version
- Database size and active connections
- Table row counts and sizes
- Auto-refresh every 5 seconds

**API Endpoints:**
- `GET /api/status` - Full status JSON
- `GET /api/health` - Simple health check

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
