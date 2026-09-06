# RE/MAX Maia private infrastructure

Fresh single-client deployment for the paired Eben AI Real Estate OS app. PostgreSQL and n8n are private. Caddy exposes HTTPS to the app; `/api/internal/*` is blocked at the edge. No Docker socket, Portainer, public database, scraping service or MFA requirement.

## Install on client-controlled infrastructure

Use a patched Linux host with Docker Engine/Compose, age, util-linux/flock and sufficient memory (at least 8 GB recommended for configured limits). Restrict SSH to authorized administrators; expose only SSH and 80/443. Review SSH authentication independently of application passwords. No host changes are performed by this repository automatically.

1. Place this checkout in `/opt/maia`. Create a private `private/` directory (0700) and copy the examples. Generate independent random PostgreSQL owner, app runtime and n8n passwords, the app auth secret, a separate stable suppression HMAC key, and n8n encryption key. Files must be 0600 and excluded from Git.
2. Set APP_DOMAIN and MAIA_APP_IMAGE in `.env`. Build/tag the paired app's tested revision; use its immutable digest for MAIA_APP_IMAGE. Set app.env with the matching runtime DB URL (URL-encode the password), HTTPS public URL and private provider configuration. Set n8n.env with its separate database password/encryption key. Placeholders must never reach a deployed app.
3. `docker compose build postgres proxy n8n` then `docker compose up -d postgres`. The initializer creates separate maia and n8n databases and runtime roles. PostgreSQL has no host port. The owner/migration role is reserved for private maintenance.
4. Build the app Dockerfile `tools` target from the same tested commit. Run `scripts/migrate.mjs` privately on the Compose database network with the maia_migrator connection string. Apply the app's `db/runtime-grants.sql` through psql as maia_migrator. The public app must never receive owner credentials.
5. Bootstrap with the private tools image and BOOTSTRAP_EMAIL/BOOTSTRAP_PASSWORD. Use individual password accounts; no public setup or signup and no MFA. Do not put bootstrap passwords on shared command lines or in shell history.
6. Start app, n8n and proxy. Check health, HTTPS, unauthenticated redirects and edge denial of internal endpoints. Access the n8n editor only through `ssh -L 5678:127.0.0.1:5678 <host>` at http://localhost:5678; keep its individual password login. Its HTTP/non-secure cookie setting is specific to this loopback SSH tunnel, never a public editor.
7. Import the paired app's seven JSON workflows and configure separately scoped app credentials. All exports are inactive. n8n network calls allow only the app hostname; models and providers are called by the app. Execution content is not retained.

## Live configuration

All outbound is forced off in the base Compose file. Before the agreed pilot, create an explicit reviewed Compose override setting app OUTBOUND_ENABLED to true, verify PROVIDER_MODE=live, and enable the applicable channel launch flag after approved numbers/templates and permission checks. Also unpause the application. Set AI_LIVE_ENABLED only after paid model accounts and EU fallback are verified. Startup alone must not send messages.

WhatsApp: official Meta token, phone ID, app secret and callback challenge token. Recruitment/insights: separate Meta access, page/forms/campaign IDs and webhook secrets. SMS: Closum API key, numeric receiving sender, random URL callback token and verified CLOSUM_INBOUND_MODE. Closum V2 documentation does not describe a cryptographic callback signature; do not claim one. Verify the client's actual inbound event format/numbers before SMS_LAUNCH_APPROVED. Never enable access logging of callback tokens, phone numbers, message bodies or provider API query strings. Caddy does not configure access logging.

The app has no model or provider key in n8n workflows. Never restore/import the old workflow ZIP or previous environment: those carry old client logic and embedded credentials. Revoke any old provider/API credentials before creating fresh client-owned credentials.

## Daily backups, seven-day retention

Install age and keep the private decryption key under independent client-controlled custody. Configure private/backup.env using the public age recipient and an existing private backup directory on the client's infrastructure. `scripts/backup.sh` takes daily maia/n8n custom-format dumps, encrypts them, and keeps encrypted software/configuration archives in a separate subdirectory. It prunes only its own archives older than seven days after successful backups. No third-party backup vendor is added.

Install systemd/maia-backup.service and .timer in `/etc/systemd/system/`, reload systemd and enable the timer. Default is 03:00 Lisbon daily with missed-run recovery. Monitor service failure and the `last-success` timestamp; alert if older than 26 hours. The backup destination must have sufficient space. Validate an actual restore before launch and periodically thereafter.

Restore requires an isolated empty target, reviewed encrypted files, separately held age key and matching software revision. Decrypt into private temporary storage; set RESTORE_CONFIRMATION=isolated-empty-target and run `scripts/restore.sh maia.dump n8n.dump`. It refuses populated public schemas, stops app/n8n, restores with error checking, pauses campaigns/outbound, cancels queued sends/AI, removes care approvals, revokes sessions/integration keys, and leaves workers stopped. Reconcile provider sends, post-backup deletions and opt-outs before new credentials/startup. Remove decrypted temporary dumps after verification. Never restore into a running client database.

## Verification and updates

`python scripts/validate.py` verifies topology and fail-closed outbound defaults. CI validates Compose/Caddy, scans Git history and pinned image tags for high/critical vulnerabilities. Image tags are version pinned; resolve and record immutable digests at release. Apply vendor updates only with full app/flow/restore verification. Do not waive an unresolved scanner finding merely to deploy. Infrastructure CI requires Docker and public registry access.

Technical support is the contract's official email, weekdays 10:00–18:00 Portugal time excluding national holidays; first response targets 5/8/12 business hours for critical/urgent/general. These are separate from chatbot availability and the sales team's handoff staffing. See the paired app's contract matrix, metric definitions and operator runbook.

Security rebuilds: images/postgres.Dockerfile updates Alpine packages and rebuilds gosu with Go 1.27.1. images/caddy.Dockerfile rebuilds Caddy with the patched Go toolchain and fixed crypto/net/text/gRPC modules. CI scans the resulting images without suppressing high/critical findings. Record the built image digests with the release.

The n8n security image upgrades system packages and replaces audited fast-uri/nodemailer/toml copies using checksum-locked dependency archives. It preserves n8n 2.37.10 and its existing module links; it does not enable additional nodes or mail sending. CI scans and starts the patched image. Review/remove these narrowly scoped overrides when upstream releases incorporate the fixes.
