# Git Config Manager

Standardizes git configuration for devcontainer users from feature options or host environment variables.

## Features

- **User identity**: Sets `user.name` and `user.email` from options or host env vars
- **GPG signing**: Configures commit signing with optional signing key
- **Safe directories**: Automatically adds workspace paths to `safe.directory`
- **Default branch**: Configures `init.defaultBranch` for new repositories
- **Cross-platform**: Handles line endings with configurable `core.autocrlf`

## Usage

Add the feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/git-config-manager:0": {
      "userName": "Developer Name",
      "userEmail": "dev@example.com",
      "defaultBranch": "main",
      "commitGpgSign": true,
      "gpgSigningKey": "ABC123DEF456"
    }
  }
}
```

Or use host environment variables:

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/git-config-manager:0": {}
  },
  "remoteEnv": {
    "GIT_USER_NAME": "${localEnv:GIT_USER_NAME}",
    "GIT_USER_EMAIL": "${localEnv:GIT_USER_EMAIL}",
    "GIT_SIGNING_KEY": "${localEnv:GIT_SIGNING_KEY}"
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `userName` | string | `""` | Git user.name. Falls back to `GIT_USER_NAME` env var |
| `userEmail` | string | `""` | Git user.email. Falls back to `GIT_USER_EMAIL` env var |
| `gpgSigningKey` | string | `""` | GPG signing key. Falls back to `GIT_SIGNING_KEY` env var |
| `commitGpgSign` | boolean | `false` | Enable GPG signing for commits |
| `defaultBranch` | string | `"main"` | Default branch name for new repositories |
| `safeDirectories` | string | `"*"` | Comma-separated paths for safe.directory. Use `*` for all |
| `coreAutoCrlf` | string | `"input"` | core.autocrlf setting |

## Helper Command

```bash
git-config-status  # Show current git configuration
```
