#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

profile_args=()
if [ -f "$root/.env.production" ] && grep -q '^CADDY_PROFILE=caddy$' "$root/.env.production"; then
  profile_args=(--profile caddy)
fi

exec docker compose --project-directory "$root" \
  --env-file "$root/.env.production" \
  -f "$root/compose.production.yaml" "${profile_args[@]}" "$@"
