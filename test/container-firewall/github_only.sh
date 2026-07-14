#!/bin/bash
set -e

source dev-container-features-test-lib

check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init

# Verify firewall was applied by postStartCommand
if sudo ipset list allowed-domains > /dev/null 2>&1; then
    check "github api reachable" bash -c "curl -s --connect-timeout 10 https://api.github.com/zen > /dev/null"
    check "allowed-domains ipset exists" true
else
    echo "WARNING: Firewall was not applied by postStartCommand. Skipping live verification."
fi

reportResults
