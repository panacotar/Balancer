#!/bin/bash
source "$(dirname "$0")/deploy/common.sh"
[ "$#" -eq 1 ] || { echo 'Usage: restore-production.sh /absolute/path/to/backup.tar.gz' >&2; exit 1; }
lock_operation
mkdir -p "$ROOT/backups"
work=$(mktemp -d "$ROOT/backups/.restore.XXXXXX")
python3 "$ROOT/scripts/deploy/validate-backup.py" "$1" "$work"
[ "$(cat "$work/image.txt")" = "$(web_image)" ] || {
  echo 'Set APP_IMAGE to the backup image recorded in image.txt before restoring.' >&2; exit 1;
}
ensure_network
compose up -d --wait db
[ "$(sql -Atc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'")" = 0 ] || {
  echo 'Restore requires an empty database; existing data will never be cleared automatically.' >&2; exit 1;
}
compose stop web
compose run --rm --no-deps -T --entrypoint sh web -c 'test -z "$(find /rails/storage -mindepth 1 ! -name .keep -print -quit)"' || {
  echo 'Restore requires an empty uploads volume.' >&2; exit 1;
}
compose exec -T --user postgres db pg_restore -U postgres -d balancer_production \
  --role=balancer --no-owner --no-acl --exit-on-error --single-transaction < "$work/database.dump"
compose run --rm --no-deps -T --entrypoint tar web -xzf - -C /rails/storage < "$work/uploads.tar.gz"
compose up -d --no-deps --no-build --wait web
verify_local
web_image > "$ROOT/.release"
echo 'Restore passed internal health checks. Verify records and image bytes before routing public traffic.'
