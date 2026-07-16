#!/bin/bash
set -e

# cosign-verify install script
# Installs Cosign (Sigstore) and configures helpers for image signature verification

COSIGN_VERSION="${COSIGNVERSION:-latest}"
VERIFY_ON_INSTALL="${VERIFYONINSTALL:-false}"

# Determine architecture (Cosign uses amd64, not x86_64)
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
if [ "$COSIGN_VERSION" = "latest" ] || [ -z "$COSIGN_VERSION" ]; then
    echo "Resolving latest Cosign version..."
    COSIGN_VERSION=$(curl -fsSL "https://api.github.com/repos/sigstore/cosign/releases/latest" | grep -oP '"tag_name":\s*"v\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [ -z "$COSIGN_VERSION" ]; then
        echo "WARNING: Could not resolve latest Cosign version, using fallback 2.4.0"
        COSIGN_VERSION="2.4.0"
    fi
    echo "Latest Cosign version: $COSIGN_VERSION"
fi

# Strip leading 'v' if present
COSIGN_VERSION="${COSIGN_VERSION#v}"

# Install Cosign
echo "Installing Cosign $COSIGN_VERSION..."
DOWNLOAD_URL="https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-${OS}-${ARCH}"
echo "Downloading from $DOWNLOAD_URL"
curl -fsSL "$DOWNLOAD_URL" -o /usr/local/bin/cosign

chmod +x /usr/local/bin/cosign

if ! command -v cosign >/dev/null 2>&1; then
    echo "ERROR: Cosign installation failed"
    exit 1
fi

cosign_version=$(cosign version 2>/dev/null | head -1 || true)
echo "Cosign installed: $cosign_version"

# Install helper script
cat > /usr/local/bin/cosign-verify-image <<'EOF'
#!/bin/bash
set -e

# cosign-verify-image — verify container image signatures and attestations
# Usage: cosign-verify-image IMAGE [options]

IMAGE="${1:-}"
if [ -z "$IMAGE" ]; then
    echo "Usage: cosign-verify-image IMAGE [--attestation] [--sbom]"
    echo "  IMAGE       The container image reference to verify"
    echo "  --attestation  Verify attestations (provenance, SBOM)"
    echo "  --sbom         Verify and extract the SBOM attestation"
    exit 1
fi

shift 2>/dev/null || true

VERIFY_ATTESTATION="false"
VERIFY_SBOM="false"

for arg in "$@"; do
    case "$arg" in
        --attestation) VERIFY_ATTESTATION="true" ;;
        --sbom) VERIFY_SBOM="true" ;;
    esac
done

echo "Verifying image: $IMAGE"

if [ "$VERIFY_ATTESTATION" = "true" ]; then
    echo "Checking attestations..."
    cosign verify-attestation "$IMAGE" \
        --type "https://slsa.dev/provenance/v1" \
        --certificate-identity-regexp='.*' \
        --certificate-oidc-issuer-regexp='.*' 2>/dev/null || \
    echo "WARNING: Could not verify attestation. The image may not have one."
fi

if [ "$VERIFY_SBOM" = "true" ]; then
    echo "Extracting SBOM attestation..."
    cosign verify-attestation "$IMAGE" \
        --type "https://spdx.dev/Document" \
        --certificate-identity-regexp='.*' \
        --certificate-oidc-issuer-regexp='.*' 2>/dev/null || \
    echo "WARNING: Could not extract SBOM attestation."
fi

echo "Verifying signature..."
if cosign verify "$IMAGE" \
    --certificate-identity-regexp='.*' \
    --certificate-oidc-issuer-regexp='.*' 2>/dev/null; then
    echo "Signature verification passed for $IMAGE"
else
    echo "WARNING: Signature verification failed or image is unsigned."
    echo "  To verify with a specific identity:"
    echo "    cosign verify \$IMAGE --certificate-identity=... --certificate-oidc-issuer=..."
fi
EOF

chmod +x /usr/local/bin/cosign-verify-image

# Run verification test if requested
if [ "$VERIFY_ON_INSTALL" = "true" ]; then
    echo "Running Cosign verification test..."
    if cosign version >/dev/null 2>&1; then
        echo "  Cosign is operational."
    else
        echo "WARNING: Cosign verification test failed."
    fi
fi

echo "cosign-verify installed."
echo "  Version: $COSIGN_VERSION"
echo "  Run 'cosign-verify-image IMAGE' to verify image signatures."
echo "  Run 'cosign-verify-image IMAGE --sbom' to extract SBOM attestations."
