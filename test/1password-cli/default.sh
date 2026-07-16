#!/bin/bash
set -e

source dev-container-features-test-lib

check "op binary exists" test -x /usr/local/bin/op
check "get-secret helper exists" test -x /usr/local/bin/get-secret
check "get-secret shows usage without args" bash -c "get-secret 2>&1 | grep -q 'Usage: get-secret'"

reportResults
