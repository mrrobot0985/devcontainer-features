# Wayfinder #20 Preparatory Analysis: `claude-code-plugins` Design Patterns

This summary captures the recurring patterns across existing Dev Container Features in `src/`, focused on designing the new `claude-code-plugins` feature.

## Patterns Checklist

### `devcontainer-feature.json` structure

- [ ] Required top-level fields: `id`, `name`, `version`, `description`
- [ ] `id` is kebab-case; `version` follows semver
- [ ] `description` is concise and states what the feature does
- [ ] `options` is an object; each option has:
  - [ ] `type`: `string` or `boolean` (only types used in this repo)
  - [ ] `default`: sensible default (`""`, `"error"`, `true`, `false`, version tag)
  - [ ] `description`: short sentence describing behavior and constraints
  - [ ] Optional `enum` for constrained string values (e.g., `logLevel`, `policy`, `profile`)
- [ ] Boolean options default to `true` for safety/privacy, `false` for opt-in extras
- [ ] Use `installsAfter` to declare ordering against:
  - [ ] `ghcr.io/devcontainers/features/common-utils`
  - [ ] `ghcr.io/anthropics/devcontainer-features/claude-code` (when writing into `~/.claude/`)
  - [ ] `ghcr.io/devcontainers/features/git` (when cloning repositories)
- [ ] Add `capAdd` only when the feature manipulates host-level resources (e.g., `NET_ADMIN`)
- [ ] Use `postStartCommand` only when runtime initialization is required (e.g., firewall init)

### Option naming and environment mapping

- [ ] JSON option names use `camelCase`
- [ ] In `install.sh`, read the value from an uppercase environment variable with the same letters minus underscores and camel-case boundaries, e.g.:
  - `enableMattPocockSkills` -> `ENABLEMATTPOCOCKSKILLS`
  - `mattPocockSkillsVersion` -> `MATTPOCOCKSKILLSVERSION`
  - `installEngineering` -> `INSTALLENGINEERING`
  - `skipOnFailure` -> `SKIPONFAILURE`
- [ ] Provide a shell default for every option, e.g. `SKIP_ON_FAILURE="${SKIPONFAILURE:-false}"`

### `install.sh` shell conventions

- [ ] Shebang: `#!/bin/sh`
- [ ] `set -e` at the top
- [ ] Activation banner: `echo "Activating feature '<id>'"`
- [ ] Derive paths using `_REMOTE_USER_HOME`:

  ```sh
  USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
  CLAUDE_DIR="${USER_HOME}/.claude"
  ```

- [ ] Create directories with `mkdir -p`
- [ ] Correct ownership at the end (and after any direct file writes):

  ```sh
  chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"
  ```

- [ ] For writing to `settings.json`, source `merge-settings.sh`
- [ ] For copying static assets, use `FEATURE_DIR="$(dirname "$0")"` and copy from there
- [ ] Final success message echoes the configured path

### Optional dependency handling

- [ ] Check with `command -v <tool> >/dev/null 2>&1`
- [ ] If missing, install via multi-package-manager fallback:
  - `apt-get` (Debian/Ubuntu) with `apt-get clean` and `rm -rf /var/lib/apt/lists/*`
  - `apk` (Alpine) with `--no-cache`
  - `yum` (RHEL/CentOS 7)
  - `dnf` (Fedora/RHEL 8+)
- [ ] If no package manager is available, print `ERROR:` and `exit 1`
- [ ] Prefer listing `git` in `installsAfter` and also tolerate installing it at runtime

### Error handling

- [ ] Use `set -e`
- [ ] Fatal errors: print `ERROR:` and `exit 1`
- [ ] Non-fatal warnings: print `WARN:` and continue
- [ ] Optional skip behavior: provide a `skipOnFailure` boolean option that exits 0 instead of failing
- [ ] Validate simple user input (e.g., `key:value` parsing) and fail with a descriptive message

### Writing to `~/.claude/`

- [ ] `~/.claude/settings.json`: use `merge-settings.sh` so multiple features can coexist and new values take precedence
- [ ] `~/.claude/rules/`, `~/.claude/skills/`, `~/.claude/hooks/`, `~/.claude/plugins/`: create directory, copy files, ensure idempotency, chown
- [ ] For idempotent directory-based installs, clear or replace existing managed files when options change

