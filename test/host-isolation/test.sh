#!/bin/bash
set -e

source dev-container-features-test-lib

check "host-isolation-check exists" test -x /usr/local/bin/host-isolation-check

reportResults
