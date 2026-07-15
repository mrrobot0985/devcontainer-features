# Feature Catalog

All features are published under the namespace:

```
ghcr.io/mrrobot0985/devcontainer-features/<id>:<version>
```

Use the `:0` suffix to follow the latest release within major version `0`.

## Overview

| Feature                  | ID                         | Version | Description                                                                                 | Auto-generated README                                                                    |
| ------------------------ | -------------------------- | ------- | ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Claude Code Backend      | `claude-code-backend`      | `0.1.1` | Configures Claude Code to use a custom API backend, such as Ollama.                         | [`src/claude-code-backend/README.md`](../../src/claude-code-backend/README.md)           |
| Claude Code Privacy      | `claude-code-privacy`      | `0.1.0` | Disables telemetry, error reporting, feedback, and automatic updates for Claude Code.       | [`src/claude-code-privacy/README.md`](../../src/claude-code-privacy/README.md)           |
| Claude Code Hooks        | `claude-code-hooks`        | `0.1.0` | Installs lifecycle hooks for Claude Code telemetry, state tracking, and policy enforcement. | [`src/claude-code-hooks/README.md`](../../src/claude-code-hooks/README.md)               |
| Claude Code Rules        | `claude-code-rules`        | `0.1.2` | Installs a curated, condensed set of Claude Code behavior rules into `~/.claude/rules/`.    | [`src/claude-code-rules/README.md`](../../src/claude-code-rules/README.md)               |
| Claude Code Skills       | `claude-code-skills`       | `0.1.0` | Clones Matt Pocock's skills into `~/.claude/skills/` with selectable categories.            | [`src/claude-code-skills/README.md`](../../src/claude-code-skills/README.md)             |
| Claude Code Plugins      | `claude-code-plugins`      | `0.1.0` | Installs Claude Code plugins from marketplaces at build time.                               | [`src/claude-code-plugins/README.md`](../../src/claude-code-plugins/README.md)           |
| Container Firewall       | `container-firewall`       | `0.2.0` | Configures an iptables/ipset whitelist firewall with selectable service presets.            | [`src/container-firewall/README.md`](../../src/container-firewall/README.md)             |
| NVIDIA Container Toolkit | `nvidia-container-toolkit` | `0.1.1` | Installs and configures the NVIDIA Container Toolkit for Docker-in-Docker GPU support.      | [`src/nvidia-container-toolkit/README.md`](../../src/nvidia-container-toolkit/README.md) |

These features compose with official features. Useful companions:

- Install Claude Code itself with `ghcr.io/anthropics/devcontainer-features/claude-code:0`.
- Install the GitHub CLI with `ghcr.io/devcontainers/features/github-cli:1`.
- Install dotfiles with `ghcr.io/devcontainers/features/dotfiles:1`.

______________________________________________________________________

## `claude-code-backend`

Configures Claude Code to use a custom API backend by writing environment variables to `~/.claude/settings.json`.

### Options

| Option      | Type   | Default  | Description                                                                                             |
| ----------- | ------ | -------- | ------------------------------------------------------------------------------------------------------- |
| `baseUrl`   | string | `""`     | Custom API base URL. Auto-defaults to `http://host.docker.internal:11434` when `authToken` is `ollama`. |
| `authToken` | string | `ollama` | Auth token for the custom backend.                                                                      |
| `models`    | string | `""`     | Comma-separated model overrides in `key:value` format.                                                  |
| `logLevel`  | string | `error`  | Anthropic client log level: `error`, `warn`, `info`, or `debug`.                                        |

Model overrides with key `subagent` map to `CLAUDE_CODE_SUBAGENT_MODEL`; all other keys map to `ANTHROPIC_DEFAULT_<KEY>_MODEL`.

