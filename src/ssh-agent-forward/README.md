# SSH Agent Forward

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Forwards the host SSH agent into the devcontainer, enabling Git operations via SSH without copying private keys or configuring deploy tokens.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/ssh-agent-forward:0": {}
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `socketPath` | string | `auto` | Path to the forwarded socket inside the container, or `auto` for `/tmp/vscode-ssh-auth-sock` |
| `forwardToUser` | boolean | `true` | Also symlink the socket into `~/.ssh/agent.sock` for tools that ignore environment variables |

## How It Works

When a devcontainer is started, the host's `SSH_AUTH_SOCK` is either mounted or passed via `remoteEnv`. This feature installs a setup script that:

1. Detects the host SSH agent socket.
2. Symlinks it to a stable container path.
3. Optionally creates a user-local symlink in `~/.ssh/agent.sock`.
4. Injects `SSH_AUTH_SOCK` into `.bashrc` and `.zshrc`.

## Running the Forward

Add to your `devcontainer.json`:

```json
"postStartCommand": "devcontainer-ssh-agent-forward"
```

Or run manually inside the container:

```bash
devcontainer-ssh-agent-forward
```

## Requirements

- The host must have an SSH agent running (`ssh-add -l` should list keys).
- The devcontainer must mount or forward `SSH_AUTH_SOCK` (VS Code / Codespaces do this automatically).

## Notes

- This feature does **not** copy private keys into the container.
- Forwards only work while the container is running and the host agent is available.
- If the host agent is not available, the setup script exits silently with a message.
