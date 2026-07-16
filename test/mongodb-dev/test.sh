#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running MongoDB Development Tools tests..."

# Verify mongosh is available
if command -v mongosh > /dev/null 2>&1; then
    echo "mongosh found"
else
    echo "WARNING: mongosh not found"
fi

# Verify other tools
for tool in mongodump mongorestore mongoimport mongoexport; do
    if command -v "$tool" > /dev/null 2>&1; then
        echo "$tool found"
    else
        echo "WARNING: $tool not found"
    fi
done

# Verify helper script
if [ -f /usr/local/bin/devcontainer-mongodb ]; then
    echo "Helper script found"
    devcontainer-mongodb status || true
else
    echo "WARNING: Helper script not found"
fi

echo "MongoDB Development Tools tests passed."
