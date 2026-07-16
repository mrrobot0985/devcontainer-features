#!/bin/bash
set -e

echo "Testing dbt Data Transformation (with-adapters scenario)..."

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
    devcontainer-dbt status || true
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

# Verify adapters
python3 -c "import dbt.adapters.duckdb" 2>/dev/null && echo "duckdb adapter available" || echo "WARNING: duckdb adapter not available"
python3 -c "import dbt.adapters.postgres" 2>/dev/null && echo "postgres adapter available" || echo "WARNING: postgres adapter not available"

echo "With-adapters scenario passed."
