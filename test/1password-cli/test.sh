#!/bin/bash
set -e

source dev-container-features-test-lib

check "op exists" bash -c "command -v op"
check "get-secret exists" test -x /usr/local/bin/get-secret

reportResults
