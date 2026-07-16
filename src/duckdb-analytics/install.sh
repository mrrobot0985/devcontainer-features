#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"
INSTALL_EXTENSIONS="${INSTALLEXTENSIONS:-false}"

# Install DuckDB
if command -v duckdb > /dev/null 2>&1; then
    echo "DuckDB already installed."
    duckdb --version 2>/dev/null || true
    exit 0
fi

echo "Installing DuckDB..."

ARCH="amd64"
case "$(uname -m)" in
    aarch64|arm64) ARCH="aarch64" ;;
    x86_64) ARCH="amd64" ;;
esac

if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    # Download latest release
    DOWNLOAD_URL="https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-${ARCH}.zip"
else
    DOWNLOAD_URL="https://github.com/duckdb/duckdb/releases/download/v${VERSION}/duckdb_cli-linux-${ARCH}.zip"
fi

# Download and extract
curl -fsSL "$DOWNLOAD_URL" -o /tmp/duckdb.zip || {
    echo "ERROR: Failed to download DuckDB from $DOWNLOAD_URL"
    exit 1
}

unzip -q /tmp/duckdb.zip -d /usr/local/bin
rm -f /tmp/duckdb.zip
chmod +x /usr/local/bin/duckdb

# Verify installation
if command -v duckdb > /dev/null 2>&1; then
    echo "DuckDB installed: $(duckdb --version 2>&1 || echo 'version unknown')"
else
    echo "ERROR: DuckDB installation failed"
    exit 1
fi

# Install extensions
if [ "$INSTALL_EXTENSIONS" = "true" ]; then
    echo "Installing DuckDB extensions..."
    duckdb -c "INSTALL httpfs; INSTALL json; INSTALL parquet;" || echo "WARNING: Some extensions failed to install"
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-duckdb"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    query)
        echo "Running DuckDB query..."
        duckdb "$@"
        ;;
    csv)
        echo "Querying CSV with DuckDB..."
        duckdb -c ".mode csv" "$@"
        ;;
    json)
        echo "Querying with JSON output..."
        duckdb -c ".mode json" "$@"
        ;;
    parquet)
        echo "Reading Parquet file..."
        duckdb -c "SELECT * FROM read_parquet('$1');"
        ;;
    status)
        echo "DuckDB Analytics status"
        duckdb --version 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-duckdb query    # Interactive shell"
        echo "  devcontainer-duckdb csv      # CSV mode query"
        echo "  devcontainer-duckdb json     # JSON mode query"
        echo "  devcontainer-duckdb parquet  # Read Parquet file"
        echo ""
        echo "Examples:"
        echo "  duckdb -c \"SELECT * FROM 'data.csv'\""
        echo "  duckdb -c \"SELECT * FROM read_parquet('file.parquet')\""
        ;;
    *)
        duckdb "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "DuckDB Analytics installed."
echo "  CLI: devcontainer-duckdb"
echo "  Shell: duckdb"
echo "  Version: $(duckdb --version 2>/dev/null || echo 'installed')"
