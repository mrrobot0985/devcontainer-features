# Provider domain research (container-firewall)

Minimum domain sets for first-class agent CLIs, researched for service tags in
`services.json`. Prefer official docs; use `extraDomains` when a CLI’s auth or
update hosts are version-volatile.

**Last reviewed:** 2026-07-17 · Issues: [#81](https://github.com/mrrobot0985/devcontainer-features/issues/81), [#77](https://github.com/mrrobot0985/devcontainer-features/issues/77)

## Domain table

| Agent / provider | Service tags | Minimum domains (in registry) | Sources / notes |
| ---------------- | ------------ | ----------------------------- | --------------- |
| Claude Code / Anthropic | `anthropic`, `claude-code` | `api.anthropic.com` | Official API host; Claude Code docs require it for API + WebFetch preflight. `claude-code` also extends `github`, `npm`, `vscode`. |
| Grok Build / xAI | `xai`, `grok-build` | `api.x.ai` | Official base URL `https://api.x.ai/v1` ([xAI quickstart](https://docs.x.ai/developers/quickstart), [REST reference](https://docs.x.ai/developers/rest-api-reference)). Console/auth (`console.x.ai`, `accounts.x.ai`) are browser flows — not required for API-key agents. `grok-build` = `xai` + `github` + `npm`. |
| OpenAI Codex | `openai`, `codex` | `api.openai.com` | Primary OpenAI API host used by Codex CLI / SDK. ChatGPT subscription login may hit `chatgpt.com` / related auth hosts (volatile) — add via `extraDomains` if using browser OAuth instead of an API key. `codex` = `openai` + `github` + `npm`. |
| Gemini CLI / Google | `google`, `gemini` | See Google row below | Gemini API key traffic uses `generativelanguage.googleapis.com` ([Gemini API](https://ai.google.dev/api)). Vertex: `aiplatform.googleapis.com`. Gemini CLI / Code Assist OAuth needs extra Google APIs (official firewall list). `gemini` = `google` + `github` + `npm`. |
| OpenRouter | `openrouter` | `openrouter.ai`, `api.openrouter.ai` | OpenRouter dashboard + OpenAI-compatible API. |
| multi-ai evaluation | `multi-ai` | Union of below | Extends `claude-code`, `xai`, `openai`, `google`, `openrouter` (transitively includes github/npm/vscode/anthropic). |

### Google atomic tag (extended for Gemini CLI)

| Domain | Role |
| ------ | ---- |
| `generativelanguage.googleapis.com` | Gemini API (API key / AI Studio) |
| `aiplatform.googleapis.com` | Vertex AI / Gemini on Google Cloud |
| `oauth2.googleapis.com` | Google OAuth token endpoints |
| `cloudaicompanion.googleapis.com` | Gemini for Google Cloud / Code Assist primary API |
| `cloudcode-pa.googleapis.com` | Gemini CLI / IDE Code Assist backend |
| `serviceusage.googleapis.com` | Project/API enablement checks |
| `cloudresourcemanager.googleapis.com` | Project pickers in CLI/IDE |

Official reference: [Configure the firewall for API traffic between your IDE and Google](https://docs.cloud.google.com/gemini/docs/codeassist/set-up-gemini) (Gemini Code Assist setup).

Telemetry / optional hosts from that list **not** included by default (add via `extraDomains` if needed):

- `firebaselogging-pa.googleapis.com` (product telemetry)
- `feedback-pa.googleapis.com` (in-IDE feedback)
- `apihub.googleapis.com` (Cloud Code API Browser)
- `people.googleapis.com`, `lh3.googleusercontent.com`, `lh5.googleusercontent.com` (profile photos)
- `accounts.google.com` (interactive browser OAuth redirects)

## OpenCode / Pi / Hermes notes

These agents are **multi-provider**. Prefer a provider composite (`claude-code`, `grok-build`, `codex`, `gemini`) or `multi-ai`, then add agent-specific hosts with `extraDomains`.

| Agent | Typical provider tags | Common extras (`extraDomains`) | Notes |
| ----- | --------------------- | ------------------------------ | ----- |
| OpenCode | `multi-ai` or chosen providers + `github`/`npm` | `opencode.ai`, `api.opencode.ai`, `models.dev` | Install CDN / auto-update / model catalog hosts vary by version; disable auto-update when possible. |
| Pi | Provider set the user configures (Anthropic, OpenAI, Google, xAI, OpenRouter, …) | None fixed | Use `multi-ai` for evaluation workspaces, or only the providers you enable. Install is npm-based. |
| Hermes | `openrouter` (+ others if configured) | Messaging platform hosts only if using gateways | Common default is OpenRouter (`api.openrouter.ai`). Add Anthropic/OpenAI/etc. when those providers are selected. |

## When to use `extraDomains`

Use `extraDomains` when:

1. **Auth is browser/OAuth-heavy** — e.g. Codex ChatGPT login (`chatgpt.com`), Google account redirects (`accounts.google.com`).
2. **CLI self-update / install CDNs change** — OpenCode install/update hosts, IDE marketplace mirrors.
3. **Optional product surfaces** — telemetry you intentionally allow, docs CDNs, model catalogs (`models.dev`).
4. **Enterprise / proxy endpoints** — private gateways, Azure OpenAI custom hosts, regional Vertex endpoints beyond `aiplatform.googleapis.com`.

Example:

```json
"features": {
  "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {
    "services": "codex",
    "extraDomains": "chatgpt.com,auth.openai.com"
  }
}
```

## Tag composition map

| Composite | Extends |
| --------- | ------- |
| `claude-code` | `github`, `npm`, `anthropic`, `vscode` |
| `grok-build` | `xai`, `github`, `npm` |
| `codex` | `openai`, `github`, `npm` |
| `gemini` | `google`, `github`, `npm` |
| `multi-ai` | `claude-code`, `xai`, `openai`, `google`, `openrouter` |

`minimal` has no domains (empty baseline). Unknown tags are skipped with a warning at runtime.
