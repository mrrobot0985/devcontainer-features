#!/bin/bash
set -e

source dev-container-features-test-lib

check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init

set +e
sudo /usr/local/bin/container-firewall-init >/tmp/dryrun.log 2>&1
_init_status=$?
set -e

check "dry run exits 0" test "$_init_status" -eq 0
check "dry run prints header" grep -q "DRY RUN:" /tmp/dryrun.log
check "dry run prints resolved allowed IPv4s" grep -qE "ipset add allowed-domains [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" /tmp/dryrun.log
check "dry run states policy" grep -q "Would apply whitelist policy" /tmp/dryrun.log
check "dry run did not create ipsets" bash -c "! sudo ipset list allowed-domains >/dev/null 2>&1"

reportResults
