#!/bin/bash
set -e

source dev-container-features-test-lib

check "audit-log exists" test -x /usr/local/bin/audit-log

# Write a test event using the default directory
audit-log default_test --foo="bar"

check "log file in default dir" test -f /workspace/.audit-logs/audit.log
check "log contains event" bash -c "jq -e '.event == \"default_test\"' /workspace/.audit-logs/audit.log"

reportResults
