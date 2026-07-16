#!/bin/bash
set -e

source dev-container-features-test-lib

check "direnv installed at pinned version" bash -c "direnv version | grep -q '^2\.34'"

reportResults
