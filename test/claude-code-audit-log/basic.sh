#!/bin/bash
set -e

source dev-container-features-test-lib

check "audit-log exists" test -x /usr/local/bin/audit-log

# Write a test event
audit-log test_event --source="basic-test" --detail="hello"

check "log file created" test -f /tmp/test-audit-logs/audit.log
check "log contains valid JSON" bash -c "jq -e '.event == \"test_event\"' /tmp/test-audit-logs/audit.log"
check "log has timestamp" bash -c "jq -e 'has(\"timestamp\")' /tmp/test-audit-logs/audit.log"
check "log has custom fields" bash -c "jq -e '.source == \"basic-test\" and .detail == \"hello\"' /tmp/test-audit-logs/audit.log"

reportResults
