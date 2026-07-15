#!/bin/sh
set -e

# implement.sh — Trigger ralph-loop for open AFK tickets.
# Usage: implement.sh [ticket-id]
# Env: MAX_TICKETS_PER_CYCLE defaults to 3

PROJECT_ROOT="${PWD}"
TICKETS_DIR="${PROJECT_ROOT}/wayfinder/tickets"
RALPH_DIR="${PROJECT_ROOT}/.ralph"
MAX_TICKETS="${MAX_TICKETS_PER_CYCLE:-3}"

run_ticket() {
    local ticket_file="$1"
    local ticket_id
    local ticket_title
    local ticket_branch
    ticket_id="$(grep -E '^id:' "$ticket_file" | sed 's/id: *//' | head -1)"
    ticket_title="$(grep -E '^title:' "$ticket_file" | sed 's/title: *//' | head -1)"
    ticket_branch="$(grep -E '^branch:' "$ticket_file" | sed 's/branch: *//' | head -1)"

    echo "=== Implementing $ticket_id: $ticket_title ==="

    # Update status to in-progress
    sed -i 's/^status: open/status: in-progress/' "$ticket_file"

    # Create branch
    git checkout -b "$ticket_branch" 2>/dev/null || git checkout "$ticket_branch"

    # Run ralph loop
    if [ -f ".devcontainer/sandcastle/ralph-loop.sh" ]; then
        bash ".devcontainer/sandcastle/ralph-loop.sh" "$ticket_id" "$ticket_branch" 1 || {
            echo "WARNING: ralph-loop failed for $ticket_id"
            sed -i 's/^status: in-progress/status: failed/' "$ticket_file"
            return 1
        }
    else
        echo "WARNING: ralph-loop.sh not found. Manual execution required."
        sed -i 's/^status: in-progress/status: blocked/' "$ticket_file"
        return 1
    fi

    # Update status to pending-review
    sed -i 's/^status: in-progress/status: pending-review/' "$ticket_file"
    echo "$ticket_id moved to pending-review."
}

if [ ! -d "$TICKETS_DIR" ]; then
    echo "ERROR: Tickets directory not found: $TICKETS_DIR"
    exit 1
fi

if [ -n "${1:-}" ]; then
    # Single ticket mode
    TICKET_ID="$1"
    TICKET_FILE="${TICKETS_DIR}/${TICKET_ID}-*.md"
    if ! ls $TICKET_FILE > /dev/null 2>&1; then
        echo "ERROR: Ticket $TICKET_ID not found"
        exit 1
    fi
    TICKET_FILE="$(ls $TICKET_FILE | head -1)"
    run_ticket "$TICKET_FILE"
else
    # Auto-select next unblocked open AFK tickets
    count=0
    for ticket in "$TICKETS_DIR"/T*.md; do
        [ -f "$ticket" ] || continue
        status="$(grep -E '^status:' "$ticket" | sed 's/status: *//' || echo "unknown")"
        type="$(grep -E '^type:' "$ticket" | sed 's/type: *//' || echo "unknown")"
        if [ "$status" = "open" ] && [ "$type" = "afk" ]; then
            blocked_by="$(grep -E '^blockedBy:' "$ticket" | sed 's/blockedBy: *//' | tr -d '[]' || echo "")"
            blocked=false
            for dep in $(echo "$blocked_by" | tr ',' ' '); do
                [ -z "$dep" ] && continue
                dep_file="${TICKETS_DIR}/${dep}-*.md"
                if ls $dep_file > /dev/null 2>&1; then
                    dep_file="$(ls $dep_file | head -1)"
                    dep_status="$(grep -E '^status:' "$dep_file" | sed 's/status: *//' || echo "unknown")"
                    if [ "$dep_status" != "complete" ] && [ "$dep_status" != "pending-review" ]; then
                        blocked=true
                        break
                    fi
                fi
            done
            if [ "$blocked" = "false" ]; then
                run_ticket "$ticket"
                count=$((count + 1))
                if [ "$count" -ge "$MAX_TICKETS" ]; then
                    echo "Reached MAX_TICKETS_PER_CYCLE ($MAX_TICKETS). Stopping."
                    break
                fi
            fi
        fi
    done
    if [ "$count" -eq 0 ]; then
        echo "No unblocked open AFK tickets found."
    fi
fi
