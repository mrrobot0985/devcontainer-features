#!/bin/bash
set -e

source dev-container-features-test-lib

check "sandbox audit script exists" test -x /usr/local/bin/ai-agent-sandbox-check

reportResults
