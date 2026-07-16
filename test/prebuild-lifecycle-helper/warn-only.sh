#!/bin/bash
set -e

source dev-container-features-test-lib

check "helper exists" test -x /usr/local/bin/prebuild-lifecycle-helper

# Create a mock devcontainer.json with heavy ops in postCreateCommand
mkdir -p /workspace/.devcontainer
cat > /workspace/.devcontainer/devcontainer.json <<'EOF'
{
  "postCreateCommand": "npm install"
}
EOF

check "detects heavy ops in postCreateCommand" bash -c "prebuild-audit /workspace/.devcontainer/devcontainer.json | grep -qi 'postCreateCommand.*dependency' || prebuild-audit /workspace/.devcontainer/devcontainer.json | grep -qi 'install'"

rm -rf /workspace/.devcontainer

reportResults
