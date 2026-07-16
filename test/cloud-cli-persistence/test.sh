#!/bin/bash
set -e

source dev-container-features-test-lib

check "cloud-persist binary exists" test -x /usr/local/bin/cloud-persist
check "cloud-persist status runs" bash -c "cloud-persist status | grep -q 'Cloud CLI persistence status'"
check "cloud-persist mount-config runs" bash -c "cloud-persist mount-config | grep -q 'devcontainer.json'"

reportResults
