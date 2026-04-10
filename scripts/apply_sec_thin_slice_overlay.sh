#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: bash scripts/apply_sec_thin_slice_overlay.sh <extracted_root>"
  exit 1
fi

EXTRACTED_ROOT="$1"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$REPO_ROOT/apps/backend/disclosure_api"

find_workspace_root() {
  local root="$1"
  local candidate="$root/disclosure-automation/apps/backend/disclosure_api/mix.exs"
  if [[ -f "$candidate" ]]; then
    dirname "$candidate"
    return 0
  fi

  local found
  found="$(find "$root" -type f -path '*disclosure-automation/apps/backend/disclosure_api/mix.exs' | head -n 1 || true)"
  if [[ -n "$found" ]]; then
    dirname "$found"
    return 0
  fi

  return 1
}

SOURCE="$(find_workspace_root "$EXTRACTED_ROOT")" || {
  echo "could not find extracted disclosure_api workspace under: $EXTRACTED_ROOT"
  exit 1
}

if [[ ! -d "$TARGET" ]]; then
  echo "target repo path not found: $TARGET"
  exit 1
fi

echo "Source: $SOURCE"
echo "Target: $TARGET"
cp -R "$SOURCE"/* "$TARGET"/

echo "Overlay copy complete."
echo "Next commands:"
echo "  cd apps/backend/disclosure_api"
echo "  mix format"
echo "  mix deps.get"
echo "  mix ecto.create"
echo "  mix ecto.migrate"
echo "  mix compile"
