#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
tag=${1:-$(git rev-parse HEAD)}
if [ "$#" -eq 0 ] && [ -n "$(git status --porcelain)" ]; then
  echo 'Commit changes first, or pass an explicit validation tag.' >&2
  exit 1
fi
[[ "$tag" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$ ]] || { echo 'Invalid image tag.' >&2; exit 1; }
mkdir -p dist
docker buildx build --platform linux/arm64 --pull --load --tag "balancer:$tag" .
docker image save "balancer:$tag" | gzip > "dist/balancer-$tag.tar.gz"
printf 'Image archive: %s/dist/balancer-%s.tar.gz\n' "$ROOT" "$tag"
