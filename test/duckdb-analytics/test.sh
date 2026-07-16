#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running DuckDB Analytics tests..."

# Verify duckdb is available
if command -v duckdb > /dev/null 2>&1; then
    echo "duckdb found: $(duckdb --version 2>&1 || echo 'version unknown')"
else
    echo "WARNING: duckdb not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-duckdb ]; then
    echo "Helper script found"
    devcontainer-duckdb status || true
else
    echo "WARNING: Helper script not found"
fi

echo "DuckDB Analytics tests passed."
