# Claude Code Plugin Installation for Devcontainer Features

## Recommendation

For a non-interactive devcontainer build, the most reliable mechanism is to run the `claude` CLI inside the feature's `install.sh`:

1. Declare `ghcr.io/anthropics/devcontainer-features/claude-code` in `installsAfter` so the `claude` binary is present.
2. Add any required third-party marketplaces with `claude plugin marketplace add <owner/repo>`.
3. Install each plugin with `claude plugin install <plugin>@<marketplace> --scope user`.

This writes `enabledPlugins` and `extraKnownMarketplaces` to `~/.claude/settings.json` and populates `~/.claude/plugins/cache/` at build time, without requiring a TTY or trust dialog.

**Fallback:** pre-build a read-only plugin seed directory and point `CLAUDE_CODE_PLUGIN_SEED_DIR` at it. This is the official container/CI path and avoids runtime cloning, but it still requires the same CLI install step to create the seed. It is the right choice when the container must start without network access.

For plugins that are simple git repositories with a `.claude-plugin/plugin.json` manifest, an additional option is to clone them into `~/.claude/skills/<name>/`, where Claude Code auto-discovers them as `<name>@skills-dir` (personal scope). This mirrors the existing `claude-code-skills` feature and does not require the `claude` CLI at build time.

## Existing repo patterns

The repository already installs content into `~/.claude` in two ways:

- `/workspaces/mrrobot0985/devcontainer-features/src/claude-code-skills/install.sh` clones git repositories into `~/.claude/skills/`, uses `_REMOTE_USER_HOME` for the target home directory, optionally installs `git`, fixes ownership with `chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}"`, and offers a `skipOnFailure` flag.
- `/workspaces/mrrobot0985/devcontainer-features/src/claude-code-backend/install.sh` writes JSON into `~/.claude/settings.json` via the shared helper `/workspaces/mrrobot0985/devcontainer-features/src/claude-code-backend/merge-settings.sh`, and also uses `installsAfter` to ensure dependencies run first.

A `claude-code-plugins` feature should follow the same conventions: install after the `claude-code` feature, target `~/.claude`, use `_REMOTE_USER_HOME`, install `git` if missing, and fix ownership on exit.

## Mechanism comparison

| Mechanism | Works headless | Needs `claude` CLI at build time | Survives rebuild | Version pinning | Plugin updates | Main failure modes |
|---|---|---|---|---|---|---|
| **(a) `claude plugin install <plugin>@<marketplace> --scope user`** | Yes. The command accepts the full `plugin@marketplace` identifier and does not require a TTY. | Yes. Relies on `ghcr.io/anthropics/devcontainer-features/claude-code` (or equivalent) in `installsAfter`. | Yes, if `~/.claude` is persisted with a volume mount; otherwise plugins are reinstalled on each rebuild. | Pin the marketplace catalog with `claude plugin marketplace add owner/repo#<ref>`; individual plugin versions are whatever the marketplace entry pins (often a commit SHA). | Subject to Claude Code's auto-updater. Official marketplaces auto-update by default; third-party ones do not. Use `DISABLE_AUTOUPDATER=1` to disable. | `claude` or `git` missing; network unavailable during build; plugin/markplace name typo; private marketplace needs credentials. |
| **(b) `CLAUDE_CODE_PLUGIN_SEED_DIR`** | Yes. The seed is read-only at runtime; marketplaces and caches are loaded without re-cloning. | Yes, to create the seed (run the same CLI commands with `CLAUDE_CODE_PLUGIN_CACHE_DIR=/seed/path` so they write directly into the seed). | Baked into the container image; survives rebuilds without a `~/.claude` volume. | Same as (a): pin the marketplace source ref when building the seed. | Disabled for seed-managed marketplaces; update by rebuilding the image. | Seed path must be set in the runtime environment; plugins still need `enabledPlugins`/`extraKnownMarketplaces` to activate; image size grows with every plugin. |
| **(c) Write `enabledPlugins`/`extraKnownMarketplaces` to `~/.claude/settings.json`** | **No.** In headless/cloud sessions the interactive trust dialog is skipped, so these settings can be silently ignored. | No (build-time); `claude` is only needed at runtime. | Yes if `~/.claude` is persisted. | Marketplace catalog SHA. | Auto-update after the project is trusted. | Silent ignore in headless/devcontainer builds; user is prompted to install on first interactive open. |
| **(d) Direct clone into `~/.claude/plugins/` or `~/.claude/skills/`** | Partial. Copying raw files into `~/.claude/plugins/` is undocumented and likely fails because marketplace metadata (`known_marketplaces.json`, cache structure) is missing. Cloning a plugin into `~/.claude/skills/<name>/` works as a skills-directory plugin (`<name>@skills-dir`, personal scope). | No for `~/.claude/skills/`; only `git` is required. | Yes if `~/.claude` is persisted. | Pin via git tag or SHA. | Manual (`git pull` or rebuild). | `~/.claude/plugins/` direct copy is unsupported; `~/.claude/skills/` loads plugins in personal scope, which may differ from the marketplace install (e.g., MCP/LSP restrictions are relaxed, but the plugin identity is `@skills-dir`). |

