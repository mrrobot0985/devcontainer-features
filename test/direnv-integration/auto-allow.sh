#!/bin/bash
set -e

source dev-container-features-test-lib

# Create a mock workspace with .envrc
mkdir -p /workspaces/test-project
cat > /workspaces/test-project/.envrc <<'EOF'
export TEST_VAR=hello
EOF

# Allow the .envrc
direnv allow /workspaces/test-project > /dev/null 2>&1 || true

# Just verify the file exists and direnv sees it
check "envrc file exists" test -f /workspaces/test-project/.envrc
check "direnv status works" bash -c "cd /workspaces/test-project && direnv status > /dev/null 2>&1"

rm -rf /workspaces/test-project

reportResults
