# Multi-Architecture Tuning

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Detects container architecture and sets environment variables for Ollama, PyTorch, and uv to avoid model/toolchain mismatches on Apple Silicon or CPU-only hosts

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `ollamaModel` | Ollama model tag to use. 'auto' selects arm64-optimized or default based on architecture. | string | auto |
| `pytorchIndex` | PyTorch package index URL. 'auto' selects cpu or cuda based on architecture and GPU availability. | string | auto |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/multi-arch-tuning:1": {}
}
```
