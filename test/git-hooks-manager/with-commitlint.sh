#!/bin/bash
set -e

source dev-container-features-test-lib

check "pre-commit installed" command -v pre-commit
check "cli exists" command -v devcontainer-git-hooks-install

reportResults
