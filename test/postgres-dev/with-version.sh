#!/bin/bash
set -e

echo "Testing PostgreSQL Development Tools (with-version scenario)..."

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
    devcontainer-postgres status || true
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

# Verify pgFormatter if requested
if command -v pg_format > /dev/null 2>&1; then
    echo "pgFormatter installed"
else
    echo "WARNING: pgFormatter not installed"
fi

# Verify pgtop if requested
if command -v pgtop > /dev/null 2>&1; then
    echo "pgtop installed"
else
    echo "WARNING: pgtop not installed"
fi

echo "With-version scenario passed."
