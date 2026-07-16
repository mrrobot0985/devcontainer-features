#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"

# Install Plumber
if command -v plumber > /dev/null 2>&1; then
    echo "Plumber already installed."
    plumber --version 2>/dev/null || true
    exit 0
fi

echo "Installing Plumber..."

ARCH="amd64"
case "$(uname -m)" in
    aarch64|arm64) ARCH="arm64" ;;
    x86_64) ARCH="amd64" ;;
esac

if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    # Download latest release
    DOWNLOAD_URL="https://github.com/streamdal/plumber/releases/latest/download/plumber-linux-${ARCH}"
else
    DOWNLOAD_URL="https://github.com/streamdal/plumber/releases/download/v${VERSION}/plumber-linux-${ARCH}"
fi

# Download binary
curl -fsSL "$DOWNLOAD_URL" -o /usr/local/bin/plumber || {
    echo "ERROR: Failed to download Plumber from $DOWNLOAD_URL"
    exit 1
}

chmod +x /usr/local/bin/plumber

# Verify installation
if command -v plumber > /dev/null 2>&1; then
    echo "Plumber installed: $(plumber --version 2>&1 || echo 'version unknown')"
else
    echo "ERROR: Plumber installation failed"
    exit 1
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-plumber"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    read)
        echo "Reading from message queue..."
        plumber read "$@"
        ;;
    write)
        echo "Writing to message queue..."
        plumber write "$@"
        ;;
    relay)
        echo "Relaying messages between queues..."
        plumber relay "$@"
        ;;
    status)
        echo "Plumber Message Queue CLI status"
        plumber --version 2>/dev/null || true
        echo ""
        echo "Supported backends:"
        echo "  Kafka, RabbitMQ, NATS, Redis, GCP PubSub, AWS SQS/SNS,"
        echo "  Azure Service Bus, MQTT, Apache Pulsar, and more"
        echo ""
        echo "Usage:"
        echo "  devcontainer-plumber read kafka --topics my-topic"
        echo "  devcontainer-plumber write rabbitmq --queue my-queue --input 'hello'"
        echo "  devcontainer-plumber relay kafka --topics src -d rabbitmq --queue dst"
        ;;
    *)
        plumber "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Plumber Message Queue CLI installed."
echo "  CLI: devcontainer-plumber"
echo "  Read: plumber read"
echo "  Write: plumber write"
echo "  Version: $(plumber --version 2>/dev/null || echo 'installed')"
