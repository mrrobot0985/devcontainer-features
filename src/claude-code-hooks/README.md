# Claude Code Hooks

Installs bash hooks for Claude Code lifecycle telemetry, state tracking, and policy enforcement.

This feature is self-contained — all hook scripts are bundled directly in the feature package, pinned to v0 of the upstream `mrrobot0985/claude-code-hooks` repository. No external clone is required at build time.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `installStatusLine` | Also install the status line hook configuration | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0": {}
}
```

To disable the status line hook:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0": {
        "installStatusLine": false
    }
}
```
