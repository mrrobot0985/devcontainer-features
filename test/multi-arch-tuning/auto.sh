#!/bin/bash
set -e

source dev-container-features-test-lib

check "env script produces ARCH_LABEL" bash -c "multi-arch-tuning-env | grep -q 'ARCH_LABEL='"
check "env script produces OLLAMA_MODEL" bash -c "multi-arch-tuning-env | grep -q 'OLLAMA_MODEL='"
check "env script produces PYTORCH_INDEX" bash -c "multi-arch-tuning-env | grep -q 'PYTORCH_INDEX='"
check "profile sources env" grep -q "multi-arch-tuning-env" /etc/profile.d/multi-arch-tuning.sh

reportResults
