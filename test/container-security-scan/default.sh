#!/bin/bash
set -e

source dev-container-features-test-lib

check "scan script exists" test -x /usr/local/bin/container-security-scan
check "trivy is installed" bash -c "command -v trivy"

reportResults
