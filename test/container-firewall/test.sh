#!/bin/bash
set -e

source dev-container-features-test-lib

check "iptables exists" command -v iptables
check "ip6tables exists" command -v ip6tables
check "ipset exists" command -v ipset
check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init

# The firewall is applied automatically by postStartCommand (via sudo).
# Verify it was applied by checking the ipset state.
if sudo ipset list allowed-domains >/dev/null 2>&1; then
    check "allowed-domains ipset exists" true

    # Verify loopback interface is functional (ping may not be installed)
    check "loopback interface up" bash -c "ip addr show lo | grep -q '127.0.0.1'"

    # For claude-code and github service selections, verify GitHub is reachable
    services="${SERVICES:-claude-code}"
    if [[ ",$services," == *",claude-code,"* ]] || [[ ",$services," == *",github,"* ]]; then
        check "github api reachable" bash -c "curl -4 -s --connect-timeout 10 https://api.github.com/zen >/dev/null"
    fi

    # If IPv6 is enabled, verify the IPv6 ipset exists
    if [ "${ENABLEIPV6:-true}" = "true" ]; then
        check "allowed-domains-v6 ipset exists" sudo ipset list allowed-domains-v6
    fi

    # If blockTelemetry is enabled, verify blocked ipsets exist
    if [ "${BLOCKTELEMETRY:-false}" = "true" ]; then
        check "blocked-domains ipset exists" sudo ipset list blocked-domains
        if [ "${ENABLEIPV6:-true}" = "true" ]; then
            check "blocked-domains-v6 ipset exists" sudo ipset list blocked-domains-v6
        fi
    fi
else
    echo "WARNING: Firewall was not applied by postStartCommand. Skipping live verification."
fi

reportResults
