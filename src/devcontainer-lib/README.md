# Devcontainer Shared Library

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Installs a shared shell utility library for use in devcontainer lifecycle scripts and custom automation. Centralizes common helper functions so devcontainer features stay focused on their core purpose.

## Problem

Devcontainer features often duplicate the same ~100 lines of helper functions for user detection, package installation, retry logic, and architecture normalization. This library addresses that duplication.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/devcontainer-lib:0": {}
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `installPath` | string | `/usr/local/share/devcontainer-lib` | Path where the library is installed |

## Using the Library

Source it in your shell scripts or lifecycle commands:

```bash
source /usr/local/share/devcontainer-lib/devcontainer-lib.sh

dc_ensure_jq
dc_log_info "Starting setup..."
dc_retry "curl -fsSL https://example.com/install.sh | bash"
```

## Available Functions

| Function | Description |
|----------|-------------|
| `dc_log_info msg` | Print INFO-prefixed message |
| `dc_log_warn msg` | Print WARNING-prefixed message |
| `dc_log_error msg` | Print ERROR-prefixed message |
| `dc_retry cmd [max=3] [delay=5]` | Retry command with exponential backoff |
| `dc_wait_for cmd [timeout=60] [interval=2]` | Poll until command succeeds |
| `dc_install_if_missing pkg` | Install via apt-get if not present |
| `dc_ensure_jq` | Ensure jq is installed |
| `dc_get_remote_user` | Resolve `_REMOTE_USER` with defaults |
| `dc_get_remote_home` | Resolve remote user home directory |
| `dc_assert_command cmd` | Fail if command is not available |
| `dc_download url outfile` | Robust curl download with retry |
| `dc_detect_arch` | Normalize `uname -m` to amd64/arm64 |
| `dc_safe_chown owner path` | chown with error suppression |
| `dc_ensure_dir path [owner]` | Create directory with ownership |
| `dc_is_feature_install` | Test if in feature install context |
| `dc_help` | Print full function list |

## Background

This feature implements the spirit of the [features-library proposal](https://github.com/devcontainers/spec/blob/main/proposals/features-library.md) in the devcontainer spec, providing a practical shared-code mechanism while the formal `include` property is still under discussion.
