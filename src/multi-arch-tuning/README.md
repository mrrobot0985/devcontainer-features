# Multi-Architecture Tuning

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Detects container architecture and GPU availability, then sets environment
variables so that Ollama model selection, PyTorch installation, and uv Python
downloads match the host capabilities.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/multi-arch-tuning:0": {}
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ollamaModel` | string | `auto` | Ollama model tag. `auto` selects arm64-optimized on ARM hosts. |
| `pytorchIndex` | string | `auto` | PyTorch index URL. `auto` selects CPU or CUDA based on GPU availability. |

## Environment Variables

The feature sets the following variables via `/etc/profile.d`:

- `ARCH_LABEL` — `arm64` or `amd64`
- `OLLAMA_MODEL` — selected model tag
- `PYTORCH_INDEX` — PyTorch wheel index
- `TORCH_INDEX_URL` — alias for PyTorch index
- `PIP_EXTRA_INDEX_URL` — alias for PyTorch index
- `UV_PYTHON_DOWNLOADS` — architecture label for uv

## Notes

- GPU detection uses `nvidia-smi`. If not available, CPU wheels are selected.
- On Apple Silicon hosts (arm64), a smaller Ollama model is chosen by default.
