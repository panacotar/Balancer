#!/usr/bin/env bash
set -euo pipefail
umask 077
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
# shellcheck disable=SC1091
source "$root/scripts/env-file.sh"

# True if nothing on this host is already listening on the given TCP port.
port_free() {
  port=$1
  if command -v ss >/dev/null 2>&1; then
    ! ss -H -ltn "( sport = :$port )" 2>/dev/null | grep -q .
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$port" <<'PY'
import socket, sys
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
try:
    s.bind(("0.0.0.0", int(sys.argv[1])))
except OSError:
    sys.exit(1)
finally:
    s.close()
PY
  else
    echo "Neither ss nor python3 is available to check port $port; assuming it is in use." >&2
    return 1
  fi
}

if [ ! -f .env.production ]; then
  sha=$(git rev-parse --short HEAD 2>/dev/null || printf 'local')
  secret=$(openssl rand -hex 64)
  database_password=$(openssl rand -hex 32)
  cat > .env.production <<EOF
DOMAIN=balancer.organicdarius.com
GIT_SHA=${sha}
SECRET_KEY_BASE=${secret}
BALANCER_DATABASE_PASSWORD=${database_password}
ACME_EMAIL=
CADDY_PROFILE=

# Stripe test keys. STRIPE_WEBHOOK_SECRET signs POST /stripe/webhook.
STRIPE_PUBLISHABLE_KEY=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=

# Optional error reporting.
SENTRY_DSN=

# Optional password-reset email. Leave SMTP_ADDRESS empty to boot without mail.
SMTP_ADDRESS=
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
MAIL_FROM=
EOF
fi
chmod 600 .env.production

if ! docker network inspect balancer-edge >/dev/null 2>&1; then
  docker network create balancer-edge >/dev/null
fi

"$root/scripts/ensure-uploads-volume.sh"

# Detect, every run, whether Balancer should run its own public Caddy.
if port_free 80 && port_free 443; then
  set_env_value CADDY_PROFILE caddy "$root/.env.production"
  echo "Production files ready. Ports 80/443 are free, so Balancer will run its own Caddy."
  echo "Set ACME_EMAIL, the Stripe test keys, and STRIPE_WEBHOOK_SECRET in .env.production before deploying."
else
  set_env_value CADDY_PROFILE "" "$root/.env.production"
  cat <<'EOF'
Production files ready. Ports 80/443 are already in use on this host, so
Balancer will not start its own Caddy.

The proxy that owns those ports needs two changes, described in doc/vps.md
section 4. They are not one command.

1. Join its container to the balancer-edge network:
     docker network connect balancer-edge <proxy-container>
   If Docker says the endpoint already exists, that step is already done.
2. Append a site for the DOMAIN hostname to that proxy's Caddyfile, then
   restart the proxy container. Pasting the site block into the shell does nothing.

Also set the Stripe test keys and STRIPE_WEBHOOK_SECRET in .env.production before deploying.
EOF
fi
