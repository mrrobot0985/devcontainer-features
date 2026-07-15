#!/usr/bin/env bash
set -euo pipefail

# Sandcastle Bootstrap
# Usage: bash .devcontainer/sandcastle/bootstrap.sh [init|hitl|afk|verify|auto]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDCASTLE_DIR="${SCRIPT_DIR}"
RALPH_DIR="${SANDCASTLE_DIR}/.ralph"
STATE_FILE="${RALPH_DIR}/state.json"
LOG_FILE="${RALPH_DIR}/logs/bootstrap.log"
RUNNER="${SANDCASTLE_DIR}/runner.mjs"

# Ensure directories exist
mkdir -p "${RALPH_DIR}/logs"

log() {
    local msg="[$(date -Iseconds)] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

read_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo '{"phase":"discover","iteration":0,"maxIterations":10,"lastRun":null,"currentEffort":null,"resolvedTickets":[],"failedTickets":[],"degradedPrototype":false}'
    fi
}

write_state() {
    local phase="$1"
    local iteration="$2"
    local current_effort="$3"
    jq -n \
        --arg phase "$phase" \
        --argjson iteration "$iteration" \
        --arg currentEffort "$current_effort" \
        --arg lastRun "$(date -Iseconds)" \
        --argjson existing "$(read_state)" \
        '$existing + {phase: $phase, iteration: $iteration, currentEffort: $current_effort, lastRun: $lastRun}' > "$STATE_FILE"
}

discover_phase() {
    log "=== DISCOVER ==="
    local scratch_dir=".scratch"
    if [ ! -d "$scratch_dir" ]; then
        log "No .scratch directory found. Running local-markdown-tracker setup..."
        # Scaffold tracker if not present
        if command -v claude >/dev/null 2>&1; then
            claude --no-interactive --skill ~/.claude/skills/local-markdown-tracker/SKILL.md 2>&1 || true
        else
            log "WARNING: claude CLI not available. Creating minimal .scratch/ structure."
            mkdir -p "$scratch_dir"
        fi
    fi

    local maps
    maps=$(find "$scratch_dir" -name "map.md" 2>/dev/null || true)
    if [ -z "$maps" ]; then
        log "No wayfinder maps found. Need to create a spec first."
        write_state "spec" 0 ""
        return
    fi

    # Pick the most recently modified map
    local latest_map
    latest_map=$(echo "$maps" | xargs -I{} sh -c 'echo "$(stat -c %Y {} 2>/dev/null || stat -f %m {}) {}"' | sort -rn | head -1 | awk '{print $2}')
    local effort_dir
    effort_dir="$(dirname "$latest_map")"
    local effort_slug
    effort_slug="$(basename "$effort_dir")"

    log "Found effort: $effort_slug"
    write_state "map" 0 "$effort_slug"
}

