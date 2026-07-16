#!/bin/bash
set -e

source dev-container-features-test-lib

check "helper exists" test -x /usr/local/bin/prebuild-lifecycle-helper

# Create a mock devcontainer.json with heavy ops
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.devcontainer"
cat > "$TMPDIR/.devcontainer/devcontainer.json" <<'EOF'
{
  "postCreateCommand": "npm install"
}
EOF

check "fails when heavy ops in postCreateCommand" bash -c "FAIL_ON_WARNING=true prebuild-audit '$TMPDIR/.devcontainer/devcontainer.json'; test \$? -ne 0" || true

rm -rf "$TMPDIR"

reportResults
