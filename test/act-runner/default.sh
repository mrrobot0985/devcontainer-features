#!/bin/bash
set -e

source dev-container-features-test-lib

check "act installed" command -v act
check "cli exists" command -v devcontainer-act

reportResults
