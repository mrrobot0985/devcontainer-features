#!/bin/bash
set -e

source dev-container-features-test-lib

check "multi-arch-tuning-env exists" test -x /usr/local/bin/multi-arch-tuning-env
check "profile snippet exists" test -f /etc/profile.d/multi-arch-tuning.sh

reportResults
