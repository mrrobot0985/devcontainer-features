#!/bin/bash
set -e

# devcontainer-lib install script
# Installs a shared shell utility library for devcontainer lifecycle scripts

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_HOME=$(getent passwd "$REMOTE_USER" | cut -d: -f6 2>/dev/null || true)
if [ -z "$REMOTE_HOME" ]; then
    if [ "$REMOTE_USER" = "root" ]; then
        REMOTE_HOME="/root"
    else
        REMOTE_HOME="/home/$REMOTE_USER"
    fi
fi

INSTALL_PATH="${INSTALLPATH:-/usr/local/share/devcontainer-lib}"

echo "Devcontainer Shared Library"
echo "  Install path: $INSTALL_PATH"

mkdir -p "$INSTALL_PATH"

# Write the shared library
cat > "$INSTALL_PATH/devcontainer-lib.sh" <<'LIB_EOF'
#!/bin/bash
# devcontainer-lib.sh — shared utility library for devcontainer features
# Source this file in your install scripts: source /usr/local/share/devcontainer-lib/devcontainer-lib.sh

# Logging helpers
dc_log_info() {
    echo "INFO [devcontainer-lib]: $1"
}

dc_log_warn() {
    echo "WARNING [devcontainer-lib]: $1"
}

dc_log_error() {
    echo "ERROR [devcontainer-lib]: $1"
}

# Retry a command with exponential backoff
# Usage: dc_retry "command" [max_attempts=3] [initial_delay=5]
dc_retry() {
    local cmd="$1"
    local max_attempts="${2:-3}"
    local delay="${3:-5}"
    local attempt=1

    while [ "$attempt" -le "$max_attempts" ]; do
        if eval "$cmd"; then
            return 0
        fi
        dc_log_warn "Command failed (attempt $attempt/$max_attempts): $cmd"
        if [ "$attempt" -lt "$max_attempts" ]; then
            sleep "$delay"
            delay=$((delay * 2))
        fi
        attempt=$((attempt + 1))
    done

    dc_log_error "Command failed after $max_attempts attempts: $cmd"
    return 1
}

# Wait until a command succeeds
# Usage: dc_wait_for "command" [timeout=60] [interval=2]
dc_wait_for() {
    local cmd="$1"
    local timeout="${2:-60}"
    local interval="${3:-2}"
    local elapsed=0

    while [ "$elapsed" -lt "$timeout" ]; do
        if eval "$cmd" >/dev/null 2>&1; then
            return 0
        fi
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done

    dc_log_error "Timed out after ${timeout}s waiting for: $cmd"
    return 1
}

# Install a package via apt-get if not already present
# Usage: dc_install_if_missing "package-name"
dc_install_if_missing() {
    local pkg="$1"
    if dpkg -l "$pkg" >/dev/null 2>&1 | grep -q "^ii"; then
        dc_log_info "$pkg is already installed"
        return 0
    fi
    dc_log_info "Installing $pkg..."
    apt-get update >/dev/null 2>&1 || true
    apt-get install -y "$pkg" >/dev/null 2>&1 || {
        dc_log_warn "Failed to install $pkg"
        return 1
    }
}

# Ensure jq is available
dc_ensure_jq() {
    if command -v jq >/dev/null 2>&1; then
        return 0
    fi
    dc_install_if_missing jq
}

# Resolve the remote user with sensible defaults
dc_get_remote_user() {
    local user="${_REMOTE_USER:-vscode}"
    echo "$user"
}

# Resolve the remote user's home directory
dc_get_remote_home() {
    local user
    user=$(dc_get_remote_user)
    local home_dir
    home_dir=$(getent passwd "$user" | cut -d: -f6 2>/dev/null || true)
    if [ -z "$home_dir" ]; then
        if [ "$user" = "root" ]; then
            home_dir="/root"
        else
            home_dir="/home/$user"
        fi
    fi
    echo "$home_dir"
}

# Fail if a command is not available
# Usage: dc_assert_command "command-name"
dc_assert_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        dc_log_error "Required command not found: $cmd"
        exit 1
    fi
}

