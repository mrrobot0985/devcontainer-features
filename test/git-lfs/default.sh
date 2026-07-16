#!/bin/bash
set -e

echo "Testing Git Large File Storage (default scenario)..."

# Verify git-lfs is available
if command -v git-lfs > /dev/null 2>&1; then
    echo "git-lfs installed"
else
    echo "ERROR: git-lfs not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-git-lfs ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
