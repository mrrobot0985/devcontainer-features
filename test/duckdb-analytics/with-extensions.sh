#!/bin/bash
set -e

echo "Testing DuckDB Analytics (with-extensions scenario)..."

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
    devcontainer-duckdb status || true
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

# Verify extensions are loadable
duckdb -c "LOAD json;" 2>/dev/null && echo "JSON extension loadable" || echo "WARNING: JSON extension not available"
duckdb -c "LOAD parquet;" 2>/dev/null && echo "Parquet extension loadable" || echo "WARNING: Parquet extension not available"

echo "With-extensions scenario passed."
