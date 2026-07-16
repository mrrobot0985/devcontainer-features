# Wave 12 Spec: docker-compose-helper v0.1.0 + ssh-agent-forward v0.1.0

## 1. docker-compose-helper v0.1.0

### Purpose

Generates and validates docker-compose.yml files for devcontainer setups. The devcontainer spec acknowledges Docker Compose as its only supported orchestrator, but no feature exists to help developers create or maintain compose files with proper service ordering and health checks.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `validate` | boolean | `true` | Validate the generated docker-compose.yml syntax |
| `healthChecks` | boolean | `true` | Add health check stanzas to dependent services |
| `dependsOnOrdering` | boolean | `true` | Ensure service `depends_on` uses start+healthy conditions |

### Behavior

1. **Discovery**: Scan `/workspaces/*` for `docker-compose.yml` or `compose.yaml` files.
2. **Validation**: If `validate: true`, run `docker compose config` to validate syntax.
3. **Health Check Injection**: If `healthChecks: true` and services have `depends_on`, inject `healthcheck:` stanzas into dependency services so downstream services wait for actual readiness (not just container start).
4. **Dependency Ordering**: If `dependsOnOrdering: true`, rewrite `depends_on` from simple service lists to `condition: service_healthy` form.
5. **Installs CLI helper**: `/usr/local/bin/devcontainer-compose-check` for manual re-runs.

### Test Scenarios

1. `default.sh` — No compose file present, exits cleanly
2. `validate-existing.sh` — Validates an existing docker-compose.yml
3. `inject-healthchecks.sh` — Injects health checks into dependencies
4. `dependency-ordering.sh` — Rewrites depends_on to use healthy conditions

---

## 2. ssh-agent-forward v0.1.0

### Purpose

Forwards the host SSH agent socket into the devcontainer so Git operations work without copying private keys or configuring deploy tokens inside the container.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `socketPath` | string | `"auto"` | Path to SSH agent socket on host, or `auto` to detect from `$SSH_AUTH_SOCK` |
| `forwardToUser` | boolean | `true` | Also symlink the socket into the container user's home for non-root tools |

### Behavior

1. **Socket Detection**: If `socketPath: auto`, read `$SSH_AUTH_SOCK` from the host environment (passed via `remoteEnv` or `containerEnv`).
2. **Mount**: Create a bind mount from the host socket path to `/tmp/ssh-agent.sock` inside the container.
3. **Environment**: Set `SSH_AUTH_SOCK=/tmp/ssh-agent.sock` in the container environment.
4. **User Access**: If `forwardToUser: true`, symlink `/tmp/ssh-agent.sock` to `$HOME/.ssh/agent.sock` and update `.bashrc`/`.zshrc` to export it.
5. **Verification**: At install time, verify the socket is accessible and `ssh-add -l` lists keys.

### Test Scenarios

1. `default.sh` — Verifies SSH_AUTH_SOCK is set in container environment
2. `socket-detect.sh` — With `socketPath: auto`, detects and forwards
3. `user-access.sh` — With `forwardToUser: true`, socket is accessible by container user

---

## Cross-cutting Requirements

- Both features follow BrainXio structure
- Both use `$_REMOTE_USER` for user detection
- Both support Debian/Ubuntu
- READMEs include version badges, options table, usage examples
- Tests use standard `dev-container-features-test-lib`
- CI matrix covers both features