# Robust file download with retry
# Usage: dc_download "url" "output-path"
dc_download() {
    local url="$1"
    local outfile="$2"
    local tmpfile="${outfile}.tmp.$$"

    if curl -fsSL --retry 3 --max-time 120 -o "$tmpfile" "$url" 2>/dev/null; then
        mv "$tmpfile" "$outfile"
        return 0
    fi

    dc_log_error "Failed to download $url"
    rm -f "$tmpfile"
    return 1
}

# Normalize architecture names from uname -m to amd64/arm64
dc_detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            dc_log_warn "Unknown architecture '$arch'; defaulting to amd64"
            echo "amd64"
            ;;
    esac
}

# Safely chown a path, suppressing errors
# Usage: dc_safe_chown "user:group" "path"
dc_safe_chown() {
    local owner="$1"
    local path="$2"
    chown "$owner" "$path" 2>/dev/null || true
}

# Create a directory owned by the remote user
# Usage: dc_ensure_dir "path" [owner="$REMOTE_USER"]
dc_ensure_dir() {
    local dir="$1"
    local owner="${2:-$REMOTE_USER}"
    mkdir -p "$dir"
    if [ -n "$owner" ]; then
        dc_safe_chown "$owner:$owner" "$dir"
    fi
}

# Test if running inside a devcontainer feature install context
dc_is_feature_install() {
    [ -n "${_REMOTE_USER:-}" ]
}

# Print a summary of available functions
dc_help() {
    echo "Devcontainer Shared Library — Available Functions"
    echo "================================================="
    echo ""
    echo "Logging:"
    echo "  dc_log_info msg       — Print INFO message"
    echo "  dc_log_warn msg       — Print WARNING message"
    echo "  dc_log_error msg      — Print ERROR message"
    echo ""
    echo "Execution:"
    echo "  dc_retry cmd [n] [d]  — Retry command with exponential backoff"
    echo "  dc_wait_for cmd [t] [i] — Poll until command succeeds"
    echo "  dc_assert_command cmd — Fail if command is missing"
    echo ""
    echo "Environment:"
    echo "  dc_get_remote_user    — Resolve _REMOTE_USER"
    echo "  dc_get_remote_home    — Resolve remote user's home directory"
    echo "  dc_detect_arch        — Normalize architecture to amd64/arm64"
    echo "  dc_is_feature_install — Test if in feature install context"
    echo ""
    echo "Package Management:"
    echo "  dc_install_if_missing pkg — Install via apt-get if absent"
    echo "  dc_ensure_jq          — Ensure jq is installed"
    echo ""
    echo "Filesystem:"
    echo "  dc_download url outfile — Robust curl download"
    echo "  dc_safe_chown owner path — chown with error suppression"
    echo "  dc_ensure_dir path [owner] — Create directory with ownership"
    echo ""
    echo "Source this library:"
    echo "  source /usr/local/share/devcontainer-lib/devcontainer-lib.sh"
}
LIB_EOF

chmod +x "$INSTALL_PATH/devcontainer-lib.sh"

# Write a README for feature authors
cat > "$INSTALL_PATH/README.md" <>'README_EOF'
# Devcontainer Shared Library

This directory contains a shared shell utility library for use in devcontainer
lifecycle scripts and custom automation.

## Usage

Source the library in your shell scripts:

```bash
source /usr/local/share/devcontainer-lib/devcontainer-lib.sh
```

## Available Functions

See `dc_help` for the full list.

Common functions:
- `dc_retry "command" [max] [delay]` — Retry with exponential backoff
- `dc_wait_for "command" [timeout] [interval]` — Poll until success
- `dc_install_if_missing "package"` — apt-get install if absent
- `dc_ensure_jq` — Ensure jq is available
- `dc_get_remote_user` / `dc_get_remote_home` — User detection
- `dc_download "url" "outfile"` — Robust curl download
- `dc_detect_arch` — Normalize architecture names

## Why?

Devcontainer features often duplicate the same ~100 lines of helper functions.
This library centralizes them so features can stay focused on their core purpose.

See: https://github.com/devcontainers/spec/blob/main/proposals/features-library.md
README_EOF

echo "Devcontainer shared library installed to $INSTALL_PATH"
echo "  Source: source $INSTALL_PATH/devcontainer-lib.sh"
echo "  Run 'dc_help' for available functions."
