# Gitleaks Secret Scanner

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Gitleaks for detecting and preventing hardcoded secrets in git repositories.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of gitleaks to install |
| `installPreCommitHook` | boolean | `false` | Install gitleaks as a pre-commit hook |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/gitleaks-scan:1": {
        "installPreCommitHook": true
    }
}
```

## CLI

```bash
# Scan entire repository
gitleaks detect --source . --verbose

# Scan staged changes only
gitleaks protect --staged --verbose

# Scan with custom config
gitleaks detect --source . --config gitleaks.toml

# Check feature status
devcontainer-gitleaks status
```

## Pre-commit Hook

When `installPreCommitHook: true`, a pre-commit hook is installed in all workspace repositories that blocks commits containing potential secrets.

## Requirements

- Git must be available (install via `ghcr.io/devcontainers/features/git`)

## Notes

- Gitleaks detects passwords, API keys, tokens, and other sensitive data
- Complements `ghcr.io/mrrobot0985/devcontainer-features/container-security-scan` (Trivy) and `sonar-scanner` for defense-in-depth
- Use `ghcr.io/mrrobot0985/devcontainer-features/git-hooks-manager` for additional hook management
