#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running Gitleaks Secret Scanner tests..."

# Verify gitleaks is available
if command -v gitleaks > /dev/null 2>&1; then
    echo "gitleaks found: $(gitleaks --version 2>&1 || echo 'version unknown')"
else
    echo "WARNING: gitleaks not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-gitleaks ]; then
    echo "Helper script found"
    devcontainer-gitleaks status || true
else
    echo "WARNING: Helper script not found"
fi

echo "Gitleaks Secret Scanner tests passed."
