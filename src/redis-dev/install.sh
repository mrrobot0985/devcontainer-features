#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
INSTALL_BENCHMARK="${INSTALLREDISBENCHMARK:-true}"
INSTALL_CHECKERS="${INSTALLREDISCHECKERS:-true}"

# Detect username
if [ "$USERNAME" = "auto" ] || [ "$USERNAME" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 '{ if ($3 >= val) exit; print $1 }' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "$CURRENT_USER" > /dev/null 2>&1; then
            USERNAME="$CURRENT_USER"
            break
        fi
    done
    if [ -z "$USERNAME" ]; then
        USERNAME="root"
    fi
fi

# Install Redis tools
if command -v apt-get > /dev/null 2>&1; then
    echo "Installing Redis tools via apt-get..."
    apt-get update

    # Try redis-tools first, then fall back to redis-server (which includes tools)
    if apt-cache show redis-tools > /dev/null 2>&1; then
        apt-get install -y redis-tools
    else
        apt-get install -y redis-tools || apt-get install -y redis-server || apt-get install -y redis
    fi

elif command -v dnf > /dev/null 2>&1; then
    echo "Installing Redis tools via dnf..."
    dnf install -y redis || echo "WARNING: redis package not available"

elif command -v yum > /dev/null 2>&1; then
    echo "Installing Redis tools via yum..."
    yum install -y redis || echo "WARNING: redis package not available"

elif command -v apk > /dev/null 2>&1; then
    echo "Installing Redis tools via apk..."
    apk add --no-cache redis

else
    echo "ERROR: No supported package manager found for installing Redis tools."
    exit 1
fi

# Verify redis-cli
if command -v redis-cli > /dev/null 2>&1; then
    echo "redis-cli installed: $(redis-cli --version 2>&1 || redis-cli -v 2>&1 || echo 'version unknown')"
else
    echo "ERROR: redis-cli installation failed"
    exit 1
fi

# Verify optional tools
if [ "$INSTALL_BENCHMARK" = "true" ]; then
    if command -v redis-benchmark > /dev/null 2>&1; then
        echo "redis-benchmark installed"
    else
        echo "WARNING: redis-benchmark not found"
    fi
fi

if [ "$INSTALL_CHECKERS" = "true" ]; then
    if command -v redis-check-aof > /dev/null 2>&1; then
        echo "redis-check-aof installed"
    else
        echo "WARNING: redis-check-aof not found"
    fi
    if command -v redis-check-rdb > /dev/null 2>&1; then
        echo "redis-check-rdb installed"
    else
        echo "WARNING: redis-check-rdb not found"
    fi
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-redis"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    connect)
        echo "Connecting to Redis..."
        redis-cli "$@"
        ;;
    ping)
        echo "Pinging Redis server..."
        redis-cli ping "$@"
        ;;
    benchmark)
        echo "Running benchmark..."
        redis-benchmark "$@"
        ;;
    check)
        echo "Checking Redis data files..."
        if command -v redis-check-aof > /dev/null 2>&1; then
            redis-check-aof "$@" || true
        fi
        if command -v redis-check-rdb > /dev/null 2>&1; then
            redis-check-rdb "$@" || true
        fi
        ;;
    info)
        echo "Getting Redis server info..."
        redis-cli info "$@"
        ;;
    status)
        echo "Redis Development Tools status"
        redis-cli --version 2>/dev/null || redis-cli -v 2>/dev/null || true
        echo ""
        echo "Available commands:"
        echo "  redis-cli, redis-benchmark, redis-check-aof, redis-check-rdb"
        echo "  devcontainer-redis connect    # Interactive redis-cli"
        echo "  devcontainer-redis ping       # Ping server"
        echo "  devcontainer-redis benchmark  # Performance test"
        echo "  devcontainer-redis check      # Check data files"
        echo "  devcontainer-redis info       # Server info"
        ;;
    *)
        redis-cli "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Redis Development Tools installed."
echo "  CLI: devcontainer-redis"
echo "  redis-cli: $(redis-cli --version 2>/dev/null || redis-cli -v 2>/dev/null || echo 'installed')"
