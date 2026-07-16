#!/bin/bash
set -e

source dev-container-features-test-lib

check "direnv binary exists" test -x /usr/local/bin/direnv
check "direnv version works" bash -c "direnv version | grep -qE '^[0-9]+\.'"
check "direnvrc exists" test -f /home/vscode/.direnvrc

reportResults
