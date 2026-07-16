#!/bin/bash
set -e

source dev-container-features-test-lib

check "cosign binary exists" test -x /usr/local/bin/cosign
check "cosign version works" bash -c "cosign version | grep -q 'GitVersion'"
check "cosign-verify-image script exists" test -x /usr/local/bin/cosign-verify-image

reportResults
