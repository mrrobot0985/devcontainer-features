#!/bin/bash
set -e

source dev-container-features-test-lib

check "cache base directory exists" test -d /tmp/custom-cache

reportResults
