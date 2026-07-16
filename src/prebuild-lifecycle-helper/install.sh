#!/bin/bash
set -e

# prebuild-lifecycle-helper v0.2.0 install script
# Installs prebuild-audit and prebuild-lifecycle-helper CLI tools

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_HOME=$(getent passwd "$REMOTE_USER" | cut -d: -f6 2>/dev/null || true)
if [ -z "$REMOTE_HOME" ]; then
    if [ "$REMOTE_USER" = "root" ]; then
        REMOTE_HOME="/root"
    else
        REMOTE_HOME="/home/$REMOTE_USER"
    fi
fi

FAIL_ON_WARNING="${FAILONWARNING:-false}"
FIX_MODE="${FIXMODE:-false}"
DETECT_LANGUAGES="${DETECTLANGUAGES:-auto}"
COMMAND_TIMEOUT="${COMMANDTIMEOUT:-60s}"

# Ensure jq is available for JSON manipulation
if ! command -v jq >/dev/null 2>&1; then
    apt-get update >/dev/null 2>&1 && apt-get install -y jq >/dev/null 2>&1 || true
fi

# Write the main audit tool
cat > /usr/local/bin/prebuild-audit <<'AUDIT_EOF'
#!/bin/bash
set -e

# prebuild-audit — analyze and optimize devcontainer lifecycle commands for prebuild caching

DEVCONTAINER_JSON=""
WARNINGS=0
FIX_MODE="${FIX_MODE:-false}"
DETECT_LANGUAGES="${DETECT_LANGUAGES:-auto}"

# Language definitions: name|lockfiles|install_command
LANG_DEFS=$(cat <<'LANGS'
node|package-lock.json npm-shrinkwrap.json yarn.lock pnpm-lock.yaml bun.lockb|npm ci
python|Pipfile.lock poetry.lock requirements.txt requirements*.txt|pip install -r requirements.txt
rust|Cargo.lock|cargo build
ruby|Gemfile.lock|bundle install
go|go.sum|go mod download
php|composer.lock|composer install --no-interaction --optimize-autoloader
java|pom.xml build.gradle build.gradle.kts|mvn dependency:resolve
dotnet|packages.lock.json|dotnet restore
LANGS
)

find_devcontainer_json() {
    local search_paths=(
        "/workspaces"
        "/workspace"
        "$PWD"
        "$REMOTE_HOME/workspace"
    )

    for base in "${search_paths[@]}"; do
        if [ -d "$base" ]; then
            for sub in "" "/.devcontainer"; do
                local candidate="$base$sub/devcontainer.json"
                if [ -f "$candidate" ]; then
                    echo "$candidate"
                    return 0
                fi
            done
        fi
    done

    # Search one level deeper in /workspaces
    if [ -d "/workspaces" ]; then
        for dir in /workspaces/*; do
            if [ -d "$dir" ]; then
                for sub in "" "/.devcontainer"; do
                    local candidate="$dir$sub/devcontainer.json"
                    if [ -f "$candidate" ]; then
                        echo "$candidate"
                        return 0
                    fi
                done
            fi
        done
    fi

    return 1
}

scan_lockfiles() {
    local workspace_dir="$1"
    local langs_filter="$2"
    local found=""

    echo "$LANG_DEFS" | while IFS='|' read -r lang locks install_cmd; do
        [ -z "$lang" ] && continue

        # Filter by requested languages
        if [ "$langs_filter" != "auto" ]; then
            local match=false
            IFS=',' read -ra req_langs <<< "$langs_filter"
            for rl in "${req_langs[@]}"; do
                if [ "$(echo "$rl" | tr -d ' ')" = "$lang" ]; then
                    match=true
                    break
                fi
            done
            [ "$match" = false ] && continue
        fi

        # Check for lockfiles
        IFS=' ' read -ra lock_arr <<< "$locks"
        for lock in "${lock_arr[@]}"; do
            if [ "$lock" = "requirements*.txt" ]; then
                if ls "$workspace_dir"/requirements*.txt >/dev/null 2>&1; then
                    echo "$lang|$install_cmd|$lock"
                    break
                fi
            elif [ -f "$workspace_dir/$lock" ]; then
                echo "$lang|$install_cmd|$lock"
                break
            fi
        done
    done
}

get_install_command() {
    local lang="$1"
    local workspace_dir="$2"

    case "$lang" in
        node)
            if [ -f "$workspace_dir/bun.lockb" ]; then
                echo "bun install"
            elif [ -f "$workspace_dir/pnpm-lock.yaml" ]; then
                echo "pnpm install --frozen-lockfile"
            elif [ -f "$workspace_dir/yarn.lock" ]; then
                echo "yarn install --frozen-lockfile"
            elif [ -f "$workspace_dir/package-lock.json" ] || [ -f "$workspace_dir/npm-shrinkwrap.json" ]; then
                echo "npm ci"
            else
                echo "npm install"
            fi
            ;;
        python)
            if [ -f "$workspace_dir/Pipfile.lock" ]; then
                echo "pipenv install --deploy"
            elif [ -f "$workspace_dir/poetry.lock" ]; then
                echo "poetry install --no-interaction"
            elif ls "$workspace_dir"/requirements*.txt >/dev/null 2>&1; then
                echo "pip install -r requirements.txt"
            else
                echo "pip install -r requirements.txt"
            fi
            ;;
        rust)
            echo "cargo build"
            ;;
        ruby)
            echo "bundle install"
            ;;
        go)
            echo "go mod download"
            ;;
        php)
            echo "composer install --no-interaction --optimize-autoloader"
            ;;
        java)
            if [ -f "$workspace_dir/pom.xml" ]; then
                echo "mvn dependency:resolve"
            elif [ -f "$workspace_dir/build.gradle" ] || [ -f "$workspace_dir/build.gradle.kts" ]; then
                echo "gradle build"
            fi
            ;;
        dotnet)
            echo "dotnet restore"
            ;;
        *)
            echo ""
            ;;
    esac
}

parse_lifecycle_command() {
    local json_file="$1"
    local key="$2"

    if command -v jq >/dev/null 2>&1; then
        local raw
        raw=$(jq -r ".${key} // empty" "$json_file" 2>/dev/null || true)
        if [ -n "$raw" ]; then
            echo "$raw"
        fi
    else
        # Fallback: extract from raw JSON
        if grep -q "\"$key\"" "$json_file" 2>/dev/null; then
            grep -A 1 "\"$key\"" "$json_file" | grep -v "^--$" | tail -n 1 | sed 's/.*: *"\(.*\)".*/\1/' | sed 's/^ *"//;s/" *,*$//'
        fi
    fi
}

