#!/bin/sh
# Destructive operations are confined to this disposable synthetic CI project.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
export COMPOSE_PROJECT_NAME="maia-rehearsal-$$"
cd "$work"
trap 'docker compose down --volumes >/dev/null 2>&1 || true' EXIT HUP INT TERM
mkdir private backups
cp -R "$root/images" "$root/scripts" "$root/systemd" "$root/postgres" .
cp "$root/Caddyfile" .
touch .env private/app.env private/n8n.env
for name in postgres_password maia_runtime_password n8n_password; do
  openssl rand -hex 24 > "private/$name"
done
cat > docker-compose.yml <<'COMPOSE'
services:
  postgres:
    image: maia-postgres:test
    environment:
      POSTGRES_USER: maia_migrator
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    volumes:
      - ./postgres/init.sh:/docker-entrypoint-initdb.d/10-maia.sh:ro
      - ./private:/run/secrets:ro
  app:
    image: maia-postgres:test
    entrypoint: [sleep, infinity]
  n8n:
    image: maia-postgres:test
    entrypoint: [sleep, infinity]
COMPOSE
docker compose up -d
ready=false
for attempt in $(seq 1 45); do
  if docker compose exec -T postgres psql -U maia_migrator -d maia -Atc 'SELECT 1' >/dev/null 2>&1; then ready=true; break; fi
  sleep 2
done
[ "$ready" = true ]
docker compose exec -T postgres psql -U maia_migrator -d maia -v ON_ERROR_STOP=1 <<'SQL'
CREATE TABLE system_state(paused boolean); INSERT INTO system_state VALUES(false);
CREATE TABLE send_intents(status text,error_code text); INSERT INTO send_intents(status) VALUES('queued'),('dispatching'),('sent');
CREATE TABLE campaigns(status text); INSERT INTO campaigns VALUES('active');
CREATE TABLE customer_care_tasks(status text,approved_by text,approved_at timestamptz); INSERT INTO customer_care_tasks VALUES('queued','synthetic',now());
CREATE TABLE ai_jobs(status text,lease_token text); INSERT INTO ai_jobs VALUES('running','synthetic');
CREATE TABLE auth_session(id text); INSERT INTO auth_session VALUES('synthetic');
CREATE TABLE integration_credentials(revoked_at timestamptz); INSERT INTO integration_credentials VALUES(NULL);
CREATE TABLE fixture(value text); INSERT INTO fixture VALUES('synthetic-restore-evidence');
SQL
docker compose exec -T postgres psql -U maia_migrator -d n8n -v ON_ERROR_STOP=1 -c "CREATE TABLE fixture(value text); INSERT INTO fixture VALUES('synthetic-workflow');"
age-keygen -o "$work/key.txt" 2>/dev/null
export BACKUP_AGE_RECIPIENT BACKUP_DESTINATION="$work/backups"
BACKUP_AGE_RECIPIENT=$(age-keygen -y "$work/key.txt")
touch backups/maia-expired.dump.age backups/n8n-recent.dump.age backups/unrelated.age
touch -d '8 days ago' backups/maia-expired.dump.age backups/unrelated.age
touch -d '6 days ago' backups/n8n-recent.dump.age
sh scripts/backup.sh
[ ! -f backups/maia-expired.dump.age ]
[ -f backups/n8n-recent.dump.age ] && [ -f backups/unrelated.age ] && [ -s backups/last-success ]
for db in maia n8n; do
  archive=$(find backups -maxdepth 1 -name "$db-20*.dump.age" -print)
  age -d -i key.txt "$archive" > "$db.dump"
done
config=$(find backups/configuration -name 'config-*.tar.gz.age' -print)
age -d -i key.txt "$config" > configuration.tar.gz
tar -tzf configuration.tar.gz | grep -q './images/n8n.Dockerfile'
if RESTORE_CONFIRMATION=isolated-empty-target sh scripts/restore.sh maia.dump n8n.dump; then
  echo 'ERROR: nonempty restore target accepted'; exit 1
fi
for db in maia n8n; do
  docker compose exec -T postgres psql -U maia_migrator -d "$db" -v ON_ERROR_STOP=1 -c 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'
done
RESTORE_CONFIRMATION=isolated-empty-target sh scripts/restore.sh maia.dump n8n.dump
result=$(docker compose exec -T postgres psql -U maia_migrator -d maia -Atc "SELECT (SELECT paused FROM system_state) AND NOT EXISTS(SELECT 1 FROM auth_session) AND NOT EXISTS(SELECT 1 FROM integration_credentials WHERE revoked_at IS NULL) AND NOT EXISTS(SELECT 1 FROM send_intents WHERE status IN('queued','dispatching')) AND NOT EXISTS(SELECT 1 FROM campaigns WHERE status='active') AND NOT EXISTS(SELECT 1 FROM ai_jobs WHERE status='running') AND NOT EXISTS(SELECT 1 FROM customer_care_tasks WHERE approved_by IS NOT NULL) AND EXISTS(SELECT 1 FROM fixture WHERE value='synthetic-restore-evidence')")
[ "$result" = t ]
[ "$(docker compose exec -T postgres psql -U maia_migrator -d n8n -Atc 'SELECT value FROM fixture')" = synthetic-workflow ]
echo 'PASS encrypted database/configuration backups, seven-day pruning, nonempty-target rejection, isolated restore and pause/revocation controls'
