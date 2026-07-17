#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"
INSTALL_DUCKDB="${INSTALLDUCKDBADAPTER:-true}"
INSTALL_POSTGRES="${INSTALLPOSTGRESADAPTER:-false}"

VENV_DIR="/usr/local/dbt"
DBT_BIN="/usr/local/bin/dbt"

install_packages() {
    if command -v apt-get > /dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends python3 python3-pip python3-venv python3-dev
    elif command -v dnf > /dev/null 2>&1; then
        dnf install -y python3 python3-pip python3-devel
    elif command -v yum > /dev/null 2>&1; then
        yum install -y python3 python3-pip python3-devel
    elif command -v apk > /dev/null 2>&1; then
        apk add --no-cache python3 py3-pip python3-dev
    else
        echo "ERROR: Cannot install Python: no supported package manager found."
        exit 1
    fi
}

# Ensure Python is available
if ! command -v python3 > /dev/null 2>&1 && ! command -v python > /dev/null 2>&1; then
    echo "Python not found. Installing Python..."
    install_packages
fi

PYTHON_CMD="python3"
if ! command -v python3 > /dev/null 2>&1; then
    PYTHON_CMD="python"
fi

# Ensure venv module is available (required on PEP 668 / Debian-based images)
if ! "$PYTHON_CMD" -m venv --help > /dev/null 2>&1; then
    echo "python venv module missing. Installing Python venv support..."
    install_packages
fi

# Create isolated install environment under /usr/local (avoids PEP 668)
echo "Creating dbt virtualenv at ${VENV_DIR}..."
rm -rf "$VENV_DIR"
"$PYTHON_CMD" -m venv "$VENV_DIR"
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
PIP_CMD="$VENV_DIR/bin/pip"
"$PIP_CMD" install --upgrade pip setuptools wheel

# Install dbt-core
echo "Installing dbt-core..."
if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    "$PIP_CMD" install --no-cache-dir dbt-core
else
    "$PIP_CMD" install --no-cache-dir "dbt-core==${VERSION}"
fi

# Install adapters into the same venv so dbt can load them
if [ "$INSTALL_DUCKDB" = "true" ]; then
    echo "Installing dbt-duckdb adapter..."
    "$PIP_CMD" install --no-cache-dir dbt-duckdb || \
        echo "WARNING: dbt-duckdb adapter not installed"
fi

if [ "$INSTALL_POSTGRES" = "true" ]; then
    echo "Installing dbt-postgres adapter..."
    "$PIP_CMD" install --no-cache-dir dbt-postgres || \
        echo "WARNING: dbt-postgres adapter not installed"
fi

deactivate || true

# Expose dbt on PATH
ln -sfn "$VENV_DIR/bin/dbt" "$DBT_BIN"

# Verify installation
if command -v dbt > /dev/null 2>&1 || [ -x "$DBT_BIN" ]; then
    echo "dbt installed: $($DBT_BIN --version 2>&1 | head -n1 || echo 'version unknown')"
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
echo "  Venv: ${VENV_DIR}"
