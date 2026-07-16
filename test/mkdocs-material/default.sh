#!/bin/bash
set -e

source dev-container-features-test-lib

check "mkdocs installed" command -v mkdocs
check "cli exists" command -v devcontainer-mkdocs-serve

reportResults
