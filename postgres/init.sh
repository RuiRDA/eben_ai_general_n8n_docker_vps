#!/bin/sh
set -eu
# Values are passed as psql variables and SQL-quoted with :'name'. Never echo them.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres   --set=maia_password="$(cat /run/secrets/maia_runtime_password)"   --set=n8n_password="$(cat /run/secrets/n8n_password)" <<'SQL'
REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;
CREATE ROLE maia_runtime LOGIN PASSWORD :'maia_password' NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE n8n_runtime LOGIN PASSWORD :'n8n_password' NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE DATABASE maia OWNER maia_migrator;
CREATE DATABASE n8n OWNER n8n_runtime;
REVOKE ALL ON DATABASE maia FROM PUBLIC;
REVOKE ALL ON DATABASE n8n FROM PUBLIC;
GRANT CONNECT ON DATABASE maia TO maia_runtime;
GRANT CONNECT ON DATABASE n8n TO n8n_runtime;
\connect maia
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO maia_runtime;
SQL
