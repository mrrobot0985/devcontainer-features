#!/bin/bash
set -e

echo "Installing Grok Build CLI..."

# Determine user home - match what devcontainer will use
REMOTE_USER="${_REMOTE_USER:-vscode}"
if [ -n "${REMOTE_USER}" ] && [ "$REMOTE_USER" != "root" ]; then
    REMOTE_HOME=$(getent passwd "$REMOTE_USER" | cut -d: -f6 2>/dev/null || echo "/home/$REMOTE_USER")
else
    REMOTE_HOME="/root"
fi

GROK_HOME="${REMOTE_HOME}/.grok"
GROK_BIN="${GROK_HOME}/bin"

# Check if already installed for this user
if [ -x "${GROK_BIN}/grok" ]; then
    echo "Grok Build already installed: $(${GROK_BIN}/grok --version 2>/dev/null || echo 'unknown')"
    exit 0
fi

# Install via official script (run as the target user)
echo "Running x.ai installer..."
curl -fsSL https://x.ai/cli/install.sh | bash

# The installer installs to whoever ran it - fix ownership if different user
if [ "$REMOTE_USER" != "root" ] && [ -d "$GROK_HOME" ]; then
    echo "Fixing ownership for $REMOTE_USER..."
    chown -R "$REMOTE_USER:$REMOTE_USER" "$GROK_HOME" 2>/dev/null || true
fi

# Ensure PATH includes grok - create profile.d script
if [ -d "$GROK_BIN" ]; then
    echo "Adding $GROK_BIN to PATH..."
    echo "export PATH=\"\${PATH}:${GROK_BIN}\"" > /etc/profile.d/grok-build.sh
    chmod +x /etc/profile.d/grok-build.sh

    # Also add symlinks to /usr/local/bin for immediate access
    if [ ! -f /usr/local/bin/grok ]; then
        ln -sf "${GROK_BIN}/grok" /usr/local/bin/grok 2>/dev/null || true
        ln -sf "${GROK_BIN}/agent" /usr/local/bin/agent 2>/dev/null || true
    fi
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