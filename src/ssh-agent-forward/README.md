# SSH Agent Forward

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Forwards the host SSH agent into the devcontainer for Git operations without copying private keys or configuring deploy tokens

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `socketPath` | Path to SSH agent socket on host, or 'auto' to detect from SSH_AUTH_SOCK environment variable | string | auto |
| `forwardToUser` | Also symlink the socket into the container user's home for non-root tools | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/ssh-agent-forward:1": {}
}
```
