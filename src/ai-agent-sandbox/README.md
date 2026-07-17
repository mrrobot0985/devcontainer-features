# AI Agent Sandbox

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Tiered security isolation presets for AI coding agent devcontainers. Audits container runtime posture and warns or fails when excessive privileges are detected.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `preset` | Security preset: strict (no network, no root, no docker.sock), moderate (safe defaults), or permissive (audit-only) | string | moderate |
| `failOnWarning` | Fail container creation if the audit detects violations for the chosen preset | boolean | false |
| `allowedDomains` | Comma-separated list of allowed outbound domains for moderate preset | string | github.com,registry.npmjs.org,pypi.org,crates.io |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/ai-agent-sandbox:1": {}
}
```
