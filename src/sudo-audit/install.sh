#!/bin/bash
set -e

# sudo-audit install script
# Installs a validation script that audits passwordless sudo

cat > /usr/local/bin/sudo-audit <<'EOF'
#!/bin/bash
set -e

# sudo-audit — audit container for passwordless sudo configuration
# Run during postCreateCommand to validate the container image.

WARNINGS=0

warn() {
    echo "WARNING [sudo-audit]: $1"
    WARNINGS=$((WARNINGS + 1))
}

# Check /etc/sudoers
if [ -f /etc/sudoers ]; then
    if grep -qE '^[^#]*NOPASSWD' /etc/sudoers 2>/dev/null; then
        warn "/etc/sudoers contains NOPASSWD directive"
    fi
fi

# Check /etc/sudoers.d/*
if [ -d /etc/sudoers.d ]; then
    for f in /etc/sudoers.d/*; do
        [ -e "$f" ] || continue
        if grep -qE '^[^#]*NOPASSWD' "$f" 2>/dev/null; then
            warn "$(basename "$f") contains NOPASSWD directive"
        fi
    done
fi

# Check sudo group membership for remoteUser
REMOTE_USER="${REMOTE_USER:-vscode}"
if id -nG "$REMOTE_USER" 2>/dev/null | grep -qw sudo; then
    echo "INFO [sudo-audit]: $REMOTE_USER is in sudo group"
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo "WARNING [sudo-audit]: $WARNINGS passwordless sudo configuration(s) detected."
    if [ "${FAIL_ON_WARNING:-false}" = "true" ]; then
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
