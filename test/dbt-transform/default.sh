#!/bin/bash
set -e

echo "Testing dbt Data Transformation (default scenario)..."

# Verify dbt is available
if command -v dbt > /dev/null 2>&1; then
    echo "dbt installed"
else
    echo "ERROR: dbt not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-dbt ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
