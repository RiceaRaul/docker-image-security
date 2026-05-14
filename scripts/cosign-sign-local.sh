#!/usr/bin/env bash
# cosign-sign-local.sh
# Sign a local OCI tarball + attest its SBOM (offline, no Sigstore tlog).
# Reproduces what the Jenkins "Sign + Attest" stage does, but on the workstation.
#
# Usage:
#   COSIGN_PASSWORD='...' ./scripts/cosign-sign-local.sh image.tar sbom.json
set -euo pipefail

ARTIFACT="${1:-image.tar}"
SBOM="${2:-sbom.json}"

[[ -f "$ARTIFACT" ]] || { echo "ERROR: $ARTIFACT not found" >&2; exit 1; }
[[ -f "$SBOM"     ]] || { echo "ERROR: $SBOM not found"     >&2; exit 1; }
[[ -f cosign.key  ]] || { echo "ERROR: cosign.key missing — run scripts/cosign-setup.sh first" >&2; exit 1; }
[[ -n "${COSIGN_PASSWORD:-}" ]] || { echo "ERROR: COSIGN_PASSWORD env required" >&2; exit 1; }

echo "==> Signing $ARTIFACT"
cosign sign-blob \
  --key cosign.key \
  --yes \
  --tlog-upload=false \
  "$ARTIFACT" > "${ARTIFACT}.sig"

echo "==> Attesting SBOM ($SBOM, CycloneDX) for $ARTIFACT"
cosign attest-blob \
  --key cosign.key \
  --yes \
  --tlog-upload=false \
  --predicate "$SBOM" \
  --type cyclonedx \
  "$ARTIFACT" > "${ARTIFACT}.intoto"

echo
echo "==> Verifying signature"
cosign verify-blob \
  --key cosign.pub \
  --signature "${ARTIFACT}.sig" \
  --insecure-ignore-tlog \
  "$ARTIFACT" && echo "OK: signature valid" || { echo "FAIL: signature invalid" >&2; exit 1; }

echo
echo "Artifacts produced:"
ls -l "${ARTIFACT}.sig" "${ARTIFACT}.intoto"
