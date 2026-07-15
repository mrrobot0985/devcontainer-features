# Getting Started with Devcontainer Features

This guide walks a new user through adding a published feature to a dev container, rebuilding the container, and verifying that the feature applied its configuration.

## What you need

- A project with a `.devcontainer/devcontainer.json` file.
- Docker installed and running.
- The [Dev Container CLI](https://github.com/devcontainers/cli) or the VS Code Dev Containers extension.

## Step 1: Pick a feature

All published features live under the namespace:

```
ghcr.io/mrrobot0985/devcontainer-features/<id>:<version>
```

The `:0` suffix resolves the latest release within major version `0`. For example, `claude-code-backend:0` is the easiest way to stay current while avoiding breaking changes.

## Step 2: Add the feature to `devcontainer.json`

Open `.devcontainer/devcontainer.json` and add the feature to the `features` object. The example below adds the official Claude Code feature plus this repository's `claude-code-backend` feature so Claude Code talks to a local Ollama instance.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/anthropics/devcontainer-features/claude-code:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:0": {
            "baseUrl": "http://host.docker.internal:11434",
            "authToken": "ollama",
            "models": "sonnet:qwen2.5"
        }
    }
}
```

`baseUrl` points at the Docker host. `authToken` is passed to the custom backend. `models` maps the `sonnet` model override to `qwen2.5`.

## Step 3: Rebuild the container

### With VS Code

Open the Command Palette and run:

```
Dev Containers: Rebuild Container
```

### With the CLI

From the project root:

```bash
devcontainer up --workspace-folder . --build-no-cache
```

`--build-no-cache` forces a fresh image build so the feature installs from scratch rather than reusing a stale layer.

## Step 4: Verify the feature worked

Open a terminal inside the container and inspect the Claude Code settings file:

```bash
cat ~/.claude/settings.json
```

You should see the backend variables set by the feature, for example:

```json
{
    "env": {
        "ANTHROPIC_BASE_URL": "http://host.docker.internal:11434",
        "ANTHROPIC_AUTH_TOKEN": "ollama",
        "ANTHROPIC_DEFAULT_SONNET_MODEL": "qwen2.5"
    }
}
```

You can also run a quick health check:

```bash
curl -sf http://host.docker.internal:11434/api/tags && echo "Ollama reachable"
```

If that succeeds, Claude Code is configured to use the custom backend.

## Next steps

- Read [Creating Your First Feature](your-first-feature.md) to learn how features are built.
- Read [Composing Multiple Features](../how-to-guides/compose-features.md) to combine several features in one container.
