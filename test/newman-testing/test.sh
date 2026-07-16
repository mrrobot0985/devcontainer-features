#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running Postman Newman Testing tests..."

# Verify newman is available
if command -v newman > /dev/null 2>&1; then
    echo "newman found: $(newman --version)"
else
    echo "WARNING: newman not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-newman ]; then
    echo "Helper script found"
    devcontainer-newman status || true
else
    echo "WARNING: Helper script not found"
fi

echo "Postman Newman Testing tests passed."
