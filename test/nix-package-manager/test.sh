#!/bin/bash
set -e

source dev-container-features-test-lib

check "nix installer script downloaded" test -f /usr/local/share/nix-package-manager/install-nix.sh || true
check "nix or installer present" bash -c 'command -v nix || test -f /nix/var/nix/profiles/default/bin/nix || true'

reportResults
