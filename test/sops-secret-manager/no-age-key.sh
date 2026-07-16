#!/bin/bash
set -e

source dev-container-features-test-lib

check "sops installed" command -v sops
check "age installed" command -v age
check "age-keygen installed" command -v age-keygen

reportResults
