#!/bin/bash
set -e

source dev-container-features-test-lib

check "sudo-audit exists" test -x /usr/local/bin/sudo-audit

# Simulate passwordless sudo (needs root to write sudoers.d)
echo "vscode ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/99-test >/dev/null
sudo chmod 440 /etc/sudoers.d/99-test
check "detects passwordless sudo" bash -c "sudo-audit | grep -q 'NOPASSWD'"
sudo rm -f /etc/sudoers.d/99-test

reportResults
