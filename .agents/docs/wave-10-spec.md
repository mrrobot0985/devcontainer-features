# Wave 10 Spec: Prebuild Lifecycle Helper v0.2.0 + direnv-integration v0.1.0

## 1. prebuild-lifecycle-helper v0.2.0

### Purpose

Evolve the existing audit-only feature into an active optimization tool that detects dependency installations placed in non-prebuild lifecycle hooks and either warns or automatically rewrites them to use `updateContentCommand` for Codespaces prebuild caching.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `failOnWarning` | boolean | `false` | Fail the build if heavy operations are detected in non-prebuild hooks |
| `fixMode` | boolean | `false` | When true, rewrite `devcontainer.json` in-place to move dependency installs to `updateContentCommand` |
| `detectLanguages` | string | `"auto"` | Comma-separated list: `auto`, `node`, `python`, `rust`, `ruby`, `go`, `php`, `java`, `dotnet`. `auto` scans workspace for lockfiles. |
| `commandTimeout` | string | `"60s"` | Timeout for each detected install command when running in fixMode |

### Detection Logic

The tool scans `/workspaces/*` for lockfiles and maps them to install commands:

| Lockfile / Marker | Language | Detected Install Command |
|---|---|---|
| `package-lock.json` / `npm-shrinkwrap.json` | node | `npm ci` |
| `yarn.lock` | node | `yarn install --frozen-lockfile` |
| `pnpm-lock.yaml` | node | `pnpm install --frozen-lockfile` |
| `bun.lockb` | node | `bun install` |
| `Pipfile.lock` | python | `pipenv install --deploy` |
| `poetry.lock` | python | `poetry install --no-interaction` |
| `requirements*.txt` | python | `pip install -r requirements.txt` |
| `Cargo.lock` | rust | `cargo build` |
| `Gemfile.lock` | ruby | `bundle install` |
| `go.sum` | go | `go mod download` |
| `composer.lock` | php | `composer install --no-interaction --optimize-autoloader` |
| `packages.lock.json` | dotnet | `dotnet restore` |
| `pom.xml` / `build.gradle*` | java | `mvn dependency:resolve` / `gradle build` |

### Behavior

1. **Discovery Phase**: Scan workspace for lockfiles (respects `.gitignore` if present).
2. **Analysis Phase**: Read `devcontainer.json` at repo root. Parse `onCreateCommand`, `updateContentCommand`, `postCreateCommand`, `postStartCommand`.
3. **Classification**: If a command string contains a detected install command (e.g. `npm install`, `pip install`, `bundle install`) and it lives in `postCreateCommand` or `onCreateCommand`, flag it.
4. **Report Phase**: Print a table showing:
   - Current hook location
   - Recommended hook location (`updateContentCommand`)
   - Detected install command
   - Estimated time savings if moved (based on project size heuristic)
5. **Fix Phase** (if `fixMode: true`): Back up original `devcontainer.json` to `devcontainer.json.prebuild-backup`, rewrite JSON with commands moved to `updateContentCommand`. Merge existing `updateContentCommand` entries. Validate resulting JSON.

### Installed Binaries

- `/usr/local/bin/prebuild-audit` — standalone CLI for manual re-runs
  - Usage: `prebuild-audit [--fix] [--lang auto,node,python] [path/to/devcontainer.json]`
  - Exit 0 = no issues found, Exit 1 = warnings found (with `--fail` flag), Exit 2 = error

### Files

- `src/prebuild-lifecycle-helper/devcontainer-feature.json` — updated options
- `src/prebuild-lifecycle-helper/install.sh` — main install + detection logic
- `src/prebuild-lifecycle-helper/README.md` — usage, examples, migration guide
- `src/prebuild-lifecycle-helper/prebuild-audit.sh` — standalone audit script
- `test/prebuild-lifecycle-helper/` — test scenarios

### Test Scenarios

1. `default.sh` — No lockfiles present, exits cleanly
2. `detect-npm.sh` — `package-lock.json` present, warns about `npm install` in `postCreateCommand`
3. `detect-python.sh` — `requirements.txt` present, warns about `pip install` in `postCreateCommand`
4. `fix-mode.sh` — `fixMode: true`, verifies `devcontainer.json` is rewritten correctly
5. `fail-on-warning.sh` — `failOnWarning: true`, expects build failure when violations found
6. `multi-language.sh` — Mixed Node + Python project, detects both

---

## 2. direnv-integration v0.1.0

### Purpose

Install and configure direnv for automatic `.envrc` loading when developers change directories inside the devcontainer, eliminating manual `export` or `source` steps.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"latest"` | direnv version to install, or `latest` for auto-resolution |
| `shell` | string | `"auto"` | Shells to hook: `auto`, `bash`, `zsh`, `fish`. `auto` detects available shells. Comma-separated for multiple. |
| `autoAllow` | boolean | `true` | Automatically run `direnv allow` in the workspace directory after install |

### Behavior

1. **Install**: Download direnv binary from GitHub releases. Architecture detection (`x86_64`, `aarch64`).
2. **Shell Hooks**: Append direnv hook to shell rc files:
   - `bash` → `~/.bashrc`
   - `zsh` → `~/.zshrc`
   - `fish` → `~/.config/fish/config.fish` (if fish installed)
3. **direnvrc**: Create `~/.direnvrc` with safe defaults:
   - `export DIRENV_WARN_TIMEOUT=10s`
   - `export DIRENV_LOG_FORMAT=""` (quiet by default in devcontainers)
   - `strict_env = true` (fail on unset variables)
4. **Auto-allow**: If `autoAllow: true`, run `direnv allow` in `/workspaces/*` directories where `.envrc` exists.
5. **Permissions**: All files owned by `_REMOTE_USER`.

### Installed Binaries

- `/usr/local/bin/direnv` — direnv binary

### Files

- `src/direnv-integration/devcontainer-feature.json`
- `src/direnv-integration/install.sh`
- `src/direnv-integration/README.md`
- `test/direnv-integration/` — test scenarios

### Test Scenarios

1. `default.sh` — Installs direnv, verifies binary exists and runs
2. `bash-hook.sh` — Verifies hook is present in `~/.bashrc`
3. `zsh-hook.sh` — Verifies hook is present in `~/.zshrc`
4. `auto-allow.sh` — Creates `.envrc`, enables feature, verifies env vars are loaded
5. `specific-version.sh` — Installs a pinned version, verifies `direnv version` output

---

## Cross-cutting Requirements

- Both features follow the BrainXio feature structure: `src/<id>/devcontainer-feature.json`, `src/<id>/install.sh`, `src/<id>/README.md`
- Both use `$_REMOTE_USER` for user detection
- Both support Debian/Ubuntu and Alpine base images
- READMEs include version badges, options table, usage examples, and CHANGELOG
- Tests use the standard `dev-container-features-test-lib` pattern
- CI matrix includes `ubuntu:latest` and `mcr.microsoft.com/devcontainers/base:ubuntu`
