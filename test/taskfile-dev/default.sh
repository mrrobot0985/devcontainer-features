#!/bin/bash
set -e

source dev-container-features-test-lib

check "task binary exists" test -x /usr/local/bin/task
check "task version works" bash -c "task --version | grep -qE '^task\s+version' || task --version | grep -qE 'v[0-9]+\.'"

reportResults
