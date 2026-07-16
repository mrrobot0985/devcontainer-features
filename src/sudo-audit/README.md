# Sudo Audit

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Audits the container image for passwordless `sudo` configuration and warns or
fails when `NOPASSWD` directives are detected in `/etc/sudoers` or
`/etc/sudoers.d/`.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/sudo-audit:0": {
        "failOnWarning": false
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `failOnWarning` | boolean | `false` | Fail container creation if passwordless sudo is detected |

## Checks

- `NOPASSWD` in `/etc/sudoers`
- `NOPASSWD` in any file under `/etc/sudoers.d/`
- Remote user sudo group membership (informational)

## Integration

Add to `postCreateCommand`:

```json
"postCreateCommand": "sudo-audit"
```

## Notes

- Passwordless sudo is common in devcontainer base images for convenience but
  increases compromise impact. Consider requiring a password or using
  passwordless only for specific commands.