is_install_command() {
    local cmd="$1"
    local install_patterns="npm install|npm ci|yarn install|pnpm install|bun install|pip install|pipenv install|poetry install|uv sync|cargo build|bundle install|go mod download|composer install|mvn dependency:resolve|mvn install|gradle build|dotnet restore"

    if echo "$cmd" | grep -qiE "$install_patterns"; then
        return 0
    fi
    return 1
}

analyze() {
    local json_file="$1"
    local workspace_dir="$2"

    local on_create update_content post_create post_start
    on_create=$(parse_lifecycle_command "$json_file" "onCreateCommand" || true)
    update_content=$(parse_lifecycle_command "$json_file" "updateContentCommand" || true)
    post_create=$(parse_lifecycle_command "$json_file" "postCreateCommand" || true)
    post_start=$(parse_lifecycle_command "$json_file" "postStartCommand" || true)

    # Scan for lockfiles
    local detected=""
    detected=$(scan_lockfiles "$workspace_dir" "$DETECT_LANGUAGES")

    echo ""
    echo "Prebuild Lifecycle Audit Report"
    echo "==============================="
    echo "Workspace: $workspace_dir"
    echo "Config:    $json_file"
    echo ""

    # Report detected languages
    if [ -n "$detected" ]; then
        echo "Detected Languages (from lockfiles):"
        echo "$detected" | while IFS='|' read -r lang install_cmd lockfile; do
            echo "  - $lang: $lockfile → $install_cmd"
        done
        echo ""
    else
        echo "No lockfiles detected."
        echo ""
    fi

    # Report current lifecycle hooks
    echo "Current Lifecycle Hooks:"
    [ -n "$on_create" ] && echo "  onCreateCommand:       $on_create"
    [ -n "$update_content" ] && echo "  updateContentCommand:  $update_content"
    [ -n "$post_create" ] && echo "  postCreateCommand:     $post_create"
    [ -n "$post_start" ] && echo "  postStartCommand:      $post_start"
    echo ""

    # Check for misplaced install commands
    local issues_found=false

    for hook_name in "onCreateCommand" "postCreateCommand" "postStartCommand"; do
        local hook_val=""
        case "$hook_name" in
            onCreateCommand) hook_val="$on_create" ;;
            postCreateCommand) hook_val="$post_create" ;;
            postStartCommand) hook_val="$post_start" ;;
        esac

        if [ -n "$hook_val" ] && is_install_command "$hook_val"; then
            echo "⚠️  $hook_name contains a dependency installation: '$hook_val'"
            echo "    → Move to updateContentCommand for prebuild optimization"
            echo ""
            WARNINGS=$((WARNINGS + 1))
            issues_found=true
        fi
    done

    # Check if updateContentCommand is missing when we have detected languages
    if [ -n "$detected" ] && [ -z "$update_content" ]; then
        echo "ℹ️  No updateContentCommand found but lockfiles detected."
        echo "    → Add updateContentCommand to cache dependencies in prebuild snapshots"
        echo ""
        WARNINGS=$((WARNINGS + 1))
        issues_found=true
    fi

    # Check if detected install commands match what's in lifecycle hooks
    if [ -n "$detected" ]; then
        echo "$detected" | while IFS='|' read -r lang install_cmd lockfile; do
            local actual_cmd
            actual_cmd=$(get_install_command "$lang" "$workspace_dir")
            local found_in_hook=""

            for hook_name in "onCreateCommand" "postCreateCommand" "postStartCommand"; do
                local hook_val=""
                case "$hook_name" in
                    onCreateCommand) hook_val="$on_create" ;;
                    postCreateCommand) hook_val="$post_create" ;;
                    postStartCommand) hook_val="$post_start" ;;
                esac
                if [ -n "$hook_val" ] && echo "$hook_val" | grep -qiF "$actual_cmd"; then
                    found_in_hook="$hook_name"
                    break
                fi
            done

            if [ -n "$found_in_hook" ] && [ "$found_in_hook" != "updateContentCommand" ]; then
                echo "⚠️  $lang dependency install '$actual_cmd' found in $found_in_hook"
                echo "    → Move to updateContentCommand to leverage prebuild caching"
                echo ""
            elif [ -z "$found_in_hook" ] && [ -z "$update_content" ]; then
                echo "ℹ️  $lang detected with lockfile but no matching lifecycle command found"
                echo "    → Consider adding '$actual_cmd' to updateContentCommand"
                echo ""
            fi
        done
    fi

    if [ "$issues_found" = false ] && [ -z "$detected" ] && [ -z "$on_create" ] && [ -z "$post_create" ] && [ -z "$post_start" ]; then
        echo "✅  No lifecycle hooks configured and no lockfiles detected."
        echo "    Nothing to optimize."
    elif [ "$issues_found" = false ]; then
        echo "✅  Lifecycle commands are prebuild-optimized or no issues detected."
    fi

    echo ""
    echo "Prebuild Optimization Notes:"
    echo "  • updateContentCommand runs during prebuild creation → frozen in snapshot"
    echo "  • postCreateCommand/postStartCommand run at connect time → slower cold start"
    echo "  • Proper placement can reduce cold start from minutes to seconds"
    echo ""

    # Fix mode
    if [ "$FIX_MODE" = "true" ] && [ "$WARNINGS" -gt 0 ]; then
        apply_fixes "$json_file" "$workspace_dir" "$on_create" "$update_content" "$post_create" "$post_start"
    fi
}

