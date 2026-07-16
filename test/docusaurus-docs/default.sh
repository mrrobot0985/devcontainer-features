#!/bin/bash
set -e

echo "Testing Docusaurus Documentation Site (default scenario)..."

# Verify npm/npx is available
if command -v npx > /dev/null 2>&1; then
    echo "npx installed"
else
    echo "ERROR: npx not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-docusaurus ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
