#!/bin/sh
set -e

# to-spec.sh — Generate SPEC.md from project context.
#
# Usage: to-spec.sh [project-root]
# Env: FORCE=true to overwrite existing SPEC.md

PROJECT_ROOT="${1:-.}"
SPEC_FILE="${PROJECT_ROOT}/SPEC.md"
FORCE="${FORCE:-false}"

if [ -f "$SPEC_FILE" ] && [ "$FORCE" != "true" ]; then
    echo "WARNING: SPEC.md already exists. Set FORCE=true to overwrite."
    exit 0
fi

# Collect context files
CONTEXT=""
for f in "${PROJECT_ROOT}/README.md" "${PROJECT_ROOT}/docs/adr/"*.md "${PROJECT_ROOT}/docs/"*.md; do
    [ -f "$f" ] || continue
    CONTEXT="${CONTEXT}## Source: $(basename "$f")\n\n$(cat "$f")\n\n"
done

# Detect project type and manifest
MANIFEST=""
for mf in "${PROJECT_ROOT}/package.json" "${PROJECT_ROOT}/pyproject.toml" "${PROJECT_ROOT}/Cargo.toml" "${PROJECT_ROOT}/go.mod"; do
    [ -f "$mf" ] || continue
    MANIFEST="${MANIFEST}## Manifest: $(basename "$mf")\n\n$(cat "$mf")\n\n"
done

# Load prompt template
PROMPT_TEMPLATE="$(dirname "$0")/../templates/spec-prompt.md"
if [ -f "$PROMPT_TEMPLATE" ]; then
    PROMPT="$(cat "$PROMPT_TEMPLATE")"
else
    PROMPT="Write a SPEC.md for the project described below."
fi

# Combine and generate
{
    echo "$PROMPT"
    echo ""
    echo "$CONTEXT"
    echo "$MANIFEST"
} > /tmp/to-spec-input.txt

# If claude CLI is available, use it headlessly
if command -v claude >/dev/null 2>&1; then
    echo "Generating SPEC.md via headless claude..."
    claude --print --no-interactive --input /tmp/to-spec-input.txt > "$SPEC_FILE" 2>/dev/null || {
        echo "WARNING: headless generation failed. Writing stub SPEC.md."
        write_stub_spec
    }
else
    echo "No claude CLI available. Writing stub SPEC.md."
    write_stub_spec
fi

# Validate required headings
for heading in "Summary" "Goals" "Non-Goals" "Architecture" "Milestones" "Risks"; do
    if ! grep -qE "^#{1,2} *${heading}" "$SPEC_FILE"; then
        echo "WARNING: SPEC.md missing required heading: ${heading}"
    fi
done

echo "SPEC.md written to $SPEC_FILE"

write_stub_spec() {
    cat > "$SPEC_FILE" <<'EOF'
# SPEC.md

## Summary

TODO: one-paragraph summary of the project and its purpose.

## Goals

- TODO: primary goal
- TODO: secondary goal

## Non-Goals

- TODO: explicitly out of scope

## Architecture

TODO: high-level architecture description.

## Milestones

### Milestone 1: Foundation
- [ ] TODO

### Milestone 2: Core Feature
- [ ] TODO

### Milestone 3: Polish
- [ ] TODO

## Risks

- TODO: technical risk
- TODO: schedule risk
EOF
}
