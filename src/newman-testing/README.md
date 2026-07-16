# Postman Newman Testing

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Postman Newman CLI for running Postman API collections in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of newman to install |
| `installReporters` | boolean | `true` | Install htmlextra and junit reporters for CI/CD |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/newman-testing:1": {
        "installReporters": true
    }
}
```

## CLI

```bash
# Run a collection
newman run collection.json

# Run with environment
newman run collection.json -e environment.json

# Run with HTML report
newman run collection.json -r htmlextra

# Run with JUnit report for CI
newman run collection.json -r junit

# Check feature status
devcontainer-newman status
```

## Reporters

When `installReporters: true`, the following reporters are available:

- `htmlextra` — Enhanced HTML report with request/response details
- `junit` — JUnit XML report for CI/CD integration

## Requirements

- Node.js and npm must be available (install via `ghcr.io/devcontainers/features/node`)
- Newman is installed globally via npm

## Notes

- Complements `ghcr.io/mrrobot0985/devcontainer-features/bruno-api-testing` for Postman users
- Collections can be exported from Postman and run headlessly in CI
- Combine with `ghcr.io/mrrobot0985/devcontainer-features/act-runner` for GitHub Actions local testing
