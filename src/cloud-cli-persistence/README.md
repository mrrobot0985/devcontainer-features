# Cloud CLI Persistence

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Persists cloud CLI authentication state across container rebuilds by validating host credential mounts and providing helper utilities for AWS, Azure, GCP, and GitHub CLI.

## Features

- **Credential mount validation** — Checks that host credential directories are properly mounted
- **Multi-provider support** — AWS, Azure, GCP, and GitHub CLI
- **Helper utility** — `cloud-persist` command for status, validation, and configuration output
- **Mount configuration guidance** — Prints the exact `devcontainer.json` `mounts` needed

## Usage

Add the feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/cloud-cli-persistence:0": {}
  },
  "mounts": [
    "source=${localEnv:HOME}/.aws,target=/home/vscode/.aws,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.azure,target=/home/vscode/.azure,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.config/gcloud,target=/home/vscode/.config/gcloud,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.config/gh,target=/home/vscode/.config/gh,type=bind,consistency=cached"
  ]
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `providers` | string | `"aws,azure,gcp,github"` | Comma-separated list of cloud providers to configure |
| `validateMounts` | boolean | `true` | Validate that host credential directories are mounted at install time |
| `printMountConfig` | boolean | `true` | Print the required `devcontainer.json` mounts configuration after setup |

## Helper Commands

```bash
cloud-persist status      # Show mount status for all providers
cloud-persist validate    # Validate mounts and warn if missing
cloud-persist mount-config # Print devcontainer.json mount configuration
```

## Notes

- Mounts are applied at container **runtime**, not build time. The validation at install time will show "not mounted yet" during image build, which is expected.
- Run `cloud-persist validate` after container start to verify everything is working.
