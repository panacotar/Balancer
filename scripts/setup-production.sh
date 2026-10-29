#!/usr/bin/env bash
set -euo pipefail
umask 077
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

if [ ! -f .env.production ]; then
  sha=$(git rev-parse --short HEAD 2>/dev/null || printf 'local')
  secret=$(openssl rand -hex 64)
  database_password=$(openssl rand -hex 32)
  cat > .env.production <<EOF
DOMAIN=balancer.organicdarius.com
GIT_SHA=${sha}
SECRET_KEY_BASE=${secret}
BALANCER_DATABASE_PASSWORD=${database_password}

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
echo "Production files ready. Set the Stripe test keys in .env.production before deploying."
