#!/bin/bash
set -e

source dev-container-features-test-lib

check "script exits 0 when safe" bash -c "DEVCONTAINER_JSON=/dev/null host-isolation-check; test \$? -eq 0"

# Create a mock devcontainer.json with an unsafe config
mkdir -p /workspaces/.devcontainer
cat > /workspaces/.devcontainer/devcontainer.json <<'EOF'
{
  "runArgs": ["--privileged"]
}
EOF

check "fails on unsafe config when failOnWarning=true" bash -c "FAIL_ON_WARNING=true host-isolation-check; test \$? -eq 1"

rm -rf /workspaces/.devcontainer

reportResults
