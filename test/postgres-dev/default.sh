#!/bin/bash
set -e

echo "Testing PostgreSQL Development Tools (default scenario)..."

# Verify psql is available
if command -v psql > /dev/null 2>&1; then
    echo "psql installed: $(psql --version | head -n1)"
else
    echo "ERROR: psql not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-postgres ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
