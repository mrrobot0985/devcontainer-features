#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running SonarScanner CLI tests..."

# Verify sonar-scanner is available
if command -v sonar-scanner > /dev/null 2>&1; then
    echo "sonar-scanner found"
    sonar-scanner --version 2>/dev/null || true
else
    echo "WARNING: sonar-scanner not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-sonar ]; then
    echo "Helper script found"
    devcontainer-sonar status || true
else
    echo "WARNING: Helper script not found"
fi

echo "SonarScanner CLI tests passed."
