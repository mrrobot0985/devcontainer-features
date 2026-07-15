#!/bin/sh
set -e

# code-review.sh — Multi-perspective review for pending-review tickets.
# Usage: code-review.sh [ticket-id]
# Env: AUTO_MERGE=false (set true to auto-merge approved tickets)

PROJECT_ROOT="${PWD}"
TICKETS_DIR="${PROJECT_ROOT}/wayfinder/tickets"
REVIEWS_DIR="${PROJECT_ROOT}/.ralph/reviews"
AUTO_MERGE="${AUTO_MERGE:-false}"

review_ticket() {
    local ticket_file="$1"
    local ticket_id
    local ticket_branch
    local review_file
    ticket_id="$(grep -E '^id:' "$ticket_file" | sed 's/id: *//' | head -1)"
    ticket_branch="$(grep -E '^branch:' "$ticket_file" | sed 's/branch: *//' | head -1)"
    review_file="${REVIEWS_DIR}/${ticket_id}.md"

    echo "=== Reviewing $ticket_id ==="

    # Run validate-branch.sh if available
    local validate_ok=true
    if [ -f ".devcontainer/sandcastle/validate-branch.sh" ]; then
        bash ".devcontainer/sandcastle/validate-branch.sh" "$ticket_branch" "$PROJECT_ROOT" || validate_ok=false
    fi

    # Run review perspectives
    local correctness_ok=true
    local architecture_ok=true
    local safety_ok=true

    local script_dir
    script_dir="$(dirname "$0")"
    if [ -f "$script_dir/review-correctness.sh" ]; then
        bash "$script_dir/review-correctness.sh" "$ticket_branch" "$PROJECT_ROOT" || correctness_ok=false
    fi
    if [ -f "$script_dir/review-architecture.sh" ]; then
        bash "$script_dir/review-architecture.sh" "$ticket_branch" "$PROJECT_ROOT" || architecture_ok=false
    fi
    if [ -f "$script_dir/review-safety.sh" ]; then
        bash "$script_dir/review-safety.sh" "$ticket_branch" "$PROJECT_ROOT" || safety_ok=false
    fi

    # Write review report
    {
        echo "# Review Report: ${ticket_id}"
        echo ""
        echo "| Perspective | Status |"
        echo "|-------------|--------|"
        echo "| Validation  | $(if [ "$validate_ok" = true ]; then echo "PASS"; else echo "FAIL"; fi) |"
        echo "| Correctness | $(if [ "$correctness_ok" = true ]; then echo "PASS"; else echo "FAIL"; fi) |"
        echo "| Architecture| $(if [ "$architecture_ok" = true ]; then echo "PASS"; else echo "FAIL"; fi) |"
        echo "| Safety      | $(if [ "$safety_ok" = true ]; then echo "PASS"; else echo "FAIL"; fi) |"
        echo ""
        echo "## Summary"
        echo ""
    } > "$review_file"

    if [ "$validate_ok" = true ] && [ "$correctness_ok" = true ] && [ "$architecture_ok" = true ] && [ "$safety_ok" = true ]; then
        echo "All checks passed. Approving $ticket_id."
        sed -i 's/^status: pending-review/status: approved/' "$ticket_file"
        if [ "$AUTO_MERGE" = "true" ]; then
            echo "AUTO_MERGE=true — merging $ticket_branch to main."
            git checkout main
            git merge --no-ff "$ticket_branch" -m "merge(${ticket_id}): approved via code-review"
            sed -i 's/^status: approved/status: complete/' "$ticket_file"
        fi
    else
        echo "Review failed for $ticket_id. See $review_file"
        sed -i 's/^status: pending-review/status: changes-requested/' "$ticket_file"
    fi
}

mkdir -p "$REVIEWS_DIR"

if [ -n "${1:-}" ]; then
    TICKET_ID="$1"
    TICKET_FILE="${TICKETS_DIR}/${TICKET_ID}-*.md"
    if ! ls $TICKET_FILE > /dev/null 2>&1; then
        echo "ERROR: Ticket $TICKET_ID not found"
        exit 1
    fi
    TICKET_FILE="$(ls $TICKET_FILE | head -1)"
    review_ticket "$TICKET_FILE"
else
    for ticket in "$TICKETS_DIR"/T*.md; do
        [ -f "$ticket" ] || continue
        status="$(grep -E '^status:' "$ticket" | sed 's/status: *//' || echo "unknown")"
        if [ "$status" = "pending-review" ]; then
            review_ticket "$ticket"
        fi
    done
fi
