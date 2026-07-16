#!/bin/bash
set -e

source dev-container-features-test-lib

check "helper exists" test -x /usr/local/bin/prebuild-lifecycle-helper

# Create a mock devcontainer.json with heavy ops
mkdir -p /workspace/.devcontainer
cat > /workspace/.devcontainer/devcontainer.json <<'EOF'
{
  "postCreateCommand": "npm install"
}
EOF

check "fails when heavy ops in postCreateCommand" bash -c "FAIL_ON_WARNING=true prebuild-lifecycle-helper; test \$? -eq 1"

rm -rf /workspace/.devcontainer

reportResults
