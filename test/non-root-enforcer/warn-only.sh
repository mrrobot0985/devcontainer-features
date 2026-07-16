#!/bin/bash
set -e

source dev-container-features-test-lib

check "non-root-enforcer exists" test -x /usr/local/bin/non-root-enforcer

# Create a mock devcontainer.json with root user
mkdir -p /workspace/.devcontainer
cat > /workspace/.devcontainer/devcontainer.json <<'EOF'
{
  "remoteUser": "root"
}
EOF

check "detects root remoteUser" bash -c "non-root-enforcer | grep -q 'root'"

rm -rf /workspace/.devcontainer

reportResults
