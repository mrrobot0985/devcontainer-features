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
    echo "WARNING: npm not found. Some MCP servers require Node.js. Install the node feature first (installsAfter: ghcr.io/devcontainers/features/node)."
fi

# Install directory
INSTALL_DIR="/usr/local/share/mcp-server-manager"
mkdir -p "$INSTALL_DIR"
mkdir -p "$(dirname "$CONFIG_PATH")"

# Parse comma-separated server list
IFS=',' read -ra SERVER_LIST <<< "$SERVERS"

# Build MCP server configuration.
# Only append a comma/entry after a server is successfully resolved so unknown
# names never produce invalid JSON (trailing/leading commas).
MCP_CONFIG='{"mcpServers":{'
FIRST=true
CONFIGURED_COUNT=0

for SERVER in "${SERVER_LIST[@]}"; do
    SERVER="$(echo "$SERVER" | tr -d '[:space:]')"
    if [ -z "$SERVER" ]; then
        continue
    fi

    ENTRY=""
    case "$SERVER" in
        github)
            # Official TypeScript package (npx-friendly). Prefer this over
            # docker-only github/github-mcp-server for multi-agent templates.
            # Token is read from the process environment (set via containerEnv).
            ENTRY='"github":{"command":"npx","args":["-y","@modelcontextprotocol/server-github"]}'
            echo "Configured MCP server: github (via @modelcontextprotocol/server-github)"
            ;;
        playwright)
            ENTRY='"playwright":{"command":"npx","args":["-y","@playwright/mcp"]}'
            echo "Configured MCP server: playwright (via @playwright/mcp)"
            ;;
        fetch)
            # Official fetch server is Python; launched via uvx when available.
            ENTRY='"fetch":{"command":"uvx","args":["mcp-server-fetch"]}'
            echo "Configured MCP server: fetch (via uvx mcp-server-fetch)"
            ;;
        sequentialthinking)
            ENTRY='"sequentialthinking":{"command":"npx","args":["-y","@modelcontextprotocol/server-sequential-thinking"]}'
            echo "Configured MCP server: sequentialthinking (via @modelcontextprotocol/server-sequential-thinking)"
            ;;
        memory)
            mkdir -p "${USER_HOME}/.mcp/memory"
            ENTRY='"memory":{"command":"npx","args":["-y","@modelcontextprotocol/server-memory"]}'
            echo "Configured MCP server: memory (via @modelcontextprotocol/server-memory)"
            ;;
        sqlite)
            ENTRY='"sqlite":{"command":"npx","args":["-y","mcp-sqlite","/tmp/mcp-sqlite.db"]}'
            echo "Configured MCP server: sqlite (via mcp-sqlite)"
            ;;
        context7)
            ENTRY='"context7":{"command":"npx","args":["-y","@upstash/context7-mcp"]}'
            echo "Configured MCP server: context7 (via @upstash/context7-mcp)"
            ;;
        supabase)
            # SUPABASE_ACCESS_TOKEN must be present in the container environment.
            ENTRY='"supabase":{"command":"npx","args":["-y","@supabase/mcp-server-supabase@latest"]}'
            echo "Configured MCP server: supabase (via @supabase/mcp-server-supabase)"
            ;;
        *)
            echo "WARNING: Unknown MCP server '$SERVER' — skipping."
            ;;
    esac

    if [ -z "$ENTRY" ]; then
        continue
    fi

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        MCP_CONFIG="${MCP_CONFIG},"
    fi
    MCP_CONFIG="${MCP_CONFIG}${ENTRY}"
    CONFIGURED_COUNT=$((CONFIGURED_COUNT + 1))
done

MCP_CONFIG="${MCP_CONFIG}}}"

# Validate JSON before writing so templates never consume a broken config
if command -v python3 >/dev/null 2>&1; then
    if ! printf '%s' "$MCP_CONFIG" | python3 -c "import json,sys; json.load(sys.stdin)"; then
        echo "ERROR: Generated MCP config is not valid JSON"
        exit 1
    fi
fi

# Write configuration file
printf '%s\n' "$MCP_CONFIG" > "$CONFIG_PATH"
if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
    chown -R "${USERNAME}:" "$(dirname "$CONFIG_PATH")" 2>/dev/null || true
fi

echo "MCP server configuration written to: $CONFIG_PATH ($CONFIGURED_COUNT server(s))"

# Install shared example for multi-ai / studio templates (workspace .mcp.json shape)
EXAMPLE_DIR="/usr/local/share/mcp-server-manager"
if [ -f "$(dirname "$0")/mcp.json.example" ]; then
    cp "$(dirname "$0")/mcp.json.example" "${EXAMPLE_DIR}/mcp.json.example"
else
    cat > "${EXAMPLE_DIR}/mcp.json.example" << 'EXAMPLE_EOF'
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "sequentialthinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
EXAMPLE_EOF
fi
echo "Example multi-agent .mcp.json installed: ${EXAMPLE_DIR}/mcp.json.example"

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

# Parse configured server names. Most AI clients spawn MCP servers themselves;
# this helper is informational for multi-agent templates.
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
echo "  Example: ${EXAMPLE_DIR}/mcp.json.example"
