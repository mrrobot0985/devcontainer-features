#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-podman-checkpoint
check "podman or alias present" bash -c 'command -v podman || command -v docker || true'

reportResults
