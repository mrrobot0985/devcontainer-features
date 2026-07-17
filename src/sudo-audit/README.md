# Sudo Audit

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Audits the container image for passwordless sudo configuration and warns or fails when NOPASSWD directives are detected

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `failOnWarning` | Fail container creation if passwordless sudo is detected | boolean | false |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/sudo-audit:1": {}
}
```
