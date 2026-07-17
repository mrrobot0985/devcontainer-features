#!/bin/bash
set -e

source dev-container-features-test-lib

check "script detects missing lockfile" bash -c "DEVCONTAINER_LOCKFILE=/nonexistent/lock.json DEVCONTAINER_CONFIG=/nonexistent/devcontainer.json devcontainer-lock-audit; test \$? -eq 1"

MOCK_DIR="$(mktemp -d)"
cat > "$MOCK_DIR/devcontainer-lock.json" <<'EOF'
{
  "features": {
    "ghcr.io/devcontainers/features/node:2": {
      "version": "2.1.0"
    }
  }
}
EOF

cat > "$MOCK_DIR/devcontainer.json" <<'EOF'
{
  "features": {
    "ghcr.io/devcontainers/features/node:2": {}
  }
}
EOF

# Ensure lockfile is newer than config
touch -d "1 minute ago" "$MOCK_DIR/devcontainer.json"
touch "$MOCK_DIR/devcontainer-lock.json"

check "valid lockfile passes" bash -c "DEVCONTAINER_LOCKFILE=$MOCK_DIR/devcontainer-lock.json DEVCONTAINER_CONFIG=$MOCK_DIR/devcontainer.json devcontainer-lock-audit | grep -q 'validation passed'"

rm -rf "$MOCK_DIR"

reportResults
