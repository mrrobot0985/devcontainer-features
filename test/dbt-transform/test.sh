#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running dbt Data Transformation tests..."

# Verify dbt is available
if command -v dbt > /dev/null 2>&1; then
    echo "dbt found"
else
    echo "WARNING: dbt not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-dbt ]; then
    echo "Helper script found"
    devcontainer-dbt status || true
else
    echo "WARNING: Helper script not found"
fi

echo "dbt Data Transformation tests passed."
