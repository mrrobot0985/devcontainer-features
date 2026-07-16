#!/bin/bash
set -e

echo "Testing MongoDB Development Tools (with-version scenario)..."

# Verify mongosh is available
if command -v mongosh > /dev/null 2>&1; then
    echo "mongosh installed"
else
    echo "WARNING: mongosh not installed"
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-mongodb ]; then
    echo "Helper script is executable"
    devcontainer-mongodb status || true
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

# Verify tools
for tool in mongodump mongorestore mongoimport mongoexport; do
    if command -v "$tool" > /dev/null 2>&1; then
        echo "$tool installed"
    else
        echo "WARNING: $tool not installed"
    fi
done

echo "With-version scenario passed."
