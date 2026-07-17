#!/bin/bash
set -e

source dev-container-features-test-lib

check "script exits 0 when safe" bash -c "DEVCONTAINER_JSON=/dev/null host-isolation-check; test \$? -eq 0"

MOCK_DIR="$(mktemp -d)"
cat > "$MOCK_DIR/devcontainer.json" <<'EOF'
{
  "runArgs": ["--privileged"]
}
EOF

check "fails on unsafe config when failOnWarning=true" bash -c "DEVCONTAINER_JSON=$MOCK_DIR/devcontainer.json FAIL_ON_WARNING=true host-isolation-check; test \$? -eq 1"

rm -rf "$MOCK_DIR"

reportResults
