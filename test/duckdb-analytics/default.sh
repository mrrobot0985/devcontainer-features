#!/bin/bash
set -e

echo "Testing DuckDB Analytics (default scenario)..."

# Verify duckdb is available
if command -v duckdb > /dev/null 2>&1; then
    echo "duckdb installed"
else
    echo "ERROR: duckdb not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-duckdb ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
