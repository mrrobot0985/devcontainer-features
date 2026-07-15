#!/usr/bin/env bash
set -euo pipefail

# Ralph Loop
# Runs runner.mjs in a Docker container for isolation, then commits results.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDCASTLE_DIR="${SCRIPT_DIR}"
RALPH_DIR="${SANDCASTLE_DIR}/.ralph"
LOG_FILE="${RALPH_DIR}/logs/ralph.log"
RUNNER="${SANDCASTLE_DIR}/runner.mjs"
BOOTSTRAP="${SANDCASTLE_DIR}/bootstrap.sh"

mkdir -p "${RALPH_DIR}/logs"

log() {
    local msg="[$(date -Iseconds)] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

# Determine which Dockerfiles exist
DOCKERFILES=()
for f in "${SANDCASTLE_DIR}/Dockerfile."{architecture,correctness,safety}; do
    [ -f "$f" ] && DOCKERFILES+=("$f")
done

if [ ${#DOCKERFILES[@]} -eq 0 ]; then
    log "No Dockerfiles found in ${SANDCASTLE_DIR}. Running locally."
    if [ -x "$BOOTSTRAP" ]; then
        bash "$BOOTSTRAP" auto
    else
        log "ERROR: bootstrap.sh not found at ${BOOTSTRAP}"
        exit 1
    fi
    exit 0
fi

# Run each perspective in parallel containers
PIDS=()
for df in "${DOCKERFILES[@]}"; do
    tag="sandcastle-$(basename "$df" | sed 's/Dockerfile\.//')"
    log "Building ${tag} from ${df}..."
    docker build -f "$df" -t "$tag" . > "${RALPH_DIR}/logs/${tag}.build.log" 2>&1 && {
        log "Running ${tag}..."
        docker run --rm \
            -v "$(pwd):/workspace" \
            -w /workspace \
            -e SANDCASTLE_DEGRADED_PROTOTYPE="${SANDCASTLE_DEGRADED_PROTOTYPE:-false}" \
            "$tag" \
            bash .devcontainer/sandcastle/bootstrap.sh auto \
            > "${RALPH_DIR}/logs/${tag}.run.log" 2>&1 &
        PIDS+=("$!")
    } || {
        log "ERROR: Failed to build ${tag}"
    }
done

if [ ${#PIDS[@]} -gt 0 ]; then
    log "Waiting for ${#PIDS[@]} parallel container(s)..."
    for pid in "${PIDS[@]}"; do
        wait "$pid" || log "Container exited with error (pid $pid)"
    done
fi

log "Ralph loop iteration complete"

# Commit state changes if anything changed
if git diff --quiet .ralph/ 2>/dev/null; then
    log "No state changes to commit"
else
    git add .ralph/
    git commit -m "chore(sandcastle): ralph loop state update" || true
    log "Committed state changes"
fi
