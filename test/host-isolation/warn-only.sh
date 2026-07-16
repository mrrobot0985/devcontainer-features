#!/bin/bash
set -e

source dev-container-features-test-lib

check "script runs without devcontainer.json" bash -c "host-isolation-check | grep -q 'skipping audit'"

# Create a mock devcontainer.json with an unsafe config
mkdir -p /workspaces/.devcontainer
cat > /workspaces/.devcontainer/devcontainer.json <<'EOF'
{
  "runArgs": ["--privileged"]
}
EOF

check "detects privileged" bash -c "host-isolation-check | grep -q 'WARNING.*privileged'"

rm -rf /workspaces/.devcontainer

reportResults
