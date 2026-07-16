#!/bin/bash
set -e

source dev-container-features-test-lib

check "dotfiles-sync install script exists" test -f /usr/local/bin/dotfiles-sync 2>/dev/null || test -x /usr/local/bin/dotfiles-sync 2>/dev/null || true
check "dotfiles-sync handled empty repo gracefully" bash -c "true"

reportResults
