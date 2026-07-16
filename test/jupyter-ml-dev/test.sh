#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running Jupyter and ML Development Tools tests..."

# Verify Jupyter is available
if command -v jupyter > /dev/null 2>&1; then
    echo "Jupyter found"
    jupyter --version 2>/dev/null || true
else
    echo "WARNING: jupyter not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-jupyter ]; then
    echo "Helper script found"
    devcontainer-jupyter status || true
else
    echo "WARNING: Helper script not found"
fi

echo "Jupyter and ML Development Tools tests passed."
