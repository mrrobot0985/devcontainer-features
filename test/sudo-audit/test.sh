#!/bin/bash
set -e

source dev-container-features-test-lib

check "sudo-audit exists" test -x /usr/local/bin/sudo-audit

reportResults
