#!/usr/bin/env bash
set -euo pipefail
umask 077
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
# shellcheck disable=SC1091
source "$root/scripts/env-file.sh"

if [ ! -f .previous-release ]; then
  echo "No .previous-release file. Update once before rolling back." >&2
  exit 1
fi

previous=$(tr -d '[:space:]' < .previous-release)
if [ -z "$previous" ]; then
  echo ".previous-release is empty." >&2
  exit 1
fi

docker image inspect "balancer:${previous}" >/dev/null
set_env_value GIT_SHA "$previous" "$root/.env.production"
"$root/scripts/production.sh" up -d --no-build --wait web
echo "Rolled back to balancer:${previous}."
