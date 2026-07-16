#!/bin/bash
set -e

source dev-container-features-test-lib

check "nix or installer present" bash -c 'command -v nix || test -f /nix/var/nix/profiles/default/bin/nix || true'

reportResults
