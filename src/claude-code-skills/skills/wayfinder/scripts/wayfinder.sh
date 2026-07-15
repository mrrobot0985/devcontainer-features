#!/bin/sh
set -e
# wayfinder.sh — Chart wayfinder map from SPEC.md.
# Usage: wayfinder.sh [project-root]
# Env: FORCE=true to overwrite existing WAYFINDER.md/map.yaml

PROJECT_ROOT="${1:-.}"
SPEC_FILE="${PROJECT_ROOT}/SPEC.md"
WAYFINDER_FILE="${PROJECT_ROOT}/WAYFINDER.md"
MAP_FILE="${PROJECT_ROOT}/wayfinder/map.yaml"
FORCE="${FORCE:-false}"

if [ ! -f "$SPEC_FILE" ]; then
    echo "ERROR: SPEC.md not found at $SPEC_FILE"
    exit 1
fi

if [ -f "$WAYFINDER_FILE" ] && [ "$FORCE" != "true" ]; then
    echo "WARNING: WAYFINDER.md already exists. Set FORCE=true to overwrite."
    exit 0
fi

mkdir -p "$(dirname "$MAP_FILE")"

# Parse SPEC.md headings to extract milestones
default_milestones() {
    cat <<'EOF'
# Wayfinder Map

## Destination

Derived from SPEC.md Summary.

## Phases

### Phase 1: Foundation
- T001: Bootstrap project structure

### Phase 2: Core Feature
- T002: Implement primary capability

### Phase 3: Polish
- T003: Documentation and tests

## Decisions

<!-- Closed decisions get appended here -->

## Not Yet Specified

<!-- Fog of war — suspected questions not yet ticketed -->

## Out of Scope

<!-- Consciously ruled out -->
EOF
}

if command -v grep >/dev/null 2>&1 && [ -s "$SPEC_FILE" ]; then
    # Extract headings from SPEC.md to seed phases
    PHASES=""
    in_milestones=false
    while IFS= read -r line; do
        case "$line" in
            "## Milestones"*|"### Milestones"*) in_milestones=true ;;
            "## "*|"# "*) in_milestones=false ;;
        esac
        if [ "$in_milestones" = "true" ] && echo "$line" | grep -qE '^#{3,4} '; then
            title="$(echo "$line" | sed 's/^#* *//')"
            PHASES="${PHASES}### Phase: ${title}
- TODO: derive tasks from milestone

"
        fi
    done < "$SPEC_FILE"
fi

if [ -z "$PHASES" ]; then
    PHASES="### Phase 1: Foundation
- T001: Bootstrap project structure

### Phase 2: Core Feature
- T002: Implement primary capability

### Phase 3: Polish
- T003: Documentation and tests
"
fi

cat > "$WAYFINDER_FILE" <<EOF
# Wayfinder Map

## Destination

$(grep -A2 '^# ' "$SPEC_FILE" 2>/dev/null | tail -1 || echo "See SPEC.md")

## Phases

${PHASES}

## Decisions

<!-- Closed decisions get appended here -->

## Not Yet Specified

<!-- Fog of war — suspected questions not yet ticketed -->

## Out of Scope

<!-- Consciously ruled out -->
EOF

# Write map.yaml
cat > "$MAP_FILE" <<EOF
version: 1
destination: "$(grep -A2 '^# ' "$SPEC_FILE" 2>/dev/null | tail -1 || echo "unknown")"
phases:
  - id: phase-1
    name: Foundation
    tickets: [T001]
  - id: phase-2
    name: Core Feature
    tickets: [T002]
  - id: phase-3
    name: Polish
    tickets: [T003]
tickets: []
dependencies: []
EOF

echo "WAYFINDER.md and wayfinder/map.yaml written."
