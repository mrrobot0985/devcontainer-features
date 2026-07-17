#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
VERSION="${VERSION:-latest}"
INSTALL_LATEX="${INSTALLLATEX:-false}"

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

# Pandoc Linux release assets use amd64/arm64 (not uname -m values like x86_64).
case "$(uname -m)" in
    x86_64|amd64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)
        echo "ERROR: Unsupported architecture: $(uname -m)"
        exit 1
        ;;
esac

get_latest_version() {
    curl -fsSL "https://api.github.com/repos/jgm/pandoc/releases/latest" 2>/dev/null | grep '"tag_name":' | head -n1 | sed -E 's/.*"tag_name": *"v?([^"]+)".*/\1/' || echo ""
}

if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    VERSION="$(get_latest_version)"
    if [ -z "$VERSION" ]; then
        echo "WARNING: Could not determine latest Pandoc version. Falling back to 3.1.11."
        VERSION="3.1.11"
    fi
fi

VERSION="${VERSION#v}"

# Assets: pandoc-${VERSION}-linux-{amd64,arm64}.tar.gz
PANDOC_URL="https://github.com/jgm/pandoc/releases/download/${VERSION}/pandoc-${VERSION}-linux-${ARCH}.tar.gz"

echo "Installing Pandoc ${VERSION} (${ARCH}) from ${PANDOC_URL}..."
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

if ! curl -fsSL "$PANDOC_URL" -o "${TEMP_DIR}/pandoc.tar.gz"; then
    echo "ERROR: Failed to download Pandoc from ${PANDOC_URL}"
    exit 1
fi
tar -xzf "${TEMP_DIR}/pandoc.tar.gz" -C "$TEMP_DIR" --strip-components=1
if [ ! -f "${TEMP_DIR}/bin/pandoc" ]; then
    echo "ERROR: pandoc binary not found in release archive"
    exit 1
fi
install -m 755 "${TEMP_DIR}/bin/pandoc" /usr/local/bin/pandoc
rm -rf "$TEMP_DIR"
trap - EXIT

echo "Pandoc installed: $(pandoc --version | head -n1)"

# Install TeX Live if requested
if [ "$INSTALL_LATEX" = "true" ]; then
    echo "Installing TeX Live for PDF support..."
    if command -v apt-get > /dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends texlive-xetex texlive-fonts-recommended texlive-plain-generic lmodern
    elif command -v dnf > /dev/null 2>&1; then
        dnf install -y texlive-scheme-basic texlive-xetex
    elif command -v yum > /dev/null 2>&1; then
        yum install -y texlive-xetex texlive-fonts-recommended
    elif command -v apk > /dev/null 2>&1; then
        apk add --no-cache texlive-xetex
    else
        echo "WARNING: Could not install TeX Live - no supported package manager found."
    fi
fi

# Install helper script
HELPER_SCRIPT="/usr/local/bin/devcontainer-pandoc"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    convert)
        pandoc "$@"
        ;;
    md2pdf)
        INPUT="${1:-}"
        OUTPUT="${2:-output.pdf}"
        if [ -z "$INPUT" ]; then
            echo "Usage: devcontainer-pandoc md2pdf <input.md> [output.pdf]"
            exit 1
        fi
        pandoc "$INPUT" -o "$OUTPUT" --pdf-engine=xelatex 2>/dev/null || pandoc "$INPUT" -o "$OUTPUT"
        echo "Converted $INPUT -> $OUTPUT"
        ;;
    status)
        echo "Pandoc Document Converter status"
        pandoc --version | head -n1
        echo ""
        echo "Usage:"
        echo "  devcontainer-pandoc convert [options] <files>  # Run pandoc"
        echo "  devcontainer-pandoc md2pdf <input.md> [out.pdf]  # Markdown to PDF"
        ;;
    *)
        pandoc "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Pandoc Document Converter installed."
echo "  CLI: devcontainer-pandoc"
echo "  Convert: pandoc input.md -o output.pdf"
