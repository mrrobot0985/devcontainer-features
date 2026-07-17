# Jupyter and ML Development Tools

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Jupyter Lab, core Python data science libraries, and machine learning tools for interactive development in devcontainers

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `installJupyterLab` | Install JupyterLab (true) or Jupyter Notebook only (false) | boolean | true |
| `packages` | Package set: minimal (jupyter only), core (+ numpy, pandas, matplotlib), full (+ scikit-learn, scipy, seaborn) | string | core |
| `installUv` | Install uv for faster Python package management | boolean | false |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/jupyter-ml-dev:1": {}
}
```
