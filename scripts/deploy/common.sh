#!/bin/bash
# Sourced by maintenance commands; never source the environment file as code.
set -euo pipefail
umask 077
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
compose() { "$ROOT/scripts/production.sh" "$@"; }
web_image() {
  compose config --format json | python3 -c 'import json,sys; print(json.load(sys.stdin)["services"]["web"]["image"])'
}
web_domain() {
  compose config --format json | python3 -c 'import json,sys; print(json.load(sys.stdin)["services"]["web"]["environment"]["DOMAIN"])'
}
restart_web=false
restart_image=''
work=''
cleanup() {
  code=$?
  trap - EXIT
  if "$restart_web"; then APP_IMAGE="$restart_image" compose up -d --no-deps --no-build --wait web || code=1; fi
  if [ -n "$work" ]; then rm -rf "$work"; fi
  rm -rf "$ROOT/.production-operation.lock"
  exit "$code"
}
lock_operation() {
  if ! mkdir "$ROOT/.production-operation.lock" 2>/dev/null; then
    echo 'Another maintenance command holds .production-operation.lock; inspect before removing a stale lock.' >&2
    exit 1
  fi
  echo "$$" > "$ROOT/.production-operation.lock/pid"
  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
}
web_running() { compose ps --status running --services | grep -qx web; }
sql() { compose exec -T --user postgres db psql -X -v ON_ERROR_STOP=1 -U postgres -d balancer_production "$@"; }
ensure_network() {
  network=$(compose config --format json | python3 -c 'import json,sys; print(json.load(sys.stdin)["networks"]["edge"]["name"])')
  docker network inspect "$network" >/dev/null 2>&1 || docker network create "$network" >/dev/null
}
verify_local() { compose exec -T web curl --fail --silent --max-time 10 http://127.0.0.1:3000/healthcheck; }
verify_public() { curl --fail --silent --show-error --max-time 30 "https://$(web_domain)/healthcheck"; }
backup_data() {
  mkdir -p "$ROOT/backups"
  work=$(mktemp -d "$ROOT/backups/.staging.XXXXXX")
  if [ -f "$ROOT/.release" ]; then backup_image=$(cat "$ROOT/.release"); else backup_image=$(web_image); fi
  if web_running; then
    restart_image=$(docker inspect --format '{{.Config.Image}}' "$(compose ps -q web)")
    backup_image=$restart_image
    restart_web=true
    compose stop web
  fi
  compose exec -T --user postgres db pg_dump -U postgres -d balancer_production \
    --format=custom --no-owner --no-acl > "$work/database.dump"
  compose run --rm --no-deps -T --entrypoint tar web -czf - -C /rails/storage . > "$work/uploads.tar.gz"
  printf 'balancer-backup-v1\n' > "$work/FORMAT"
  printf '%s\n' "$backup_image" > "$work/image.txt"
  python3 - "$work" <<'PY'
import hashlib
from pathlib import Path
import sys
root = Path(sys.argv[1])
with (root / 'SHA256SUMS').open('w') as manifest:
    for name in ('database.dump', 'uploads.tar.gz'):
        digest = hashlib.sha256()
        with (root / name).open('rb') as source:
            while chunk := source.read(1024 * 1024):
                digest.update(chunk)
        manifest.write(f'{digest.hexdigest()}  {name}\n')
PY
  backup="$ROOT/backups/balancer-$(date -u +%Y%m%dT%H%M%SZ)-$$.tar.gz"
  COPYFILE_DISABLE=1 tar -czf "$backup.partial" -C "$work" FORMAT image.txt SHA256SUMS database.dump uploads.tar.gz
  mv "$backup.partial" "$backup"
  rm -rf "$work"
  work=''
  printf 'Backup: %s\n' "$backup"
}
