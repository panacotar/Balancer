#!/bin/bash
set -euo pipefail
export BALANCER_APP_PASSWORD
BALANCER_APP_PASSWORD=$(cat /run/secrets/db_password)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
\getenv app_password BALANCER_APP_PASSWORD
CREATE ROLE balancer LOGIN PASSWORD :'app_password' NOSUPERUSER NOCREATEDB NOCREATEROLE;
ALTER DATABASE balancer_production OWNER TO balancer;
GRANT ALL ON SCHEMA public TO balancer;
SQL
unset BALANCER_APP_PASSWORD
