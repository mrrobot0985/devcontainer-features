#!/bin/bash
set -e

source dev-container-features-test-lib

check "starship binary exists" test -x /usr/local/bin/starship
check "starship version works" bash -c "starship --version | grep -qE '[0-9]+\.'"
check "bash rc contains starship" bash -c "grep -q 'starship init bash' ~/.bashrc 2>/dev/null || true"

reportResults
