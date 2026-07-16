#!/bin/bash
set -e

source dev-container-features-test-lib

check "sudo-audit exists" test -x /usr/local/bin/sudo-audit

# Simulate passwordless sudo
echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-test
check "detects passwordless sudo" bash -c "sudo-audit | grep -q 'NOPASSWD'"
rm -f /etc/sudoers.d/99-test

reportResults
