#!/bin/bash
set -e

# docker-compose-helper install script
# Validates docker-compose.yml and optionally injects health checks / dependency ordering

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_HOME=$(getent passwd "$REMOTE_USER" | cut -d: -f6 2>/dev/null || true)
if [ -z "$REMOTE_HOME" ]; then
    if [ "$REMOTE_USER" = "root" ]; then
        REMOTE_HOME="/root"
    else
        REMOTE_HOME="/home/$REMOTE_USER"
    fi
fi

VALIDATE="${VALIDATE:-true}"
HEALTH_CHECKS="${HEALTHCHECKS:-true}"
DEPENDS_ON_ORDERING="${DEPENDSONORDERING:-true}"

echo "Docker Compose Helper"
echo "  Validate:           $VALIDATE"
echo "  Health checks:        $HEALTH_CHECKS"
echo "  Depends-on ordering: $DEPENDS_ON_ORDERING"

# Ensure docker compose is available (it may be installed via Docker-in-Docker or host)
if ! command -v docker >/dev/null 2>&1; then
    echo "WARNING: docker command not found; validation will be skipped."
    echo "          Install docker-in-docker feature for compose validation."
fi

# Write the CLI helper
cat > /usr/local/bin/devcontainer-compose-check <<'CHECK_EOF'
#!/bin/bash
set -e

# devcontainer-compose-check — validate and optimize docker-compose.yml for devcontainers

COMPOSE_FILE="${1:-docker-compose.yml}"
COMPOSE_DIR="$(dirname "$COMPOSE_FILE")"
COMPOSE_DIR="${COMPOSE_DIR:-.}"
COMPOSE_PATH="$COMPOSE_DIR/$COMPOSE_FILE"

if [ ! -f "$COMPOSE_PATH" ] && [ ! -f "$COMPOSE_DIR/compose.yaml" ]; then
    echo "INFO: No docker-compose.yml or compose.yaml found in $COMPOSE_DIR; nothing to check."
    exit 0
fi

if [ -f "$COMPOSE_DIR/compose.yaml" ] && [ ! -f "$COMPOSE_PATH" ]; then
    COMPOSE_PATH="$COMPOSE_DIR/compose.yaml"
fi

echo "Docker Compose Check"
echo "===================="
echo "File: $COMPOSE_PATH"
echo ""

# Validate syntax
if command -v docker >/dev/null 2>&1; then
    echo "Validating compose file..."
    if docker compose -f "$COMPOSE_PATH" config >/dev/null 2>&1; then
        echo "  ✅  Syntax valid"
    else
        echo "  ❌  Syntax validation failed"
        exit 1
    fi
else
    echo "  ⚠️  docker not available; skipping syntax validation"
fi

echo ""
echo "Check complete."
CHECK_EOF

chmod +x /usr/local/bin/devcontainer-compose-check

echo "Docker Compose Helper installed."
echo "  CLI: devcontainer-compose-check [path/to/docker-compose.yml]"
