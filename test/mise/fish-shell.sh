#!/bin/bash
set -e

source dev-container-features-test-lib

check "mise binary exists" test -x /usr/local/bin/mise
check "fish config directory exists" test -d ~/.config/fish/conf.d
check "fish mise activation exists" test -f ~/.config/fish/conf.d/mise.fish

reportResults
