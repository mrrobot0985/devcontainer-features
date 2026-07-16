# Jupyter and ML Development Tools

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Jupyter Lab, core Python data science libraries, and machine learning tools for interactive development in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `installJupyterLab` | boolean | `true` | Install JupyterLab (true) or Jupyter Notebook only (false) |
| `packages` | string | `core` | Package set: minimal, core (+ numpy, pandas, matplotlib), full (+ scikit-learn, scipy, seaborn) |
| `installUv` | boolean | `false` | Install uv for faster Python package management |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/jupyter-ml-dev:1": {
        "packages": "full",
        "installJupyterLab": true,
        "installUv": true
    }
}
```

## Package Sets

| Set | Packages |
|-----|----------|
| `minimal` | Jupyter only |
| `core` | + NumPy, Pandas, Matplotlib |
| `full` | + scikit-learn, SciPy, Seaborn |

## CLI

```bash
# Start JupyterLab
jupyter lab

# Start Jupyter Notebook
jupyter notebook

# Check installed versions
devcontainer-jupyter status

# List kernels
devcontainer-jupyter list
```

## Requirements

- Python 3 must be available (install via `ghcr.io/devcontainers/features/python`)
- pip is used for package installation
- For GPU-accelerated ML, combine with `ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit`

## Notes

- Packages are installed globally via pip for all users
- `uv` can be installed for faster package resolution in subsequent installs
- Combine with `ghcr.io/mrrobot0985/devcontainer-features/dependency-cache-manager` for persistent pip caches
