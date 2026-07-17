# AI Agent Sandbox

![Version](https://img.shields.io/badge/version-1.0.1-blue?style=flat-square)

Tiered security isolation presets for AI coding agent devcontainers. Audits container runtime posture and warns or fails when excessive privileges are detected.

This feature is the **audit** half of the agent security floor. Pair it with [`container-firewall`](../container-firewall/README.md) for **enforcement** (iptables/ipset whitelist). See the [agent security floor](../../docs/how-to-guides/combine-features.md#agent-security-floor) recipe and issue [#78](https://github.com/mrrobot0985/devcontainer-features/issues/78).

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `preset` | Security preset: strict (no network, no root, no docker.sock), moderate (safe defaults), or permissive (audit-only) | string | moderate |
| `failOnWarning` | Fail container creation if the audit detects violations for the chosen preset | boolean | false |
| `allowedDomains` | Comma-separated list of allowed outbound domains for moderate preset | string | github.com,registry.npmjs.org,pypi.org,crates.io |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/ai-agent-sandbox:1": {}
}
```

## Recommended presets (agent-minimal / agent-studio)

| Template shape                      | Recommended `preset` | `failOnWarning`                           | Notes                                                                       |
| ----------------------------------- | -------------------- | ----------------------------------------- | --------------------------------------------------------------------------- |
| **agent-minimal** (no DinD)         | `moderate` (default) | `false` until clean, then optional `true` | Default security floor for Claude, Grok, Codex, Gemini, multi-ai, etc.      |
| **agent-studio** (with DinD)        | `moderate` (default) | **keep `false`**                          | Docker socket and elevated caps are expected; warnings must not fail create |
| Studio that only wants soft logging | `permissive`         | `false`                                   | Findings print as INFO and do not increment the warning count               |
| Hardened offline / no-network agent | `strict`             | optional `true`                           | Expects no outbound network, no docker.sock, non-root                       |

### agent-minimal

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/non-root-enforcer:1": {},
    "ghcr.io/mrrobot0985/devcontainer-features/ai-agent-sandbox:1": {
        "preset": "moderate"
    },
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {
        "services": "claude-code"
    }
}
```

Swap the firewall `services` tag for the agent (`grok-build`, `codex`, `gemini`, `multi-ai`, …) as documented in the security floor guide.

### agent-studio (Docker-in-Docker)

```json
"features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/mrrobot0985/devcontainer-features/non-root-enforcer:1": {},
    "ghcr.io/mrrobot0985/devcontainer-features/host-isolation:1": {},
    "ghcr.io/mrrobot0985/devcontainer-features/ai-agent-sandbox:1": {
        "preset": "moderate",
        "failOnWarning": false
    },
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {
        "services": "claude-code,docker"
    }
}
```

The official `docker-in-docker` feature exposes `/var/run/docker.sock` inside the container. The moderate preset **will warn** about that socket (and may warn about privileged / `SYS_ADMIN` / `NET_ADMIN` when DinD or the firewall need them). That is expected studio posture, not a misconfiguration.

**Do not set `failOnWarning: true` on DinD studios** unless you intentionally want create to fail when the socket or elevated capabilities are present.

If you want a clean “all checks passed” line while still logging findings for operators, switch the studio to `permissive`:

```json
"ghcr.io/mrrobot0985/devcontainer-features/ai-agent-sandbox:1": {
    "preset": "permissive"
}
```

## What each preset does

| Check                                                | `strict`            | `moderate`       | `permissive`    |
| ---------------------------------------------------- | ------------------- | ---------------- | --------------- |
| Docker socket present                                | ERROR (counts)      | WARNING (counts) | INFO (no count) |
| Running as root                                      | ERROR (counts)      | WARNING (counts) | INFO (no count) |
| Dangerous capabilities (`SYS_ADMIN`, `NET_ADMIN`, …) | ERROR (counts)      | WARNING (counts) | INFO (no count) |
| Outbound network reachable                           | ERROR (counts)      | INFO only        | INFO only       |
| `allowedDomains` unreachable                         | n/a                 | WARNING (counts) | n/a             |
| Read-only root FS                                    | WARNING if writable | n/a              | n/a             |

Exit status: the audit exits non-zero **only** when `failOnWarning` is `true` and at least one counted issue was found. Defaults never fail container creation.

## Pairing with container-firewall

| Role    | Feature                                                 |
| ------- | ------------------------------------------------------- |
| Audit   | `ai-agent-sandbox` — reports posture (this feature)     |
| Enforce | `container-firewall` — applies iptables/ipset whitelist |

They are complementary: sandbox does not modify network policy; firewall does not audit docker.sock or root. Use both on the agent security floor ([#78](https://github.com/mrrobot0985/devcontainer-features/issues/78), [#82](https://github.com/mrrobot0985/devcontainer-features/issues/82)).

When the firewall (or DinD) holds `NET_ADMIN`, moderate may warn about dangerous capabilities. Keep `failOnWarning: false` on that stack so create stays green while the audit remains visible in logs.

## Domain probes

Moderate mode probes each entry in `allowedDomains` over HTTPS. Probes treat **connectivity** as success and ignore HTTP status codes (for example `crates.io` returns 403 to a bare GET but is still reachable). Unreachable domains produce a warning only — they do not fail create unless `failOnWarning` is enabled.

## See also

- [How to combine features — agent security floor](../../docs/how-to-guides/combine-features.md#agent-security-floor)
- [`container-firewall`](../container-firewall/README.md)
- [`non-root-enforcer`](../non-root-enforcer/README.md)
- [`host-isolation`](../host-isolation/README.md)
