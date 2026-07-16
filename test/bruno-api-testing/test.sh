#!/bin/bash
set -e

source dev-container-features-test-lib

check "bru installed" command -v bru || true
check "cli exists" command -v devcontainer-bruno

reportResults