### Example

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/anthropics/devcontainer-features/claude-code:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:0": {
            "baseUrl": "http://ollama:11434",
            "authToken": "ollama",
            "models": "sonnet:qwen2.5"
        }
    }
}
```

______________________________________________________________________

## `claude-code-privacy`

Hardens Claude Code privacy settings by writing flags to `~/.claude/settings.json`.

### Options

| Option                  | Type    | Default | Description                        |
| ----------------------- | ------- | ------- | ---------------------------------- |
| `disableTelemetry`      | boolean | `true`  | Disable telemetry collection.      |
| `disableErrorReporting` | boolean | `true`  | Disable automatic error reporting. |
| `disableFeedback`       | boolean | `true`  | Disable the `/feedback` command.   |
| `disableUpdates`        | boolean | `true`  | Disable automatic updates.         |

### Example

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/anthropics/devcontainer-features/claude-code:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-privacy:0": {}
    }
}
```

______________________________________________________________________

## `claude-code-hooks`

Installs bash hooks for Claude Code lifecycle telemetry, state tracking, and policy enforcement. The feature is self-contained: all hook scripts are bundled directly in the feature package.

### Options

| Option                | Type    | Default | Description                                                             |
| --------------------- | ------- | ------- | ----------------------------------------------------------------------- |
| `installSessionHooks` | boolean | `true`  | Install session lifecycle hooks (start, end, setup, compact, etc.).     |
| `installAgentHooks`   | boolean | `true`  | Install agent behavior hooks (tool use, permissions, subagents, tasks). |
| `installTurnHooks`    | boolean | `true`  | Install turn-level hooks (prompt submission, stop, notifications).      |
| `installStatusLine`   | boolean | `true`  | Also install the status line hook configuration.                        |

### Example

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/anthropics/devcontainer-features/claude-code:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0": {
            "installSessionHooks": true,
            "installAgentHooks": true,
            "installTurnHooks": true,
            "installStatusLine": true
        }
    }
}
```

______________________________________________________________________

## `claude-code-rules`

Installs a curated, condensed set of Claude Code behavior rules into `~/.claude/rules/`.

Rules are organized into four declarative groups:

- **Safety (`enforceSafety`):** `human-sovereignty`, `no-attribution`, `no-secrets`
- **Workflow (`standardizeWorkflow`):** `mcp-tools-first`, `skill-discovery`, `anti-overengineering`, `conventional-commits`, `no-orphans`, `branch-strategy`
- **Git Protection (`protectGit`):** `no-git-config-override`
- **Python Tooling (`preferPythonTooling`):** `prefer-uv`, `markdown-formatting`

### Options

| Option                | Type    | Default | Description                                                                                                                            |
| --------------------- | ------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `enforceSafety`       | boolean | `true`  | Enforce safety invariants: human sovereignty, no-attribution, no-secrets.                                                              |
| `standardizeWorkflow` | boolean | `true`  | Standardize agent workflow: skill discovery, MCP tools first, anti-overengineering, conventional commits, no-orphans, branch strategy. |
| `protectGit`          | boolean | `true`  | Protect git configuration: never override git config inline.                                                                           |
| `preferPythonTooling` | boolean | `false` | Prefer Python toolchain rules: uv/uvx for Python, mdformat with frontmatter/gfm plugins.                                               |

### Example

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/anthropics/devcontainer-features/claude-code:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-rules:0": {
            "enforceSafety": true,
            "standardizeWorkflow": true,
            "protectGit": true,
            "preferPythonTooling": false
        }
    }
}
```

______________________________________________________________________

## `claude-code-skills`

Installs skills into `~/.claude/skills/` with configurable sources.

### Options

| Option                    | Type    | Default  | Description                                                               |
| ------------------------- | ------- | -------- | ------------------------------------------------------------------------- |
| `enableMattPocockSkills`  | boolean | `true`   | Clone and install Matt Pocock's skills from github.com/mattpocock/skills. |
| `mattPocockSkillsVersion` | string  | `v1.1.0` | Version/tag of mattpocock/skills to clone.                                |
| `installEngineering`      | boolean | `true`   | Install engineering skills (requires `enableMattPocockSkills`).           |
| `installProductivity`     | boolean | `true`   | Install productivity skills (requires `enableMattPocockSkills`).          |
| `installMisc`             | boolean | `false`  | Install miscellaneous skills (requires `enableMattPocockSkills`).         |
| `installPersonal`         | boolean | `false`  | Install personal skills (requires `enableMattPocockSkills`).              |
| `skipOnFailure`           | boolean | `false`  | Skip skill installation if clone fails instead of failing the build.      |

