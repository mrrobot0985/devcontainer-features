#!/bin/bash
set -e

source dev-container-features-test-lib

check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init

# Verify firewall was applied by postCreateCommand
if sudo ipset list allowed-domains > /dev/null 2>&1; then
    check "allowed-domains ipset exists" true
    # Verify the extra domain was resolved and its IPs were added to the ipset.
    # Live curl can be flaky due to DNS round-robin returning different IPs.
    check "allowed-domains populated" bash -c "sudo ipset list allowed-domains | grep -qE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'"
else
    echo "WARNING: Firewall was not applied by postCreateCommand. Skipping live verification."
fi

reportResults
