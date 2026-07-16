#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"

# Install Ollama CLI
if command -v ollama > /dev/null 2>&1; then
    echo "Ollama CLI already installed."
    ollama --version 2>/dev/null || true
    exit 0
fi

echo "Installing Ollama CLI..."

ARCH="amd64"
case "$(uname -m)" in
    aarch64|arm64) ARCH="arm64" ;;
    x86_64) ARCH="amd64" ;;
esac

if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    # Download latest release
    DOWNLOAD_URL="https://github.com/ollama/ollama/releases/latest/download/ollama-linux-${ARCH}"
else
    DOWNLOAD_URL="https://github.com/ollama/ollama/releases/download/v${VERSION}/ollama-linux-${ARCH}"
fi

# Download binary
curl -fsSL "$DOWNLOAD_URL" -o /usr/local/bin/ollama || {
    echo "ERROR: Failed to download Ollama from $DOWNLOAD_URL"
    exit 1
}

chmod +x /usr/local/bin/ollama

# Verify installation
if command -v ollama > /dev/null 2>&1; then
    echo "Ollama CLI installed: $(ollama --version 2>/dev/null || echo 'version unknown')"
else
    echo "ERROR: Ollama CLI installation failed"
    exit 1
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-ollama"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    pull)
        echo "Pulling model..."
        ollama pull "$@"
        ;;
    list)
        echo "Listing models..."
        ollama list "$@"
        ;;
    run)
        echo "Running model..."
        ollama run "$@"
        ;;
    rm)
        echo "Removing model..."
        ollama rm "$@"
        ;;
    status)
        echo "Ollama CLI status"
        ollama --version 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-ollama pull llama3.2  # Pull model"
        echo "  devcontainer-ollama list           # List models"
        echo "  devcontainer-ollama run llama3.2   # Run model"
        echo "  devcontainer-ollama rm llama3.2    # Remove model"
        echo ""
        echo "Note: This is the CLI only. For a full server, use docker-compose."
        ;;
    *)
        ollama "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Ollama CLI installed."
echo "  CLI: devcontainer-ollama"
echo "  Pull: ollama pull"
echo "  List: ollama list"
echo "  Version: $(ollama --version 2>/dev/null || echo 'installed')"
