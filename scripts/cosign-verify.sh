#!/usr/bin/env bash
# cosign-verify.sh
# Verify a signed OCI tarball using cosign.pub (no registry, no tlog).
#
# Usage: ./scripts/cosign-verify.sh image.tar
set -euo pipefail

ARTIFACT="${1:-image.tar}"
SIG="${ARTIFACT}.sig"

[[ -f "$ARTIFACT" ]] || { echo "ERROR: $ARTIFACT not found" >&2; exit 1; }
[[ -f "$SIG"      ]] || { echo "ERROR: $SIG not found (sign first)"   >&2; exit 1; }
[[ -f cosign.pub  ]] || { echo "ERROR: cosign.pub missing" >&2; exit 1; }

cosign verify-blob \
  --key cosign.pub \
  --signature "$SIG" \
  --insecure-ignore-tlog \
  "$ARTIFACT"

echo "OK: $ARTIFACT signature verified"
