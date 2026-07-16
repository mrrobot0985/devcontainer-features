#!/bin/bash
set -e

echo "Testing Kafka Development Tools (default scenario)..."

# Verify kcat is available
if command -v kcat > /dev/null 2>&1 || command -v kafkacat > /dev/null 2>&1; then
    echo "kcat/kafkacat installed"
else
    echo "WARNING: kcat/kafkacat not installed"
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-kafka ]; then
    echo "Helper script is executable"
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

echo "Default scenario passed."
