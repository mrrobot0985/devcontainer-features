# Wave 11 Spec: devcontainer-lib v0.1.0 + taskfile-dev v0.1.0

## 1. devcontainer-lib v0.1.0

### Purpose

Addresses the verified finding that devcontainer features contain ~100 lines of identical helper functions with no supported sharing mechanism (devcontainers/spec proposals/features-library). Installs a shared utility library to a well-known path so other BrainXio features can source common functions instead of duplicating them.

### Install Location

- `/usr/local/share/devcontainer-lib/devcontainer-lib.sh` — main library
- `/usr/local/share/devcontainer-lib/README.md` — usage guide for feature authors

### Provided Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `dc_log_info` | `dc_log_info "message"` | Print INFO-prefixed message |
| `dc_log_warn` | `dc_log_warn "message"` | Print WARNING-prefixed message |
| `dc_log_error` | `dc_log_error "message"` | Print ERROR-prefixed message |
| `dc_retry` | `dc_retry "command" [max=3] [delay=5]` | Retry command with exponential backoff |
| `dc_wait_for` | `dc_wait_for "command" [timeout=60] [interval=2]` | Poll until command succeeds |
| `dc_install_if_missing` | `dc_install_if_missing "package"` | Install via apt-get if not present |
| `dc_ensure_jq` | `dc_ensure_jq` | Install jq if missing |
| `dc_get_remote_user` | `dc_get_remote_user` | Resolve `_REMOTE_USER` with sensible defaults |
| `dc_get_remote_home` | `dc_get_remote_home` | Resolve remote user home directory |
| `dc_assert_command` | `dc_assert_command "cmd"` | Fail if command is not available |
| `dc_download` | `dc_download "url" "outfile"` | Robust curl download with retry |
| `dc_detect_arch` | `dc_detect_arch` | Normalize uname -m to amd64/arm64 |
| `dc_safe_chown` | `dc_safe_chown "user" "path"` | chown with error suppression |

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `installPath` | string | `/usr/local/share/devcontainer-lib` | Path where the library is installed |

### Usage in Other Features

```bash
#!/bin/bash
set -e
source /usr/local/share/devcontainer-lib/devcontainer-lib.sh || true

dc_ensure_jq
dc_log_info "Starting install..."
```

### Test Scenarios

1. `default.sh` — Library file exists, can be sourced, functions are callable
2. `functions-work.sh` — Tests dc_retry, dc_wait_for, dc_detect_arch
3. `idempotent.sh` — Re-installing the feature does not duplicate functions

---

## 2. taskfile-dev v0.1.0

### Purpose

Installs the [Task](https://taskfile.dev) command runner (go-task) for projects using `Taskfile.yml` instead of Makefiles. Registers shell completions and optionally aliases `task` to `t`.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"latest"` | Task version to install, or `latest` for auto-resolution |
| `alias` | boolean | `true` | Create `t` alias for `task` in shell rc files |
| `completions` | boolean | `true` | Install bash and zsh completions |
| `detectTaskfile` | boolean | `true` | Print a hint if Taskfile.yml is found in workspace |

### Install Method

- Download official release from GitHub: `https://github.com/go-task/task/releases/download/v${VERSION}/task_linux_${ARCH}.tar.gz`
- Extract `task` binary to `/usr/local/bin/`
- Extract completions to `/usr/local/share/bash-completion/completions/` and `/usr/local/share/zsh/site-functions/`

### Architecture Mapping

- x86_64 → amd64
- aarch64/arm64 → arm64

### Shell Integration

- bash: `alias t='task'` in `~/.bashrc` (if alias option enabled)
- zsh: `alias t='task'` in `~/.zshrc` (if alias option enabled)

### Test Scenarios

1. `default.sh` — Installs task, verifies `task --version` works
2. `alias.sh` — Verifies `t` alias exists in bashrc
3. `completions.sh` — Verifies completion files are installed
4. `specific-version.sh` — Installs pinned version, verifies exact version output

---

## Cross-cutting Requirements

- Both features follow BrainXio structure: `src/<id>/devcontainer-feature.json`, `src/<id>/install.sh`, `src/<id>/README.md`
- Both use `$_REMOTE_USER` for user detection
- Both support Debian/Ubuntu base images
- READMEs include version badges, options table, usage examples, and CHANGELOG
- Tests use standard `dev-container-features-test-lib` pattern
- CI matrix includes `ubuntu:latest` and `mcr.microsoft.com/devcontainers/base:ubuntu`
