#!/bin/bash
set -e

source dev-container-features-test-lib

# Create a mock workspace with .envrc
mkdir -p /workspaces/test-project
cat > /workspaces/test-project/.envrc <<'EOF'
export TEST_VAR=hello
EOF

# Run direnv allow as the user
su - vscode -c "cd /workspaces/test-project && direnv allow" 2>/dev/null || true

# Verify direnv allow created the .envrc allow file
check "direnv allow ran" bash -c "test -f /workspaces/test-project/.direnv/allow-* || test -d /workspaces/test-project/.direnv"

rm -rf /workspaces/test-project

reportResults
