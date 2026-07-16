# Container Security Scan

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Installs Trivy and provides a `container-security-scan` helper that runs a
vulnerability scan on the container image or filesystem during
`postCreateCommand`.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/container-security-scan:0": {
        "severity": "HIGH,CRITICAL",
        "exitCode": 0
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `severity` | string | `HIGH,CRITICAL` | Severity levels to report |
| `exitCode` | number | `0` | Exit code when vulnerabilities found (0 = report only) |

## Commands

- `container-security-scan` — scan the current container filesystem
- `container-security-scan <image>` — scan a specific image

## Integration

Add to `postCreateCommand`:

```json
"postCreateCommand": "container-security-scan"
```

## Notes

- Trivy is installed via the official apt repository or curl fallback.
- Scan results are printed to stdout; parse with `--format json` if needed.
- Use `exitCode: 1` to fail container creation when CVEs are detected.
