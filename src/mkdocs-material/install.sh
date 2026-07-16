#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
PLUGINS="${PLUGINS:-search,minify,git-revision-date,redirects}"
GENERATE_CONFIG="${GENERATECONFIG:-true}"
SERVE_PORT="${SERVEPORT:-8000}"

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

# Ensure Python/pip is available
if ! command -v pip3 > /dev/null 2>&1 && ! command -v pip > /dev/null 2>&1; then
    echo "pip not found. Installing python3-pip..."
    if command -v apt-get > /dev/null 2>&1; then
        apt-get update && apt-get install -y python3-pip
    elif command -v dnf > /dev/null 2>&1; then
        dnf install -y python3-pip
    elif command -v yum > /dev/null 2>&1; then
        yum install -y python3-pip
    elif command -v apk > /dev/null 2>&1; then
        apk add --no-cache py3-pip
    else
        echo "ERROR: Cannot install pip: no supported package manager found."
        exit 1
    fi
fi

# Install MkDocs with Material theme
if ! command -v mkdocs > /dev/null 2>&1; then
    echo "Installing MkDocs with Material theme..."
    if command -v pip3 > /dev/null 2>&1; then
        pip3 install --break-system-packages mkdocs-material 2>/dev/null || pip3 install mkdocs-material
    elif command -v pip > /dev/null 2>&1; then
        pip install --break-system-packages mkdocs-material 2>/dev/null || pip install mkdocs-material
    else
        echo "ERROR: Cannot install MkDocs: pip not available."
        exit 1
    fi
else
    echo "MkDocs already installed."
fi

# Install requested plugins
IFS=',' read -ra PLUGIN_LIST <<< "$PLUGINS"
for PLUGIN in "${PLUGIN_LIST[@]}"; do
    PLUGIN="$(echo "$PLUGIN" | tr -d '[:space:]')"
    case "$PLUGIN" in
        search)
            # Built into mkdocs-material
            echo "Plugin 'search' is built into mkdocs-material."
            ;;
        minify)
            echo "Installing mkdocs-minify-plugin..."
            if command -v pip3 > /dev/null 2>&1; then
                pip3 install --break-system-packages mkdocs-minify-plugin 2>/dev/null || pip3 install mkdocs-minify-plugin
            elif command -v pip > /dev/null 2>&1; then
                pip install --break-system-packages mkdocs-minify-plugin 2>/dev/null || pip install mkdocs-minify-plugin
            fi
            ;;
        git-revision-date)
            echo "Installing mkdocs-git-revision-date-localized-plugin..."
            if command -v pip3 > /dev/null 2>&1; then
                pip3 install --break-system-packages mkdocs-git-revision-date-localized-plugin 2>/dev/null || pip3 install mkdocs-git-revision-date-localized-plugin
            elif command -v pip > /dev/null 2>&1; then
                pip install --break-system-packages mkdocs-git-revision-date-localized-plugin 2>/dev/null || pip install mkdocs-git-revision-date-localized-plugin
            fi
            ;;
        redirects)
            echo "Installing mkdocs-redirects..."
            if command -v pip3 > /dev/null 2>&1; then
                pip3 install --break-system-packages mkdocs-redirects 2>/dev/null || pip3 install mkdocs-redirects
            elif command -v pip > /dev/null 2>&1; then
                pip install --break-system-packages mkdocs-redirects 2>/dev/null || pip install mkdocs-redirects
            fi
            ;;
        mermaid)
            echo "Installing mkdocs-mermaid2-plugin..."
            if command -v pip3 > /dev/null 2>&1; then
                pip3 install --break-system-packages mkdocs-mermaid2-plugin 2>/dev/null || pip3 install mkdocs-mermaid2-plugin
            elif command -v pip > /dev/null 2>&1; then
                pip install --break-system-packages mkdocs-mermaid2-plugin 2>/dev/null || pip install mkdocs-mermaid2-plugin
            fi
            ;;
        *)
            echo "WARNING: Unknown plugin '$PLUGIN' — skipping."
            ;;
    esac
done

# Generate default mkdocs.yml if requested
DEFAULT_MKDOCS="${USER_HOME}/mkdocs.yml"
if [ ! -f "$DEFAULT_MKDOCS" ] && [ "$GENERATE_CONFIG" = "true" ]; then
    cat > "$DEFAULT_MKDOCS" << 'MKDOCS_EOF'
site_name: Documentation
site_description: Project documentation
site_author: Team

 theme:
  name: material
  palette:
    - scheme: default
      primary: indigo
      accent: indigo
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
    - scheme: slate
      primary: indigo
      accent: indigo
      toggle:
        icon: material/brightness-4
        name: Switch to light mode
  features:
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - search.highlight
    - search.share

plugins:
  - search

markdown_extensions:
  - pymdownx.highlight:
      anchor_linenums: true
  - pymdownx.inlinehilite
  - pymdownx.snippets
  - pymdownx.superfences
  - admonition
  - pymdownx.details
  - pymdownx.tabbed:
      alternate_style: true
  - tables
  - attr_list
  - md_in_html
  - toc:
      permalink: true

extra:
  social:
    - icon: fontawesome/brands/github
      link: https://github.com/username/repo

nav:
  - Home: index.md
  - Getting Started: getting-started.md
MKDOCS_EOF
    if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
        chown "${USERNAME}:" "$DEFAULT_MKDOCS" 2>/dev/null || true
    fi
    echo "Default mkdocs.yml written to $DEFAULT_MKDOCS"
fi

# Write a convenience startup script
STARTUP_SCRIPT="/usr/local/bin/devcontainer-mkdocs-serve"
cat > "$STARTUP_SCRIPT" << 'STARTUP_EOF'
#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8000}"
CONFIG="${2:-mkdocs.yml}"

echo "Starting MkDocs server on port $PORT..."
if [ -f "$CONFIG" ]; then
    mkdocs serve --dev-addr "0.0.0.0:${PORT}" --config-file "$CONFIG"
else
    echo "WARNING: MkDocs config not found at $CONFIG"
    echo "Run 'mkdocs new .' to create a new project or provide a config file."
    exit 1
fi
STARTUP_EOF

chmod +x "$STARTUP_SCRIPT"

# Add shell aliases
for PROFILE in "${USER_HOME}/.bashrc" "${USER_HOME}/.zshrc"; do
    if [ -f "$PROFILE" ]; then
        if ! grep -q "devcontainer-mkdocs-serve" "$PROFILE" 2>/dev/null; then
            echo "alias mkdocs-serve='devcontainer-mkdocs-serve'" >> "$PROFILE"
        fi
    fi
done

echo "MkDocs Material installed."
echo "  CLI: devcontainer-mkdocs-serve [port] [config]"
echo "  Default port: $SERVE_PORT"
