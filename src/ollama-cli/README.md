# Ollama CLI

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Ollama CLI for managing and running local AI models in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of Ollama to install |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/ollama-cli:1": {
        "version": "latest"
    }
}
```

## CLI

```bash
# Pull a model
ollama pull llama3.2

# List downloaded models
ollama list

# Run a model
ollama run llama3.2

# Remove a model
ollama rm llama3.2

# Check feature status
devcontainer-ollama status
```

## Requirements

- No additional requirements — Ollama CLI is a single binary
- Models are downloaded to `~/.ollama/models`
- GPU support requires NVIDIA Container Toolkit (use `ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit`)

## Notes

- This installs the **CLI only** for model management
- For a full Ollama server, use `docker-compose-helper` with the `ollama/ollama` image
- Combine with `ghcr.io/mrrobot0985/devcontainer-features/jupyter-ml-dev` for AI/ML development
- Combine with `ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit` for GPU-accelerated inference
