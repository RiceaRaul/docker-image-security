#!/usr/bin/env bash
# Attack: push a tampered image under the same tag (supply chain swap).
# Mitigation: `cosign verify` fails on unsigned/tampered image.
set -euo pipefail

REG="registry.sec-lab.local"
TAG="${REG}/secapp:demo"

echo "==> Push signed image"
docker tag secapp:hardened "$TAG"
docker push "$TAG"
cosign sign --key cosign.key --yes "$TAG"
cosign verify --key cosign.pub "$TAG" && echo "VERIFIED (signed)"

echo
echo "==> Attacker pushes tampered image under same tag"
docker tag secapp:bad "$TAG"
docker push "$TAG"

echo
echo "==> cosign verify on tampered image (expect FAILURE):"
cosign verify --key cosign.pub "$TAG" || echo "BLOCKED — signature mismatch"
