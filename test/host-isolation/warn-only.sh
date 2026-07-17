#!/bin/bash
set -e

source dev-container-features-test-lib

check "script runs without devcontainer.json" bash -c "DEVCONTAINER_JSON=/dev/null host-isolation-check | grep -q 'skipping audit'"

# Mock config in a writable temp dir (test user may not own /workspaces)
MOCK_DIR="$(mktemp -d)"
cat > "$MOCK_DIR/devcontainer.json" <<'EOF'
{
  "runArgs": ["--privileged"]
}
EOF

check "detects privileged" bash -c "DEVCONTAINER_JSON=$MOCK_DIR/devcontainer.json host-isolation-check | grep -q 'WARNING.*privileged'"

rm -rf "$MOCK_DIR"

reportResults
