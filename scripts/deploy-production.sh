#!/bin/bash
source "$(dirname "$0")/deploy/common.sh"
mode=${1:-update}
[[ "$mode" == init || "$mode" == update ]] || { echo 'Usage: deploy-production.sh [init|update]' >&2; exit 1; }
lock_operation
image=$(web_image)
# Refuse implicit pulls/builds: load the tested ARM64 image before deployment.
arch=$(docker image inspect --format '{{.Architecture}}' "$image")
[ "$arch" = arm64 ] || { echo 'Expected an ARM64 application image.' >&2; exit 1; }
ensure_network
compose up -d --wait db
if [ "$mode" = init ]; then
  [ "$(sql -Atc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'")" = 0 ] || {
    echo 'Initialization requires an empty database. Use update for an existing installation.' >&2; exit 1;
  }
  compose run --rm --no-deps -T --entrypoint sh web -c 'test -z "$(find /rails/storage -mindepth 1 ! -name .keep -print -quit)"' || {
    echo 'Initialization requires an empty uploads volume.' >&2; exit 1;
  }
else
  [ -f "$ROOT/.release" ] || { echo 'Missing .release; establish the currently running image before updating.' >&2; exit 1; }
  backup_data
  cp "$ROOT/.release" "$ROOT/.previous-release"
fi
# From here on a migration failure must leave the web app stopped.
restart_web=false
compose stop web
compose run --rm --no-deps -T web bin/rails db:migrate
if [ "$mode" = init ]; then compose run --rm --no-deps -T web bin/rails db:seed; fi
compose up -d --no-deps --no-build --wait web
verify_local
printf '%s\n' "$image" > "$ROOT/.release"
echo 'Balancer is healthy internally. Verify public HTTPS after the Caddy/DNS integration.'
if [ "$mode" = update ]; then verify_public; fi
