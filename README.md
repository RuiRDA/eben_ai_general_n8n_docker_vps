# Eben AI - Infrastructure Setup Guide

This guide provides a step-by-step process for setting up the complete infrastructure on a Hetzner VPS using Docker.

## 1. Initial Server Setup

### 1.1. Connect to the VPS
Connect to your server using SSH with the provided IP address:
```bash
ssh root@YOUR_SERVER_IP
```

### 1.2. Create a Non-Root User

To enhance security, create a new user to avoid working as root.

```bash
# Create a new user
adduser <username>

# Grant administrative privileges
usermod -aG sudo <username>

# Set up SSH for the new user
rsync --archive --chown=<username>:<username> ~/.ssh /home/<username>
```

After creating the user, log out and log back in with the new user credentials:

```bash
ssh -i /path/to/your/ssh_key <username>@YOUR_SERVER_IP
```

### 1.3. Update and Install Dependencies
Update the server's package list and install necessary software:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx certbot python3-certbot-nginx htop git curl
```

### 1.4. Configure Firewall
Allow SSH and HTTP/HTTPS traffic through the firewall.
```bash
sudo ufw allow 'Nginx Full'
sudo ufw allow 'OpenSSH'
sudo ufw enable
```

## 2. Install Docker Engine

For further instructions, you can refer to the official documentation: https://docs.docker.com/engine/install/ubuntu/

### 2.1. Set up Docker's apt repository.

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

### 2.2. Install Docker packages.

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## 3. Clone the Repository

Clone the project repository to your server:
```bash
git clone <repo-url> .
cd ./
```

## 4. Configure Environment Variables

Create a `.env` file by copying the example and fill in your secure credentials:
```bash
cp .example_env .env
nano .env
```
**Important:** Replace all placeholder values (e.g., `secure_password_here`) with strong, unique passwords.

## 5. Setup DNS

In your domain provider's dashboard, create the following DNS records pointing to your server's IP address:

- **A Record (n8n):** `n8n.eben-ai-one.ebenaisolutions.pt` -> `YOUR_SERVER_IP`
- **A Record (Baserow):** `baserow.eben-ai-one.ebenaisolutions.pt` -> `YOUR_SERVER_IP`
- **A Record (Portainer):** `portainer.eben-ai-one.ebenaisolutions.pt` -> `YOUR_SERVER_IP`

## 6. Obtain SSL Certificates and Deploy

The host NGINX service must be running for Certbot to issue certificates, but it must be stopped before starting the Docker containers to avoid a port conflict.

### 6.1. Generate Certificates
Run Certbot to obtain the SSL certificates.
```bash
# Ensure the host NGINX is running for certificate validation
sudo systemctl start nginx

sudo certbot --nginx -d n8n.eben-ai-one.ebenaisolutions.pt -d baserow.eben-ai-one.ebenaisolutions.pt -d portainer.eben-ai-one.ebenaisolutions.pt --register-unsafely-without-email --agree-tos
```
Follow the on-screen instructions and choose to redirect HTTP traffic to HTTPS.

### 6.2. Deploy Docker Containers
Stop the host NGINX service and start all Docker services.
```bash
# Stop the host NGINX to free up port 80/443 for the container
sudo systemctl stop nginx

# Start the Docker containers
sudo docker compose up -d --force-recreate
```

## 7. Verify the Setup

- **Check container status:** `docker-compose ps`
- **Access services:**
  - **n8n:** `https://n8n.eben-ai-one.ebenaisolutions.pt`
  - **Baserow:** `https://baserow.eben-ai-one.ebenaisolutions.pt`
  - **Portainer:** `https://portainer.eben-ai-one.ebenaisolutions.pt`

## 8. Portainer First-Time Setup

When you first access Portainer, you will be prompted to create an administrator account. Set a strong password and connect to the local Docker environment.

## 9. Backups

Regular backups are configured for the PostgreSQL database. It is also recommended to back up the following files:
- `./docker-compose.yml`
- `./.env`
- The `/etc/letsencrypt` directory.