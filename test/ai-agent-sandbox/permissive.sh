#!/bin/bash
set -e

source dev-container-features-test-lib

check "sandbox audit script exists" test -x /usr/local/bin/ai-agent-sandbox-check
check "sandbox audit runs" bash -c "ai-agent-sandbox-check | grep -q 'AI Agent Sandbox'"

reportResults
