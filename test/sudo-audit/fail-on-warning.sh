#!/bin/bash
set -e

source dev-container-features-test-lib

check "sudo-audit exists" test -x /usr/local/bin/sudo-audit

# Simulate passwordless sudo and verify failure
echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-test
check "fails when passwordless sudo detected" bash -c "FAIL_ON_WARNING=true sudo-audit; test \$? -eq 1"
rm -f /etc/sudoers.d/99-test

reportResults
