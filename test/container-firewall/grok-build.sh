#!/bin/bash
set -e

source dev-container-features-test-lib

check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init
check "xai domain is api.x.ai" bash -c "jq -e '.xai.domains | index(\"api.x.ai\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "grok-build extends xai" bash -c "jq -e '.\"grok-build\".extends | index(\"xai\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "grok-build extends github" bash -c "jq -e '.\"grok-build\".extends | index(\"github\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "grok-build extends npm" bash -c "jq -e '.\"grok-build\".extends | index(\"npm\")' /usr/local/share/container-firewall/services.json >/dev/null"

set +e
sudo bash -c '/usr/local/bin/container-firewall-init >/tmp/grok-build-dryrun.log 2>&1'
_init_status=$?
set -e

check "grok-build dry run exits 0" test "$_init_status" -eq 0
check "no unknown service tags" bash -c "! grep -q 'Unknown service tag' /tmp/grok-build-dryrun.log"
check "dry run resolves allowed domains" grep -qE "ipset add allowed-domains [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" /tmp/grok-build-dryrun.log
check "dry run did not create ipsets" bash -c "! sudo ipset list allowed-domains >/dev/null 2>&1"

reportResults
