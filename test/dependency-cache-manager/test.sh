#!/bin/bash
set -e

source dev-container-features-test-lib

check "cache manager script exists" test -x /usr/local/bin/setup-dependency-cache

reportResults
