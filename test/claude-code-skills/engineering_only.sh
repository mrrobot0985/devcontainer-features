#!/bin/bash
set -e

# shellcheck disable=SC2034
SCENARIO_NAME=engineering_only
source "$(dirname "$0")/test.sh"
