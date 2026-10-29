#!/usr/bin/env bash
set -euo pipefail
umask 077
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

backup=${1:-}
if [ "${2:-}" != "--yes" ] || [ ! -f "$backup/database.dump" ] || [ ! -f "$backup/uploads.tar.gz" ]; then
  echo "Usage: scripts/restore-production.sh backups/STAMP --yes" >&2
  echo "Stops the site and replaces the database and uploaded photos." >&2
  exit 1
fi

"$root/scripts/production.sh" stop web
"$root/scripts/production.sh" exec -T db \
  sh -c 'PGPASSWORD="$POSTGRES_PASSWORD" pg_restore -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner' \
  < "$backup/database.dump"
"$root/scripts/production.sh" run --rm --no-deps --entrypoint find web /rails/storage -mindepth 1 -delete
"$root/scripts/production.sh" run --rm --no-deps --entrypoint tar web -xzf - -C /rails/storage < "$backup/uploads.tar.gz"
"$root/scripts/production.sh" up -d --no-build --wait web
echo "Restored $backup."
