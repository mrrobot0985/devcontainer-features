#!/bin/bash
set -e

echo "Installing Grok Build CLI..."

# Check if already installed
if command -v grok >/dev/null 2>&1; then
    echo "Grok Build already installed: $(grok --version 2>/dev/null || echo 'version unknown')"
    exit 0
fi

# Install via official script
curl -fsSL https://x.ai/cli/install.sh | bash

# Verify installation
if command -v grok >/dev/null 2>&1; then
    echo "Grok Build installed successfully: $(grok --version)"
else
    echo "ERROR: Grok Build installation failed"
    exit 1
fi

echo "Run 'grok login' to authenticate."