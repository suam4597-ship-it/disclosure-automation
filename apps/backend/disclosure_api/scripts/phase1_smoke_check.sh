#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

export MIX_ENV="${MIX_ENV:-dev}"

echo "[phase1-smoke] deps.get"
mix deps.get

echo "[phase1-smoke] ecto.create"
mix ecto.create

echo "[phase1-smoke] ecto.migrate"
mix ecto.migrate

echo "[phase1-smoke] compile"
mix compile

echo "[phase1-smoke] done"
