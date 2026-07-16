#!/bin/bash
set -e

# ai-agent-sandbox install script
# Installs a runtime audit script that checks container security posture.

PRESET="__PRESET__"
FAIL_ON_WARNING="__FAILONWARNING__"
ALLOWED_DOMAINS="__ALLOWEDDOMAINS__"

cat > /usr/local/bin/ai-agent-sandbox-check <<EOF
#!/bin/bash
set -e

# ai-agent-sandbox-check — runtime security posture audit for AI agent containers
# Run during postCreateCommand to validate isolation for the chosen preset.

PRESET="$PRESET"
FAIL_ON_WARNING="$FAIL_ON_WARNING"
ALLOWED_DOMAINS="$ALLOWED_DOMAINS"
WARNINGS=0

warn() {
    echo "WARNING [ai-agent-sandbox]: \$1"
    WARNINGS=\$((WARNINGS + 1))
}

info() {
    echo "INFO [ai-agent-sandbox]: \$1"
}

fail_or_warn() {
    local msg="\$1"
    case "\$PRESET" in
        strict)
            echo "ERROR [ai-agent-sandbox]: \$msg"
            WARNINGS=\$((WARNINGS + 1))
            ;;
        moderate)
            echo "WARNING [ai-agent-sandbox]: \$msg"
            WARNINGS=\$((WARNINGS + 1))
            ;;
        permissive)
            echo "INFO [ai-agent-sandbox]: \$msg"
            ;;
    esac
}

check_docker_sock() {
    if [ -S /var/run/docker.sock ] || [ -S /run/docker.sock ]; then
        fail_or_warn "Docker socket is mounted. Container escape is trivial via docker.sock."
    else
        info "Docker socket not mounted — good."
    fi
}

check_root_user() {
    local user_id
    user_id=\$(id -u)
    if [ "\$user_id" -eq 0 ]; then
        fail_or_warn "Container is running as root (UID 0). AI agents should run as non-root."
    else
        info "Container is running as non-root user (UID \$user_id) — good."
    fi
}

check_capabilities() {
    local dangerous=""

    # Try capsh first for accurate capability decoding
    if command -v capsh >/dev/null 2>&1; then
        local capsh_out
        capsh_out=\$(capsh --print 2>/dev/null | grep '^Current' || true)
        if echo "\$capsh_out" | grep -qE 'sys_admin|net_admin|sys_ptrace|sys_module'; then
            echo "\$capsh_out" | grep -oE '[^, ]*(sys_admin|net_admin|sys_ptrace|sys_module)[^, ]*' | while read -r cap; do
                dangerous="\$dangerous\$cap "
            done
        fi
    fi

    # Fallback: test privileged operations directly
    if [ -z "\$dangerous" ]; then
        # SYS_ADMIN test: try a harmless mount
        if mount -t tmpfs none /tmp/.cap-test-sysadmin 2>/dev/null; then
            umount /tmp/.cap-test-sysadmin 2>/dev/null || true
            dangerous="\${dangerous}SYS_ADMIN "
        fi
        # NET_ADMIN test: try iptables list
        if iptables -L 2>/dev/null >/dev/null; then
            dangerous="\${dangerous}NET_ADMIN "
        fi
        # SYS_PTRACE test: check if we can attach to init (pid 1)
        if command -v strace >/dev/null 2>&1; then
            if strace -p 1 -e none 2>/dev/null | head -1 | grep -q 'strace:'; then
                : # strace worked, we have ptrace
            fi
        fi
    fi

    if [ -n "\$dangerous" ]; then
        fail_or_warn "Dangerous capabilities detected: \$dangerous"
    else
        info "No dangerous capabilities detected — good."
    fi
}

probe_domain() {
    local domain="\$1"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 3 --max-time 5 "https://\$domain" >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget --timeout=5 -qO- "https://\$domain" >/dev/null 2>&1
    else
        return 1
    fi
}

check_network() {
    local reachable=""
    local domains="github.com registry.npmjs.org pypi.org crates.io"

    for domain in \$domains; do
        if probe_domain "\$domain"; then
            reachable="true"
            break
        fi
    done

    if [ "\$reachable" = "true" ]; then
        if [ "\$PRESET" = "strict" ]; then
            fail_or_warn "Outbound network is reachable. Strict preset expects no network access."
        else
            info "Outbound network is reachable."
        fi
    else
        info "Outbound network is not reachable — good for strict preset."
    fi

    # Moderate mode: validate allowed domains are reachable
    if [ "\$PRESET" = "moderate" ] && [ -n "\$ALLOWED_DOMAINS" ]; then
        local blocked=""
        IFS=',' read -ra ALLOWED_LIST <<< "\$ALLOWED_DOMAINS"
        for domain in "\${ALLOWED_LIST[@]}"; do
            domain=\$(echo "\$domain" | xargs) # trim whitespace
            if [ -n "\$domain" ] && ! probe_domain "\$domain"; then
                blocked="\$blocked\$domain "
            fi
        done
        if [ -n "\$blocked" ]; then
            warn "Configured allowed domains are unreachable: \$blocked"
        fi
    fi
}

check_readonly_root() {
    if [ "\$PRESET" = "strict" ]; then
        # Try to write to root filesystem (not /tmp which may be tmpfs)
        if touch /.readonly-check 2>/dev/null; then
            rm -f /.readonly-check
            warn "Root filesystem is writable. Strict preset recommends a read-only root filesystem."
        else
            info "Root filesystem is read-only — good."
        fi
    fi
}

main() {
    echo "=== AI Agent Sandbox (\$PRESET preset) ==="

    check_docker_sock
    check_root_user
    check_capabilities
    check_network
    check_readonly_root

    echo ""
    if [ "\$WARNINGS" -gt 0 ]; then
        echo "WARNING [ai-agent-sandbox]: \$WARNINGS issue(s) detected."
        if [ "\$FAIL_ON_WARNING" = "true" ]; then
            echo "ERROR [ai-agent-sandbox]: failOnWarning is enabled; aborting."
            exit 1
        fi
    else
        echo "INFO [ai-agent-sandbox]: All checks passed for \$PRESET preset."
    fi
}

main
EOF

chmod +x /usr/local/bin/ai-agent-sandbox-check

echo "=== AI Agent Sandbox installed ==="
echo "Run /usr/local/bin/ai-agent-sandbox-check to audit container security posture."
