#!/bin/bash
set -e

source dev-container-features-test-lib

check "syft binary exists" test -x /usr/local/bin/syft
check "syft version works" bash -c "syft version | grep -qE '[0-9]+\\.'"
check "generate-sbom script exists" test -x /usr/local/bin/generate-sbom

reportResults
