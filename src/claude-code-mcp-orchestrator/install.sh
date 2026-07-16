#!/bin/bash
set -e

# claude-code-mcp-orchestrator install script
# Installs mcp-ctl helper for managing MCP servers

CONFIG_PATH="__CONFIGPATH__"
AUTO_START="__AUTOSTART__"

cat > /usr/local/bin/mcp-ctl <<'EOF'
#!/bin/bash
set -e

# mcp-ctl — manage MCP servers from .mcp.json
# Usage: mcp-ctl start|stop|status|list

CONFIG_PATH="${MCP_CONFIG:-/workspace/.mcp.json}"
PID_DIR="/tmp/mcp-pids"

mkdir -p "$PID_DIR"

list_servers() {
    if [ ! -f "$CONFIG_PATH" ]; then
        echo "No MCP config found at $CONFIG_PATH"
        return 0
    fi
    if command -v jq >/dev/null 2>&1; then
        jq -r 'keys[]' "$CONFIG_PATH" 2>/dev/null || true
    else
        echo "jq required for list"
        return 1
    fi
}

start_servers() {
    if [ ! -f "$CONFIG_PATH" ]; then
        echo "INFO: No MCP config at $CONFIG_PATH; nothing to start."
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "ERROR: jq required to parse .mcp.json"
        return 1
    fi

    echo "Starting MCP servers from $CONFIG_PATH..."
    jq -r 'to_entries[] | "\(.key)|\(.value.command // \"\")|\(.value.args // [] | join(\" \"))"' "$CONFIG_PATH" | while IFS='|' read -r name cmd args; do
        [ -z "$cmd" ] && continue
        pid_file="$PID_DIR/$name.pid"
        if [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
            echo "  $name already running (PID $(cat \"$pid_file\"))"
            continue
        fi
        echo "  Starting $name: $cmd $args"
        nohup sh -c "$cmd $args" >/dev/null 2>>1 &
        echo $! > "$pid_file"
    done
    echo "MCP servers started."
}

stop_servers() {
    echo "Stopping MCP servers..."
    for pid_file in "$PID_DIR"/*.pid; do
        [ -e "$pid_file" ] || continue
        name=$(basename "$pid_file" .pid)
        pid=$(cat "$pid_file" 2>/dev/null || true)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "  Stopping $name (PID $pid)"
            kill "$pid" 2>/dev/null || true
        fi
        rm -f "$pid_file"
    done
    echo "MCP servers stopped."
}

status_servers() {
    echo "MCP server status:"
    for pid_file in "$PID_DIR"/*.pid; do
        [ -e "$pid_file" ] || continue
        name=$(basename "$pid_file" .pid)
        pid=$(cat "$pid_file" 2>/dev/null || true)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "  $name: running (PID $pid)"
        else
            echo "  $name: not running"
        fi
    done
}

case "${1:-}" in
    start) start_servers ;;
    stop) stop_servers ;;
    status) status_servers ;;
    list) list_servers ;;
    *) echo "Usage: mcp-ctl {start|stop|status|list}"; exit 1 ;;
esac
EOF

chmod +x /usr/local/bin/mcp-ctl

echo "claude-code-mcp-orchestrator installed."
echo "  Config path: $CONFIG_PATH"
echo "  Auto-start: $AUTO_START"
echo "  Run 'mcp-ctl start' to launch MCP servers."
