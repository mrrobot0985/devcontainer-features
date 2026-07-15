#!/bin/sh
set -e

# to-tickets.sh — Convert SPEC.md into ticket files.
# Usage: to-tickets.sh [project-root]
# Env: FORCE=true to overwrite existing tickets

PROJECT_ROOT="${1:-.}"
SPEC_FILE="${PROJECT_ROOT}/SPEC.md"
WAYFINDER_FILE="${PROJECT_ROOT}/WAYFINDER.md"
TICKETS_DIR="${PROJECT_ROOT}/wayfinder/tickets"
FORCE="${FORCE:-false}"

if [ ! -f "$SPEC_FILE" ]; then
    echo "ERROR: SPEC.md not found at $SPEC_FILE"
    exit 1
fi

mkdir -p "$TICKETS_DIR"

# Extract actionable headings from SPEC.md
# Use simple heuristics: H3/H4 under Milestones or Implementation
counter=1
in_milestones=false
while IFS= read -r line; do
    case "$line" in
        "## Milestones"*|"### Milestones"*|"## Implementation"*) in_milestones=true ;;
        "## "*) in_milestones=false ;;
    esac
    if [ "$in_milestones" = "true" ] && echo "$line" | grep -qE '^#{3,4} '; then
        title="$(echo "$line" | sed 's/^#* *//')"
        slug="$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-$//')"
        ticket_id="$(printf 'T%03d' "$counter")"
        ticket_file="${TICKETS_DIR}/${ticket_id}-${slug}.md"

        if [ -f "$ticket_file" ] && [ "$FORCE" != "true" ]; then
            echo "SKIP: $ticket_file exists (set FORCE=true to overwrite)"
            counter=$((counter + 1))
            continue
        fi

        cat > "$ticket_file" <<EOF
---
id: ${ticket_id}
title: ${title}
status: open
priority: medium
type: afk
branch: feat/${ticket_id}-${slug}
blockedBy: []
---

# ${ticket_id}: ${title}

## Description

Derived from SPEC.md section: "${title}".

## Acceptance Criteria

- [ ] TODO: define acceptance criteria

## Notes

<!-- Implementation notes, research findings, etc. -->
EOF
        echo "Created: $ticket_file"
        counter=$((counter + 1))
    fi
done < "$SPEC_FILE"

# Update WAYFINDER.md ticket list if it exists
if [ -f "$WAYFINDER_FILE" ]; then
    # Simple append of ticket list
    if ! grep -q "## Tickets" "$WAYFINDER_FILE"; then
        echo "" >> "$WAYFINDER_FILE"
        echo "## Tickets" >> "$WAYFINDER_FILE"
        echo "" >> "$WAYFINDER_FILE"
    fi
fi

echo "Tickets created in $TICKETS_DIR"
