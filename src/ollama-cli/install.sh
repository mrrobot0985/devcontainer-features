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

# Ensure download/extract tools
export DEBIAN_FRONTEND=noninteractive
if ! command -v curl > /dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq curl ca-certificates >/dev/null
fi
if ! command -v zstd > /dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq zstd >/dev/null
fi

ARCH="amd64"
case "$(uname -m)" in
    aarch64|arm64) ARCH="arm64" ;;
    x86_64) ARCH="amd64" ;;
    *)
        echo "ERROR: Unsupported architecture: $(uname -m)"
        exit 1
        ;;
esac

# Normalize version: strip leading 'v' for tag construction
VERSION="${VERSION#v}"
ASSET="ollama-linux-${ARCH}"

if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    RELEASE_BASE="https://github.com/ollama/ollama/releases/latest/download"
else
    RELEASE_BASE="https://github.com/ollama/ollama/releases/download/v${VERSION}"
fi

TMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

install_from_archive() {
    local archive_path="$1"
    # Archives contain bin/ollama (+ lib/ for full runtime); CLI-only needs the binary
    if [ ! -f "$TMP_DIR/bin/ollama" ]; then
        # Some older layouts may place the binary at the archive root
        if [ -f "$TMP_DIR/ollama" ]; then
            install -m 755 "$TMP_DIR/ollama" /usr/local/bin/ollama
            return 0
        fi
        echo "ERROR: ollama binary not found in archive $archive_path"
        return 1
    fi
    install -m 755 "$TMP_DIR/bin/ollama" /usr/local/bin/ollama
}

# Prefer current .tar.zst assets, then .tgz (older releases), then bare binary (legacy).
# Archives ship bin/ + large lib/ trees (CUDA etc.); CLI-only extracts bin/ollama
# (first member) with --occurrence=1 so the download can stop early via SIGPIPE.
if curl -fsSLI "${RELEASE_BASE}/${ASSET}.tar.zst" >/dev/null 2>&1; then
    DOWNLOAD_URL="${RELEASE_BASE}/${ASSET}.tar.zst"
    echo "Downloading ${DOWNLOAD_URL}..."
    # Early tar exit after first member causes SIGPIPE on curl/zstd; success is binary presence
    set +e +o pipefail
    curl -fsSL "$DOWNLOAD_URL" 2>/dev/null | zstd -d 2>/dev/null | tar -x -C "$TMP_DIR" --occurrence=1 bin/ollama
    set -e -o pipefail
    install_from_archive "$DOWNLOAD_URL"
elif curl -fsSLI "${RELEASE_BASE}/${ASSET}.tgz" >/dev/null 2>&1; then
    DOWNLOAD_URL="${RELEASE_BASE}/${ASSET}.tgz"
    echo "Downloading ${DOWNLOAD_URL}..."
    set +e +o pipefail
    curl -fsSL "$DOWNLOAD_URL" 2>/dev/null | tar -xz -C "$TMP_DIR" --occurrence=1 bin/ollama
    set -e -o pipefail
    install_from_archive "$DOWNLOAD_URL"
elif curl -fsSLI "${RELEASE_BASE}/${ASSET}" >/dev/null 2>&1; then
    DOWNLOAD_URL="${RELEASE_BASE}/${ASSET}"
    echo "Downloading ${DOWNLOAD_URL}..."
    curl -fsSL "$DOWNLOAD_URL" -o /usr/local/bin/ollama
    chmod +x /usr/local/bin/ollama
else
    echo "ERROR: Failed to find Ollama release asset for ${ASSET} at ${RELEASE_BASE}"
    echo "Tried: ${ASSET}.tar.zst, ${ASSET}.tgz, ${ASSET}"
    exit 1
fi

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
