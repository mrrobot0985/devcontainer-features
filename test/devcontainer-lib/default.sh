#!/bin/bash
set -e

source dev-container-features-test-lib

check "library file exists" test -f /usr/local/share/devcontainer-lib/devcontainer-lib.sh
check "library is executable" test -x /usr/local/share/devcontainer-lib/devcontainer-lib.sh
check "readme exists" test -f /usr/local/share/devcontainer-lib/README.md

reportResults
