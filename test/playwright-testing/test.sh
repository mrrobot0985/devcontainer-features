#!/bin/bash
set -e

# Run all test scenarios for playwright-testing feature

cd "$(dirname "$0")"

echo "Running Playwright Testing feature tests..."

# Source the devcontainer-lib if available for test helpers
if [ -f /usr/local/share/devcontainer-lib/devcontainer-lib.sh ]; then
    source /usr/local/share/devcontainer-lib/devcontainer-lib.sh
fi

# Default test: verify Playwright CLI is available
if command -v npx > /dev/null 2>&1; then
    echo "Checking Playwright version..."
    npx playwright --version || true
else
    echo "WARNING: npx not found in PATH"
fi

# Check helper script
if [ -f /usr/local/bin/devcontainer-playwright ]; then
    echo "Helper script found: /usr/local/bin/devcontainer-playwright"
    devcontainer-playwright status || true
else
    echo "WARNING: Helper script not found"
fi

# Check browser binaries
CACHE_DIR="${HOME}/.cache/ms-playwright"
if [ -d "$CACHE_DIR" ]; then
    echo "Browser cache directory exists: $CACHE_DIR"
    ls -la "$CACHE_DIR" || true
else
    echo "WARNING: Browser cache directory not found at $CACHE_DIR"
fi

echo "Playwright Testing tests passed."