### Testing

- [ ] Each feature has a directory under `test/<feature-id>/`
- [ ] `scenarios.json` defines named scenarios with an `image` and `features` block
- [ ] `test.sh` sources `dev-container-features-test-lib` and runs `reportResults`
- [ ] Scenario-specific shell scripts use `check "<description>" <command>` assertions
- [ ] Tests commonly assert:
  - Directory existence under `~/.claude/`
  - File contents via `jq` for `settings.json`
  - String presence in rc files or installed scripts
- [ ] Global integration scenario under `test/_global/` exercises the full feature stack

## Reference Schema

A well-formed `devcontainer-feature.json` for a Claude Code extension looks like this:

```json
{
  "id": "claude-code-<name>",
  "name": "Claude Code <Name>",
  "version": "0.1.0",
  "description": "Concise description of what this feature installs/configures",
  "options": {
    "exampleBoolean": {
      "type": "boolean",
      "default": true,
      "description": "Enable or disable a specific behavior"
    },
    "exampleString": {
      "type": "string",
      "default": "",
      "description": "Free-form string option"
    },
    "exampleEnum": {
      "type": "string",
      "enum": ["error", "warn", "info", "debug"],
      "default": "error",
      "description": "Constrained string option"
    }
  },
  "installsAfter": [
    "ghcr.io/devcontainers/features/common-utils",
    "ghcr.io/devcontainers/features/git",
    "ghcr.io/anthropics/devcontainer-features/claude-code"
  ]
}
```

## Recommended `install.sh` Skeleton

```sh
#!/bin/sh
set -e

echo "Activating feature 'claude-code-plugins'"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
PLUGINS_DIR="${CLAUDE_DIR}/plugins"
FEATURE_DIR="$(dirname "$0")"

# Read options (uppercase env vars, matching JSON camelCase names)
EXAMPLE_BOOLEAN="${EXAMPLEBOOLEAN:-true}"
EXAMPLE_STRING="${EXAMPLESTRING:-}"
EXAMPLE_ENUM="${EXAMPLEENUM:-error}"
SKIP_ON_FAILURE="${SKIPONFAILURE:-false}"

mkdir -p "$PLUGINS_DIR"

# Install optional dependencies if needed (git, jq, curl, etc.)
# ... multi-package-manager fallback ...

# Copy plugin assets
# ... copy_group or cp -r from $FEATURE_DIR/plugins ...

# If writing to settings.json, source merge-settings.sh
HELPER_FILE="$(dirname "$0")/merge-settings.sh"
# shellcheck source=merge-settings.sh
# shellcheck disable=SC1091
. "$HELPER_FILE"

# merge_settings_json "$SETTINGS_FILE" "$ENV_JSON" "env"

chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"

echo "Claude Code plugins installed to ${PLUGINS_DIR}"
```

## Specific Code Templates

### Template 1: Multi-package-manager dependency install (from `claude-code-skills`)

`/workspaces/mrrobot0985/devcontainer-features/src/claude-code-skills/install.sh`, lines 29-46:

```sh
if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y --no-install-recommends git
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache git
    elif command -v yum >/dev/null 2>&1; then
        yum install -y git
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y git
    else
        echo "ERROR: git is required but could not be installed"
        exit 1
    fi
fi
```

### Template 2: Atomic settings.json merge helper (from `claude-code-backend`)

`/workspaces/mrrobot0985/devcontainer-features/src/claude-code-backend/merge-settings.sh`, lines 21-81:

```sh
merge_settings_json() {
    _settings_file="$1"
    _json_source="$2"
    _target_path="${3:-}"

    # ... validation ...

    _merged=$(jq -n \
        --argjson settings "$_settings" \
        --argjson snippet "$_json" \
        --argjson path "$_path_components" '
        ($path | length) as $depth |
        if $depth == 0 then
            $settings * $snippet
        else
            $settings | setpath($path; (getpath($path) // {}) * $snippet)
        end
    ')

    mkdir -p "$(dirname "$_settings_file")"
    printf '%s\n' "$_merged" | jq . > "${_settings_file}.tmp" && mv "${_settings_file}.tmp" "$_settings_file"
}
```

