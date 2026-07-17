# Composing Multiple Features

Most real dev containers combine several features at once. This guide explains how to declare them in `devcontainer.json`, how the CLI orders their installation, and how lifecycle hooks interact.

## A composed example

The `test/_global/scenarios.json` file defines integration scenarios that install several features together. `claude_stack` composes the official Claude Code feature with Claude suite helpers and the firewall. `agent_security_floor` composes the agent-minimal security floor (`non-root-enforcer`, `ai-agent-sandbox` moderate, `container-firewall` with `multi-ai` dry-run) and is the CI coverage for that floor (see [How to Combine Features](combine-features.md#agent-minimal)).

`claude_stack` example:

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/devcontainers/features/node:1": {
            "version": "20"
        },
        "ghcr.io/anthropics/devcontainer-features/claude-code:1": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-privacy:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:0": {
            "baseUrl": "http://ollama:11434",
            "models": "sonnet:qwen2.5"
        },
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-skills:0": {
            "skipOnFailure": true
        },
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-plugins:0": {
            "skipOnFailure": true
        },
        "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:0": {
            "blockTelemetry": true
        }
    }
}
```

## Feature ordering

The devcontainer CLI installs features in an order that satisfies dependencies and hints. You can influence ordering in three ways:

### 1. `installsAfter`

In `devcontainer-feature.json`, `installsAfter` lists features that should be installed before this one when both are present. It is a hint, not a hard dependency.

```json
"installsAfter": [
    "ghcr.io/devcontainers/features/common-utils",
    "ghcr.io/anthropics/devcontainer-features/claude-code"
]
```

For example, `claude-code-hooks` installs after `claude-code` so the Claude Code directory already exists before hooks are copied.

### 2. `dependsOn`

Use `dependsOn` when a feature requires another feature to function correctly. The CLI installs dependencies first. Unlike `installsAfter`, a missing `dependsOn` feature can cause an error rather than silently skipping ordering.

```jsonc
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {
        "defaultRuntime": true
    }
}
```

In practice, features that wrap another tool (for example, the NVIDIA feature paired with Docker-in-Docker) should also document the companion feature in their example usage.

### 3. `overrideFeatureInstallOrder`

For total control, add `overrideFeatureInstallOrder` to `devcontainer.json`. The CLI installs the listed features first, in the order given, then installs everything else:

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/devcontainers/features/common-utils:2": {},
        "ghcr.io/anthropics/devcontainer-features/claude-code:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:0": {}
    },
    "overrideFeatureInstallOrder": [
        "ghcr.io/devcontainers/features/common-utils",
        "ghcr.io/anthropics/devcontainer-features/claude-code"
    ]
}
```

Use this only when the default ordering causes problems, because it makes the configuration harder to maintain.

## Lifecycle hooks

Feature install scripts run during the image build. After the container starts, lifecycle hooks run in the following order:

| Hook                   | When it runs                                 | Typical use                                   |
| ---------------------- | -------------------------------------------- | --------------------------------------------- |
| `initializeCommand`    | Before the container is created, on the host | Clone repos, create host directories          |
| `onCreateCommand`      | Once, after the container is created         | One-time setup that needs a running container |
| `updateContentCommand` | When content is updated                      | Re-run after branch changes                   |
| `postCreateCommand`    | After `onCreateCommand`                      | Start background services                     |
| `postStartCommand`     | Every time the container starts              | Apply runtime configuration                   |
| `postAttachCommand`    | Every time a user attaches                   | Shell-specific setup                          |

### Feature-declared hooks

A feature can declare its own lifecycle hooks in `devcontainer-feature.json`. The `container-firewall` feature does this to apply firewall rules after the container starts:

```json
{
    "capAdd": ["NET_ADMIN"],
    "postStartCommand": "sudo /usr/local/bin/container-firewall-init"
}
```

The CLI merges `postStartCommand` from all features and the top-level `devcontainer.json`. When multiple features declare the same hook, the CLI runs them in installation order.

### Best practices for composition

- Keep features focused. A feature should do one thing.

- Use `installsAfter` rather than `overrideFeatureInstallOrder` when possible.

- Avoid duplicating work across features. For example, let `claude-code-privacy`, `claude-code-backend`, and `claude-code-hooks` all write to `~/.claude/settings.json` through merge helpers rather than overwriting the file.

- Test composed stacks with the global scenarios:

  ```bash
  devcontainer features test --global-scenarios-only .
  ```

## See also

- [Feature Installation Lifecycle](../explanation/feature-lifecycle.md)
- [Debugging Feature Installation Failures](debug-install-failures.md)
