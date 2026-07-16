#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
SERVERS="${MCPSERVERMANAGERSERVERS:-github}"
CONFIG_PATH="${MCPSERVERMANAGERCONFIGPATH:-auto}"
START_SERVERS="${MCPSERVERMANAGERSTARTSERVERS:-true}"

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

# Determine config path
if [ "$CONFIG_PATH" = "auto" ] || [ "$CONFIG_PATH" = "automatic" ]; then
    CONFIG_PATH="${USER_HOME}/.mcp/mcp-servers.json"
fi

# Ensure Node.js is available for npm-based MCP servers
if ! command -v npm >/dev/null 2>&1; then
    echo "WARNING: npm not found. Some MCP servers require Node.js. Install node feature first."
fi

# Install directory
INSTALL_DIR="/usr/local/share/mcp-server-manager"
mkdir -p "$INSTALL_DIR"
mkdir -p "$(dirname "$CONFIG_PATH")"

# Parse comma-separated server list
IFS=',' read -ra SERVER_LIST <<< "$SERVERS"

# Build MCP server configuration
MCP_CONFIG='{"mcpServers":{'
FIRST=true

for SERVER in "${SERVER_LIST[@]}"; do
    SERVER="$(echo "$SERVER" | tr -d '[:space:]')"
    if [ -z "$SERVER" ]; then
        continue
    fi

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        MCP_CONFIG="${MCP_CONFIG},"
    fi

    case "$SERVER" in
        github)
            MCP_CONFIG="${MCP_CONFIG}\"github\":{\"command\":\"npx\",\"args\":[\"-y\",\"@github/github-mcp-server\"]}"
            echo "Configured MCP server: github (via @github/github-mcp-server)"
            ;;
        playwright)
            MCP_CONFIG="${MCP_CONFIG}\"playwright\":{\"command\":\"npx\",\"args\":[\"-y\",\"@anthropics/playwright-mcp\"]}"
            echo "Configured MCP server: playwright (via @anthropics/playwright-mcp)"
            ;;
        fetch)
            MCP_CONFIG="${MCP_CONFIG}\"fetch\":{\"command\":\"npx\",\"args\":[\"-y\",\"@modelcontextprotocol/server-fetch\"]}"
            echo "Configured MCP server: fetch (via @modelcontextprotocol/server-fetch)"
            ;;
        sequentialthinking)
            MCP_CONFIG="${MCP_CONFIG}\"sequentialthinking\":{\"command\":\"npx\",\"args\":[\"-y\",\"@modelcontextprotocol/server-sequential-thinking\"]}"
            echo "Configured MCP server: sequentialthinking (via @modelcontextprotocol/server-sequential-thinking)"
            ;;
        memory)
            # Memory server uses sqlite; create a data directory
            mkdir -p "${USER_HOME}/.mcp/memory"
            MCP_CONFIG="${MCP_CONFIG}\"memory\":{\"command\":\"npx\",\"args\":[\"-y\",\"@modelcontextprotocol/server-memory\"]}"
            echo "Configured MCP server: memory (via @modelcontextprotocol/server-memory)"
            ;;
        sqlite)
            MCP_CONFIG="${MCP_CONFIG}\"sqlite\":{\"command\":\"npx\",\"args\":[\"-y\",\"@modelcontextprotocol/server-sqlite\",\"/tmp/mcp-sqlite.db\"]}"
            echo "Configured MCP server: sqlite (via @modelcontextprotocol/server-sqlite)"
            ;;
        context7)
            MCP_CONFIG="${MCP_CONFIG}\"context7\":{\"command\":\"npx\",\"args\":[\"-y\",\"@upstash/context7-mcp\"]}"
            echo "Configured MCP server: context7 (via @upstash/context7-mcp)"
            ;;
        *)
            echo "WARNING: Unknown MCP server '$SERVER' — skipping."
            ;;
    esac
done

MCP_CONFIG="${MCP_CONFIG}}}"

# Write configuration file
echo "$MCP_CONFIG" > "$CONFIG_PATH"
if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
    chown -R "${USERNAME}:" "$(dirname "$CONFIG_PATH")" 2>/dev/null || true
fi

echo "MCP server configuration written to: $CONFIG_PATH"

# Generate startup script if requested
if [ "$START_SERVERS" = "true" ]; then
    cat > /usr/local/bin/devcontainer-mcp-start << 'START_EOF'
#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="__CONFIG_PATH__"

if [ ! -f "$CONFIG_PATH" ]; then
    echo "ERROR: MCP config not found at $CONFIG_PATH"
    exit 1
fi

echo "Starting MCP servers from $CONFIG_PATH..."

# Parse and start each MCP server in the background
# This is a simple launcher; production use may want supervisord or systemd
SERVERS=$(python3 -c "import json; print(' '.join(json.load(open('$CONFIG_PATH'))['mcpServers'].keys()))" 2>/dev/null || echo "")

if [ -z "$SERVERS" ]; then
    echo "No MCP servers configured."
    exit 0
fi

for SERVER in $SERVERS; do
    echo "  - Would start: $SERVER (configure your AI client to use $CONFIG_PATH)"
done

echo "MCP servers configured. Use the config file in your AI client."
START_EOF

    sed -i "s|__CONFIG_PATH__|${CONFIG_PATH}|g" /usr/local/bin/devcontainer-mcp-start
    chmod +x /usr/local/bin/devcontainer-mcp-start
    echo "Startup script installed: devcontainer-mcp-start"
fi

# Install a status checker
cat > /usr/local/bin/devcontainer-mcp-status << 'STATUS_EOF'
#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="__CONFIG_PATH__"

if [ ! -f "$CONFIG_PATH" ]; then
    echo "MCP config not found at $CONFIG_PATH"
    exit 1
fi

echo "MCP Server Status"
echo "================="
echo "Config: $CONFIG_PATH"
echo ""
python3 -c "
import json
try:
    config = json.load(open('$CONFIG_PATH'))
    servers = config.get('mcpServers', {})
    if not servers:
        print('No servers configured.')
    else:
        for name, cfg in servers.items():
            cmd = cfg.get('command', 'N/A')
            args = ' '.join(cfg.get('args', []))
            print(f'  {name}: {cmd} {args}')
except Exception as e:
    print(f'Error reading config: {e}')
"
STATUS_EOF

sed -i "s|__CONFIG_PATH__|${CONFIG_PATH}|g" /usr/local/bin/devcontainer-mcp-status
chmod +x /usr/local/bin/devcontainer-mcp-status

echo "MCP Server Manager installed."
echo "  Config: $CONFIG_PATH"
echo "  Status: devcontainer-mcp-status"
