# Debugging Feature Installation Failures

When a feature fails to install or behaves differently than expected, the cause usually falls into one of a few categories. This guide walks through the most common issues and how to fix them.

## Read the build log first

Feature installation happens during the container image build. The full output of `install.sh` appears in the build log. Look for:

- Non-zero exit codes from package managers.
- Missing commands or files.
- Network timeouts.
- Permission errors.

With the Dev Container CLI, run with `--log-level debug` for more detail:

```bash
devcontainer up --workspace-folder . --build-no-cache --log-level debug
```

## Stale Docker cache

Symptom: an old version of the feature installs, or a fixed bug reappears.

Cause: Docker layers and the devcontainer CLI feature cache can reuse previous builds even after you changed the feature.

Fix:

```bash
# Force a fresh build
devcontainer up --workspace-folder . --build-no-cache

# Or remove the CLI feature cache
rm -rf /tmp/devcontainercli-*/container-features/*

# Remove generated containers and images
docker ps -aq --filter label=devcontainer.local_folder | xargs -r docker rm -f
docker images --format "{{.Repository}}:{{.Tag}}" | grep "vsc-" | xargs -r docker rmi -f
```

## Lockfile pins feature versions

Symptom: you reference `claude-code-backend:0` but an older published version installs.

Cause: `.devcontainer/devcontainer-lock.json` records the exact digest of each feature at the time it was first resolved and overrides `:0` or `:latest`.

Fix:

```bash
rm -f .devcontainer/devcontainer-lock.json
devcontainer up --workspace-folder . --build-no-cache
```

The lockfile is useful for reproducibility, but it must be regenerated when you want to pick up new releases.

## `host.docker.internal` is unreachable

Symptom: the `claude-code-backend` feature defaults to `http://host.docker.internal:11434`, but Claude Code cannot reach Ollama.

Checks:

1. Ensure Ollama is running on the Docker host and listening on `0.0.0.0:11434` or the host's bridge IP.

1. From inside the container, test connectivity:

   ```bash
   curl -sf http://host.docker.internal:11434/api/tags
   ```

1. If that fails, find the host's actual IP and use it in `devcontainer.json`:

   ```jsonc
   "features": {
       "ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:0": {
           "baseUrl": "http://192.168.1.42:11434"
       }
   }
   ```

1. On Linux, `host.docker.internal` may not resolve by default. Add it to `runArgs`:

   ```jsonc
   "runArgs": ["--add-host=host.docker.internal:host-gateway"]
   ```

The `claude-code-backend` install script adds a shell healthcheck that warns users when Ollama is unreachable.

## `NET_ADMIN` missing for the firewall

Symptom: `container-firewall` installs but `iptables` returns an error, or no outbound traffic is allowed.

Cause: iptables requires the `NET_ADMIN` capability. The feature declares it in `devcontainer-feature.json`:

```json
{
    "capAdd": ["NET_ADMIN"]
}
```

The devcontainer CLI should add `--cap-add NET_ADMIN` automatically. If you run the container manually with Docker, add it yourself:

```bash
docker run --cap-add NET_ADMIN my-image
```

If your orchestrator strips capabilities, the firewall cannot function and the init script logs a warning before exiting gracefully.

## Scenario tests pass but the real container fails

Symptom: tests in `test/<feature>/` pass, but the feature fails in a real project.

Common causes:

- The scenario uses a different base image than the real project.
- The scenario passes explicit options that hide a default-option bug.
- The real project has a lockfile or additional features that change ordering.

Fix: reproduce the real project's exact `devcontainer.json` in a new scenario under `test/_global/scenarios.json` and run:

```bash
devcontainer features test --global-scenarios-only .
```

## See also

- [Testing a Feature Locally](test-a-feature-locally.md)
- [Dev Container CLI Reference](../reference/devcontainer-cli.md)
- [Feature Installation Lifecycle](../explanation/feature-lifecycle.md)
