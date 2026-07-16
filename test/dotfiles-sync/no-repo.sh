#!/bin/bash
set -e

source dev-container-features-test-lib

check "install completes without repo" bash -c "true"

reportResults
