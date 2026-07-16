#!/bin/bash
set -e

source dev-container-features-test-lib

check "mise binary exists" test -x /usr/local/bin/mise
check "mise version works" bash -c "mise --version | grep -qE '[0-9]+\.'"
check "bash rc contains mise activation" bash -c "grep -q 'mise activate bash' ~/.bashrc 2>/dev/null || true"

reportResults
