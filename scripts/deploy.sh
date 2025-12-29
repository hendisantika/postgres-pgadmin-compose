#!/bin/bash

set -e

# ============================================
# PostgreSQL + pgAdmin Deployment Script
# For Ubuntu 24.04
# ============================================

echo "=========================================="
echo "PostgreSQL + pgAdmin Deployment"
echo "=========================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please run as a regular user (not root)"
    exit 1
fi

# Variables
INSTALL_DIR="${HOME}/postgres-pgadmin-compose"
REPO_URL="https://github.com/hendisantika/postgres-pgadmin-compose.git"

# Step 1: Update system
echo ""
echo "[1/6] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install Docker if not installed
echo ""
echo "[2/6] Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
    echo "Docker installed. You may need to log out and back in for group changes."
else
    echo "Docker already installed: $(docker --version)"
fi

# Step 3: Install Docker Compose plugin if not installed
echo ""
echo "[3/6] Checking Docker Compose..."
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose plugin..."
    sudo apt install -y docker-compose-plugin
else
    echo "Docker Compose already installed: $(docker compose version)"
fi

# Step 4: Clone or update repository
echo ""
echo "[4/6] Setting up repository..."
if [ -d "$INSTALL_DIR" ]; then
    echo "Repository exists, pulling latest changes..."
    cd "$INSTALL_DIR"
    git pull
else
    echo "Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Step 5: Setup environment
echo ""
echo "[5/6] Setting up environment..."
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo ""
    echo "============================================"
    echo "IMPORTANT: Edit .env file with your credentials!"
    echo "============================================"
    echo ""
    echo "Run: nano $INSTALL_DIR/.env"
    echo ""
    echo "Set the following values:"
    echo "  POSTGRES_USER=your_username"
    echo "  POSTGRES_PASSWORD=your_secure_password"
    echo "  POSTGRES_DB=your_database"
    echo "  PGADMIN_DEFAULT_EMAIL=your_email"
    echo "  PGADMIN_DEFAULT_PASSWORD=your_secure_password"
    echo ""
else
    echo ".env file already exists"
fi

# Step 6: Setup SSL directory
echo ""
echo "[6/6] Setting up SSL directory..."
mkdir -p nginx/ssl

if [ ! -f "nginx/ssl/cloudflare.pem" ] || [ ! -f "nginx/ssl/cloudflare.key" ]; then
    echo ""
    echo "============================================"
    echo "IMPORTANT: Add Cloudflare SSL certificates!"
    echo "============================================"
    echo ""
    echo "1. Go to Cloudflare Dashboard → SSL/TLS → Origin Server"
    echo "2. Create Origin Certificate for:"
    echo "   - pgadmin.mnet.web.id"
    echo "   - pg.mnet.web.id"
    echo ""
    echo "3. Save certificates:"
    echo "   nano $INSTALL_DIR/nginx/ssl/cloudflare.pem"
    echo "   nano $INSTALL_DIR/nginx/ssl/cloudflare.key"
    echo ""
    echo "4. Set permissions:"
    echo "   chmod 600 $INSTALL_DIR/nginx/ssl/cloudflare.key"
    echo ""
fi

echo ""
echo "=========================================="
echo "Deployment preparation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Edit .env file:"
echo "   nano $INSTALL_DIR/.env"
echo ""
echo "2. Add Cloudflare certificates to nginx/ssl/"
echo ""
echo "3. Start services:"
echo "   cd $INSTALL_DIR"
echo "   make up-nginx-ssl"
echo ""
echo "4. Configure Cloudflare DNS:"
echo "   pgadmin.mnet.web.id → A → $(curl -s ifconfig.me) (Proxied)"
echo "   pg.mnet.web.id → A → $(curl -s ifconfig.me) (DNS only)"
echo ""
