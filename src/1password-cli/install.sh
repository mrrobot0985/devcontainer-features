#!/bin/bash
set -e

# 1password-cli install script
# Installs the 1Password CLI and a get-secret helper

VERSION="${VERSION:-latest}"
ARCH="$(uname -m)"

# Map architecture
case "$ARCH" in
    aarch64|arm64) ARCH_LABEL="arm64" ;;
    armv7l|arm) ARCH_LABEL="arm" ;;
    i386|i686) ARCH_LABEL="386" ;;
    *) ARCH_LABEL="amd64" ;;
esac

# Ensure download tools
if ! command -v curl >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq curl ca-certificates >/dev/null
fi
if ! command -v unzip >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq unzip >/dev/null
fi

# Resolve "latest" to a concrete stable release (exclude betas)
if [ "$VERSION" = "latest" ] || [ -z "$VERSION" ]; then
    echo "Resolving latest 1Password CLI version..."
    VERSION=$(curl -fsSL "https://app-updates.agilebits.com/product_history/CLI2" \
        | grep -oE 'pkg/v[0-9]+\.[0-9]+\.[0-9]+/' \
        | grep -v beta \
        | head -1 \
        | sed 's|pkg/v||; s|/||')
    if [ -z "$VERSION" ]; then
        echo "WARNING: Could not resolve latest version; using fallback 2.35.0"
        VERSION="2.35.0"
    fi
fi
VERSION="${VERSION#v}"

echo "Installing 1Password CLI (v${VERSION} ${ARCH_LABEL})..."

OP_URL="https://cache.agilebits.com/dist/1P/op2/pkg/v${VERSION}/op_linux_${ARCH_LABEL}_v${VERSION}.zip"
curl -fsSL "$OP_URL" -o /tmp/op.zip

unzip -o /tmp/op.zip -d /tmp/op-extract
install -m 755 /tmp/op-extract/op /usr/local/bin/op
rm -rf /tmp/op.zip /tmp/op-extract

if ! command -v op >/dev/null 2>&1; then
    echo "ERROR: 1Password CLI installation failed"
    exit 1
fi

# Install get-secret helper
cat > /usr/local/bin/get-secret <<'EOF'
#!/bin/bash
set -e

# get-secret — retrieve a secret from 1Password
# Usage: get-secret <vault> <item> <field>

if [ "$#" -lt 3 ]; then
    echo "Usage: get-secret <vault> <item> <field>"
    exit 1
fi

VAULT="$1"
ITEM="$2"
FIELD="$3"

if ! command -v op >/dev/null 2>&1; then
    echo "ERROR: 1Password CLI (op) not found"
    exit 1
fi

op read "op://$VAULT/$ITEM/$FIELD" 2>/dev/null || {
    echo "ERROR: Failed to read secret from op://$VAULT/$ITEM/$FIELD"
    exit 1
}
EOF

chmod +x /usr/local/bin/get-secret

echo "1Password CLI installed: $(op --version 2>/dev/null || echo "ok")"
echo "  Run 'get-secret <vault> <item> <field>' to retrieve secrets."
