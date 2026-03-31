#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BACKEND_DIR="$ROOT_DIR/apps/backend"
APP_DIR="$BACKEND_DIR/disclosure_api"
PRIV_DIR="$APP_DIR/priv"

if [[ ! -d "$APP_DIR" ]]; then
  echo "[copy-phase0] Phoenix app not found at $APP_DIR"
  echo "[copy-phase0] Run: bash apps/backend/scripts/bootstrap_phoenix_api.sh"
  exit 1
fi

mkdir -p "$PRIV_DIR/repo/migrations"
mkdir -p "$PRIV_DIR/openapi"
mkdir -p "$PRIV_DIR/config_samples"
mkdir -p "$PRIV_DIR/fixtures"

cp "$BACKEND_DIR"/ecto_migrations/*.exs "$PRIV_DIR/repo/migrations/"
cp "$BACKEND_DIR"/openapi/*.yaml "$PRIV_DIR/openapi/"
cp "$BACKEND_DIR"/config/*.sample.yaml "$PRIV_DIR/config_samples/"
cp "$BACKEND_DIR"/fixtures/*.json "$PRIV_DIR/fixtures/"

echo "[copy-phase0] Copied migrations -> $PRIV_DIR/repo/migrations"
echo "[copy-phase0] Copied openapi specs -> $PRIV_DIR/openapi"
echo "[copy-phase0] Copied config samples -> $PRIV_DIR/config_samples"
echo "[copy-phase0] Copied fixtures -> $PRIV_DIR/fixtures"
echo "[copy-phase0] Manual follow-ups remain in docs/phase-1/codespaces-backend-runbook.md"
