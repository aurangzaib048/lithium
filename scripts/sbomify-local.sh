#!/usr/bin/env bash
#
# Upload SBOMs to local sbomify instance for development testing.
#
# Generates CycloneDX and SPDX SBOMs using syft, then uploads both
# to the local sbomify backend via sbomify-action CLI.
#
# Prerequisites:
#   - syft installed (brew install syft)
#   - sbomify-action repo at ../github-action (or set SBOMIFY_ACTION_DIR)
#   - Local sbomify running at http://127.0.0.1:8000
#   - API token, component ID, and product ID configured below
#
# Usage:
#   ./scripts/sbomify-local.sh

set -euo pipefail

# --- Configuration ---
SBOMIFY_ACTION_DIR="${SBOMIFY_ACTION_DIR:-$(dirname "$0")/../../github-action}"
API_BASE_URL="${SBOMIFY_API_BASE_URL:-http://127.0.0.1:8000}"
TOKEN="${SBOMIFY_LOCAL_TOKEN:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzYm9taWZ5Iiwic3ViIjoiMSIsInNhbHQiOiI1ODg0MjgyMiJ9.4D1s6miBPzjx_hEeP5gx9ZnA1M01aHESRaE3exOjANY}"
COMPONENT_ID="${SBOMIFY_LOCAL_COMPONENT_ID:-toZPapGzCdX4}"
PRODUCT_ID="${SBOMIFY_LOCAL_PRODUCT_ID:-Vy9hNQEnHhcw}"
COMPONENT_NAME="Lithium Python Stack"

# --- Derived ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION="$(bash "$SCRIPT_DIR/calver-version.sh")"
TMPDIR="${TMPDIR:-/tmp}"

echo "=== sbomify local upload ==="
echo "Version: $VERSION"
echo "API: $API_BASE_URL"
echo ""

# --- Generate SBOMs ---
echo "Generating CycloneDX SBOM..."
syft "dir:$PROJECT_DIR" -o "cyclonedx-json=$TMPDIR/lithium-local-cdx.json" --quiet

echo "Generating SPDX SBOM..."
syft "dir:$PROJECT_DIR" -o "spdx-json=$TMPDIR/lithium-local-spdx.json" --quiet

CDX_COMPONENTS=$(python3 -c "import json; print(len(json.load(open('$TMPDIR/lithium-local-cdx.json')).get('components',[])))")
SPDX_PACKAGES=$(python3 -c "import json; print(len(json.load(open('$TMPDIR/lithium-local-spdx.json')).get('packages',[])))")
echo "CycloneDX: $CDX_COMPONENTS components | SPDX: $SPDX_PACKAGES packages"
echo ""

# --- Upload CycloneDX ---
echo "Uploading CycloneDX..."
cd "$PROJECT_DIR"
uv run --project "$SBOMIFY_ACTION_DIR" \
  sbomify-action \
  --sbom-file "$TMPDIR/lithium-local-cdx.json" \
  --sbom-format cyclonedx \
  --component-name "$COMPONENT_NAME" \
  --component-version "$VERSION" \
  --augment --enrich \
  --token "$TOKEN" \
  --component-id "$COMPONENT_ID" \
  --api-base-url "$API_BASE_URL" \
  --product-release "[\"$PRODUCT_ID:$VERSION\"]"

echo ""

# --- Upload SPDX ---
echo "Uploading SPDX..."
uv run --project "$SBOMIFY_ACTION_DIR" \
  sbomify-action \
  --sbom-file "$TMPDIR/lithium-local-spdx.json" \
  --sbom-format spdx \
  --component-name "$COMPONENT_NAME" \
  --component-version "$VERSION" \
  --augment --no-enrich \
  --token "$TOKEN" \
  --component-id "$COMPONENT_ID" \
  --api-base-url "$API_BASE_URL" \
  --product-release "[\"$PRODUCT_ID:$VERSION\"]"

echo ""
echo "=== Done ==="
