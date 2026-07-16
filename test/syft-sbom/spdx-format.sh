#!/bin/bash
set -e

source dev-container-features-test-lib

check "syft binary exists" test -x /usr/local/bin/syft
check "syft version works" bash -c "syft version | grep -qE '[0-9]+\\.'"
check "generate-sbom generates spdx" bash -c "cd /tmp && generate-sbom --format spdx-json /tmp/test-sbom.json && test -s /tmp/test-sbom.json"

reportResults
