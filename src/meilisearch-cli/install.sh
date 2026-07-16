#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"

# Install Meilisearch CLI
if command -v meilisearch > /dev/null 2>&1; then
    echo "Meilisearch CLI already installed."
    meilisearch --version 2>/dev/null || true
    exit 0
fi

echo "Installing Meilisearch CLI..."

ARCH="amd64"
case "$(uname -m)" in
    aarch64|arm64) ARCH="aarch64" ;;
    x86_64) ARCH="amd64" ;;
esac

if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    # Download latest release
    DOWNLOAD_URL="https://github.com/meilisearch/meilisearch/releases/latest/download/meilisearch-linux-${ARCH}"
else
    DOWNLOAD_URL="https://github.com/meilisearch/meilisearch/releases/download/v${VERSION}/meilisearch-linux-${ARCH}"
fi

# Download binary
curl -fsSL "$DOWNLOAD_URL" -o /usr/local/bin/meilisearch || {
    echo "ERROR: Failed to download Meilisearch from $DOWNLOAD_URL"
    exit 1
}

chmod +x /usr/local/bin/meilisearch

# Verify installation
if command -v meilisearch > /dev/null 2>&1; then
    echo "Meilisearch CLI installed: $(meilisearch --version 2>&1 || echo 'version unknown')"
else
    echo "ERROR: Meilisearch CLI installation failed"
    exit 1
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-meilisearch"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    serve)
        echo "Starting Meilisearch server..."
        meilisearch "$@"
        ;;
    index)
        echo "Managing index..."
        echo "Use curl or meilisearch HTTP API for index operations"
        echo "Example: curl -X POST http://localhost:7700/indexes -H 'Content-Type: application/json' -d '{\"uid\":\"books\"}'"
        ;;
    status)
        echo "Meilisearch CLI status"
        meilisearch --version 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-meilisearch serve        # Start server"
        echo "  devcontainer-meilisearch index        # Index management tips"
        echo ""
        echo "HTTP API examples:"
        echo "  curl http://localhost:7700/health"
        echo "  curl -X POST http://localhost:7700/indexes/books/documents"
        ;;
    *)
        meilisearch "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Meilisearch CLI installed."
echo "  CLI: devcontainer-meilisearch"
echo "  Serve: meilisearch"
echo "  Version: $(meilisearch --version 2>/dev/null || echo 'installed')"