## Why the CLI install approach is primary

- It is the documented non-interactive equivalent of the interactive `/plugin install` command. The official docs state that `claude plugin install` "installs to user scope unless you pass `--scope`" and is the way to "install without an interactive step" ([Discover and install prebuilt plugins through marketplaces](https://code.claude.com/docs/en/discover-plugins)).
- It does not depend on the trust dialog. The settings-only approach is explicitly tied to the interactive trust event and is silently skipped in headless sessions ([pcamarajr.dev blog on headless Claude Code plugins](https://pcamarajr.dev/blog/claude-code-plugins-headless)).
- It writes the same settings that `claude-code-backend` already manipulates, so it composes naturally with the existing feature ecosystem.

## Why `CLAUDE_CODE_PLUGIN_SEED_DIR` is the fallback

- It is the only method the docs explicitly call out "for container images and CI environments" ([Create and distribute a plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces)).
- It lets the container start without network access and without re-cloning plugins.
- It composes with `enabledPlugins`/`extraKnownMarketplaces`: if the same marketplace is declared in settings, Claude Code uses the cached seed copy instead of cloning.

## Example `install.sh` for the primary approach

```sh
#!/bin/sh
set -e

echo "Activating feature 'claude-code-plugins'"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"

PLUGINS="${PLUGINLIST:-ralph-loop@claude-plugins-official}"
MARKETPLACES="${MARKETPLACELIST:-}"
SKIP_ON_FAILURE="${SKIPONFAILURE:-false}"

# Ensure the destination directory exists.
mkdir -p "$CLAUDE_DIR"

# Ensure git is available so the CLI can clone marketplace repositories.
if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y --no-install-recommends git
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache git
    elif command -v yum >/dev/null 2>&1; then
        yum install -y git
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y git
    else
        echo "ERROR: git is required but could not be installed"
        exit 1
    fi
fi

# The claude-code feature must run before this one.
if ! command -v claude >/dev/null 2>&1; then
    echo "ERROR: claude CLI not found. Ensure ghcr.io/anthropics/devcontainer-features/claude-code is installed before this feature."
    exit 1
fi

# Point the CLI at the remote user's config directory during this build.
export HOME="$USER_HOME"
export CLAUDE_CONFIG_DIR="$CLAUDE_DIR"

# Add any requested third-party marketplaces. For reproducible builds, pin the
# marketplace catalog with an owner/repo#ref syntax, e.g.:
#   claude plugin marketplace add obra/superpowers-marketplace#v1.2.3
add_marketplace() {
    _mp="$1"
    echo "Adding marketplace ${_mp}..."
    if ! claude plugin marketplace add "$_mp"; then
        if [ "$SKIP_ON_FAILURE" = "true" ]; then
            echo "WARNING: Failed to add marketplace ${_mp}; continuing because skipOnFailure=true."
            return 0
        fi
        echo "ERROR: Failed to add marketplace ${_mp}"
        return 1
    fi
}

# Install each requested plugin at user scope so it is available across projects.
install_plugin() {
    _spec="$1"
    echo "Installing plugin ${_spec}..."
    if ! claude plugin install "$_spec" --scope user; then
        if [ "$SKIP_ON_FAILURE" = "true" ]; then
            echo "WARNING: Failed to install plugin ${_spec}; continuing because skipOnFailure=true."
            return 0
        fi
        echo "ERROR: Failed to install plugin ${_spec}"
        return 1
    fi
}

OLD_IFS="$IFS"
IFS=','
set -f

for mp in $MARKETPLACES; do
    [ -z "$mp" ] && continue
    add_marketplace "$mp"
done

for spec in $PLUGINS; do
    [ -z "$spec" ] && continue
    install_plugin "$spec"
done

set +f
IFS="$OLD_IFS"

# Fix ownership so the remote user can read/write the config.
chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"

echo "Claude Code plugins installed to ${CLAUDE_DIR}"
```

### Corresponding `devcontainer-feature.json` options

```json
{
  "id": "claude-code-plugins",
  "name": "Claude Code Plugins",
  "version": "0.1.0",
  "description": "Installs Claude Code plugins from marketplaces at build time",
  "options": {
    "pluginList": {
      "type": "string",
      "default": "",
      "description": "Comma-separated list of plugins to install as plugin@marketplace"
    },
    "marketplaceList": {
      "type": "string",
      "default": "",
      "description": "Comma-separated list of additional marketplaces to add as owner/repo or owner/repo#ref"
    },
    "skipOnFailure": {
      "type": "boolean",
      "default": false,
      "description": "Skip plugin installation if a plugin or marketplace fails instead of failing the build"
    }
  },
  "installsAfter": [
    "ghcr.io/devcontainers/features/common-utils",
    "ghcr.io/devcontainers/features/git",
    "ghcr.io/anthropics/devcontainer-features/claude-code"
  ]
}
```

## Example usage

```json
{
  "features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code": {},
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-plugins": {
      "pluginList": "ralph-loop@claude-plugins-official,superpowers@claude-plugins-official",
      "marketplaceList": "obra/superpowers-marketplace#v1.2.3",
      "skipOnFailure": true
    }
  }
}
```

## Implementation notes and failure modes

- **Home directory persistence:** Devcontainer rebuilds discard the container home. The primary approach writes to `~/.claude`, so follow the official guidance and mount a named volume at that path (or set `CLAUDE_CONFIG_DIR` to a mounted path) if you want plugins to survive rebuilds. Without a volume, the feature will reinstall the plugins on every rebuild, which is fine for CI-like reproducibility but slower.
- **Authentication:** Public marketplaces and the official marketplace do not require an `ANTHROPIC_API_KEY` during `claude plugin marketplace add` or `claude plugin install`. Private marketplaces require git credentials; configure them with a credential helper or a scoped git URL rewrite before running the install commands.
- **Version pinning:** `claude plugin install` does not accept a version argument. Pin by locking the marketplace source to a ref (`owner/repo#tag`) so the marketplace catalog entry points at a fixed commit SHA.
- **Updates:** By default, official marketplaces auto-update installed plugins in the background. To keep the devcontainer image stable, set `DISABLE_AUTOUPDATER=1` in `containerEnv` and rebuild the container to pick up new plugin versions.
- **No TTY required:** Verified by running `claude plugin marketplace add` and `claude plugin install ralph-loop@claude-plugins-official --scope user` in a non-interactive shell with no `ANTHROPIC_API_KEY`; both completed without prompts.
- **Scope:** Use `--scope user` during the feature build. `--scope project` writes to the current working directory's `.claude/settings.json`, which is the project workspace during normal use but not necessarily during feature installation.
- **Seed fallback gotchas:** A seed directory alone does not auto-enable plugins; the runtime still needs `enabledPlugins` (in user/project settings) or a seed-built `known_marketplaces.json` plus a matching install request. The simplest seed workflow is: build the seed with `CLAUDE_CODE_PLUGIN_CACHE_DIR=/seed/path claude plugin install ...`, then set `CLAUDE_CODE_PLUGIN_SEED_DIR=/seed/path` at runtime.

## Sources

- [Discover and install prebuilt plugins through marketplaces](https://code.claude.com/docs/en/discover-plugins)
- [Plugins reference](https://code.claude.com/docs/en/plugins-reference)
- [Create and distribute a plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces)
- [Development containers](https://code.claude.com/docs/en/devcontainer)
- [Run Claude Code programmatically](https://code.claude.com/docs/en/headless)
- [Headless Claude Code plugins blog post](https://pcamarajr.dev/blog/claude-code-plugins-headless)
- [Claude Code GitHub issue #35140 on `CLAUDE_CODE_PLUGIN_SEED_DIR`](https://github.com/anthropics/claude-code/issues/35140)
- [Ralph Loop plugin page](https://claude.com/plugins/ralph-loop)
- [Obra Superpowers installation docs](https://obra-superpowers.mintlify.app/installation/claude-code)
- Existing feature scripts in this repository:
  - `/workspaces/mrrobot0985/devcontainer-features/src/claude-code-skills/install.sh`
  - `/workspaces/mrrobot0985/devcontainer-features/src/claude-code-backend/install.sh`
  - `/workspaces/mrrobot0985/devcontainer-features/src/claude-code-backend/merge-settings.sh`
