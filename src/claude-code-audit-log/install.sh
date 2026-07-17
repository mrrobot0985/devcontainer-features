#!/bin/bash
set -e

# claude-code-audit-log install script
# Installs the audit-log helper to /usr/local/bin/

LOG_DIR="${LOGDIR:-/workspace/.audit-logs}"

# jq is used by consumers and scenario tests for JSON checks
if ! command -v jq >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq jq >/dev/null
fi

# Create log directory owned by the remote user (install runs as root)
mkdir -p "$LOG_DIR"
REMOTE_USER="${_REMOTE_USER:-vscode}"
if id "$REMOTE_USER" >/dev/null 2>&1; then
    chown -R "$REMOTE_USER:$REMOTE_USER" "$LOG_DIR" 2>/dev/null || true
fi

# Persist configured directory for the helper default
mkdir -p /usr/local/etc
printf '%s\n' "$LOG_DIR" > /usr/local/etc/claude-code-audit-log-dir

cat > /usr/local/bin/audit-log <<'EOF'
#!/bin/bash
set -e

# audit-log — append a structured JSON event to the workspace audit log
# Usage: audit-log <event> [--key=value ...]

if [ -n "${AUDIT_LOG_DIR:-}" ]; then
    LOG_DIR="$AUDIT_LOG_DIR"
elif [ -f /usr/local/etc/claude-code-audit-log-dir ]; then
    LOG_DIR="$(cat /usr/local/etc/claude-code-audit-log-dir)"
else
    LOG_DIR="/workspace/.audit-logs"
fi
LOG_FILE="$LOG_DIR/audit.log"

mkdir -p "$LOG_DIR"

_event="$1"
shift

json="{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
json="$json,\"event\":\"$_event\""

for arg in "$@"; do
    case "$arg" in
        --*)
            key="${arg%%=*}"
            key="${key#--}"
            val="${arg#*=}"
            val="$(printf '%s' "$val" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')"
            json="$json,\"$key\":\"$val\""
            ;;
    esac
done

json="$json}"

printf '%s\n' "$json" >> "$LOG_FILE"
EOF

chmod +x /usr/local/bin/audit-log

echo "claude-code-audit-log installed. Log directory: $LOG_DIR"
