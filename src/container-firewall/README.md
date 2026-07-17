# Container Firewall

![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat-square)

Configures an iptables/ipset whitelist firewall for the container with selectable service tags and optional telemetry blocking

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `services` | Comma-separated service tags to whitelist. Use 'minimal' for an empty baseline. Composite tags (claude-code, grok-build, codex, gemini, multi-ai) expand to multiple services. | string | claude-code |
| `extraDomains` | Additional comma-separated domains to whitelist beyond the selected services. | string | "" |
| `blockTelemetry` | Block known telemetry and tracking endpoints at the network level | boolean | false |
| `policy` | whitelist drops non-matching traffic; monitor logs but does not block | string | whitelist |
| `enableIPv6` | Also apply whitelist rules to IPv6 (ip6tables) | boolean | true |
| `failIfUnprivileged` | Fail container creation when iptables cannot be used (missing CAP_NET_ADMIN). When false, emit a warning and continue as a no-op. | boolean | true |
| `dryRun` | Resolve all configured domains and print the IPs/CIDRs and policy that would be applied without modifying iptables or ipset rules. | boolean | false |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {}
}
```

## Service tags

Atomic tags whitelist a fixed domain set (and optional dynamic IP ranges). Composite
tags expand via `extends` in [`services.json`](./services.json).

### Atomic

| Tag | Domains (summary) |
| --- | ----------------- |
| `minimal` | _(none)_ |
| `github` | `github.com`, `api.github.com` (+ GitHub meta IP ranges) |
| `npm` | `registry.npmjs.org` |
| `pypi` | `pypi.org`, `files.pythonhosted.org` |
| `astral` | `astral.sh` |
| `anthropic` | `api.anthropic.com` |
| `xai` | `api.x.ai` |
| `openai` | `api.openai.com` |
| `google` | Gemini/Vertex + OAuth/Code Assist hosts (see [PROVIDER-DOMAINS.md](./PROVIDER-DOMAINS.md)) |
| `openrouter` | `openrouter.ai`, `api.openrouter.ai` |
| `vscode` | VS Code marketplace / update hosts |
| `apt` | Debian/Ubuntu package mirrors |
| `docker` | Docker Hub registry hosts |
| `huggingface` | Hugging Face hub/CDN |
| `gitlab` | GitLab.com + registry |

### Composite (agent presets)

| Tag | Extends |
| --- | ------- |
| `claude-code` | `github`, `npm`, `anthropic`, `vscode` |
| `grok-build` | `xai`, `github`, `npm` |
| `codex` | `openai`, `github`, `npm` |
| `gemini` | `google`, `github`, `npm` |
| `multi-ai` | `claude-code`, `xai`, `openai`, `google`, `openrouter` |

### Examples

Grok Build agent workspace:

```json
"features": {
  "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {
    "services": "grok-build"
  }
}
```

OpenAI Codex:

```json
"features": {
  "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {
    "services": "codex"
  }
}
```

Multi-provider evaluation:

```json
"features": {
  "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {
    "services": "multi-ai"
  }
}
```

Research notes, minimum domain sets, OpenCode/Pi/Hermes guidance, and when to use
`extraDomains` are documented in [PROVIDER-DOMAINS.md](./PROVIDER-DOMAINS.md).

## Alternatives

Related community feature: `ghcr.io/w3cj/devcontainer-features/firewall:0` (iptables whitelist sandbox, more AI-provider-flag oriented).

**Our delta:** service tags, dry-run, monitor mode, and multi-agent composite tags (`claude-code`, `grok-build`, `codex`, `gemini`, `multi-ai`).
