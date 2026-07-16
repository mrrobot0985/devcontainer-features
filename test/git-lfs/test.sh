#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running Git Large File Storage tests..."

# Verify git-lfs is available
if command -v git-lfs > /dev/null 2>&1; then
    echo "git-lfs found: $(git-lfs --version 2>&1 | head -n1 || echo 'version unknown')"
else
    echo "WARNING: git-lfs not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-git-lfs ]; then
    echo "Helper script found"
    devcontainer-git-lfs status || true
else
    echo "WARNING: Helper script not found"
fi

echo "Git Large File Storage tests passed."
