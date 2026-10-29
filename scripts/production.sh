#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
exec docker compose --project-directory "$root" \
  --env-file "$root/.env.production" \
  -f "$root/compose.production.yaml" "$@"
