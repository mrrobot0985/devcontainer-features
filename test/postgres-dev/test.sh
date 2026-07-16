#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running PostgreSQL Development Tools tests..."

# Verify psql is available
if command -v psql > /dev/null 2>&1; then
    echo "psql found: $(psql --version | head -n1)"
else
    echo "ERROR: psql not found"
    exit 1
fi

# Verify other client tools
for tool in pg_dump pg_restore pg_isready pg_basebackup; do
    if command -v "$tool" > /dev/null 2>&1; then
        echo "$tool found"
    else
        echo "WARNING: $tool not found"
    fi
done

# Verify helper script
if [ -f /usr/local/bin/devcontainer-postgres ]; then
    echo "Helper script found"
    devcontainer-postgres status || true
else
    echo "WARNING: Helper script not found"
fi

echo "PostgreSQL Development Tools tests passed."
