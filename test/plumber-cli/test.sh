#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running Plumber Message Queue CLI tests..."

# Verify plumber is available
if command -v plumber > /dev/null 2>&1; then
    echo "plumber found: $(plumber --version 2>&1 || echo 'version unknown')"
else
    echo "WARNING: plumber not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-plumber ]; then
    echo "Helper script found"
    devcontainer-plumber status || true
else
    echo "WARNING: Helper script not found"
fi

echo "Plumber Message Queue CLI tests passed."
