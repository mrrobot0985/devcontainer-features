#!/bin/bash
set -e

echo "Testing Gitleaks Secret Scanner (default scenario)..."

# Verify gitleaks is available
if command -v gitleaks > /dev/null 2>&1; then
    echo "gitleaks installed"
else
    echo "ERROR: gitleaks not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-gitleaks ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
