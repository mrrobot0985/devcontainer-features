#!/bin/bash
set -e

source dev-container-features-test-lib

check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init
check "services registry installed" test -f /usr/local/share/container-firewall/services.json

# multi-ai composite should declare all atomic pieces in the registry.
for tag in xai openai google openrouter anthropic claude-code multi-ai grok-build codex gemini; do
    check "registry has tag $tag" bash -c "jq -e --arg t '$tag' '.[\$t]' /usr/local/share/container-firewall/services.json >/dev/null"
done

check "multi-ai extends claude-code" bash -c "jq -e '.\"multi-ai\".extends | index(\"claude-code\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "multi-ai extends xai" bash -c "jq -e '.\"multi-ai\".extends | index(\"xai\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "multi-ai extends openai" bash -c "jq -e '.\"multi-ai\".extends | index(\"openai\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "multi-ai extends google" bash -c "jq -e '.\"multi-ai\".extends | index(\"google\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "multi-ai extends openrouter" bash -c "jq -e '.\"multi-ai\".extends | index(\"openrouter\")' /usr/local/share/container-firewall/services.json >/dev/null"

set +e
sudo bash -c '/usr/local/bin/container-firewall-init >/tmp/multi-agent-dryrun.log 2>&1'
_init_status=$?
set -e

check "multi-ai dry run exits 0" test "$_init_status" -eq 0
check "multi-ai dry run header" grep -q "DRY RUN:" /tmp/multi-agent-dryrun.log
check "no unknown service tags" bash -c "! grep -q 'Unknown service tag' /tmp/multi-agent-dryrun.log"
check "resolves api.anthropic.com" grep -q "Resolving api.anthropic.com" /tmp/multi-agent-dryrun.log
check "resolves api.x.ai" grep -q "Resolving api.x.ai" /tmp/multi-agent-dryrun.log
check "resolves api.openai.com" grep -q "Resolving api.openai.com" /tmp/multi-agent-dryrun.log
check "resolves generativelanguage.googleapis.com" grep -q "Resolving generativelanguage.googleapis.com" /tmp/multi-agent-dryrun.log
check "resolves api.openrouter.ai" grep -q "Resolving api.openrouter.ai" /tmp/multi-agent-dryrun.log
check "dry run did not create ipsets" bash -c "! sudo ipset list allowed-domains >/dev/null 2>&1"

reportResults
