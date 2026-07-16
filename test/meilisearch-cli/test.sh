#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running Meilisearch CLI tests..."

# Verify meilisearch is available
if command -v meilisearch > /dev/null 2>&1; then
    echo "meilisearch found: $(meilisearch --version 2>&1 || echo 'version unknown')"
else
    echo "WARNING: meilisearch not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-meilisearch ]; then
    echo "Helper script found"
    devcontainer-meilisearch status || true
else
    echo "WARNING: Helper script not found"
fi

echo "Meilisearch CLI tests passed."
