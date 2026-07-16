#!/bin/bash
set -e

echo "Testing Postman Newman Testing (with-reporters scenario)..."

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
    devcontainer-newman status || true
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

# Verify reporters
if [ -d "$(npm root -g)/newman-reporter-htmlextra" ] || npm list -g newman-reporter-htmlextra > /dev/null 2>&1; then
    echo "htmlextra reporter installed"
else
    echo "WARNING: htmlextra reporter not installed"
fi

if [ -d "$(npm root -g)/newman-reporter-junit" ] || npm list -g newman-reporter-junit > /dev/null 2>&1; then
    echo "junit reporter installed"
else
    echo "WARNING: junit reporter not installed"
fi

echo "With-reporters scenario passed."
