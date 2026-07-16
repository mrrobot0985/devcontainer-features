#!/bin/bash
set -e

echo "Testing Ollama CLI (default scenario)..."

# Verify ollama is available
if command -v ollama > /dev/null 2>&1; then
    echo "ollama installed"
else
    echo "ERROR: ollama not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-ollama ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
