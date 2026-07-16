#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running Redis Development Tools tests..."

# Verify redis-cli is available
if command -v redis-cli > /dev/null 2>&1; then
    echo "redis-cli found"
else
    echo "ERROR: redis-cli not found"
    exit 1
fi

# Verify other tools
for tool in redis-benchmark redis-check-aof redis-check-rdb; do
    if command -v "$tool" > /dev/null 2>&1; then
        echo "$tool found"
    else
        echo "WARNING: $tool not found"
    fi
done

# Verify helper script
if [ -f /usr/local/bin/devcontainer-redis ]; then
    echo "Helper script found"
    devcontainer-redis status || true
else
    echo "WARNING: Helper script not found"
fi

echo "Redis Development Tools tests passed."
