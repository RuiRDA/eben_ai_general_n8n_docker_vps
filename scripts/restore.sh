#!/bin/sh
set -eu
: "${RESTORE_CONFIRMATION:?Set RESTORE_CONFIRMATION=isolated-empty-target}"
[ "$RESTORE_CONFIRMATION" = isolated-empty-target ] || exit 1
[ "$#" -eq 2 ] || { echo 'Usage: restore.sh maia.dump n8n.dump (decrypted in private storage)'; exit 1; }
docker compose stop app n8n
for db in maia n8n; do
  case "$db" in maia) archive=$1 ;; n8n) archive=$2 ;; esac
  tables=$(docker compose exec -T postgres psql -U maia_migrator -d "$db" -Atc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'")
  [ "$tables" = 0 ] || { echo 'Restore target must have an empty public schema.'; exit 1; }
  docker compose exec -T postgres pg_restore -U maia_migrator --exit-on-error -d "$db" < "$archive"
done
docker compose exec -T postgres psql -U maia_migrator -d maia -v ON_ERROR_STOP=1 <<'SQL'
UPDATE system_state SET paused=true;
UPDATE send_intents SET status='uncertain',error_code='restore_reconciliation' WHERE status='dispatching';
UPDATE campaigns SET status='paused' WHERE status='active';
UPDATE customer_care_tasks SET status='planned',approved_by=NULL,approved_at=NULL WHERE status IN('approved','queued');
UPDATE send_intents SET status='cancelled',error_code='restore_review' WHERE status='queued';
UPDATE ai_jobs SET status='cancelled',lease_token=NULL WHERE status IN('queued','running');
DELETE FROM auth_session;
UPDATE integration_credentials SET revoked_at=now();
SQL
echo 'Restored paused. Reconcile post-backup suppressions, deletions and provider sends before issuing credentials or restarting workers.'
