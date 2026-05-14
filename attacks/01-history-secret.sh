#!/usr/bin/env bash
# Attack: extract API_KEY from `docker history` of the bad image.
# Mitigation: BuildKit `--secret` mount (see docker/Dockerfile).
set -euo pipefail

IMG_BAD="secapp:bad"
IMG_GOOD="secapp:hardened"

echo "==> Building bad image"
docker build -f docker/Dockerfile.bad -t "$IMG_BAD" .

echo
echo "==> Bad image history (secret visible):"
docker history --no-trunc "$IMG_BAD" | grep -i "API_KEY" || true

echo
echo "==> Building hardened image"
DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile -t "$IMG_GOOD" .

echo
echo "==> Hardened image history (no secret):"
docker history --no-trunc "$IMG_GOOD" | grep -i "API_KEY" && echo "LEAK!" || echo "no leak"
