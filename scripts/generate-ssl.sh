#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SSL_DIR="${PROJECT_DIR}/nginx/ssl"

# Create SSL directory
mkdir -p "$SSL_DIR"

# Generate self-signed certificate
echo "Generating self-signed SSL certificate..."

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_DIR/key.pem" \
    -out "$SSL_DIR/cert.pem" \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,DNS:*.localhost,IP:127.0.0.1"

chmod 600 "$SSL_DIR/key.pem"
chmod 644 "$SSL_DIR/cert.pem"

echo ""
echo "SSL certificate generated successfully!"
echo "  Certificate: $SSL_DIR/cert.pem"
echo "  Private Key: $SSL_DIR/key.pem"
echo ""
echo "Note: This is a self-signed certificate for development only."
echo "For production, use certificates from a trusted CA (e.g., Let's Encrypt)."
