# Devcontainer Lock Audit

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

CI gate that enforces `.devcontainer-lock.json` presence and validates that
pinned feature versions match the current `devcontainer.json` configuration.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/devcontainer-lock-audit:0": {}
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `failOnMissing` | boolean | `true` | Fail if lockfile is missing |
| `failOnStale` | boolean | `true` | Fail if lockfile is older than devcontainer.json |

## Checks

- Lockfile exists at `.devcontainer/devcontainer-lock.json`
- Lockfile contains a `features` key with valid JSON
- Lockfile is not older than `devcontainer.json`
- Every feature referenced in `devcontainer.json` has a corresponding lock entry

## Integration

Add to `postCreateCommand` or CI workflow:

```json
"postCreateCommand": "devcontainer-lock-audit"
```

## Notes

- Requires `jq` for full validation; basic checks work without it.
- Use `--frozen-lockfile` with `devcontainer build` to enforce lockfile matching.
