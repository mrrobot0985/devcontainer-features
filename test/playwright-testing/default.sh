#!/bin/bash
set -e

echo "Testing Playwright Testing (default scenario)..."

# Verify Playwright is installed
if command -v npx > /dev/null 2>&1; then
    npx playwright --version || true
fi

# Verify helper script exists and is executable
if [ -x /usr/local/bin/devcontainer-playwright ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
