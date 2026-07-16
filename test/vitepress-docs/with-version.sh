#!/bin/bash
set -e

echo "Testing VitePress Documentation Site (with-version scenario)..."

# Verify npx is available
if command -v npx > /dev/null 2>&1; then
    echo "npx installed"
else
    echo "ERROR: npx not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-vitepress ]; then
    echo "Helper script is executable"
    devcontainer-vitepress status || true
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "With-version scenario passed."
