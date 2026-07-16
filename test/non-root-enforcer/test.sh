#!/bin/bash
set -e

source dev-container-features-test-lib

check "non-root-enforcer exists" test -x /usr/local/bin/non-root-enforcer

reportResults