### Example

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/anthropics/devcontainer-features/claude-code:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-skills:0": {
            "enableMattPocockSkills": true,
            "mattPocockSkillsVersion": "v1.1.0",
            "installEngineering": true,
            "installProductivity": true,
            "installMisc": false,
            "installPersonal": false,
            "skipOnFailure": false
        }
    }
}
```

______________________________________________________________________

## `claude-code-plugins`

Installs Claude Code plugins from marketplaces at build time.

### Options

| Option                       | Type    | Default | Description                                                                                 |
| ---------------------------- | ------- | ------- | ------------------------------------------------------------------------------------------- |
| `enableRalphLoop`            | boolean | `false` | Install Ralph Loop plugin from the official marketplace.                                    |
| `enableObraSuperpowers`      | boolean | `false` | Install Obra Superpowers plugin from the official marketplace.                              |
| `enableWorkflows`            | boolean | `false` | Install claude-code-workflows plugin.                                                       |
| `enableEverythingClaudeCode` | boolean | `false` | Install everything-claude-code plugin.                                                      |
| `customPlugins`              | string  | `""`    | Comma-separated list of additional plugins to install as `plugin@marketplace`.              |
| `customMarketplaces`         | string  | `""`    | Comma-separated list of additional marketplaces to add as `owner/repo` or `owner/repo#ref`. |
| `skipOnFailure`              | boolean | `false` | Skip plugin installation if a plugin or marketplace fails instead of failing the build.     |

### Example

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/anthropics/devcontainer-features/claude-code:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-plugins:0": {
            "customPlugins": "my-plugin@my-marketplace",
            "customMarketplaces": "owner/repo",
            "skipOnFailure": true
        }
    }
}
```

______________________________________________________________________

## `container-firewall`

Configures an iptables/ipset whitelist firewall for the container with selectable service presets and optional telemetry blocking.

### Options

| Option           | Type    | Default       | Description                                                                                       |
| ---------------- | ------- | ------------- | ------------------------------------------------------------------------------------------------- |
| `profile`        | string  | `claude-code` | Preset bundle of allowed outbound services: `claude-code`, `github-only`, `minimal`, or `custom`. |
| `customDomains`  | string  | `""`          | Comma-separated extra domains to allow (used only with `profile=custom`).                         |
| `blockTelemetry` | boolean | `false`       | Block known telemetry and tracking endpoints at the network level.                                |
| `policy`         | string  | `whitelist`   | `whitelist` drops non-matching traffic; `monitor` logs but does not block.                        |
| `enableIPv6`     | boolean | `true`        | Also apply whitelist rules to IPv6 (ip6tables).                                                   |

The feature automatically requests `NET_ADMIN` via `capAdd` and applies the firewall at container start via `postStartCommand`. No manual `devcontainer.json` configuration is required.

### Example

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:0": {
            "profile": "claude-code",
            "blockTelemetry": true
        }
    }
}
```

______________________________________________________________________

## `nvidia-container-toolkit`

Installs and configures the NVIDIA Container Toolkit so GPU-accelerated containers can run from an inner Docker daemon (Docker-in-Docker).

### Options

| Option           | Type    | Default | Description                                                                  |
| ---------------- | ------- | ------- | ---------------------------------------------------------------------------- |
| `enable`         | boolean | `true`  | Enable the feature. When `false`, the feature is a no-op.                    |
| `defaultRuntime` | boolean | `false` | Set `nvidia` as the default container runtime for the inner dockerd.         |
| `restartDockerd` | boolean | `true`  | Automatically reload the inner dockerd after configuration if it is running. |

### Example

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/devcontainers/features/docker-in-docker:2": {},
        "ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:0": {
            "defaultRuntime": true,
            "restartDockerd": true
        }
    }
}
```
