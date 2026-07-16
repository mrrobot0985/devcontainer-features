#!/bin/bash
set -e

source dev-container-features-test-lib

# Create a mock workspace with package-lock.json and devcontainer.json with npm install in postCreateCommand
mkdir -p /workspace
touch /workspace/package-lock.json
mkdir -p /workspace/.devcontainer
cat > /workspace/.devcontainer/devcontainer.json <<'EOF'
{
  "postCreateCommand": "npm install",
  "updateContentCommand": "echo hello"
}
EOF

check "detects node from lockfile" bash -c "prebuild-audit /workspace/.devcontainer/devcontainer.json | grep -qi 'node'"
check "suggests moving npm install" bash -c "prebuild-audit /workspace/.devcontainer/devcontainer.json | grep -qi 'updateContentCommand'"

rm -rf /workspace/.devcontainer /workspace/package-lock.json

reportResults
