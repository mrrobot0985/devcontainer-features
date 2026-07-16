# x.ai CLI (Grok)

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs the x.ai CLI (Grok Build) for interacting with Grok models from the
command line.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/xai-cli:0": {
        "version": "latest"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | x.ai CLI version to install |

## Commands

- `grok` — start an interactive Grok session
- `grok -p "<prompt>"` — run Grok headlessly with a prompt
- `grok login` — authenticate with x.ai account
- `grok --version` — show CLI version

## Environment Variables

| Variable | Description |
|----------|-------------|
| `XAI_API_KEY` | Set your API key directly (format: `xai-...`) |

## Example

```bash
# In postCreateCommand or a script
export XAI_API_KEY="xai-xxxxxxxxxxxx"
grok -p "Write a hello world function in Python"
```

## Notes

- Requires a SuperGrok or X Premium Plus subscription
- Supports macOS (Intel/Apple Silicon) and Linux (x86_64/arm64)
- For headless authentication, use `--device-auth` flag with `grok login`
- The CLI supports plan mode, subagents, skills, hooks, and MCP servers
