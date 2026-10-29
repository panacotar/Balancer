#!/usr/bin/env bash
set -euo pipefail
umask 077
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
# shellcheck disable=SC1091
source "$root/scripts/env-file.sh"

if [ ! -f .env.production ]; then
  echo "Run scripts/setup-production.sh first." >&2
  exit 1
fi

git pull --ff-only

sha=$(git rev-parse --short HEAD)
previous=$(sed -n 's/^GIT_SHA=//p' .env.production | head -n 1)
printf '%s\n' "$previous" > .previous-release
chmod 600 .previous-release

if "$root/scripts/production.sh" ps --status running --services 2>/dev/null | grep -qx db; then
  "$root/scripts/backup-production.sh"
fi

docker build -t "balancer:${sha}" "$root"
set_env_value GIT_SHA "$sha" "$root/.env.production"
"$root/scripts/ensure-uploads-volume.sh"
if ! docker network inspect balancer-edge >/dev/null 2>&1; then
  docker network create balancer-edge >/dev/null
fi
"$root/scripts/production.sh" up -d --no-build --wait
printf '%s\n' "$sha" > .release
chmod 600 .release
echo "Running balancer:${sha}. The previous tag is in .previous-release."
