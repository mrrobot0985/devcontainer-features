#!/bin/bash
set -e

source dev-container-features-test-lib

check "container-security-scan exists" test -x /usr/local/bin/container-security-scan

reportResults
