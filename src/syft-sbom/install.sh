#!/bin/bash
set -e

# syft-sbom install script
# Installs Syft and provides helpers for SBOM generation

SYFT_VERSION="${SYFTVERSION:-latest}"
DEFAULT_FORMAT="${DEFAULTFORMAT:-cyclonedx-json}"

# Determine architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    arm64) ARCH="arm64" ;;
    *)
        echo "WARNING: Unsupported architecture $ARCH, attempting amd64 fallback"
        ARCH="amd64"
        ;;
esac

# Determine OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
    linux) OS="linux" ;;
    darwin) OS="darwin" ;;
    *)
        echo "WARNING: Unsupported OS $OS, attempting linux fallback"
        OS="linux"
        ;;
esac

# Resolve latest version via GitHub API if needed
if [ "$SYFT_VERSION" = "latest" ] || [ -z "$SYFT_VERSION" ]; then
    echo "Resolving latest Syft version..."
    SYFT_VERSION=$(curl -fsSL "https://api.github.com/repos/anchore/syft/releases/latest" | grep -oP '"tag_name":\s*"v\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [ -z "$SYFT_VERSION" ]; then
        echo "WARNING: Could not resolve latest Syft version, using fallback 1.18.0"
        SYFT_VERSION="1.18.0"
    fi
    echo "Latest Syft version: $SYFT_VERSION"
fi

# Strip leading 'v' if present
SYFT_VERSION="${SYFT_VERSION#v}"

# Install Syft
echo "Installing Syft $SYFT_VERSION..."
DOWNLOAD_URL="https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_${OS}_${ARCH}.tar.gz"
echo "Downloading from $DOWNLOAD_URL"
curl -fsSL "$DOWNLOAD_URL" | tar -xz -C /tmp

mv /tmp/syft /usr/local/bin/syft 2>/dev/null || true
chmod +x /usr/local/bin/syft 2>/dev/null || true

if ! command -v syft >/dev/null 2>&1; then
    echo "ERROR: Syft installation failed"
    exit 1
fi

syft_version=$(syft version 2>/dev/null | head -1 || true)
echo "Syft installed: $syft_version"

# Install helper script
cat > /usr/local/bin/generate-sbom <<EOF
#!/bin/bash
set -e

# generate-sbom — generate SBOM from container filesystem or image
# Usage: generate-sbom [OUTPUT_PATH] [--format FORMAT] [--source PATH]

OUTPUT_PATH="sbom.json"
FORMAT="${DEFAULT_FORMAT}"
SOURCE="dir:."

while [ "\$#" -gt 0 ]; do
    case "\$1" in
        --format)
            FORMAT="\$2"
            shift 2
            ;;
        --source)
            SOURCE="\$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: \$1"
            exit 1
            ;;
        *)
            if [ "\$OUTPUT_PATH" = "sbom.json" ]; then
                OUTPUT_PATH="\$1"
            fi
            shift
            ;;
    esac
done

echo "Generating SBOM..."
echo "  Source:  \$SOURCE"
echo "  Format:  \$FORMAT"
echo "  Output:  \$OUTPUT_PATH"

syft "\$SOURCE" -o "\$FORMAT" > "\$OUTPUT_PATH"
echo "SBOM written to \$OUTPUT_PATH"
EOF

chmod +x /usr/local/bin/generate-sbom

echo "syft-sbom installed."
echo "  Version: $SYFT_VERSION"
echo "  Default format: $DEFAULT_FORMAT"
echo "  Run 'generate-sbom' to generate an SBOM."
echo "  Run 'generate-sbom --format spdx-json --source dir:/path' for custom options."
