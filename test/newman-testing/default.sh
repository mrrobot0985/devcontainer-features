#!/bin/bash
set -e

echo "Testing Postman Newman Testing (default scenario)..."

# Verify newman is available
if command -v newman > /dev/null 2>&1; then
    echo "newman installed: $(newman --version)"
else
    echo "ERROR: newman not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-newman ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
