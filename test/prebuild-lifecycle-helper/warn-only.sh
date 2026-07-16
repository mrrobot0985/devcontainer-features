#!/bin/bash
set -e

source dev-container-features-test-lib

check "helper exists" test -x /usr/local/bin/prebuild-lifecycle-helper

# Create a mock devcontainer.json with heavy ops in postCreateCommand
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.devcontainer"
cat > "$TMPDIR/.devcontainer/devcontainer.json" <<'EOF'
{
  "postCreateCommand": "npm install"
}
EOF

check "detects heavy ops in postCreateCommand" bash -c "prebuild-audit '$TMPDIR/.devcontainer/devcontainer.json' | grep -qi 'install'"

rm -rf "$TMPDIR"

reportResults
