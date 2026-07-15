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

## Repository Structure

```
.
├── src/<feature>/              # One directory per feature
│   ├── devcontainer-feature.json
│   ├── install.sh
│   ├── uninstall.sh (optional)
│   └── README.md (auto-generated from JSON metadata)
├── test/<feature>/             # Scenario tests for each feature
│   ├── scenarios.json
│   ├── test.sh
│   └── *.sh (scenario scripts)
├── test/_global/               # Cross-feature integration scenarios
├── scripts/                    # Local helper scripts
│   ├── local-ci.sh             # Run the full local CI gate
│   └── generate-feature-readmes.py
├── .githooks/pre-commit       # Git hook: keep READMEs in sync
└── .github/workflows/          # CI/CD definitions
```

## Features

| Feature | Version | Description |
| ------- | ------- | ----------- |
| `claude-code-backend` | ![claude-code-backend version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-features/main/src/claude-code-backend/devcontainer-feature.json&label=&query=$.version&color=blue) | Configures Claude Code to use a custom API backend, such as Ollama. |
| `claude-code-privacy` | ![claude-code-privacy version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-features/main/src/claude-code-privacy/devcontainer-feature.json&label=&query=$.version&color=blue) | Disables telemetry, error reporting, feedback, and automatic updates for Claude Code. |
| `claude-code-hooks` | ![claude-code-hooks version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-features/main/src/claude-code-hooks/devcontainer-feature.json&label=&query=$.version&color=blue) | Installs lifecycle hooks for Claude Code telemetry, state tracking, and policy enforcement. |
| `claude-code-rules` | ![claude-code-rules version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-features/main/src/claude-code-rules/devcontainer-feature.json&label=&query=$.version&color=blue) | Installs a curated, condensed set of Claude Code behavior rules into `~/.claude/rules/`. |
| `claude-code-skills` | ![claude-code-skills version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-features/main/src/claude-code-skills/devcontainer-feature.json&label=&query=$.version&color=blue) | Clones Matt Pocock's skills into `~/.claude/skills/` with selectable categories. |
| `claude-code-plugins` | ![claude-code-plugins version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-features/main/src/claude-code-plugins/devcontainer-feature.json&label=&query=$.version&color=blue) | Installs Claude Code plugins from marketplaces at build time. |
| `container-firewall` | ![container-firewall version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-features/main/src/container-firewall/devcontainer-feature.json&label=&query=$.version&color=blue) | Configures an iptables/ipset whitelist firewall with selectable service presets. |
| `nvidia-container-toolkit` | ![nvidia-container-toolkit version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-features/main/src/nvidia-container-toolkit/devcontainer-feature.json&label=&query=$.version&color=blue) | Installs and configures the NVIDIA Container Toolkit for Docker-in-Docker GPU support. |

These features are designed to be composed with official features:

- Install Claude Code itself with the official feature: `ghcr.io/anthropics/devcontainer-features/claude-code`
- Install the GitHub CLI with: `ghcr.io/devcontainers/features/github-cli`
- Install dotfiles with: `ghcr.io/devcontainers/features/dotfiles`

### `claude-code-backend`

Configures Claude Code to use a custom API backend by writing environment variables to `~/.claude/settings.json`.

**Options:**

| Option      | Type   | Default  | Description                                                                       |
| ----------- | ------ | -------- | --------------------------------------------------------------------------------- |
| `baseUrl`   | string | `""`     | Custom API base URL (auto-defaults to `http://host.docker.internal:11434` when `authToken` is `ollama`). |
| `authToken` | string | `ollama` | Auth token for the custom backend.                                                |
| `models`    | string | `""`     | Comma-separated model overrides in `key:value` format.                            |
| `logLevel`  | string | `error`  | Anthropic client log level (`error`, `warn`, `info`, `debug`).                    |

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

Hardens Claude Code privacy settings by writing flags to `~/.claude/settings.json`.

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

Installs bash hooks for Claude Code lifecycle telemetry, state tracking, and policy enforcement. This feature is self-contained — all hook scripts are bundled directly in the feature package.

**Options:**

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| `installSessionHooks` | boolean | `true` | Install session lifecycle hooks (start, end, setup, compact, etc.) |
| `installAgentHooks` | boolean | `true` | Install agent behavior hooks (tool use, permissions, subagents, tasks) |
| `installTurnHooks` | boolean | `true` | Install turn-level hooks (prompt submission, stop, notifications) |
| `installStatusLine` | boolean | `true` | Also install the status line hook configuration |

**Example:**

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

### `claude-code-rules`

Installs a curated, condensed set of Claude Code behavior rules into `~/.claude/rules/`.

Rules are organized into four declarative groups:

**Safety (`enforceSafety`):** `human-sovereignty`, `no-attribution`, `no-secrets`

**Workflow (`standardizeWorkflow`):** `mcp-tools-first`, `skill-discovery`, `anti-overengineering`, `conventional-commits`, `no-orphans`, `branch-strategy`

**Git Protection (`protectGit`):** `no-git-config-override`

**Python Tooling (`preferPythonTooling`):** `prefer-uv`, `markdown-formatting`

**Options:**

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| `enforceSafety` | boolean | `true` | Enforce safety invariants: human sovereignty, no-attribution, no-secrets |
| `standardizeWorkflow` | boolean | `true` | Standardize agent workflow: skill discovery, MCP tools first, anti-overengineering, conventional commits, no-orphans, branch strategy |
| `protectGit` | boolean | `true` | Protect git configuration: never override git config inline |
| `preferPythonTooling` | boolean | `false` | Prefer Python toolchain rules: uv/uvx for Python, mdformat with frontmatter/gfm plugins |

**Example:**

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

### `claude-code-skills`

