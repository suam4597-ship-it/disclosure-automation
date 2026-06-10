#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BACKEND_DIR="$ROOT_DIR/apps/backend"
TARGET_DIR="$BACKEND_DIR/disclosure_api"

if [[ -d "$TARGET_DIR" ]]; then
  echo "[bootstrap] Target already exists: $TARGET_DIR"
  echo "[bootstrap] Remove it first if you want a fresh Phoenix app scaffold."
  exit 1
fi

if ! command -v mix >/dev/null 2>&1; then
  echo "[bootstrap] mix is not installed or not on PATH"
  exit 1
fi

if ! mix help phx.new >/dev/null 2>&1; then
  echo "[bootstrap] phx.new archive is not available"
  echo "[bootstrap] Install it first: mix archive.install hex phx_new --force"
  exit 1
fi

cd "$BACKEND_DIR"

echo "[bootstrap] Generating Phoenix API-only app at $TARGET_DIR"
mix phx.new disclosure_api \
  --module DisclosureAutomation \
  --app disclosure_automation \
  --database postgres \
  --no-assets \
  --no-dashboard \
  --no-html \
  --no-live \
  --no-mailer \
  --binary-id

echo "[bootstrap] Done"
echo "[bootstrap] Next: bash apps/backend/scripts/copy_phase0_assets.sh"
