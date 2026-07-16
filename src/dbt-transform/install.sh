#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"
INSTALL_DUCKDB="${INSTALLDUCKDBADAPTER:-true}"
INSTALL_POSTGRES="${INSTALLPOSTGRESADAPTER:-false}"

# Ensure Python and pip are available
if ! command -v python3 > /dev/null 2>&1 && ! command -v python > /dev/null 2>&1; then
    echo "Python not found. Installing Python..."
    if command -v apt-get > /dev/null 2>&1; then
        apt-get update && apt-get install -y python3 python3-pip python3-venv
    elif command -v dnf > /dev/null 2>&1; then
        dnf install -y python3 python3-pip
    elif command -v yum > /dev/null 2>&1; then
        yum install -y python3 python3-pip
    elif command -v apk > /dev/null 2>&1; then
        apk add --no-cache python3 py3-pip
    else
        echo "ERROR: Cannot install Python: no supported package manager found."
        exit 1
    fi
fi

# Determine pip command
PIP_CMD="pip3"
if ! command -v pip3 > /dev/null 2>&1; then
    PIP_CMD="pip"
fi
if ! command -v "$PIP_CMD" > /dev/null 2>&1; then
    echo "ERROR: pip not found. Cannot install dbt."
    exit 1
fi

# Install dbt-core
echo "Installing dbt-core..."
if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    "$PIP_CMD" install --no-cache-dir --break-system-packages dbt-core 2>/dev/null || \
        "$PIP_CMD" install --no-cache-dir dbt-core
else
    "$PIP_CMD" install --no-cache-dir --break-system-packages "dbt-core==${VERSION}" 2>/dev/null || \
        "$PIP_CMD" install --no-cache-dir "dbt-core==${VERSION}"
fi

# Install adapters
if [ "$INSTALL_DUCKDB" = "true" ]; then
    echo "Installing dbt-duckdb adapter..."
    "$PIP_CMD" install --no-cache-dir --break-system-packages dbt-duckdb 2>/dev/null || \
        "$PIP_CMD" install --no-cache-dir dbt-duckdb || \
        echo "WARNING: dbt-duckdb adapter not installed"
fi

if [ "$INSTALL_POSTGRES" = "true" ]; then
    echo "Installing dbt-postgres adapter..."
    "$PIP_CMD" install --no-cache-dir --break-system-packages dbt-postgres 2>/dev/null || \
        "$PIP_CMD" install --no-cache-dir dbt-postgres || \
        echo "WARNING: dbt-postgres adapter not installed"
fi

# Verify installation
if command -v dbt > /dev/null 2>&1; then
    echo "dbt installed: $(dbt --version 2>&1 | head -n1 || echo 'version unknown')"
else
    echo "ERROR: dbt installation failed"
    exit 1
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-dbt"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    build)
        echo "Running dbt build..."
        dbt build "$@"
        ;;
    test)
        echo "Running dbt tests..."
        dbt test "$@"
        ;;
    run)
        echo "Running dbt models..."
        dbt run "$@"
        ;;
    debug)
        echo "Debugging dbt connection..."
        dbt debug "$@"
        ;;
    status)
        echo "dbt Data Transformation status"
        dbt --version 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-dbt build  # Build all models"
        echo "  devcontainer-dbt test   # Run tests"
        echo "  devcontainer-dbt run    # Run models"
        echo "  devcontainer-dbt debug  # Test connection"
        ;;
    *)
        dbt "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "dbt Data Transformation installed."
echo "  CLI: devcontainer-dbt"
echo "  Build: dbt build"
echo "  Test: dbt test"
