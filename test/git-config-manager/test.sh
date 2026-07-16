#!/bin/bash
set -e

source dev-container-features-test-lib

check "git-config-status script exists" test -x /usr/local/bin/git-config-status
check "git-config-status runs" bash -c "git-config-status | grep -q 'Git Configuration Status'"
check "git default branch set" bash -c "git config --global init.defaultBranch | grep -q 'main'"

reportResults
