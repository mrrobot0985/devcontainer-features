# Claude Code Privacy

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Privacy-hardened defaults for [Claude Code](https://claude.ai/code).

This feature writes documented, stable environment variables into `~/.claude/settings.json` so that Claude Code starts with telemetry, error reporting, the `/feedback` command, and automatic updates disabled by default.

## Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| `disableTelemetry` | boolean | `true` | Disable telemetry collection |
| `disableErrorReporting` | boolean | `true` | Disable automatic error reporting |
| `disableFeedback` | boolean | `true` | Disable the `/feedback` command |
| `disableUpdates` | boolean | `true` | Disable automatic updates |

## Usage

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-privacy:0": {
      "disableTelemetry": true,
      "disableErrorReporting": true,
      "disableFeedback": true,
      "disableUpdates": true
    }
  }
}
```

## Notes

- This feature modifies `~/.claude/settings.json` for the remote user.
- It is idempotent: repeated installs merge the privacy flags without removing other settings.
- Pair with `claude-code-backend` to keep all traffic on a local or self-hosted API endpoint.
