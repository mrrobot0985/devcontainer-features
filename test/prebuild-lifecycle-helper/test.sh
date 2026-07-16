#!/bin/bash
set -e

source dev-container-features-test-lib

check "prebuild-lifecycle-helper exists" test -x /usr/local/bin/prebuild-lifecycle-helper

reportResults
