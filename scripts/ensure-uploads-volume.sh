#!/usr/bin/env bash
set -euo pipefail
docker volume create balancer_uploads >/dev/null
docker run --rm --network none -v balancer_uploads:/rails/storage alpine:3 chown 1000:1000 /rails/storage
