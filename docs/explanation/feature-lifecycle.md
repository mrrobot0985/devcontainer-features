# Feature Installation Lifecycle

A dev container feature participates in two distinct phases: image build and container runtime. Understanding the split helps you decide what belongs in `install.sh` and what belongs in lifecycle hooks.

## Build-time installation

When you build a dev container that references a feature, the devcontainer CLI:

1. Resolves the feature from the registry or local `src/` directory.
2. Adds a build step that runs the feature's `install.sh` as `root`.
3. Passes each option as an environment variable whose name is the option id converted to uppercase. For example, the `baseUrl` option becomes `BASEURL`.

A minimal `install.sh` can therefore read its options like this:

```bash
#!/bin/sh
set -e

BASE_URL="${BASEURL:-}"
```

### User context

Because `install.sh` runs as `root`, it must not assume it is the target user. The CLI provides two variables:

- `_REMOTE_USER` — the username the container runs as.
- `_REMOTE_USER_HOME` — that user's home directory.

Use them when creating or changing ownership of files in the user's home:

```bash
USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
mkdir -p "$USER_HOME/.config"
chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$USER_HOME/.config"
```

### Idempotency and failures

The install script should be idempotent. If the container image is rebuilt, the script runs again from a clean filesystem, so idempotency is usually free. Set `set -e` so any failing command fails the entire build.

## Runtime lifecycle hooks

After the image is built and the container starts, the CLI runs lifecycle hooks in a fixed order. These hooks run as the container user, not as `root`.

| Hook | Runs when | Typical use |
| ---- | --------- | ----------- |
| `initializeCommand` | Before the container is created, on the host | Prepare host-side state |
| `onCreateCommand` | Once after first creation | First-time setup that needs a running container |
| `updateContentCommand` | When content is updated (for example, on branch switch) | Re-sync dependencies |
| `postCreateCommand` | After `onCreateCommand` | Start services, finalize configuration |
| `postStartCommand` | Every time the container starts | Apply runtime configuration |
| `postAttachCommand` | Every time a user attaches | Shell-specific setup |

### Feature-declared hooks

A feature can declare hooks directly in `devcontainer-feature.json`. The `container-firewall` feature uses `postStartCommand` to apply firewall rules after the container has started and networking is fully available:

```json
{
    "postStartCommand": "sudo /usr/local/bin/container-firewall-init"
}
```

Feature-declared hooks are merged with any hooks defined at the top level of `devcontainer.json`. When multiple features declare the same hook, they run in the order the features were installed.

## Feature metadata labels

When the devcontainer CLI installs a feature, it embeds the feature metadata into labels on the resulting container image. These labels record:

- The feature id and version.
- The resolved feature digest.
- The options used during installation.

The CLI uses this information for caching and resolution. That is why changing a feature's version in `devcontainer-feature.json` and publishing a new prefixed tag causes new containers to pick up the new version, while stale images may continue to use an older cached version until you rebuild with `--build-no-cache` or clean caches.

## Putting it together: `claude-code-backend`

The `claude-code-backend` feature demonstrates the build/runtime split:

- **Build-time (`install.sh`):** installs `jq` if missing, merges backend settings into `~/.claude/settings.json`, and optionally appends an Ollama healthcheck to the user's shell rc files.
- **Runtime (shell healthcheck):** when the user opens a shell, the healthcheck warns if `http://host.docker.internal:11434` is unreachable. This cannot be done at build time because the host service may not be running.

## Best practices

- Do heavy, one-time setup in `install.sh`.
- Use lifecycle hooks only for things that need a running container or must run repeatedly.
- Keep `install.sh` idempotent and fail fast with `set -e`.
- Never hardcode the container user; rely on `_REMOTE_USER` and `_REMOTE_USER_HOME`.
