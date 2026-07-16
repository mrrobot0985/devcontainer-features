#!/bin/bash
set -e

source dev-container-features-test-lib

# Create a mock workspace with package-lock.json and misplaced npm install
TMPDIR=$(mktemp -d)
touch "$TMPDIR/package-lock.json"
mkdir -p "$TMPDIR/.devcontainer"
cat > "$TMPDIR/.devcontainer/devcontainer.json" <<'EOF'
{
  "name": "test",
  "postCreateCommand": "npm install",
  "postStartCommand": "echo done"
}
EOF

# Run fix mode
check "fix mode rewrites devcontainer.json" bash -c "FIX_MODE=true prebuild-audit '$TMPDIR/.devcontainer/devcontainer.json'"

# Verify backup exists
check "backup created" test -f "$TMPDIR/.devcontainer/devcontainer.json.prebuild-backup"

# Verify npm install moved to updateContentCommand
check "npm install moved to updateContentCommand" bash -c "grep -q 'updateContentCommand' '$TMPDIR/.devcontainer/devcontainer.json'"
check "postCreateCommand removed or empty" bash -c "! grep -q '\"postCreateCommand\": *\"npm install\"' '$TMPDIR/.devcontainer/devcontainer.json'"
check "postStartCommand preserved" bash -c "grep -q 'echo done' '$TMPDIR/.devcontainer/devcontainer.json'"

rm -rf "$TMPDIR"

reportResults
