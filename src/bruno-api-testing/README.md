# Bruno API Testing

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Installs Bruno CLI for local-first, Git-friendly API testing and collection management in devcontainers.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/bruno-api-testing:0": {
        "version": "latest",
        "globalInstall": true
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of @usebruno/cli to install |
| `globalInstall` | boolean | `true` | Install Bruno CLI globally via npm |

## Why Bruno?

- **Local-first:** Collections stored as `.bru` files in your repo — no cloud sync
- **Git-friendly:** API requests live alongside code, versioned with Git
- **Privacy:** No account or cloud required
- **CLI-first:** `bru run` for CI/CD integration

## CLI

```bash
# Initialize a new collection
bru init

# Run all requests in collection
bru run

# Run with specific environment
bru run --env local

# Check status
devcontainer-bruno status
```

## Collection Format

Bruno stores collections as plain text `.bru` files:

```
collections/
  get-users.bru
  create-user.bru
  environments/
    local.bru
    production.bru
```

## Requirements

- Node.js and npm must be available (install via `ghcr.io/devcontainers/features/node`)

## Notes

- Bruno collections are stored in the filesystem, making them ideal for devcontainers
- Combine with `git-hooks-manager` to validate API collections on commit
- Use `sops-secret-manager` to encrypt environment files with secrets
