#!/bin/bash
set -e

source dev-container-features-test-lib

check "script detects missing lockfile" bash -c "DEVCONTAINER_LOCKFILE=/dev/null DEVCONTAINER_CONFIG=/dev/null devcontainer-lock-audit; test \$? -eq 1"

# Create a valid lockfile
mkdir -p /workspace/.devcontainer
cat > /workspace/.devcontainer/devcontainer-lock.json <<'EOF'
{
  "features": {
    "ghcr.io/devcontainers/features/node:2": {
      "version": "2.1.0"
    }
  }
}
EOF

cat > /workspace/.devcontainer/devcontainer.json <<'EOF'
{
  "features": {
    "ghcr.io/devcontainers/features/node:2": {}
  }
}
EOF

# Ensure lockfile is newer
touch /workspace/.devcontainer/devcontainer-lock.json

check "valid lockfile passes" bash -c "devcontainer-lock-audit | grep -q 'validation passed'"

rm -rf /workspace/.devcontainer

reportResults
