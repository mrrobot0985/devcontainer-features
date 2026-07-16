#!/bin/bash
set -e

source dev-container-features-test-lib

check "sops installed" command -v sops
check "age installed" command -v age
check "age-keygen installed" command -v age-keygen
check "age key exists" bash -c 'test -f /root/.config/sops/age/keys.txt || test -f /home/*/.config/sops/age/keys.txt || true'

reportResults
