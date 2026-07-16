# Playwright Testing

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Playwright for browser automation and end-to-end testing in devcontainers with configurable browser binaries and system dependencies.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of @playwright/test to install |
| `browsers` | string | `chromium` | Comma-separated browsers: chromium, firefox, webkit, or all |
| `installDeps` | boolean | `true` | Install system dependencies required by browsers |
| `globalInstall` | boolean | `false` | Install globally via npm instead of in workspace |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/playwright-testing:1": {
        "browsers": "chromium,firefox",
        "installDeps": true
    }
}
```

Install all browsers with system dependencies:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/playwright-testing:1": {
        "browsers": "all",
        "installDeps": true,
        "globalInstall": true
    }
}
```

## CLI

```bash
# Run tests
npx playwright test

# Record interactions
devcontainer-playwright codegen https://example.com

# Show HTML report
devcontainer-playwright report

# Check status
devcontainer-playwright status
```

## Requirements

- Node.js and npm must be available (install via `ghcr.io/devcontainers/features/node`)
- System dependencies are installed automatically when `installDeps: true`
- For headed mode, combine with `ghcr.io/devcontainers/features/desktop-lite` for VNC access

## Notes

- Browser binaries are installed to `~/.cache/ms-playwright` (or global npm cache)
- System dependencies include fonts, graphics libraries, and codec packages
- The `chromium` browser is recommended for CI environments (smallest footprint)
- Use `globalInstall: true` for shared Playwright across multiple projects
