#!/bin/bash
set -e

# Global composition: static agent-studio floor without DinD.
# non-root-enforcer + ai-agent-sandbox + host-isolation + container-firewall (docker tag, dry-run).
# Nested DinD is proven in templates, not features CI.

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "non-root-enforcer exists" test -x /usr/local/bin/non-root-enforcer
check "ai-agent-sandbox-check exists" test -x /usr/local/bin/ai-agent-sandbox-check
check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init
check "host-isolation-check exists" test -x /usr/local/bin/host-isolation-check

check "firewall services registry present" test -f /usr/local/share/container-firewall/services.json
check "registry has docker tag" bash -c "jq -e '.docker' /usr/local/share/container-firewall/services.json >/dev/null"

set +e
/usr/local/bin/ai-agent-sandbox-check >/tmp/sandbox-studio.log 2>&1
_sandbox_status=$?
set -e
check "sandbox check exits 0" test "$_sandbox_status" -eq 0

set +e
sudo bash -c '/usr/local/bin/container-firewall-init >/tmp/firewall-studio-dryrun.log 2>&1'
_fw_status=$?
set -e
check "firewall dry-run exits 0" test "$_fw_status" -eq 0
check "firewall dry-run header" grep -q 'DRY RUN:' /tmp/firewall-studio-dryrun.log
check "dry-run did not create ipsets" bash -c "! sudo ipset list allowed-domains >/dev/null 2>&1"

set +e
/usr/local/bin/host-isolation-check >/tmp/host-isolation.log 2>&1
_hi_status=$?
set -e
check "host-isolation-check exits 0" test "$_hi_status" -eq 0

set +e
/usr/local/bin/non-root-enforcer >/tmp/non-root-studio.log 2>&1
_nre_status=$?
set -e
check "non-root-enforcer exits 0" test "$_nre_status" -eq 0

reportResults