### Template 3: Writing env values to `settings.json` (from `claude-code-privacy`)

`/workspaces/mrrobot0985/devcontainer-features/src/claude-code-privacy/install.sh`, lines 46-65:

```sh
USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

mkdir -p "$CLAUDE_DIR"

ENV_JSON=$(jq -n \
    --arg dt "$DISABLE_TELEMETRY" \
    --arg der "$DISABLE_ERROR_REPORTING" \
    --arg dfc "$DISABLE_FEEDBACK_COMMAND" \
    --arg du "$DISABLE_UPDATES" \
    '{
        "DISABLE_TELEMETRY": $dt,
        "DISABLE_ERROR_REPORTING": $der,
        "DISABLE_FEEDBACK_COMMAND": $dfc,
        "DISABLE_UPDATES": $du
    }')

merge_settings_json "$SETTINGS_FILE" "$ENV_JSON" "env"

chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"
```

### Template 4: Conditional category copying with idempotency (from `claude-code-skills`)

`/workspaces/mrrobot0985/devcontainer-features/src/claude-code-skills/install.sh`, lines 65-97:

```sh
copy_category() {
    _category="$1"
    _enabled="$2"
    _src_dir="$TEMP_DIR/skills/skills/$_category"

    if [ "$_enabled" != "true" ]; then
        echo "Skipping ${_category} (disabled)"
        return 0
    fi

    if [ ! -d "$_src_dir" ]; then
        echo "WARN: category directory ${_src_dir} not found"
        return 0
    fi

    for _skill in "$_src_dir"/*; do
        if [ -d "$_skill" ]; then
            _skill_name="$(basename "$_skill")"
            _dest="$SKILLS_DIR/$_skill_name"

            if [ -d "$_dest" ]; then
                echo "Replacing existing ${_skill_name}..."
                rm -rf "$_dest"
            fi

            cp -r "$_skill" "$_dest"
            echo "Skill copied: ${_skill_name}"
        fi
    done
}
```

### Template 5: Test scenario file (from `claude-code-skills`)

`/workspaces/mrrobot0985/devcontainer-features/test/claude-code-skills/scenarios.json`:

```json
{
    "default": {
        "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
        "features": {
            "claude-code-skills": {
                "skipOnFailure": true
            }
        }
    }
}
```

### Template 6: Test assertion script (from `claude-code-skills`)

`/workspaces/mrrobot0985/devcontainer-features/test/claude-code-skills/test.sh`:

```sh
#!/bin/bash
set -e

source dev-container-features-test-lib

SKILLS_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude/skills"

check "skills directory exists" test -d "$SKILLS_DIR"

reportResults
```

### Template 7: `settings.json` assertion using `jq` (from `claude-code-backend`)

`/workspaces/mrrobot0985/devcontainer-features/test/claude-code-backend/test.sh`:

```sh
#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"
BASHRC_FILE="${_REMOTE_USER_HOME:-$HOME}/.bashrc"

check "settings.json exists" test -f "$SETTINGS_FILE"
check "baseUrl auto-defaulted" bash -c "jq -e '.env.ANTHROPIC_BASE_URL == \"http://host.docker.internal:11434\"' \"$SETTINGS_FILE\" >/dev/null"
check "authToken set" bash -c "jq -e '.env.ANTHROPIC_AUTH_TOKEN == \"ollama\"' \"$SETTINGS_FILE\" >/dev/null"

reportResults
```

## Key Takeaways for `claude-code-plugins`

1. Treat plugins as static assets that belong in `~/.claude/plugins/` (following the conventions for `rules/`, `skills/`, and `hooks/`).
2. Provide boolean options for enabling/disabling plugin groups or individual plugins.
3. If any configuration must live in `settings.json`, reuse `merge-settings.sh` so the feature composes safely with `claude-code-backend`, `claude-code-privacy`, and `claude-code-hooks`.
4. Always correct ownership to `_REMOTE_USER` after writing into `~/.claude/`.
5. If the feature clones third-party plugin repositories, include `ghcr.io/devcontainers/features/git` in `installsAfter` and implement a `skipOnFailure` option.
6. Mirror the test structure: `test/claude-code-plugins/scenarios.json`, `test/claude-code-plugins/test.sh`, and scenario-specific assertion scripts.
