#!/bin/bash
set -e

source dev-container-features-test-lib

check "dotfiles-status script exists" test -x /usr/local/bin/dotfiles-status
check "dotfiles-status runs" bash -c "dotfiles-status | grep -q 'Dotfiles Sync Status'"

reportResults
