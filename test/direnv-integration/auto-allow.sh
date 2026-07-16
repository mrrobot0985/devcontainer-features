#!/bin/bash
set -e

source dev-container-features-test-lib

# Create a mock workspace with .envrc
mkdir -p /workspaces/test-project
cat > /workspaces/test-project/.envrc <<'EOF'
export TEST_VAR=hello
EOF

# Re-run direnv allow as the user to simulate auto-allow behavior
su - vscode -c "cd /workspaces/test-project && direnv allow" 2>/dev/null || true

# Verify the env var is loaded when cd'ing into the directory
check "envrc allowed" bash -c "cd /workspaces/test-project && direnv export bash | grep -q 'TEST_VAR=hello'"

rm -rf /workspaces/test-project

reportResults
