#!/bin/bash
source "$(dirname "$0")/deploy/common.sh"
[ "${1:-}" = --schema-compatible ] || {
  echo 'Usage: rollback-production.sh --schema-compatible (only after checking migration compatibility)' >&2; exit 1;
}
lock_operation
[ -f "$ROOT/.previous-release" ] || { echo 'No previous image recorded.' >&2; exit 1; }
image=$(cat "$ROOT/.previous-release")
docker image inspect "$image" >/dev/null
APP_IMAGE="$image" compose up -d --no-deps --no-build --wait web
verify_local
printf '%s\n' "$image" > "$ROOT/.release"
verify_public
echo 'Restored the previous application image. Set APP_IMAGE in .env.production to match .release.'
