#!/bin/bash
set -e

source dev-container-features-test-lib

check "non-root-enforcer exists" test -x /usr/local/bin/non-root-enforcer

# Mock config in a writable temp dir (test user may not own /workspace or /workspaces)
MOCK_DIR="$(mktemp -d)"
cat > "$MOCK_DIR/devcontainer.json" <<'EOF'
{}
EOF

check "fails when remoteUser missing" bash -c "DEVCONTAINER_CONFIG=$MOCK_DIR/devcontainer.json FAIL_ON_WARNING=true non-root-enforcer; test \$? -eq 1"

rm -rf "$MOCK_DIR"

reportResults
