#!/bin/bash
set -e

source dev-container-features-test-lib

# Create a mock workspace with .envrc
mkdir -p /workspaces/test-project
cat > /workspaces/test-project/.envrc <<'EOF'
export TEST_VAR=hello
EOF

# Allow the .envrc as the container user
su - vscode -c "cd /workspaces/test-project && direnv allow" 2>/dev/null || true

# Verify direnv exports the variable (requires hook to be in shell, so source it)
check "envrc exports variable" bash -c 'eval "$(direnv hook bash)"; cd /workspaces/test-project && direnv export bash | grep -q "TEST_VAR=hello"'

rm -rf /workspaces/test-project

reportResults
