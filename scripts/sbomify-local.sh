#!/usr/bin/env bash
#
# Upload SBOMs to local sbomify instance for development testing.
#
# Generates CycloneDX and SPDX SBOMs using syft, then uploads both
# to the local sbomify backend via sbomify-action CLI.
#
# Prerequisites:
#   - sbomify-action repo at ../github-action (or set SBOMIFY_ACTION_DIR)
#   - Local sbomify running at http://127.0.0.1:8000
#   - API token, component ID, and product ID configured below
#
# Uses --lock-file (same as staging CI workflow) so the sbomify-action
# picks the best available generator (cdxgen > cyclonedx-py > syft).
#
# Usage:
#   ./scripts/sbomify-local.sh              # both formats
#   ./scripts/sbomify-local.sh cyclonedx    # CycloneDX only
#   ./scripts/sbomify-local.sh spdx         # SPDX only

set -euo pipefail

# --- Configuration ---
SBOMIFY_ACTION_DIR="${SBOMIFY_ACTION_DIR:-$(dirname "$0")/../../github-action}"
API_BASE_URL="${SBOMIFY_API_BASE_URL:-http://127.0.0.1:8000}"
TOKEN="${SBOMIFY_LOCAL_TOKEN:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzYm9taWZ5Iiwic3ViIjoiMSIsInNhbHQiOiI1ODg0MjgyMiJ9.4D1s6miBPzjx_hEeP5gx9ZnA1M01aHESRaE3exOjANY}"
COMPONENT_ID="${SBOMIFY_LOCAL_COMPONENT_ID:-toZPapGzCdX4}"
PRODUCT_ID="${SBOMIFY_LOCAL_PRODUCT_ID:-Vy9hNQEnHhcw}"
COMPONENT_NAME="Lithium Python Stack"
FORMAT="${1:-both}"  # cyclonedx, spdx, or both

# --- Derived ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION="$(bash "$SCRIPT_DIR/calver-version.sh")"

echo "=== sbomify local upload ==="
echo "Version: $VERSION"
echo "API: $API_BASE_URL"
echo "Format: $FORMAT"
echo ""

cd "$PROJECT_DIR"

upload_sbom() {
  local fmt="$1"
  echo "--- Uploading $fmt ---"
  uv run --project "$SBOMIFY_ACTION_DIR" \
    sbomify-action \
    --lock-file uv.lock \
    --sbom-format "$fmt" \
    --component-name "$COMPONENT_NAME" \
    --component-version "$VERSION" \
    --augment --enrich \
    --token "$TOKEN" \
    --component-id "$COMPONENT_ID" \
    --api-base-url "$API_BASE_URL" \
    --product-release "[\"$PRODUCT_ID:$VERSION\"]"
  echo ""
}

case "$FORMAT" in
  cyclonedx) upload_sbom cyclonedx ;;
  spdx)      upload_sbom spdx ;;
  both)      upload_sbom cyclonedx; upload_sbom spdx ;;
  *)         echo "Usage: $0 [cyclonedx|spdx|both]"; exit 1 ;;
esac

echo "=== Done ==="
