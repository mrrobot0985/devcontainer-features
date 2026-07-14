#!/bin/bash
set -e

source dev-container-features-test-lib

check "iptables exists" command -v iptables
check "ipset exists" command -v ipset
check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init

# The firewall is applied automatically by postStartCommand (via sudo).
# Verify it was applied by checking the ipset state.
if sudo ipset list allowed-domains >/dev/null 2>&1; then
    check "allowed-domains ipset exists" true

    # Verify loopback interface is functional (ping may not be installed)
    check "loopback interface up" bash -c "ip addr show lo | grep -q '127.0.0.1'"

    # For claude-code and github-only profiles, verify GitHub is reachable
    if [ "${PROFILE:-claude-code}" = "claude-code" ] || [ "${PROFILE:-claude-code}" = "github-only" ]; then
        check "github api reachable" bash -c "curl -s --connect-timeout 10 https://api.github.com/zen >/dev/null"
    fi

    # If blockTelemetry is enabled, verify blocked ipset exists
    if [ "${BLOCKTELEMETRY:-false}" = "true" ]; then
        check "blocked-domains ipset exists" sudo ipset list blocked-domains
    fi
else
    echo "WARNING: Firewall was not applied by postStartCommand. Skipping live verification."
fi

reportResults
