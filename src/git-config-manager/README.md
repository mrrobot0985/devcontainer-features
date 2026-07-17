# Git Config Manager

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Standardizes git configuration for devcontainer users from feature options or host environment variables

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `userName` | Git user.name. Falls back to host env var GIT_USER_NAME if empty. | string | "" |
| `userEmail` | Git user.email. Falls back to host env var GIT_USER_EMAIL if empty. | string | "" |
| `gpgSigningKey` | GPG signing key for commit signing. Falls back to host env var GIT_SIGNING_KEY. | string | "" |
| `commitGpgSign` | Enable GPG signing for commits | boolean | false |
| `defaultBranch` | Default branch name for new repositories | string | main |
| `safeDirectories` | Comma-separated list of paths to add to safe.directory. Use * for all. | string | * |
| `coreAutoCrlf` | core.autocrlf setting (true, false, input) | string | input |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/git-config-manager:1": {}
}
```