apply_fixes() {
    local json_file="$1"
    local workspace_dir="$2"
    local on_create="$3"
    local update_content="$4"
    local post_create="$5"
    local post_start="$6"

    if ! command -v jq >/dev/null 2>&1; then
        echo "❌  Cannot apply fixes: jq is not available. Install jq and retry."
        return 1
    fi

    echo "🔧  Fix mode enabled. Applying optimizations..."

    local backup_file="${json_file}.prebuild-backup"
    cp "$json_file" "$backup_file"
    echo "    Backup created: $backup_file"

    local new_update=""
    local new_post_create=""
    local new_on_create=""
    local new_post_start=""

    # Collect install commands from wrong hooks
    local install_cmds=""

    for hook_val in "$on_create" "$post_create" "$post_start"; do
        if [ -n "$hook_val" ] && is_install_command "$hook_val"; then
            if [ -z "$install_cmds" ]; then
                install_cmds="$hook_val"
            else
                install_cmds="$install_cmds && $hook_val"
            fi
        fi
    done

    # Build new updateContentCommand
    if [ -n "$update_content" ]; then
        if [ -n "$install_cmds" ]; then
            new_update="$update_content && $install_cmds"
        else
            new_update="$update_content"
        fi
    else
        new_update="$install_cmds"
    fi

    # Build non-install commands for other hooks
    build_non_install_hook() {
        local original="$1"
        local result=""
        if [ -n "$original" ] && ! is_install_command "$original"; then
            result="$original"
        fi
        echo "$result"
    }

    new_on_create=$(build_non_install_hook "$on_create")
    new_post_create=$(build_non_install_hook "$post_create")
    new_post_start=$(build_non_install_hook "$post_start")

    # Apply changes with jq
    local tmp_json="${json_file}.tmp"

    jq --arg update "$new_update" \
       --arg oncreate "$new_on_create" \
       --arg postcreate "$new_post_create" \
       --arg poststart "$new_post_start" '
        .updateContentCommand = $update
        | if $oncreate != "" then .onCreateCommand = $oncreate else del(.onCreateCommand) end
        | if $postcreate != "" then .postCreateCommand = $postcreate else del(.postCreateCommand) end
        | if $poststart != "" then .postStartCommand = $poststart else del(.postStartCommand) end
    ' "$json_file" > "$tmp_json" && mv "$tmp_json" "$json_file"

    echo "    ✅  devcontainer.json updated"
    echo ""
    echo "    Changes applied:"
    [ -n "$new_update" ] && echo "      updateContentCommand: $new_update"
    [ -n "$new_on_create" ] && echo "      onCreateCommand: $new_on_create"
    [ -n "$new_post_create" ] && echo "      postCreateCommand: $new_post_create"
    [ -n "$new_post_start" ] && echo "      postStartCommand: $new_post_start"
    echo ""
}

