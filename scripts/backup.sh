#!/bin/sh
set -eu
umask 077
: "${BACKUP_AGE_RECIPIENT:?Set client-owned age public recipient}"
: "${BACKUP_DESTINATION:?Set an existing private directory on client infrastructure}"
command -v age >/dev/null
command -v flock >/dev/null
[ -d "$BACKUP_DESTINATION" ]
exec 9>"$BACKUP_DESTINATION/.backup.lock"
flock -n 9 || exit 1
stamp=$(date -u +%Y%m%dT%H%M%SZ)
tmp=$(mktemp "$BACKUP_DESTINATION/.dump.XXXXXX")
trap 'rm -f "$tmp"' EXIT HUP INT TERM
for db in maia n8n; do
  docker compose exec -T postgres pg_dump -U maia_migrator -d "$db" -Fc > "$tmp"
  [ -s "$tmp" ]
  age -r "$BACKUP_AGE_RECIPIENT" -o "$BACKUP_DESTINATION/$db-$stamp.dump.age" "$tmp"
  : > "$tmp"
done
# Software/configuration only, kept separately from customer databases.
mkdir -p "$BACKUP_DESTINATION/configuration"
tar -czf "$tmp" ./private/app.env ./private/n8n.env ./private/postgres_password ./private/maia_runtime_password ./private/n8n_password ./.env ./Caddyfile ./docker-compose.yml ./postgres/init.sh ./images ./scripts ./systemd
age -r "$BACKUP_AGE_RECIPIENT" -o "$BACKUP_DESTINATION/configuration/config-$stamp.tar.gz.age" "$tmp"
# Exactly seven days. Scope pruning to this script's encrypted archive names.
find "$BACKUP_DESTINATION" -maxdepth 1 -type f \( -name 'maia-*.dump.age' -o -name 'n8n-*.dump.age' \) -mmin +10080 -delete
find "$BACKUP_DESTINATION/configuration" -maxdepth 1 -type f -name 'config-*.tar.gz.age' -mmin +10080 -delete
date -u +%FT%TZ > "$BACKUP_DESTINATION/last-success"
