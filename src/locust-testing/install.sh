#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"
INSTALL_PLUGINS="${INSTALLPLUGINS:-false}"

# Ensure Python and pip are available
if ! command -v python3 > /dev/null 2>&1 && ! command -v python > /dev/null 2>&1; then
    echo "Python not found. Installing Python..."
    if command -v apt-get > /dev/null 2>&1; then
        apt-get update && apt-get install -y python3 python3-pip python3-venv
    elif command -v dnf > /dev/null 2>&1; then
        dnf install -y python3 python3-pip
    elif command -v yum > /dev/null 2>&1; then
        yum install -y python3 python3-pip
    elif command -v apk > /dev/null 2>&1; then
        apk add --no-cache python3 py3-pip
    else
        echo "ERROR: Cannot install Python: no supported package manager found."
        exit 1
    fi
fi

# Determine pip command
PIP_CMD="pip3"
if ! command -v pip3 > /dev/null 2>&1; then
    PIP_CMD="pip"
fi
if ! command -v "$PIP_CMD" > /dev/null 2>&1; then
    echo "ERROR: pip not found. Cannot install Locust."
    exit 1
fi

# Install Locust
echo "Installing Locust..."
if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    "$PIP_CMD" install --no-cache-dir --break-system-packages locust 2>/dev/null || \
        "$PIP_CMD" install --no-cache-dir locust
else
    "$PIP_CMD" install --no-cache-dir --break-system-packages "locust==${VERSION}" 2>/dev/null || \
        "$PIP_CMD" install --no-cache-dir "locust==${VERSION}"
fi

# Install plugins
if [ "$INSTALL_PLUGINS" = "true" ]; then
    echo "Installing Locust plugins..."
    "$PIP_CMD" install --no-cache-dir --break-system-packages locust-plugins 2>/dev/null || \
        "$PIP_CMD" install --no-cache-dir locust-plugins || \
        echo "WARNING: locust-plugins not installed"
fi

# Verify installation
if command -v locust > /dev/null 2>&1; then
    echo "Locust installed: $(locust --version 2>&1 || echo 'version unknown')"
else
    echo "ERROR: locust installation failed"
    exit 1
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-locust"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    run)
        echo "Running Locust load test..."
        locust "$@"
        ;;
    web)
        echo "Starting Locust web UI..."
        locust --web-host 0.0.0.0 "$@"
        ;;
    headless)
        echo "Running Locust in headless mode..."
        locust --headless "$@"
        ;;
    status)
        echo "Locust Load Testing status"
        locust --version 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-locust run      # Run load test"
        echo "  devcontainer-locust web      # Start web UI"
        echo "  devcontainer-locust headless # Headless mode"
        echo ""
        echo "Example:"
        echo "  locust -f locustfile.py --host https://api.example.com"
        ;;
    *)
        locust "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Locust Load Testing installed."
echo "  CLI: devcontainer-locust"
echo "  Run: locust -f locustfile.py"
echo "  Web UI: locust --web-host 0.0.0.0"
