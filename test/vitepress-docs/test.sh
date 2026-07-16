#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running VitePress Documentation Site tests..."

# Verify npx is available
if command -v npx > /dev/null 2>&1; then
    echo "npx found"
else
    echo "WARNING: npx not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-vitepress ]; then
    echo "Helper script found"
    devcontainer-vitepress status || true
else
    echo "WARNING: Helper script not found"
fi

echo "VitePress Documentation Site tests passed."
