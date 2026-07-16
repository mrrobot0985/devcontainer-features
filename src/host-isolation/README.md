# Host Isolation Security Profile

Audits `devcontainer.json` for unsafe `runArgs`, `mounts`, and `capAdd`
configurations. Warns when `--privileged`, Docker socket binds, or excessive
capabilities are detected.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/host-isolation:0": {
        "failOnWarning": false
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `failOnWarning` | boolean | `false` | Fail container creation if unsafe configs are detected |

## Checks

- `--privileged` in `runArgs`
- Docker socket (`docker.sock`) in `mounts`
- Dangerous capabilities (`SYS_ADMIN`, `NET_ADMIN`, `ALL`) in `capAdd`

## Integration

Add to `postCreateCommand` to validate on every container start:

```json
"postCreateCommand": "host-isolation-check"
```

## Notes

- Uses `jq` for precise JSON parsing when available; falls back to grep.
- Warnings are printed to stdout so they appear in container logs.
