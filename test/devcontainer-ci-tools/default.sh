#!/bin/bash
set -e

source dev-container-features-test-lib

check "devcontainer CLI exists" test -x /usr/local/bin/devcontainer
check "devcontainer CLI is executable" bash -c "devcontainer --version | grep -qE '[0-9]+\.'"
check "act exists" test -x /usr/local/bin/act

reportResults
