#!/usr/bin/env bash
set -euo pipefail

# x.ai CLI (Grok) install script
# Installs the Grok Build CLI for interacting with Grok models.
#
# Official installer usage (https://x.ai/cli/install.sh):
#   curl -fsSL https://x.ai/cli/install.sh | bash            # latest stable
#   curl -fsSL https://x.ai/cli/install.sh | bash -s 0.1.42  # specific version
# Version is a positional argument (not -v). Env: GROK_CHANNEL, GROK_BIN_DIR.

VERSION="${VERSION:-latest}"

echo "Installing x.ai CLI (Grok)..."

export DEBIAN_FRONTEND=noninteractive
if ! command -v curl >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq curl ca-certificates >/dev/null
fi

# Strip leading 'v' so "v0.2.102" matches X.Y.Z expected by the installer
VERSION="${VERSION#v}"

# Install into a PATH directory so `grok` is available without shell restart
export GROK_BIN_DIR="${GROK_BIN_DIR:-/usr/local/bin}"

if [ "$VERSION" = "latest" ] || [ -z "$VERSION" ]; then
    curl -fsSL https://x.ai/cli/install.sh | bash
else
    curl -fsSL https://x.ai/cli/install.sh | bash -s -- "$VERSION"
fi

# The official installer places the real binary under $HOME/.grok/downloads and
# symlinks GROK_BIN_DIR -> that path. Feature install runs as root, so those
# paths are under /root with 0700 perms and non-root users cannot exec them.
# Replace symlinks with world-executable copies in GROK_BIN_DIR.
for cmd in grok agent; do
    bin_path="${GROK_BIN_DIR}/${cmd}"
    if [ -L "$bin_path" ]; then
        target="$(readlink -f "$bin_path" 2>/dev/null || true)"
        if [ -n "$target" ] && [ -f "$target" ]; then
            rm -f "$bin_path"
            install -m 755 "$target" "$bin_path"
        fi
    elif [ -f "$bin_path" ]; then
        chmod a+rx "$bin_path" 2>/dev/null || true
    fi
done

export PATH="${GROK_BIN_DIR}:${HOME}/.grok/bin:${PATH}"

if command -v grok >/dev/null 2>&1; then
    echo "x.ai CLI (Grok) installed successfully."
    grok --version || true
else
    echo "ERROR: x.ai CLI (grok) not found in PATH after installation"
    echo "Looked in: ${GROK_BIN_DIR} and ${HOME}/.grok/bin"
    exit 1
fi
