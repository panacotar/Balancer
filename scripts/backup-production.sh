#!/usr/bin/env bash
set -euo pipefail
umask 077
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
mkdir -p backups
chmod 700 backups

stamp=$(date -u +%Y%m%dT%H%M%SZ)
dest="$root/backups/$stamp"
mkdir "$dest"

cleanup() {
  status=$?
  if [ "$status" -ne 0 ]; then
    rm -rf "$dest"
  fi
  exit "$status"
}
trap cleanup EXIT

"$root/scripts/production.sh" exec -T db \
  sh -c 'PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --no-owner --no-acl' \
  > "$dest/database.dump"

"$root/scripts/production.sh" run --rm --no-deps --entrypoint tar web \
  -czf - -C /rails/storage . > "$dest/uploads.tar.gz"

shopt -s nullglob
matches=( "$root"/backups/20* )
if [ "${#matches[@]}" -gt 14 ]; then
  kept=0
  printf '%s\n' "${matches[@]}" | sort -r | while IFS= read -r dir; do
    kept=$((kept + 1))
    if [ "$kept" -gt 14 ]; then
      rm -rf "$dir"
    fi
  done
fi

trap - EXIT
printf 'Backup: %s\n' "$dest"
