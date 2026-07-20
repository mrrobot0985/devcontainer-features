#!/bin/bash
set -e

echo "Installing Grok Build CLI..."

# Determine user home
REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_HOME=$(getent passwd "$REMOTE_USER" | cut -d: -f6 2>/dev/null || echo "/home/$REMOTE_USER")
if [ "$REMOTE_USER" = "root" ]; then
    REMOTE_HOME="/root"
fi

GROK_HOME="${REMOTE_HOME}/.grok"
GROK_BIN="${GROK_HOME}/bin"

# Check if already installed
if [ -x "${GROK_BIN}/grok" ]; then
    echo "Grok Build already installed: $(${GROK_BIN}/grok --version 2>/dev/null || echo 'unknown')"
elif command -v grok >/dev/null 2>&1; then
    echo "Grok Build already installed: $(grok --version 2>/dev/null || echo 'unknown')"
    exit 0
fi

# Install via official script
curl -fsSL https://x.ai/cli/install.sh | bash

# The install script puts grok in ~/.grok/bin
# Add to PATH via profile.d for persistence
if [ -d "$GROK_BIN" ]; then
    echo "export PATH=\"\${PATH}:${GROK_BIN}\"" > /etc/profile.d/grok-build.sh
    chmod +x /etc/profile.d/grok-build.sh
    export PATH="${PATH}:${GROK_BIN}"
fi

# Verify installation
if [ -x "${GROK_BIN}/grok" ]; then
    echo "Grok Build installed successfully: $(${GROK_BIN}/grok --version)"
elif command -v grok >/dev/null 2>&1; then
    echo "Grok Build installed successfully: $(grok --version)"
else
    echo "ERROR: Grok Build installation failed"
    exit 1
fi

echo ""
echo "Run 'grok login' to authenticate."