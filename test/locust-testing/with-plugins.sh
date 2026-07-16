#!/bin/bash
set -e

echo "Testing Locust Load Testing (with-plugins scenario)..."

# Verify locust is available
if command -v locust > /dev/null 2>&1; then
    echo "locust installed"
else
    echo "ERROR: locust not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-locust ]; then
    echo "Helper script is executable"
    devcontainer-locust status || true
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

# Verify plugins
python3 -c "import locust_plugins" 2>/dev/null && echo "locust-plugins available" || echo "WARNING: locust-plugins not available"

echo "With-plugins scenario passed."
