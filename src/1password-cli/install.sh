#!/bin/bash
set -e

# 1password-cli install script
# Installs the 1Password CLI and a get-secret helper

VERSION="__VERSION__"
ARCH="$(uname -m)"

# Map architecture
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    ARCH_LABEL="arm64"
else
    ARCH_LABEL="amd64"
fi

# Determine version
if [ "$VERSION" = "latest" ]; then
    VERSION=""
else
    VERSION="v${VERSION}"
fi

# Download and install 1Password CLI
echo "Installing 1Password CLI (${VERSION:-latest} ${ARCH_LABEL})..."

OP_URL="https://cache.agilebits.com/dist/1P/op2/pkg/${VERSION:-latest}/op_linux_${ARCH_LABEL}_${VERSION:-latest}.zip"
# Try with version in path, fallback to latest
if ! curl -fsSL "$OP_URL" -o /tmp/op.zip 2>/dev/null; then
    OP_URL="https://cache.agilebits.com/dist/1P/op2/pkg/latest/op_linux_${ARCH_LABEL}_latest.zip"
    curl -fsSL "$OP_URL" -o /tmp/op.zip
fi

unzip -o /tmp/op.zip -d /usr/local/bin/ op 2>/dev/null || true
chmod +x /usr/local/bin/op
rm -f /tmp/op.zip

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

echo "1Password CLI installed."
echo "  Run 'get-secret <vault> <item> <field>' to retrieve secrets."
