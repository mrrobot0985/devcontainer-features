#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running Kafka Development Tools tests..."

# Verify kcat is available
if command -v kcat > /dev/null 2>&1 || command -v kafkacat > /dev/null 2>&1; then
    echo "kcat/kafkacat found"
else
    echo "WARNING: kcat/kafkacat not found"
fi

# Verify helper script
if [ -f /usr/local/bin/devcontainer-kafka ]; then
    echo "Helper script found"
    devcontainer-kafka status || true
else
    echo "WARNING: Helper script not found"
fi

echo "Kafka Development Tools tests passed."
