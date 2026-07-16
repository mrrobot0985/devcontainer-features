#!/bin/bash
set -e

echo "Testing Astro Static Site (with-typescript scenario)..."

# Verify npx is available
if command -v npx > /dev/null 2>&1; then
    echo "npx installed"
else
    echo "ERROR: npx not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-astro ]; then
    echo "Helper script is executable"
    devcontainer-astro status || true
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

# Verify TypeScript
if command -v tsc > /dev/null 2>&1; then
    echo "TypeScript installed"
else
    echo "WARNING: TypeScript not installed"
fi

echo "With-typescript scenario passed."
