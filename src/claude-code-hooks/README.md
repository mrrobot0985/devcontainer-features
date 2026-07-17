# Claude Code Hooks

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs bash hooks for Claude Code lifecycle telemetry, state tracking, and policy enforcement (self-contained, pinned to v0)

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `installSessionHooks` | Install session lifecycle hooks (start, end, setup, compact, etc.) | boolean | true |
| `installAgentHooks` | Install agent behavior hooks (tool use, permissions, subagents, tasks) | boolean | true |
| `installTurnHooks` | Install turn-level hooks (prompt submission, stop, notifications) | boolean | true |
| `installStatusLine` | Also install the status line hook configuration | boolean | true |
| `blockDangerousCommands` | Block dangerous Bash commands at the PreToolUse hook instead of only logging them | boolean | false |
| `dangerousCommandDenylist` | Additional comma-separated regex patterns to treat as dangerous when blockDangerousCommands is enabled | string | "" |
| `stateRetentionLimit` | Maximum number of entries to retain in per-tool/per-file state objects. Older entries are pruned automatically. | string | 100 |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:1": {}
}
```
