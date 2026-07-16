#!/bin/bash
set -e

# x.ai CLI (Grok) install script
# Installs the Grok Build CLI for interacting with Grok models

VERSION="__VERSION__"

echo "Installing x.ai CLI (Grok)..."

# Install x.ai CLI using the official installer
if [ "$VERSION" = "latest" ] || [ -z "$VERSION" ]; then
    curl -fsSL https://x.ai/cli/install.sh | bash
else
    curl -fsSL https://x.ai/cli/install.sh | bash -s -- -v "$VERSION"
fi

# Verify installation
if command -v grok >/dev/null 2>&1; then
    echo "x.ai CLI (Grok) installed successfully."
    grok --version || true
else
    echo "ERROR: x.ai CLI (grok) not found in PATH after installation"
    exit 1
fi