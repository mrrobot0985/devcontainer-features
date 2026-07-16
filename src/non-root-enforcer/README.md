# Non-Root Enforcer

Audits `devcontainer.json` for `remoteUser: root` or missing `remoteUser`, and
warns or fails because Claude Code and other AI agents require a non-root user
to enforce permission dialogs.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/non-root-enforcer:0": {
        "failOnWarning": false
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `failOnWarning` | boolean | `false` | Fail if remoteUser is root or missing |

## Checks

- `remoteUser` is present in `devcontainer.json`
- `remoteUser` is not `root`

## Integration

Add to `postCreateCommand`:

```json
"postCreateCommand": "non-root-enforcer"
```

## Notes

- Claude Code rejects `--dangerously-skip-permissions` when run as root.
- Most devcontainer base images create a `vscode` user automatically.
