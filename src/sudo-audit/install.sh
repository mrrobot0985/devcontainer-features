#!/bin/bash
set -e

# sudo-audit install script
# Installs a validation script that audits passwordless sudo

FAIL_ON_WARNING="${FAILONWARNING:-false}"

mkdir -p /usr/local/etc
printf '%s\n' "$FAIL_ON_WARNING" > /usr/local/etc/sudo-audit-fail-on-warning

cat > /usr/local/bin/sudo-audit <<'EOF'
#!/bin/bash
set -e

# sudo-audit — audit container for passwordless sudo configuration
# Run during postCreateCommand to validate the container image.

WARNINGS=0

if [ -n "${FAIL_ON_WARNING:-}" ]; then
    :
elif [ -f /usr/local/etc/sudo-audit-fail-on-warning ]; then
    FAIL_ON_WARNING="$(cat /usr/local/etc/sudo-audit-fail-on-warning)"
else
    FAIL_ON_WARNING="false"
fi

warn() {
    echo "WARNING [sudo-audit]: $1"
    WARNINGS=$((WARNINGS + 1))
}

# sudoers files are typically mode 0440; prefer sudo for reads when available.
grep_sudoers() {
    local file="$1"
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        sudo grep -qE '^[^#]*NOPASSWD' "$file" 2>/dev/null
    else
        grep -qE '^[^#]*NOPASSWD' "$file" 2>/dev/null
    fi
}

# Check /etc/sudoers
if [ -f /etc/sudoers ]; then
    if grep_sudoers /etc/sudoers; then
        warn "/etc/sudoers contains NOPASSWD directive"
    fi
fi

# Check /etc/sudoers.d/*
if [ -d /etc/sudoers.d ]; then
    for f in /etc/sudoers.d/*; do
        [ -e "$f" ] || continue
        if grep_sudoers "$f"; then
            warn "$(basename "$f") contains NOPASSWD directive"
        fi
    done
fi

# Check sudo group membership for remoteUser
REMOTE_USER="${_REMOTE_USER:-${REMOTE_USER:-vscode}}"
if id -nG "$REMOTE_USER" 2>/dev/null | grep -qw sudo; then
    echo "INFO [sudo-audit]: $REMOTE_USER is in sudo group"
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo "WARNING [sudo-audit]: $WARNINGS passwordless sudo configuration(s) detected."
    if [ "$FAIL_ON_WARNING" = "true" ]; then
        echo "ERROR [sudo-audit]: failOnWarning is enabled; aborting container creation."
        exit 1
    fi
else
    echo "INFO [sudo-audit]: No passwordless sudo configurations detected."
fi

exit 0
EOF

chmod +x /usr/local/bin/sudo-audit

echo "sudo-audit installed. Run 'sudo-audit' to check for passwordless sudo."
