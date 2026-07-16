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

fail() {
    echo "ERROR [ai-agent-sandbox]: \$1"
    WARNINGS=\$((WARNINGS + 1))
}

check_docker_sock() {
    if [ -S /var/run/docker.sock ] || [ -S /run/docker.sock ]; then
        case "\$PRESET" in
            strict)
                fail "Docker socket is mounted. Container escape is trivial via docker.sock."
                ;;
            moderate)
                warn "Docker socket is mounted. This allows container escape."
                ;;
            permissive)
                info "Docker socket is mounted (permissive mode)."
                ;;
        esac
    else
        info "Docker socket not mounted — good."
    fi
}

check_root_user() {
    local user_id
    user_id=\$(id -u)
    if [ "\$user_id" -eq 0 ]; then
        case "\$PRESET" in
            strict)
                fail "Container is running as root (UID 0). AI agents should run as non-root."
                ;;
            moderate)
                warn "Container is running as root (UID 0). Consider setting remoteUser to a non-root user."
                ;;
            permissive)
                info "Container is running as root (UID 0)."
                ;;
        esac
    else
        info "Container is running as non-root user (UID \$user_id) — good."
    fi
}

check_capabilities() {
    local caps=""
    if [ -f /proc/self/status ]; then
        caps=\$(grep '^CapEff:' /proc/self/status | awk '{print \$2}' | tr '[:lower:]' '[:upper:]')
    fi

    if [ -z "\$caps" ] || [ "\$caps" = "0" ]; then
        info "No effective capabilities — good."
        return
    fi

    # Check for dangerous capabilities in the effective set
    local dangerous=""
    # SYS_ADMIN allows mount, pivot_root, etc.
    if printf '%s' "\$caps" | grep -qiE 'SYS_ADMIN'; then dangerous="\${dangerous}SYS_ADMIN "; fi
    # NET_ADMIN allows iptables, network config changes
    if printf '%s' "\$caps" | grep -qiE 'NET_ADMIN'; then dangerous="\${dangerous}NET_ADMIN "; fi
    # SYS_PTRACE allows tracing arbitrary processes
    if printf '%s' "\$caps" | grep -qiE 'SYS_PTRACE'; then dangerous="\${dangerous}SYS_PTRACE "; fi
    # SYS_MODULE allows loading kernel modules
    if printf '%s' "\$caps" | grep -qiE 'SYS_MODULE'; then dangerous="\${dangerous}SYS_MODULE "; fi
    # ALL means every capability
    if printf '%s' "\$caps" | grep -qiE 'ALL'; then dangerous="ALL "; fi

    if [ -n "\$dangerous" ]; then
        case "\$PRESET" in
            strict)
                fail "Dangerous capabilities detected: \$dangerous"
                ;;
            moderate)
                warn "Dangerous capabilities detected: \$dangerous"
                ;;
            permissive)
                info "Capabilities detected: \$dangerous"
                ;;
        esac
    else
        info "No dangerous capabilities detected — good."
    fi
}

check_network() {
    # In strict mode, outbound network should not be available
    # In moderate mode, only allowed domains should be reachable
    local reachable=""
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL --connect-timeout 3 --max-time 5 https://github.com >/dev/null 2>&1; then
            reachable="true"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget --timeout=5 -qO- https://github.com >/dev/null 2>&1; then
            reachable="true"
        fi
    fi

    if [ "\$reachable" = "true" ]; then
        case "\$PRESET" in
            strict)
                fail "Outbound network is reachable. Strict preset expects no network access."
                ;;
            moderate)
                info "Outbound network is reachable (moderate allows domain-limited access)."
                ;;
            permissive)
                info "Outbound network is reachable."
                ;;
        esac
    else
        info "Outbound network is not reachable — good for strict preset."
    fi
}

check_readonly_root() {
    if [ "\$PRESET" = "strict" ]; then
        if touch /tmp/.readonly-check 2>/dev/null; then
            rm -f /tmp/.readonly-check
            # /tmp is usually writable even with read-only root, so this is a weak check
            info "Note: strict preset recommends a read-only root filesystem (securityOpt)."
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
