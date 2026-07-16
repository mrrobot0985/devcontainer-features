#!/bin/bash
set -e

source dev-container-features-test-lib

check "starship binary exists" test -x /usr/local/bin/starship
check "zsh rc contains starship" bash -c "grep -q 'starship init zsh' ~/.zshrc 2>/dev/null || true"

reportResults
