#!/usr/bin/env bash
set -euo pipefail

echo "[post-create] Installing Ubuntu packages..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl unzip git inotify-tools postgresql-client build-essential

INSTALL_ROOT="$HOME/.elixir-install"
INSTALL_SCRIPT="$HOME/install.sh"

if ! command -v elixir >/dev/null 2>&1; then
  echo "[post-create] Installing Erlang/OTP and Elixir via official install script..."
  curl -fsSL https://elixir-lang.org/install.sh -o "$INSTALL_SCRIPT"
  sh "$INSTALL_SCRIPT" elixir@1.19.5 otp@28.1
  {
    echo ''
    echo '# disclosure-automation elixir toolchain'
    echo 'export PATH="$HOME/.elixir-install/installs/otp/28.1/bin:$PATH"'
    echo 'export PATH="$HOME/.elixir-install/installs/elixir/1.19.5-otp-28/bin:$PATH"'
  } >> "$HOME/.bashrc"
  export PATH="$HOME/.elixir-install/installs/otp/28.1/bin:$PATH"
  export PATH="$HOME/.elixir-install/installs/elixir/1.19.5-otp-28/bin:$PATH"
fi

echo "[post-create] Installing Hex/Rebar/Phoenix generator..."
mix local.hex --force
mix local.rebar --force
mix archive.install hex phx_new --force

echo "[post-create] Toolchain versions"
elixir --version
mix --version

echo "[post-create] Ready. Next:"
echo "  1) bash apps/backend/scripts/bootstrap_phoenix_api.sh"
echo "  2) bash apps/backend/scripts/copy_phase0_assets.sh"
echo "  3) cd apps/backend/disclosure_api && mix deps.get"
