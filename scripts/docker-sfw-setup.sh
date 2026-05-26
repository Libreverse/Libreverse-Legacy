#!/usr/bin/env bash
# Install Socket Firewall (sfw) in Docker build when socket_api_key secret is present.
set -euo pipefail

SECRET_PATH="/run/secrets/socket_api_key"
if [ ! -f "$SECRET_PATH" ]; then
  echo "No socket_api_key secret; skipping sfw install."
  exit 0
fi

export SOCKET_API_KEY
SOCKET_API_KEY="$(tr -d '\n' < "$SECRET_PATH")"
if [ -z "$SOCKET_API_KEY" ]; then
  echo "Empty socket_api_key; skipping sfw install."
  exit 0
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) SFW_ARCH="x64" ;;
  aarch64) SFW_ARCH="arm64" ;;
  *) echo "Unsupported arch for sfw: $ARCH"; exit 1 ;;
esac

curl -fsSL -o /usr/local/bin/sfw \
  "https://github.com/SocketDev/firewall-release/releases/latest/download/sfw-linux-${SFW_ARCH}"
chmod +x /usr/local/bin/sfw
echo "Socket Firewall installed."
