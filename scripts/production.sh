#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
exec docker compose --project-directory "$ROOT" --env-file "$ROOT/.env.production" \
  -f "$ROOT/compose.production.yaml" "$@"
