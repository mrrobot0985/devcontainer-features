#!/bin/bash
set -e

source dev-container-features-test-lib

# Create a mock workspace with package-lock.json and devcontainer.json
TMPDIR=$(mktemp -d)
touch "$TMPDIR/package-lock.json"
mkdir -p "$TMPDIR/.devcontainer"
cat > "$TMPDIR/.devcontainer/devcontainer.json" <<'EOF'
{
  "postCreateCommand": "npm install",
  "updateContentCommand": "echo hello"
}
EOF

check "detects node from lockfile" bash -c "prebuild-audit '$TMPDIR/.devcontainer/devcontainer.json' | grep -qi 'node'"
check "suggests moving npm install" bash -c "prebuild-audit '$TMPDIR/.devcontainer/devcontainer.json' | grep -qi 'updateContentCommand'"

rm -rf "$TMPDIR"

reportResults
