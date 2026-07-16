#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-compose-check
check "cli is executable" test -x /usr/local/bin/devcontainer-compose-check

reportResults
