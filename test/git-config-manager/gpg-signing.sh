#!/bin/bash
set -e

source dev-container-features-test-lib

check "git-config-status script exists" test -x /usr/local/bin/git-config-status
check "git default branch is trunk" bash -c "git config --global init.defaultBranch | grep -q 'trunk'"
check "git gpg sign enabled" bash -c "git config --global commit.gpgsign | grep -q 'true'"
check "git signing key set" bash -c "git config --global user.signingkey | grep -q 'TESTKEY123'"

reportResults
