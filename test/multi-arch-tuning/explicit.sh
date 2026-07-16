#!/bin/bash
set -e

source dev-container-features-test-lib

check "explicit ollama model set" bash -c "multi-arch-tuning-env | grep -q 'OLLAMA_MODEL=\"llama3.1:8b\"'"
check "explicit pytorch index set" bash -c "multi-arch-tuning-env | grep -q 'PYTORCH_INDEX=\"https://download.pytorch.org/whl/cpu\"'"

reportResults
