#!/bin/bash
set -e

source dev-container-features-test-lib

check "prebuild-audit exists" test -x /usr/local/bin/prebuild-audit
check "prebuild-lifecycle-helper exists" test -x /usr/local/bin/prebuild-lifecycle-helper
check "prebuild-audit runs" bash -c "prebuild-audit --help | grep -q 'Usage:'"

reportResults
