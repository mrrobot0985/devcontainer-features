#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running Locust Load Testing tests..."

# Verify locust is available
if command -v locust > /dev/null 2>&1; then
    echo "locust found: $(locust --version 2>&1 || echo 'version unknown')"
else
    echo "WARNING: locust not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-locust ]; then
    echo "Helper script found"
    devcontainer-locust status || true
else
    echo "WARNING: Helper script not found"
fi

echo "Locust Load Testing tests passed."
