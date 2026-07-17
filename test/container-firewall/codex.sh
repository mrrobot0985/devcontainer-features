#!/bin/bash
set -e

source dev-container-features-test-lib

check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init
check "openai domain is api.openai.com" bash -c "jq -e '.openai.domains | index(\"api.openai.com\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "codex extends openai" bash -c "jq -e '.codex.extends | index(\"openai\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "codex extends github" bash -c "jq -e '.codex.extends | index(\"github\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "codex extends npm" bash -c "jq -e '.codex.extends | index(\"npm\")' /usr/local/share/container-firewall/services.json >/dev/null"

set +e
sudo bash -c '/usr/local/bin/container-firewall-init >/tmp/codex-dryrun.log 2>&1'
_init_status=$?
set -e

check "codex dry run exits 0" test "$_init_status" -eq 0
check "no unknown service tags" bash -c "! grep -q 'Unknown service tag' /tmp/codex-dryrun.log"
check "dry run resolves allowed domains" grep -qE "ipset add allowed-domains [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" /tmp/codex-dryrun.log
check "dry run did not create ipsets" bash -c "! sudo ipset list allowed-domains >/dev/null 2>&1"

reportResults
