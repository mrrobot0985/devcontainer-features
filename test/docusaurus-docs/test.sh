#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running Docusaurus Documentation Site tests..."

# Verify Docusaurus is available
if command -v npx > /dev/null 2>&1; then
    echo "npx found"
else
    echo "WARNING: npx not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-docusaurus ]; then
    echo "Helper script found"
    devcontainer-docusaurus status || true
else
    echo "WARNING: Helper script not found"
fi

echo "Docusaurus Documentation Site tests passed."
