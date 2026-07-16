#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
INSTALL_JUPYTERLAB="${INSTALLJUPYTERLAB:-true}"
PACKAGES="${PACKAGES:-core}"
INSTALL_UV="${INSTALLUV:-false}"

# Detect username
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

USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

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
    echo "ERROR: pip not found. Cannot install Jupyter/ML packages."
    exit 1
fi

# Optionally install uv for faster package management
if [ "$INSTALL_UV" = "true" ]; then
    echo "Installing uv..."
    if ! command -v uv > /dev/null 2>&1; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$USER_HOME/.local/bin:$PATH"
    fi
fi

# Install Jupyter
if [ "$INSTALL_JUPYTERLAB" = "true" ]; then
    echo "Installing JupyterLab..."
    "$PIP_CMD" install --no-cache-dir --break-system-packages jupyterlab 2>/dev/null || "$PIP_CMD" install --no-cache-dir jupyterlab
else
    echo "Installing Jupyter Notebook..."
    "$PIP_CMD" install --no-cache-dir --break-system-packages notebook 2>/dev/null || "$PIP_CMD" install --no-cache-dir notebook
fi

# Install packages based on selected set
case "$PACKAGES" in
    minimal)
        echo "Package set: minimal (Jupyter only)"
        ;;
    core)
        echo "Package set: core (+ numpy, pandas, matplotlib)"
        "$PIP_CMD" install --no-cache-dir --break-system-packages numpy pandas matplotlib 2>/dev/null || \
            "$PIP_CMD" install --no-cache-dir numpy pandas matplotlib
        ;;
    full)
        echo "Package set: full (+ scikit-learn, scipy, seaborn)"
        "$PIP_CMD" install --no-cache-dir --break-system-packages numpy pandas matplotlib scikit-learn scipy seaborn 2>/dev/null || \
            "$PIP_CMD" install --no-cache-dir numpy pandas matplotlib scikit-learn scipy seaborn
        ;;
    *)
        echo "WARNING: Unknown package set '$PACKAGES'. Using core."
        "$PIP_CMD" install --no-cache-dir --break-system-packages numpy pandas matplotlib 2>/dev/null || \
            "$PIP_CMD" install --no-cache-dir numpy pandas matplotlib
        ;;
esac

# Set ownership for user-installed packages
if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
    USER_SITE="$USER_HOME/.local"
    if [ -d "$USER_SITE" ]; then
        chown -R "${USERNAME}:" "$USER_SITE" 2>/dev/null || true
    fi
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-jupyter"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    lab)
        echo "Starting JupyterLab..."
        jupyter lab "$@"
        ;;
    notebook)
        echo "Starting Jupyter Notebook..."
        jupyter notebook "$@"
        ;;
    list)
        echo "Listing Jupyter kernels..."
        jupyter kernelspec list
        ;;
    status)
        echo "Jupyter and ML Development Tools status"
        jupyter --version 2>/dev/null || true
        echo ""
        python3 -c "import numpy; print('NumPy:', numpy.__version__)" 2>/dev/null || true
        python3 -c "import pandas; print('Pandas:', pandas.__version__)" 2>/dev/null || true
        python3 -c "import matplotlib; print('Matplotlib:', matplotlib.__version__)" 2>/dev/null || true
        python3 -c "import sklearn; print('scikit-learn:', sklearn.__version__)" 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-jupyter lab        # Start JupyterLab"
        echo "  devcontainer-jupyter notebook   # Start Jupyter Notebook"
        echo "  devcontainer-jupyter list       # List kernels"
        ;;
    *)
        jupyter "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Jupyter and ML Development Tools installed."
echo "  CLI: devcontainer-jupyter"
if [ "$INSTALL_JUPYTERLAB" = "true" ]; then
    echo "  Start: jupyter lab"
else
    echo "  Start: jupyter notebook"
fi
echo "  Packages: $PACKAGES"
