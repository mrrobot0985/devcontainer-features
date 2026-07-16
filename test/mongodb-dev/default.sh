#!/bin/bash
set -e

echo "Testing MongoDB Development Tools (default scenario)..."

# Verify mongosh is available
if command -v mongosh > /dev/null 2>&1; then
    echo "mongosh installed"
else
    echo "WARNING: mongosh not installed"
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-mongodb ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
