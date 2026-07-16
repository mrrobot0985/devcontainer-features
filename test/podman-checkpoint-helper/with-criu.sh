#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-podman-checkpoint

reportResults
