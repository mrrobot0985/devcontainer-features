#!/bin/bash
set -e

source dev-container-features-test-lib

# Create a mock workspace with .envrc
mkdir -p /workspaces/test-project
cat > /workspaces/test-project/.envrc <<'EOF'
export TEST_VAR=hello
EOF

# Verify the file exists (the install script auto-allows if .envrc exists)
check "envrc file exists" test -f /workspaces/test-project/.envrc
check "direnv binary works" bash -c "direnv version >/dev/null 2>&1"

rm -rf /workspaces/test-project

reportResults
