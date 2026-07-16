#!/bin/bash
set -e

echo "Testing Meilisearch CLI (default scenario)..."

# Verify meilisearch is available
if command -v meilisearch > /dev/null 2>&1; then
    echo "meilisearch installed"
else
    echo "ERROR: meilisearch not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-meilisearch ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
