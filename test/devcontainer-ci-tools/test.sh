#!/bin/bash
set -e

source dev-container-features-test-lib

check "devcontainer CLI exists" test -x /usr/local/bin/devcontainer
check "act exists" test -x /usr/local/bin/act

reportResults
