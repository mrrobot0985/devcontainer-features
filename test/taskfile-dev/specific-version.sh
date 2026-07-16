#!/bin/bash
set -e

source dev-container-features-test-lib

check "task installed at pinned version" bash -c "task --version | grep -q '3.39'"

reportResults
