# Claude Code Hooks

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Installs bash hooks for Claude Code lifecycle telemetry, state tracking, and policy enforcement.

This feature is self-contained — all hook scripts are bundled directly in the feature package, pinned to v0 of the upstream `mrrobot0985/claude-code-hooks` repository. No external clone is required at build time.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `installSessionHooks` | Install session lifecycle hooks (start, end, setup, compact, etc.) | boolean | true |
| `installAgentHooks` | Install agent behavior hooks (tool use, permissions, subagents, tasks) | boolean | true |
| `installTurnHooks` | Install turn-level hooks (prompt submission, stop, notifications) | boolean | true |
| `installStatusLine` | Also install the status line hook configuration | boolean | true |
| `blockDangerousCommands` | Block dangerous Bash commands at the PreToolUse hook instead of only logging them | boolean | false |
| `dangerousCommandDenylist` | Additional comma-separated regex patterns to treat as dangerous when blockDangerousCommands is enabled | string | "" |
| `stateRetentionLimit` | Maximum number of entries to retain in per-tool/per-file state objects | number | 100 |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0": {}
}
```

To disable specific hook categories:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0": {
        "installSessionHooks": false,
        "installAgentHooks": true,
        "installTurnHooks": true,
        "installStatusLine": false
    }
}
```

To install only session hooks:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0": {
        "installSessionHooks": true,
        "installAgentHooks": false,
        "installTurnHooks": false,
        "installStatusLine": true
    }
}
```

To enable dangerous-command blocking with a custom denylist:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0": {
        "installAgentHooks": true,
        "blockDangerousCommands": true,
        "dangerousCommandDenylist": "curl[[:space:]]+https://evil\\.com"
    }
}
```
