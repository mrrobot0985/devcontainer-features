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
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

# Status must exit promptly (must not start the VitePress dev server).
STATUS_OUT="$(devcontainer-vitepress status 2>&1 || true)"
echo "$STATUS_OUT"
if ! echo "$STATUS_OUT" | grep -qiE 'vitepress[[:space:]]+1\.0'; then
    echo "ERROR: expected vitepress 1.0.x in status output"
    exit 1
fi

echo "With-version scenario passed."
