#!/bin/bash
set -e

echo "Testing Plumber Message Queue CLI (default scenario)..."

# Verify plumber is available
if command -v plumber > /dev/null 2>&1; then
    echo "plumber installed"
else
    echo "ERROR: plumber not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-plumber ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
