#!/bin/bash
set -e

source dev-container-features-test-lib

check "direnv hook in bashrc" bash -c "grep -q 'direnv hook bash' /home/vscode/.bashrc"

reportResults
