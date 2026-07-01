# Claude Code Backend

Configures Claude Code to use a custom API backend such as Ollama, LiteLLM, or any OpenAI-compatible endpoint.

## Options

| Option      | Type   | Default                               | Description                                                   |
| ----------- | ------ | ------------------------------------- | ------------------------------------------------------------- |
| `baseUrl`   | string | `"http://host.docker.internal:11434"` | Custom API base URL                                           |
| `authToken` | string | `"ollama"`                            | Auth token for the custom backend                             |
| `models`    | string | `""`                                  | Comma-separated model overrides in `key:value` format         |
| `logLevel`  | string | `"error"`                             | Anthropic client log level (`error`, `warn`, `info`, `debug`) |

## Model Overrides

Use the `models` option to override model identifiers used by Claude Code. Entries are comma-separated `key:value` pairs. Keys are normalized to `ANTHROPIC_DEFAULT_<KEY>_MODEL` environment variables, except `subagent` which maps to `CLAUDE_CODE_SUBAGENT_MODEL`.

Example:

```json
"models": "haiku:claude-3-haiku,sonnet:claude-3-sonnet,subagent:claude-3-5-sonnet"
```

## Example `devcontainer.json`

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code": {},
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend": {
      "baseUrl": "http://host.docker.internal:11434",
      "authToken": "ollama",
      "models": "sonnet:llama3.1:405b,subagent:qwen2.5-coder:32b",
      "logLevel": "warn"
    }
  }
}
```

## Notes

- This feature writes to `~/.claude/settings.json` under the `env` key.
- The configured backend must be reachable from the dev container at `baseUrl`.
- Install scripts run as `root` during build; file ownership is corrected to `_REMOTE_USER`.
