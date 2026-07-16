#!/bin/bash
set -e

echo "Testing Playwright Testing (with-browsers scenario)..."

# Verify Playwright is installed globally
if command -v npx > /dev/null 2>&1; then
    npx playwright --version || true
fi

# Verify helper script exists and is executable
if [ -x /usr/local/bin/devcontainer-playwright ]; then
    echo "Helper script is executable"
    devcontainer-playwright status || true
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

# Check that browsers were installed
CACHE_DIR="${HOME}/.cache/ms-playwright"
if [ -d "$CACHE_DIR" ]; then
    echo "Browser cache directory exists"
    ls -la "$CACHE_DIR" || true
else
    echo "WARNING: Browser cache directory not found"
fi

echo "With-browsers scenario passed."
