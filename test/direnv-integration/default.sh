#!/bin/bash
set -e

source dev-container-features-test-lib

check "direnv binary exists" bash -c "which direnv >/dev/null 2>&1 || command -v direnv >/dev/null 2>&1"
check "direnv version works" bash -c "direnv version >/dev/null 2>&1"
check "direnvrc exists" test -f /home/vscode/.direnvrc

reportResults
