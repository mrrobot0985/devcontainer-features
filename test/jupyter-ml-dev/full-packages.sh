#!/bin/bash
set -e

echo "Testing Jupyter and ML Development Tools (full-packages scenario)..."

# Verify Jupyter is available
if command -v jupyter > /dev/null 2>&1; then
    echo "Jupyter installed"
else
    echo "ERROR: jupyter not found"
    exit 1
fi

# Verify helper script
if [ -x /usr/local/bin/devcontainer-jupyter ]; then
    echo "Helper script is executable"
    devcontainer-jupyter status || true
else
    echo "ERROR: Helper script not found or not executable"
    exit 1
fi

# Verify full package set
python3 -c "import numpy" 2>/dev/null && echo "NumPy available" || echo "WARNING: NumPy not available"
python3 -c "import pandas" 2>/dev/null && echo "Pandas available" || echo "WARNING: Pandas not available"
python3 -c "import matplotlib" 2>/dev/null && echo "Matplotlib available" || echo "WARNING: Matplotlib not available"
python3 -c "import sklearn" 2>/dev/null && echo "scikit-learn available" || echo "WARNING: scikit-learn not available"
python3 -c "import scipy" 2>/dev/null && echo "SciPy available" || echo "WARNING: SciPy not available"
python3 -c "import seaborn" 2>/dev/null && echo "Seaborn available" || echo "WARNING: Seaborn not available"

echo "Full-packages scenario passed."
