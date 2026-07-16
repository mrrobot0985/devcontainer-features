#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-compose-check
check "helper script exists" test -x /usr/local/share/docker-compose-helper/compose-helper.sh

reportResults
