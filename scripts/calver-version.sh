#!/usr/bin/env bash
#
# Emit a CalVer version string for the current git HEAD.
#
# Format: YYYY.MM.DD.<short-sha>
#   - YYYY.MM.DD is the UTC date. UTC is used so the same commit produces
#     the same version regardless of which timezone the build runs in.
#   - <short-sha> is the 7-char abbreviated commit SHA from git.
#
# Example: 2026.04.07.0433631
#
# Override: if the INPUT_VERSION env var is set and non-empty, its value
# is emitted verbatim. The sbomify workflow uses this to honor the
# manual workflow_dispatch component_version input.
#
# Usage:
#   ./scripts/calver-version.sh
#   INPUT_VERSION=1.2.3 ./scripts/calver-version.sh

set -euo pipefail

if [ -n "${INPUT_VERSION:-}" ]; then
  printf '%s\n' "$INPUT_VERSION"
  exit 0
fi

date_part=$(date -u +%Y.%m.%d)
sha_part=$(git rev-parse --short HEAD)
printf '%s.%s\n' "$date_part" "$sha_part"
