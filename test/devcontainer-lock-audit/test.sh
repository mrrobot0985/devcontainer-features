#!/bin/bash
set -e

source dev-container-features-test-lib

check "devcontainer-lock-audit exists" test -x /usr/local/bin/devcontainer-lock-audit

reportResults
