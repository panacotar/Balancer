#!/bin/bash
set -euo pipefail
umask 077
ROOT=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$ROOT/deploy/secrets" "$ROOT/backups"
chmod 700 "$ROOT/deploy/secrets" "$ROOT/backups"
if [ ! -e "$ROOT/.env.production" ]; then
  cp "$ROOT/.env.production.example" "$ROOT/.env.production"
fi
for name in secret_key_base db_password db_admin_password; do
  if [ ! -e "$ROOT/deploy/secrets/$name" ]; then
    openssl rand -hex 64 > "$ROOT/deploy/secrets/$name"
  fi
done
for name in smtp_password stripe_secret_key stripe_publishable_key stripe_webhook_secret cloudinary_url sentry_dsn; do
  if [ ! -e "$ROOT/deploy/secrets/$name" ]; then
    : > "$ROOT/deploy/secrets/$name"
  fi
done
# Compose file secrets retain host ownership. Readability inside non-root
# containers is required; the 0700 parent keeps them private on the host.
chmod 644 "$ROOT"/deploy/secrets/*
printf '%s\n' 'Created/preserved .env.production and deploy/secrets/.' \
  'Edit SMTP configuration and its secret file before deploying. Never regenerate existing database passwords.'
