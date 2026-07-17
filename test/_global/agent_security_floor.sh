#!/bin/bash
set -e

# Global composition: agent-minimal security floor
# (non-root-enforcer + ai-agent-sandbox moderate + container-firewall multi-ai dry-run).
# CI covers this stack via test-global; see docs/how-to-guides/combine-features.md.

# shellcheck source=/dev/null
source dev-container-features-test-lib

# --- Binaries / helpers ---
check "non-root-enforcer exists" test -x /usr/local/bin/non-root-enforcer
check "ai-agent-sandbox-check exists" test -x /usr/local/bin/ai-agent-sandbox-check
check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init

# --- Configs present ---
check "non-root-enforcer config present" test -f /usr/local/etc/non-root-enforcer-fail-on-warning
check "firewall services registry present" test -f /usr/local/share/container-firewall/services.json
check "registry has multi-ai tag" bash -c "jq -e '.\"multi-ai\"' /usr/local/share/container-firewall/services.json >/dev/null"
check "multi-ai extends claude-code" bash -c "jq -e '.\"multi-ai\".extends | index(\"claude-code\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "multi-ai extends xai" bash -c "jq -e '.\"multi-ai\".extends | index(\"xai\")' /usr/local/share/container-firewall/services.json >/dev/null"

# --- Sandbox: moderate + failOnWarning false must not fail create / check ---
set +e
/usr/local/bin/ai-agent-sandbox-check >/tmp/sandbox-check.log 2>&1
_sandbox_status=$?
set -e

check "sandbox check exits 0 (failOnWarning false)" test "$_sandbox_status" -eq 0
check "sandbox reports moderate preset" grep -q 'moderate' /tmp/sandbox-check.log
check "sandbox prints AI Agent Sandbox banner" grep -q 'AI Agent Sandbox' /tmp/sandbox-check.log

# --- Firewall dry-run (avoids CAP_NET_ADMIN requirement in CI) ---
set +e
sudo bash -c '/usr/local/bin/container-firewall-init >/tmp/firewall-dryrun.log 2>&1'
_fw_status=$?
set -e

check "firewall dry-run exits 0" test "$_fw_status" -eq 0
check "firewall dry-run header" grep -q 'DRY RUN:' /tmp/firewall-dryrun.log
check "firewall dry-run complete" grep -q 'DRY RUN complete' /tmp/firewall-dryrun.log
check "no unknown service tags" bash -c "! grep -q 'Unknown service tag' /tmp/firewall-dryrun.log"
check "dry-run resolves multi-ai domains" bash -c "grep -qE 'Resolving (api\\.anthropic\\.com|api\\.x\\.ai|api\\.openai\\.com)' /tmp/firewall-dryrun.log"
check "dry-run did not create ipsets" bash -c "! sudo ipset list allowed-domains >/dev/null 2>&1"

# --- Non-root enforcer helper is runnable ---
set +e
/usr/local/bin/non-root-enforcer >/tmp/non-root-enforcer.log 2>&1
_nre_status=$?
set -e
check "non-root-enforcer exits 0" test "$_nre_status" -eq 0

reportResults
