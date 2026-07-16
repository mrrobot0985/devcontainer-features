#!/bin/bash
set -e

source dev-container-features-test-lib

# Create a mock workspace with package-lock.json and misplaced npm install
mkdir -p /workspace
touch /workspace/package-lock.json
mkdir -p /workspace/.devcontainer
cat > /workspace/.devcontainer/devcontainer.json <<'EOF'
{
  "name": "test",
  "postCreateCommand": "npm install",
  "postStartCommand": "echo done"
}
EOF

# Run fix mode
check "fix mode rewrites devcontainer.json" bash -c "FIX_MODE=true prebuild-audit /workspace/.devcontainer/devcontainer.json"

# Verify backup exists
check "backup created" test -f /workspace/.devcontainer/devcontainer.json.prebuild-backup

# Verify npm install moved to updateContentCommand
check "npm install moved to updateContentCommand" bash -c "grep -q 'updateContentCommand' /workspace/.devcontainer/devcontainer.json"
check "postCreateCommand removed or empty" bash -c '! grep -q '"postCreateCommand": *"npm install"' /workspace/.devcontainer/devcontainer.json'"
check "postStartCommand preserved" bash -c "grep -q 'echo done' /workspace/.devcontainer/devcontainer.json"

rm -rf /workspace/.devcontainer /workspace/package-lock.json

reportResults
