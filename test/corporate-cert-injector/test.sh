#!/bin/bash
set -e

source dev-container-features-test-lib

check "corporate-cert-status script exists" test -x /usr/local/bin/corporate-cert-status
check "corporate-cert-status runs" bash -c "corporate-cert-status | grep -q 'Corporate Certificate Injector Status'"

reportResults
