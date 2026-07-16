#!/bin/bash
set -e

source dev-container-features-test-lib

check "non-root-enforcer exists" test -x /usr/local/bin/non-root-enforcer

# Create a mock devcontainer.json with missing remoteUser
mkdir -p /workspace/.devcontainer
cat > /workspace/.devcontainer/devcontainer.json <<'EOF'
{}
EOF

check "fails when remoteUser missing" bash -c "FAIL_ON_WARNING=true non-root-enforcer; test \$? -eq 1"

rm -rf /workspace/.devcontainer

reportResults