Installs skills into `~/.claude/skills/` with configurable sources.

**Options:**

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| `enableMattPocockSkills` | boolean | `true` | Clone and install Matt Pocock's skills from github.com/mattpocock/skills |
| `mattPocockSkillsVersion` | string | `v1.1.0` | Version/tag of mattpocock/skills to clone |
| `installEngineering` | boolean | `true` | Install engineering skills (requires enableMattPocockSkills) |
| `installProductivity` | boolean | `true` | Install productivity skills (requires enableMattPocockSkills) |
| `installMisc` | boolean | `false` | Install miscellaneous skills (requires enableMattPocockSkills) |
| `installPersonal` | boolean | `false` | Install personal skills (requires enableMattPocockSkills) |
| `skipOnFailure` | boolean | `false` | Skip skill installation if clone fails instead of failing the build |

**Example:**

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

### `container-firewall`

Configures an iptables/ipset whitelist firewall for the container with selectable service presets and optional telemetry blocking.

**Options:**

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| `profile` | string | `claude-code` | Preset bundle of allowed outbound services (`claude-code`, `github-only`, `minimal`, `custom`) |
| `customDomains` | string | `""` | Comma-separated extra domains to allow (used only with `profile=custom`) |
| `blockTelemetry` | boolean | `false` | Block known telemetry and tracking endpoints at the network level |
| `policy` | string | `whitelist` | `whitelist` drops non-matching traffic; `monitor` logs but does not block |
| `enableIPv6` | boolean | `true` | Also apply whitelist rules to IPv6 (ip6tables) |

**Automation:** This feature automatically requests `NET_ADMIN` via `capAdd` and applies the firewall at container start via `postStartCommand`. No manual `devcontainer.json` configuration is required.

**Example:**

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

### `nvidia-container-toolkit`

Installs and configures the NVIDIA Container Toolkit so GPU-accelerated containers can run from an inner Docker daemon (Docker-in-Docker).

**Options:**

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| `enable` | boolean | `true` | Enable the NVIDIA Container Toolkit feature. When `false`, the feature is a no-op. |
| `defaultRuntime` | boolean | `false` | Set `nvidia` as the default container runtime for the inner dockerd. |
| `restartDockerd` | boolean | `true` | Automatically reload the inner dockerd after configuration if it is running. |

**Example:**

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/devcontainers/features/docker-in-docker:2": {},
        "ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:1": {
            "defaultRuntime": true,
            "restartDockerd": true
        }
    }
}
```

## Scripts and Automation

| Script / Hook | Purpose |
| ------------- | ------- |
| `scripts/local-ci.sh` | Local pre-push gate. Runs shellcheck, README sync checks, workflow validation via `act`, dry-run release, and feature smoke tests. Not invoked by CI; it is a convenience helper. |
| `scripts/generate-feature-readmes.py` | Generates or updates `src/<feature>/README.md` files from `devcontainer-feature.json` metadata. Run manually, or let the pre-commit hook run it. |
| `.githooks/pre-commit` | Git hook installed with `git config core.hooksPath .githooks`. Auto-generates missing feature READMEs and blocks commits where `devcontainer-feature.json` is staged without its matching `README.md`. |

Install the hook once after cloning:

```bash
git config core.hooksPath .githooks
```

Run the README generator manually:

```bash
uv run python scripts/generate-feature-readmes.py
```

Run the local CI gate before pushing:

```bash
./scripts/local-ci.sh
```

## What Runs When I Push / Open a PR

CI runs on every push to `main` and on every pull request. The workflows are split so each check has a single responsibility.

| Workflow | File | Trigger | What it does |
| -------- | ---- | ------- | ------------ |
| **CI - Test Features** | `test.yaml` | push to `main`, PR, manual | Runs autogenerated default tests, per-feature scenario tests, and global integration scenarios across a matrix of base images. Fails if any required test job fails. |
| **Validate devcontainer-feature.json files** | `validate.yml` | push to `main`, PR, manual | Validates `devcontainer-feature.json` schema, runs shellcheck on scripts, and checks that feature READMEs are in sync with JSON metadata. |
| **Lint workflows** | `lint-workflows.yml` | push to `main`, PR, manual | Lints all GitHub Actions workflow files with `actionlint`. |
| **Conventional Commits** | `conventional-commits.yml` | PR open/edit/sync | Ensures the PR title follows Conventional Commits. |

All checks above are required to pass before a PR can merge.

## Releasing

This is a monorepo containing multiple dev container features. To prevent git tag collisions, each feature gets its own prefixed tag: `<feature-name>-v<semver>`.

### Automated release path

1. `auto-release.yml` runs weekly and on demand. It compares each feature's source directory against its latest prefixed tag and bumps the patch version in `devcontainer-feature.json` when changes are detected.
2. When a version bump is needed, it opens a pull request titled `chore: bump feature versions`.
3. After that PR merges to `main`, `tag-release.yml` creates any missing prefixed tags from the current `devcontainer-feature.json` versions.
4. Pushing a prefixed tag triggers `release.yaml`, which publishes the affected feature to GHCR.

### Manual release (emergency only)

If you must release a specific feature manually:

1. Update the `version` field in `src/<feature>/devcontainer-feature.json`.
2. Commit the change with a conventional commit message:  
   `feat(<feature>): bump version to X.Y.Z`
3. Create and push a signed tag:  
   `git tag -s <feature-name>-vX.Y.Z -m "release <feature> vX.Y.Z"`
4. Push the tag to trigger the release workflow:  
   `git push origin <feature-name>-vX.Y.Z`

Features are private by default; set each package to public in its GHCR package settings to stay within the free tier.

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
devcontainer features test -f claude-code-hooks --skip-autogenerated .
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
