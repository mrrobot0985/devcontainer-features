#!/bin/bash
set -e

echo "Installing Grok Build CLI..."

# Check if already installed
if command -v grok >/dev/null 2>&1; then
    echo "Grok Build already installed: $(grok --version 2>/dev/null || echo 'version unknown')"
    exit 0
fi

# Try curl first (official way)
if command -v curl >/dev/null 2>&1; then
    echo "Trying official installer..."
    if curl -fsSL https://x.ai/cli/install.sh 2>/dev/null | bash; then
        if command -v grok >/dev/null 2>&1; then
            echo "Grok Build installed successfully: $(grok --version)"
            exit 0
        fi
    fi
fi

# Fallback: download binary directly
echo "Trying direct binary download..."

# Determine architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_NAME="x86_64" ;;
    aarch64|arm64) ARCH_NAME="aarch64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

GROK_VERSION=$(curl -s https://api.github.com/repos/xai-org/grok/releases/latest | grep '"tag_name"' | sed 's/.*v\([0-9.]*\).*/\1/' || echo "0.2.106")
TARBALL="grok-${GROK_VERSION}-linux-${ARCH_NAME}.tar.gz"

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

curl -LO "https://github.com/xai-org/grok/releases/download/v${GROK_VERSION}/${TARBALL}" || {
    echo "Trying latest release..."
    # Try the specific known version
    curl -LO "https://github.com/xai-org/grok/releases/download/v0.2.106/grok-0.2.106-linux-${ARCH_NAME}.tar.gz"
}

tar -xzf "grok-${GROK_VERSION}-linux-${ARCH_NAME}.tar.gz" 2>/dev/null || \
tar -xzf "grok-0.2.106-linux-${ARCH_NAME}.tar.gz" 2>/dev/null || {
    echo "ERROR: Failed to download Grok"
    cd /
    rm -rf "$TEMP_DIR"
    exit 1
}

# Install
sudo install -o root -g root -m 755 grok*/grok /usr/local/bin/grok
sudo install -o root -g root -m 755 grok*/agent /usr/local/bin/agent 2>/dev/null || true

# Cleanup
cd /
rm -rf "$TEMP_DIR"

# Verify
if command -v grok >/dev/null 2>&1; then
    echo "Grok Build installed successfully: $(grok --version)"
else
    echo "ERROR: Grok Build installation failed"
    exit 1
fi

echo "Run 'grok login' to authenticate."