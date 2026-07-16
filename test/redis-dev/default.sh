#!/bin/bash
set -e

echo "Testing Redis Development Tools (default scenario)..."

# Verify redis-cli is available
if command -v redis-cli > /dev/null 2>&1; then
    echo "redis-cli installed"
else
    echo "ERROR: redis-cli not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-redis ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
