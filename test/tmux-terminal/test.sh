#!/bin/bash
set -e

source dev-container-features-test-lib

check "tmux installed" command -v tmux
check "tmux version works" bash -c "tmux -V | grep -qi tmux"
check "cli exists" command -v devcontainer-tmux

reportResults
