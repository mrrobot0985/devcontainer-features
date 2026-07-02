# Dev Container Features

![CI](https://github.com/mrrobot0985/devcontainer-features/actions/workflows/test.yaml/badge.svg)
![Release](https://github.com/mrrobot0985/devcontainer-features/actions/workflows/release.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A focused collection of custom [Dev Container Features](https://containers.dev/implementors/features/) that extend Claude Code with configuration layers not available in official packages.

## Namespace

Published to GitHub Container Registry:

```
ghcr.io/mrrobot0985/devcontainer-features/<id>:<version>
```

## Features

| Feature               | Description                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------- |
| `claude-code-backend` | Configures Claude Code to use a custom API backend, such as Ollama.                         |
| `claude-code-privacy` | Disables telemetry, error reporting, feedback, and automatic updates for Claude Code.       |
| `claude-code-hooks`   | Installs lifecycle hooks for Claude Code telemetry, state tracking, and policy enforcement. |

These features are designed to be composed with official features:

- Install Claude Code itself with the official feature: `ghcr.io/anthropics/devcontainer-features/claude-code`
- Install the GitHub CLI with: `ghcr.io/devcontainers/features/github-cli`
- Install dotfiles with: `ghcr.io/devcontainers/features/dotfiles`

### `claude-code-backend`

Configures Claude Code to use a custom API backend by writing environment variables to `~/.claude/settings.local.json`.

**Options:**

| Option      | Type   | Default                             | Description                                                    |
| ----------- | ------ | ----------------------------------- | -------------------------------------------------------------- |
| `baseUrl`   | string | `http://host.docker.internal:11434` | Custom API base URL.                                           |
| `authToken` | string | `ollama`                            | Auth token for the custom backend.                             |
| `models`    | string | `""`                                | Comma-separated model overrides in `key:value` format.         |
| `logLevel`  | string | `error`                             | Anthropic client log level (`error`, `warn`, `info`, `debug`). |

Model overrides with key `subagent` map to `CLAUDE_CODE_SUBAGENT_MODEL`; all other keys map to `ANTHROPIC_DEFAULT_<KEY>_MODEL`.

**Example:**

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

### `claude-code-privacy`

Hardens Claude Code privacy settings by writing flags to `~/.claude/settings.local.json`.

**Options:**

| Option                  | Type    | Default | Description                        |
| ----------------------- | ------- | ------- | ---------------------------------- |
| `disableTelemetry`      | boolean | `true`  | Disable telemetry collection.      |
| `disableErrorReporting` | boolean | `true`  | Disable automatic error reporting. |
| `disableFeedback`       | boolean | `true`  | Disable the `/feedback` command.   |
| `disableUpdates`        | boolean | `true`  | Disable automatic updates.         |

**Example:**

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/anthropics/devcontainer-features/claude-code:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-privacy:0": {}
    }
}
```

### `claude-code-hooks`

Installs [claude-code-hooks](https://github.com/mrrobot0985/claude-code-hooks) into `~/.claude/hooks/` and wires them into `~/.claude/settings.local.json`.

**Options:**

| Option              | Type    | Default                                                | Description                                      |
| ------------------- | ------- | ------------------------------------------------------ | ------------------------------------------------ |
| `repository`        | string  | `https://github.com/mrrobot0985/claude-code-hooks.git` | Git repository URL containing the hooks.         |
| `branch`            | string  | `main`                                                 | Git branch, tag, or commit to checkout.          |
| `installStatusLine` | boolean | `true`                                                 | Also install the status line hook configuration. |

**Example:**

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/anthropics/devcontainer-features/claude-code:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0": {
            "repository": "https://github.com/mrrobot0985/claude-code-hooks.git",
            "branch": "main",
            "installStatusLine": true
        }
    }
}
```

## CI

Feature changes are validated by [`.github/workflows/test.yaml`](.github/workflows/test.yaml):

- `test-autogenerated` — runs each feature with default options across a matrix of base images.
- `test-scenarios` — runs each feature's scenario definitions.
- `test-global` — runs multi-feature integration scenarios from `test/_global/scenarios.json`.

Run the local CI gate before pushing:

```bash
./scripts/local-ci.sh
```

## Development

### Git Hooks

This repository uses a pre-commit hook to keep feature READMEs in sync with `devcontainer-feature.json` metadata. Install it once after cloning:

```bash
git config core.hooksPath .githooks
```

The hook:
- Auto-generates any missing `src/<feature>/README.md` files from their JSON metadata.
- Warns when a staged `devcontainer-feature.json` is not accompanied by its `README.md` update.

You can also run the generator manually:

```bash
uv run python scripts/generate-feature-readmes.py
```

## Publishing

On release, `.github/workflows/release.yaml` publishes each feature to GHCR using the `devcontainers/action@v1` GitHub Action. Features are private by default; set each package to public in its GHCR package settings to stay within the free tier.

## Using the Dev Container CLI

Install the CLI globally via npm or use the VS Code extension's bundled binary:

```bash
npm install -g @devcontainers/cli
# or use the VS Code extension binary:
# ~/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin/devcontainer
```

### Test a single feature locally

```bash
# Build a container with only the claude-code-hooks feature
devcontainer features test -f claude-code-hooks --skip-autogenerated
```

### Build a container from a devcontainer.json that uses these features

```bash
cd /path/to/your/project
devcontainer up --workspace-folder . --build-no-cache
```

### Force a fresh build (bypass Docker cache)

```bash
devcontainer up --workspace-folder . --build-no-cache
```

### Remove stale feature caches

If features are not updating after a new release, clean all caches:

```bash
# Remove old containers, images, and the devcontainer CLI feature cache
docker ps -aq --filter label=devcontainer.local_folder | xargs -r docker rm -f
docker images --format "{{.Repository}}:{{.Tag}}" | grep "vsc-" | xargs -r docker rmi -f
docker volume ls -q | grep "claude-code-config" | xargs -r docker volume rm -f
rm -rf /tmp/devcontainercli-*/container-features/*
rm -f .devcontainer/devcontainer-lock.json
```

### Important: Lockfiles Pin Feature Versions

If `.devcontainer/devcontainer-lock.json` exists, it overrides `:latest` and pins each feature to a specific digest. Delete the lockfile to force resolution of the newest published version.

## License

MIT
