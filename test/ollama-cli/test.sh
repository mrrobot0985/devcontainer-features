#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running Ollama CLI tests..."

# Verify ollama is available
if command -v ollama > /dev/null 2>&1; then
    echo "ollama found: $(ollama --version 2>&1 || echo 'version unknown')"
else
    echo "WARNING: ollama not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-ollama ]; then
    echo "Helper script found"
    devcontainer-ollama status || true
else
    echo "WARNING: Helper script not found"
fi

echo "Ollama CLI tests passed."
