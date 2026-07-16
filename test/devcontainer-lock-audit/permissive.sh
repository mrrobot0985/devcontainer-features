#!/bin/bash
set -e

source dev-container-features-test-lib

check "permissive mode warns on missing" bash -c "FAIL_ON_MISSING=false FAIL_ON_STALE=false devcontainer-lock-audit | grep -q 'Lockfile not found'"
check "permissive mode exits 0" bash -c "FAIL_ON_MISSING=false FAIL_ON_STALE=false devcontainer-lock-audit; test \$? -eq 0"

reportResults
