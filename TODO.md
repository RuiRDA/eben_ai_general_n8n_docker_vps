# n8n Update Guide

This document outlines the steps to safely update the n8n Docker container to the latest version.

## Update Steps

1.  **Pull the latest n8n image:**
    This command downloads the newest version of the n8n image from Docker Hub.
    ```bash
    sudo docker pull n8nio/n8n:latest
    ```

2.  **Stop and remove the current n8n container:**
    This command stops and removes the running n8n container. Your data will be safe because it is stored in a Docker volume.
    ```bash
    sudo docker compose stop n8n
    sudo docker compose rm n8n
    ```

3.  **Recreate and start the n8n container:**
    This command recreates the n8n container using the newly pulled image and starts it. The `--no-deps` flag ensures that only the n8n service is recreated, leaving all other services untouched.
    ```bash
    sudo docker compose up -d --no-deps n8n
    ```

4.  **Clean up old images (Optional):**
    This command removes any old, unused Docker images to free up disk space.
    ```bash
    sudo docker image prune -f
    ```