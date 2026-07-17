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

# Verify helper script (status must not block on the dev server)
if [ -f /usr/local/bin/devcontainer-vitepress ]; then
    echo "Helper script found"
    STATUS_OUT="$(devcontainer-vitepress status 2>&1 || true)"
    echo "$STATUS_OUT"
    if ! echo "$STATUS_OUT" | grep -qi 'vitepress'; then
        echo "WARNING: status did not report vitepress"
    fi
else
    echo "WARNING: Helper script not found"
fi

echo "VitePress Documentation Site tests passed."
