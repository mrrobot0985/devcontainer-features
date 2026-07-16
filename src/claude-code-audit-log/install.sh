#!/bin/bash
set -e

# claude-code-audit-log install script
# Installs the audit-log helper to /usr/local/bin/

LOG_DIR="${LOGDIR:-/workspace/.audit-logs}"

# Create log directory if it does not exist
mkdir -p "$LOG_DIR"
chown "$(id -u):$(id -g)" "$LOG_DIR" 2>/dev/null || true

# Install the audit-log script
cat > /usr/local/bin/audit-log <<'EOF'
#!/bin/bash
set -e

# audit-log — append a structured JSON event to the workspace audit log
# Usage: audit-log <event> [--key=value ...]

LOG_DIR="${AUDIT_LOG_DIR:-/workspace/.audit-logs}"
LOG_FILE="$LOG_DIR/audit.log"

# Ensure directory exists
mkdir -p "$LOG_DIR"

# Build JSON object
_event="$1"
shift

# Start JSON
json="{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
json="$json,\"event\":\"$_event\""

# Parse remaining arguments as key=value or --key=value
for arg in "$@"; do
    case "$arg" in
        --*)
            key="${arg%%=*}"
            key="${key#--}"
            val="${arg#*=}"
            # Escape backslashes, quotes, and control characters
            val="$(printf '%s' "$val" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')"
            json="$json,\"$key\":\"$val\""
            ;;
    esac
done

json="$json}"

# Atomic append
printf '%s\n' "$json" >> "$LOG_FILE"
EOF

chmod +x /usr/local/bin/audit-log

echo "claude-code-audit-log installed. Log directory: $LOG_DIR"
