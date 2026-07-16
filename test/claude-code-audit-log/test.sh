#!/bin/bash
set -e

source dev-container-features-test-lib

check "audit-log exists" test -x /usr/local/bin/audit-log

check "log directory created" test -d /workspace/.audit-logs

reportResults
