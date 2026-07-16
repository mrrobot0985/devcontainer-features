#!/bin/bash
set -e

source dev-container-features-test-lib

check "corporate-cert-status script exists" test -x /usr/local/bin/corporate-cert-status
check "node profile exists" test -f /etc/profile.d/corporate-certs-node.sh

reportResults
