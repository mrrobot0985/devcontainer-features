# Claude Code Audit Log

Installs a lightweight `audit-log` script that appends structured JSON events to
a workspace file. Designed for compliance and post-incident review when used
with `claude-code-hooks`.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-audit-log:0": {}
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `logDir` | string | `/workspace/.audit-logs` | Directory for log files |

## Example

```bash
audit-log dangerous_command_blocked \
  --tool="Bash" \
  --command="rm -rf /" \
  --session="$CLAUDE_SESSION_ID"
```

Produces:

```json
{"timestamp":"2026-07-16T00:30:00Z","event":"dangerous_command_blocked","tool":"Bash","command":"rm -rf /","session":"abc123"}
```

## Notes

- Log files persist across container rebuilds because they live in the workspace.
- No rotation or export is performed; add external tooling if needed.