# Main
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: prebuild-audit [--fix] [--lang auto,node,python,...] [path/to/devcontainer.json]"
    echo ""
    echo "Analyzes devcontainer.json lifecycle commands for prebuild optimization."
    echo ""
    echo "Options:"
    echo "  --fix          Rewrite devcontainer.json to move installs to updateContentCommand"
    echo "  --lang         Comma-separated language filter (auto for all)"
    echo "  --help         Show this help"
    echo ""
    echo "Exit codes: 0 = clean, 1 = warnings found, 2 = error"
    exit 0
fi

# Parse CLI args
while [ $# -gt 0 ]; do
    case "$1" in
        --fix)
            FIX_MODE="true"
            shift
            ;;
        --lang)
            DETECT_LANGUAGES="$2"
            shift 2
            ;;
        *)
            if [ -z "$DEVCONTAINER_JSON" ] && [ -f "$1" ]; then
                DEVCONTAINER_JSON="$1"
            fi
            shift
            ;;
    esac
done

# Auto-discover devcontainer.json if not provided
if [ -z "$DEVCONTAINER_JSON" ]; then
    DEVCONTAINER_JSON=$(find_devcontainer_json || true)
fi

if [ -z "$DEVCONTAINER_JSON" ] || [ ! -f "$DEVCONTAINER_JSON" ]; then
    echo "INFO [prebuild-audit]: No devcontainer.json found; nothing to audit."
    echo ""
    echo "Searched locations:"
    echo "  /workspaces/*/devcontainer.json"
    echo "  /workspaces/*/.devcontainer/devcontainer.json"
    echo "  /workspace/.devcontainer/devcontainer.json"
    echo ""
    echo "Provide a path explicitly: prebuild-audit /path/to/devcontainer.json"
    exit 0
fi

WORKSPACE_DIR=$(dirname "$DEVCONTAINER_JSON")
if [ "$(basename "$WORKSPACE_DIR")" = ".devcontainer" ]; then
    WORKSPACE_DIR=$(dirname "$WORKSPACE_DIR")
fi

analyze "$DEVCONTAINER_JSON" "$WORKSPACE_DIR"

if [ "$WARNINGS" -gt 0 ]; then
    echo "WARNING [prebuild-audit]: $WARNINGS optimization opportunity(s) detected."
    exit 1
else
    echo "INFO [prebuild-audit]: No optimization issues found."
    exit 0
fi
AUDIT_EOF

chmod +x /usr/local/bin/prebuild-audit

# Create backward-compatible wrapper
cat > /usr/local/bin/prebuild-lifecycle-helper <<'WRAPPER_EOF'
#!/bin/bash
# Backward-compatible wrapper for prebuild-audit
export FAIL_ON_WARNING="${FAILONWARNING:-false}"
export FIX_MODE="${FIXMODE:-false}"
export DETECT_LANGUAGES="${DETECTLANGUAGES:-auto}"

# Run the audit
/usr/local/bin/prebuild-audit "$@"
WRAPPER_EOF

chmod +x /usr/local/bin/prebuild-lifecycle-helper

# Also run at install time if requested
if [ "$FAIL_ON_WARNING" = "true" ] || [ "$FIX_MODE" = "true" ]; then
    echo "Running prebuild-audit with configured options..."
    export FIX_MODE
    export DETECT_LANGUAGES
    export FAIL_ON_WARNING
    /usr/local/bin/prebuild-audit || {
        if [ "$FAIL_ON_WARNING" = "true" ] && [ $? -eq 1 ]; then
            echo "ERROR [prebuild-lifecycle-helper]: Audit failed with warnings and failOnWarning is enabled."
            exit 1
        fi
    }
fi

echo "prebuild-lifecycle-helper v0.2.0 installed."
echo "  Tools: prebuild-audit, prebuild-lifecycle-helper"
echo "  Run 'prebuild-audit --help' for usage."
