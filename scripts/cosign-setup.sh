#!/usr/bin/env bash
# cosign-setup.sh
# Generate a cosign keypair for offline image/blob signing.
# Author: Ricea Ion Raul (CSML, Software Security)
#
# Usage:
#   COSIGN_PASSWORD='your-strong-pass' ./scripts/cosign-setup.sh
#
# Outputs:
#   cosign.key   private key (NEVER commit — already in .gitignore)
#   cosign.pub   public key  (commit to repo, used by `cosign verify`)
#
# Upload to Jenkins after running:
#   - credential id "cosign-key"      = Secret file  -> cosign.key
#   - credential id "cosign-password" = Secret text  -> $COSIGN_PASSWORD
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v cosign >/dev/null 2>&1; then
  echo "ERROR: cosign not installed. Install: https://docs.sigstore.dev/cosign/installation/" >&2
  exit 1
fi

if [[ -z "${COSIGN_PASSWORD:-}" ]]; then
  echo "ERROR: set COSIGN_PASSWORD env var before running." >&2
  echo "Example: COSIGN_PASSWORD='secret123' $0" >&2
  exit 1
fi

if [[ -f cosign.key || -f cosign.pub ]]; then
  echo "Existing keys detected (cosign.key / cosign.pub)."
  read -r -p "Overwrite? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
  rm -f cosign.key cosign.pub
fi

echo "==> Generating cosign keypair..."
cosign generate-key-pair

echo
echo "==> Files created:"
ls -l cosign.key cosign.pub

echo
echo "==> Public key fingerprint:"
cosign public-key --key cosign.key | openssl pkey -pubin -outform DER 2>/dev/null \
  | openssl dgst -sha256 -binary | base64 || true

cat <<EOF

Next steps:
  1. Commit only the public key:
       git add cosign.pub
       git commit -m "add cosign public key"
       git push

  2. Upload cosign.key to Jenkins:
       Manage Jenkins -> Credentials -> System -> Global
       - Kind: Secret file        ID: cosign-key       File: cosign.key
       - Kind: Secret text        ID: cosign-password  Value: \$COSIGN_PASSWORD

  3. Verify locally:
       cosign sign-blob   --key cosign.key --yes --tlog-upload=false README.md > /tmp/sig
       cosign verify-blob --key cosign.pub --signature /tmp/sig --insecure-ignore-tlog README.md

EOF
