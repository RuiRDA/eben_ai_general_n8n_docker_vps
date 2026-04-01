#!/bin/bash

echo "=========================================="
echo "Starting Certificate Renewal Process"
echo "$(date)"
echo "=========================================="

# 1. Stop the Docker Nginx container
echo "[1/5] Stopping Docker Nginx container..."
# FIXED PATH BELOW
cd /home/rui/eben_ai_general_n8n_docker_vps || exit
docker compose stop nginx

# 2. Start the Host Nginx service
echo "[2/5] Starting Host Nginx service for validation..."
systemctl start nginx

# 3. Run Certbot Renewal
echo "[3/5] Requesting certificate renewal..."
certbot renew

# 4. Stop the Host Nginx service
echo "[4/5] Stopping Host Nginx service..."
systemctl stop nginx

# 5. Restart the Docker Nginx container
echo "[5/5] Restarting Docker Nginx container..."
docker compose up -d nginx

echo "=========================================="
echo "Renewal Process Complete"
echo "=========================================="