spec_phase() {
    log "=== SPEC ==="
    local effort_slug
    effort_slug=$(jq -r '.currentEffort // empty' "$STATE_FILE" 2>/dev/null || true)

    if [ -z "$effort_slug" ]; then
        # Derive effort slug from repo name or ask
        effort_slug="$(basename "$(pwd)")"
        log "No effort set. Using repo name: $effort_slug"
    fi

    local spec_path=".scratch/${effort_slug}/spec.md"
    if [ -f "$spec_path" ]; then
        log "Spec already exists at $spec_path"
        write_state "map" 0 "$effort_slug"
        return
    fi

    log "Creating spec via to-spec-headless..."
    if command -v claude >/dev/null 2>&1; then
        claude --no-interactive --skill ~/.claude/skills/to-spec-headless/SKILL.md "$effort_slug" 2>&1 || {
            log "ERROR: to-spec-headless failed"
            write_state "failed" 0 "$effort_slug"
            return
        }
    else
        log "WARNING: claude CLI not available. Creating placeholder spec."
        mkdir -p ".scratch/${effort_slug}"
        cat > "$spec_path" << EOF
# Spec: ${effort_slug}

## Problem Statement

<To be filled by to-spec-headless>

## Solution

<To be filled by to-spec-headless>

## User Stories

1. As a developer, I want automated sandcastle lifecycle, so that projects self-drive from inception to maintenance

## Implementation Decisions

- Use local-markdown tracker (\`.scratch/\`)
- Custom headless skills for AFK mode
- Deterministic scripts for state transitions

## Testing Decisions

- End-to-end: create empty dir → run auto → verify spec exists

## Status

Status: needs-triage
EOF
    fi

    if [ -f "$spec_path" ]; then
        log "Spec created at $spec_path"
        write_state "map" 0 "$effort_slug"
    else
        log "ERROR: Spec was not created"
        write_state "failed" 0 "$effort_slug"
    fi
}

map_phase() {
    log "=== MAP ==="
    local effort_slug
    effort_slug=$(jq -r '.currentEffort // empty' "$STATE_FILE" 2>/dev/null || true)
    if [ -z "$effort_slug" ]; then
        log "ERROR: No current effort in state"
        write_state "discover" 0 ""
        return
    fi

    local map_path=".scratch/${effort_slug}/map.md"
    if [ -f "$map_path" ]; then
        log "Map already exists at $map_path"
        write_state "ticket" 0 "$effort_slug"
        return
    fi

    log "Creating wayfinder map via wayfinder-headless..."
    if command -v claude >/dev/null 2>&1; then
        claude --no-interactive --skill ~/.claude/skills/wayfinder-headless/SKILL.md "$effort_slug" 2>&1 || {
            log "ERROR: wayfinder-headless failed"
            write_state "failed" 0 "$effort_slug"
            return
        }
    else
        log "WARNING: claude CLI not available. Creating placeholder map."
        mkdir -p ".scratch/${effort_slug}/issues"
        cat > "$map_path" << EOF
# Wayfinder: ${effort_slug}

## Destination

Automated sandcastle lifecycle from inception to maintenance.

## Notes

- Domain: devcontainer automation
- Skills: local-markdown-tracker, to-spec-headless, wayfinder-headless, to-tickets-headless, implement-headless, code-review-headless

## Decisions so far

## Not yet specified

## Out of scope
EOF
    fi

    if [ -f "$map_path" ]; then
        log "Map created at $map_path"
        write_state "ticket" 0 "$effort_slug"
    else
        log "ERROR: Map was not created"
        write_state "failed" 0 "$effort_slug"
    fi
}

ticket_phase() {
    log "=== TICKET ==="
    local effort_slug
    effort_slug=$(jq -r '.currentEffort // empty' "$STATE_FILE" 2>/dev/null || true)
    if [ -z "$effort_slug" ]; then
        log "ERROR: No current effort in state"
        write_state "discover" 0 ""
        return
    fi

    local issues_dir=".scratch/${effort_slug}/issues"
    if [ -d "$issues_dir" ] && [ "$(ls -A "$issues_dir" 2>/dev/null)" ]; then
        log "Tickets already exist in $issues_dir"
        write_state "implement" 0 "$effort_slug"
        return
    fi

    log "Creating tickets via to-tickets-headless..."
    if command -v claude >/dev/null 2>&1; then
        claude --no-interactive --skill ~/.claude/skills/to-tickets-headless/SKILL.md "$effort_slug" 2>&1 || {
            log "ERROR: to-tickets-headless failed"
            write_state "failed" 0 "$effort_slug"
            return
        }
    else
        log "WARNING: claude CLI not available. Creating placeholder tickets."
        mkdir -p "$issues_dir"
        cat > "${issues_dir}/01-first-ticket.md" << EOF
Status: open
Type: task
Blocked by:

## Title

First implementation ticket

## What it delivers

A minimal working end-to-end slice.

## Spec references

- Problem Statement

## Acceptance criteria

- Code compiles/parses
- Tests pass
- Committed with conventional message
EOF
    fi

    if [ -d "$issues_dir" ] && [ "$(ls -A "$issues_dir" 2>/dev/null)" ]; then
        log "Tickets created in $issues_dir"
        write_state "implement" 0 "$effort_slug"
    else
        log "ERROR: Tickets were not created"
        write_state "failed" 0 "$effort_slug"
    fi
}

implement_phase() {
    log "=== IMPLEMENT ==="
    local effort_slug
    effort_slug=$(jq -r '.currentEffort // empty' "$STATE_FILE" 2>/dev/null || true)
    if [ -z "$effort_slug" ]; then
        log "ERROR: No current effort in state"
        write_state "discover" 0 ""
        return
    fi

    local max_iterations
    max_iterations=$(jq -r '.maxIterations // 10' "$STATE_FILE")
    local iteration
    iteration=$(jq -r '.iteration // 0' "$STATE_FILE")

    if [ "$iteration" -ge "$max_iterations" ]; then
        log "Max iterations ($max_iterations) reached. Stopping auto-mode."
        write_state "verify" "$iteration" "$effort_slug"
        return
    fi

    log "Finding frontier tickets for effort: $effort_slug (iteration $iteration/$max_iterations)"

    if [ -x "$RUNNER" ] || [ -f "$RUNNER" ]; then
        node "$RUNNER" implement "$effort_slug" 2>&1 || {
            log "ERROR: runner.mjs implement failed"
            write_state "failed" "$iteration" "$effort_slug"
            return
        }
    else
        log "WARNING: runner.mjs not found at $RUNNER"
        # Minimal fallback: find first open unblocked ticket and echo
        local issues_dir=".scratch/${effort_slug}/issues"
        if [ -d "$issues_dir" ]; then
            for ticket in "$issues_dir"/*.md; do
                [ -f "$ticket" ] || continue
                local status blocked_by
                status=$(grep -m1 '^Status:' "$ticket" | sed 's/Status: *//' || true)
                blocked_by=$(grep -m1 '^Blocked by:' "$ticket" | sed 's/Blocked by: *//' || true)
                if [ "$status" = "open" ] && [ -z "$blocked_by" ]; then
                    log "Found frontier ticket: $(basename "$ticket")"
                    log "Manual intervention required — runner.mjs not available"
                    break
                fi
            done
        fi
    fi

    iteration=$((iteration + 1))
    write_state "implement" "$iteration" "$effort_slug"

    # Check if any open tickets remain
    local remaining
    remaining=$(node "$RUNNER" frontier-count "$effort_slug" 2>/dev/null || echo "0")
    if [ "$remaining" = "0" ]; then
        log "No more frontier tickets. Moving to review phase."
        write_state "review" "$iteration" "$effort_slug"
    fi
}

review_phase() {
    log "=== REVIEW ==="
    local effort_slug
    effort_slug=$(jq -r '.currentEffort // empty' "$STATE_FILE" 2>/dev/null || true)
    if [ -z "$effort_slug" ]; then
        log "ERROR: No current effort in state"
        write_state "discover" 0 ""
        return
    fi

    log "Running code-review-headless..."
    if command -v claude >/dev/null 2>&1; then
        claude --no-interactive --skill ~/.claude/skills/code-review-headless/SKILL.md "$effort_slug" 2>&1 || {
            log "WARNING: code-review-headless failed, but proceeding"
        }
    else
        log "WARNING: claude CLI not available. Skipping review."
    fi

    write_state "verify" 0 "$effort_slug"
}

verify_phase() {
    log "=== VERIFY ==="
    local effort_slug
    effort_slug=$(jq -r '.currentEffort // empty' "$STATE_FILE" 2>/dev/null || true)
    if [ -z "$effort_slug" ]; then
        log "ERROR: No current effort in state"
        write_state "discover" 0 ""
        return
    fi

    log "Verifying branch state..."
    if [ -x "${SANDCASTLE_DIR}/validate-branch.sh" ]; then
        bash "${SANDCASTLE_DIR}/validate-branch.sh" 2>&1 || {
            log "WARNING: validate-branch.sh failed"
        }
    else
        log "WARNING: validate-branch.sh not found"
    fi

    log "Auto-mode cycle complete for effort: $effort_slug"
    log "Run 'bash .devcontainer/sandcastle/bootstrap.sh auto' to continue if more work exists."
    write_state "done" 0 "$effort_slug"
}

failed_phase() {
    log "=== FAILED ==="
    log "Previous phase failed. Check logs at ${LOG_FILE}"
    log "State: $(cat "$STATE_FILE")"
    exit 1
}

auto_mode() {
    log "=== AUTO MODE START ==="
    local state phase
    state=$(read_state)
    phase=$(echo "$state" | jq -r '.phase // "discover"')

    log "Current phase: $phase"

    case "$phase" in
        discover) discover_phase ;;
        spec) spec_phase ;;
        map) map_phase ;;
        ticket) ticket_phase ;;
        implement) implement_phase ;;
        review) review_phase ;;
        verify) verify_phase ;;
        done)
            log "Previous auto-mode completed. Restarting from discover..."
            write_state "discover" 0 ""
            discover_phase
            ;;
        failed) failed_phase ;;
        *)
            log "Unknown phase: $phase. Resetting to discover."
            write_state "discover" 0 ""
            discover_phase
            ;;
    esac

    log "=== AUTO MODE END ==="
}

# Main entry point
case "${1:-}" in
    init)
        log "=== INIT ==="
        write_state "discover" 0 ""
        discover_phase
        ;;
    hitl)
        log "=== HITL ==="
        log "Human-in-the-loop mode not implemented in this version."
        ;;
    afk)
        log "=== AFK ==="
        auto_mode
        ;;
    verify)
        verify_phase
        ;;
    auto)
        auto_mode
        ;;
    *)
        echo "Usage: $0 {init|hitl|afk|verify|auto}"
        echo ""
        echo "  init   — Scaffold .scratch/ and discover effort"
        echo "  hitl   — Human-in-the-loop mode (not implemented)"
        echo "  afk    — Away-from-keyboard mode (alias for auto)"
        echo "  verify — Validate branch and review"
        echo "  auto   — Self-driving lifecycle: discover → spec → map → ticket → implement → review → verify"
        exit 1
        ;;
esac
