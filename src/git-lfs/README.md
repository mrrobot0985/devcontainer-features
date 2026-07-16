# Git Large File Storage

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Git LFS for version controlling large files in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of git-lfs to install |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/git-lfs:1": {
        "version": "latest"
    }
}
```

## CLI

```bash
# Track a file pattern
git lfs track "*.psd"

# Track a specific file
git lfs track "model.bin"

# Check status
git lfs status

# List tracked files
git lfs ls-files

# Check feature status
devcontainer-git-lfs status
```

## Requirements

- Git must be available (install via `ghcr.io/devcontainers/features/git`)

## Notes

- Automatically runs `git lfs install --system` during feature installation
- Complements `ghcr.io/mrrobot0985/devcontainer-features/git-config-manager` and `git-hooks-manager`
- Common use cases: ML models, game assets, media files, large datasets
