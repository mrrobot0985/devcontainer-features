#!/bin/bash
set -e

echo "Testing Gitleaks Secret Scanner (with-hook scenario)..."

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
    devcontainer-gitleaks status || true
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

# Check if pre-commit hook was installed in workspace repos
if [ -d "/workspaces" ]; then
    for repo in /workspaces/*; do
        if [ -f "$repo/.git/hooks/pre-commit" ]; then
            echo "Pre-commit hook found in $repo"
        fi
    done
fi

echo "With-hook scenario passed."
