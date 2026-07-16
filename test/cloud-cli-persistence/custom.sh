#!/bin/bash
set -e

source dev-container-features-test-lib

check "cloud-persist binary exists" test -x /usr/local/bin/cloud-persist
check "cloud-persist status mentions aws" bash -c "cloud-persist status | grep -q 'aws:'"
check "cloud-persist status mentions github" bash -c "cloud-persist status | grep -q 'github:'"

reportResults
