# Let's Encrypt SSL Certificate Renewal Guide

This guide explains how to update and renew the Let's Encrypt SSL certificates for the **eben-ai** infrastructure.

The certificates are currently stored in `/etc/letsencrypt` on the host machine and are mounted into the Nginx container.

## Prerequisites

- Access to the VPS via SSH.
- `certbot` installed on the host machine.
- Nginx container running (for HTTP-01 challenge) or Nginx stopped (for standalone mode).

---

## 1. Automated Renewal (Dry Run)

Before performing an actual renewal, test the process:

```bash
sudo certbot renew --dry-run
```

If the dry run is successful, you can proceed to the actual renewal.

## 2. Manual Renewal

To manually renew all certificates:

```bash
sudo certbot renew
```

### After Renewal: Reload Nginx

Once the certificates are updated on the host, the Nginx container must be reloaded to apply the new keys:

```bash
docker exec nginx_eben_ai nginx -s reload
```

---

## 3. Requesting a New Certificate (or replacing existing)

If you need to request a new certificate for the domains (n8n, baserow, portainer), use the following command. This uses the `webroot` method which is less disruptive.

```bash
sudo certbot certonly --webroot -w /var/www/html \
  -d n8n.eben-ai-one.ebenaisolutions.pt \
  -d baserow.eben-ai-one.ebenaisolutions.pt \
  -d portainer.eben-ai-one.ebenaisolutions.pt
```

*Note: Ensure your Nginx configuration allows access to `.well-known/acme-challenge/`.*

---

## 4. Troubleshooting

### Permission Issues
If the Nginx container cannot read the new certificates, check the permissions on the host:

```bash
sudo chmod -R 755 /etc/letsencrypt/archive
sudo chmod -R 755 /etc/letsencrypt/live
```

### Port 80/443 Conflict
If you see an error like `address already in use`, it means another process (often a standalone Nginx installation on the host) is already using port 80 or 443.

**To fix this:**
1. Check what is using the port:
   ```bash
   sudo lsof -i :80
   ```
2. If it's the host's Nginx, stop it:
   ```bash
   sudo systemctl stop nginx
   # And disable it from starting on boot if you only want Docker Nginx
   sudo systemctl disable nginx
   ```
3. **Stubborn Process:** If the port is still in use after stopping the service, force kill the process holding port 80:
   ```bash
   sudo fuser -k 80/tcp
   ```
4. Then start your Docker container:
   ```bash
   sudo docker compose up -d nginx
   ```

## 5. Automatic Cron Job (Recommended)

To ensure certificates never expire, add a cron job to the host:

1. Open crontab:
   ```bash
   sudo crontab -e
   ```

2. Add this line to run daily at 3:00 AM:
   ```cron
   0 3 * * * certbot renew --quiet && docker exec nginx_eben_ai nginx -s reload
   ```










(crontab -l 2>/dev/null; echo "0 3 * * * docker stop nginx_eben_ai && certbot renew --standalone --quiet && docker start nginx_eben_ai") | crontab -