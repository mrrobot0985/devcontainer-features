#!/bin/bash
set -e

echo "Testing SonarScanner CLI (default scenario)..."

# Verify sonar-scanner is available
if command -v sonar-scanner > /dev/null 2>&1; then
    echo "sonar-scanner installed"
    sonar-scanner --version 2>/dev/null || true
else
    echo "ERROR: sonar-scanner not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-sonar ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
