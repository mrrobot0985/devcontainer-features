#!/bin/bash
set -e

echo "Testing Redis Development Tools (with-benchmark scenario)..."

# Verify redis-cli is available
if command -v redis-cli > /dev/null 2>&1; then
    echo "redis-cli installed"
else
    echo "ERROR: redis-cli not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-redis ]; then
    echo "Helper script is executable"
    devcontainer-redis status || true
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

# Verify benchmark tool
if command -v redis-benchmark > /dev/null 2>&1; then
    echo "redis-benchmark installed"
else
    echo "WARNING: redis-benchmark not installed"
fi

# Verify checkers
if command -v redis-check-aof > /dev/null 2>&1; then
    echo "redis-check-aof installed"
else
    echo "WARNING: redis-check-aof not installed"
fi

if command -v redis-check-rdb > /dev/null 2>&1; then
    echo "redis-check-rdb installed"
else
    echo "WARNING: redis-check-rdb not installed"
fi

echo "With-benchmark scenario passed."
