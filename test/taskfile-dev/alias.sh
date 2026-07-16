#!/bin/bash
set -e

source dev-container-features-test-lib

check "t alias in bashrc" bash -c "grep -q \"alias t='task'\" /home/vscode/.bashrc"
check "t alias in zshrc" bash -c "grep -q \"alias t='task'\" /home/vscode/.zshrc"

reportResults
