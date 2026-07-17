#!/usr/bin/env bash
# check-ghcr-majors.sh — fail-closed GHCR lag gate for template-consumed majors.
#
# Verifies that major floating tags (`:1`) for owned features are resolvable on
# GHCR. Intended for release CI and a scheduled workflow — not for mass re-publish.
#
# Feature ID sources (union, order-independent):
#   1. Positional args and/or FEATURE_IDS (comma/space-separated)
#   2. Critical hardcoded set (known template consumers)
#   3. If TEMPLATES_SRC is set, or ../../templates/src exists relative to this
#      script's repo root, grep ghcr.io/mrrobot0985/devcontainer-features/<id>
#
# Resolution backends (first available):
#   docker manifest inspect | crane manifest | oras manifest fetch | gh api
#
# Exit 0 when every required :1 tag resolves. Exit 1 on any failure (fail closed).
# Exit 2 on usage / missing resolver tools.
set -euo pipefail

REGISTRY_NS="${GHCR_NAMESPACE:-ghcr.io/mrrobot0985/devcontainer-features}"
MAJOR="${GHCR_MAJOR_TAG:-1}"

# Critical set: always gated even when templates checkout is absent.
# Keep in sync with templates/src consumers (Layer A–D + studio).
CRITICAL_IDS=(
  non-root-enforcer
  ai-agent-sandbox
  container-firewall
  claude-code-backend
  claude-code-privacy
  claude-code-plugins
  claude-code-hooks
  claude-code-rules
  claude-code-skills
  claude-code-mcp-servers
  claude-code-audit-log
  host-isolation
  mcp-server-manager
)

usage() {
  cat <<'EOF'
Usage: check-ghcr-majors.sh [feature-id ...]

Env:
  FEATURE_IDS       Extra IDs (comma or space separated)
  TEMPLATES_SRC     Path to templates/src (optional; auto-detects ../../templates/src)
  GHCR_NAMESPACE    Default: ghcr.io/mrrobot0985/devcontainer-features
  GHCR_MAJOR_TAG    Default: 1
  SKIP_CRITICAL=1   Do not include the hardcoded critical set (args/templates only)
  ALLOW_EMPTY=1     Exit 0 if the ID set is empty (default: fail closed)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

declare -A ID_SET=()

add_id() {
  local id="$1"
  id="${id//[[:space:]]/}"
  [[ -z "$id" ]] && return 0
  # strip accidental path/version fragments
  id="${id##*/}"
  id="${id%%:*}"
  [[ -z "$id" ]] && return 0
  ID_SET["$id"]=1
}

# Args
for a in "$@"; do
  add_id "$a"
done

# FEATURE_IDS env
if [[ -n "${FEATURE_IDS:-}" ]]; then
  # shellcheck disable=SC2206
  _extra=(${FEATURE_IDS//,/ })
  for a in "${_extra[@]}"; do
    add_id "$a"
  done
fi

# Critical set
if [[ "${SKIP_CRITICAL:-0}" != "1" ]]; then
  for a in "${CRITICAL_IDS[@]}"; do
    add_id "$a"
  done
fi

# Templates scan
TEMPLATES_ROOT="${TEMPLATES_SRC:-}"
if [[ -z "$TEMPLATES_ROOT" ]]; then
  candidate="${REPO_ROOT}/../templates/src"
  if [[ -d "$candidate" ]]; then
    TEMPLATES_ROOT="$(cd "$candidate" && pwd)"
  fi
fi

if [[ -n "${TEMPLATES_ROOT:-}" && -d "$TEMPLATES_ROOT" ]]; then
  # shellcheck disable=SC2016
  while IFS= read -r id; do
    add_id "$id"
  done < <(
    grep -rhoE 'ghcr\.io/mrrobot0985/devcontainer-features/[a-zA-Z0-9._-]+' \
      "$TEMPLATES_ROOT" 2>/dev/null \
      | sed 's|.*/||' | sort -u || true
  )
  echo "templates scan: ${TEMPLATES_ROOT} (+ discovered owned feature refs)"
else
  echo "templates scan: skipped (no TEMPLATES_SRC / ../../templates/src)"
fi

IDS=()
while IFS= read -r k; do
  [[ -n "$k" ]] && IDS+=("$k")
done < <(printf '%s\n' "${!ID_SET[@]}" | sort -u)
if [[ ${#IDS[@]} -eq 0 ]]; then
  if [[ "${ALLOW_EMPTY:-0}" == "1" ]]; then
    echo "No feature IDs to check; ALLOW_EMPTY=1 — OK"
    exit 0
  fi
  echo "ERROR: empty feature ID set (fail closed). Pass args, FEATURE_IDS, or ensure critical set." >&2
  exit 1
fi

# Pick resolver
resolve() {
  local ref="$1"
  if command -v docker >/dev/null 2>&1; then
    docker manifest inspect "$ref" >/dev/null 2>&1
    return $?
  fi
  if command -v crane >/dev/null 2>&1; then
    crane manifest "$ref" >/dev/null 2>&1
    return $?
  fi
  if command -v oras >/dev/null 2>&1; then
    oras manifest fetch "$ref" >/dev/null 2>&1
    return $?
  fi
  if command -v gh >/dev/null 2>&1; then
    # ghcr package version tag via packages API (owner/package naming)
    # ref: ghcr.io/OWNER/devcontainer-features/ID:TAG
    local owner pkg tag
    owner="$(printf '%s' "$ref" | cut -d/ -f2)"
    pkg="devcontainer-features/$(printf '%s' "$ref" | cut -d/ -f4 | cut -d: -f1)"
    tag="$(printf '%s' "$ref" | rev | cut -d: -f1 | rev)"
    gh api \
      -H "Accept: application/vnd.github+json" \
      "/users/${owner}/packages/container/${pkg//\//%2F}/versions" \
      --jq ".[] | select(.metadata.container.tags[]? == \"${tag}\") | .id" \
      2>/dev/null | grep -q .
    return $?
  fi
  return 127
}

if ! command -v docker >/dev/null 2>&1 \
  && ! command -v crane >/dev/null 2>&1 \
  && ! command -v oras >/dev/null 2>&1 \
  && ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: need one of docker, crane, oras, or gh to resolve manifests" >&2
  exit 2
fi

echo "GHCR lag gate: major=:${MAJOR} ns=${REGISTRY_NS}"
echo "Checking ${#IDS[@]} feature(s): ${IDS[*]}"

failed=0
ok=0
for id in "${IDS[@]}"; do
  ref="${REGISTRY_NS}/${id}:${MAJOR}"
  if resolve "$ref"; then
    echo "  OK   ${ref}"
    ok=$((ok + 1))
  else
    echo "  FAIL ${ref}" >&2
    failed=$((failed + 1))
  fi
done

echo "Summary: ok=${ok} fail=${failed} total=${#IDS[@]}"
if [[ "$failed" -gt 0 ]]; then
  echo "ERROR: GHCR lag gate failed closed — ${failed} major tag(s) not resolvable." >&2
  echo "Do not mass re-publish; investigate publish lag or missing package visibility." >&2
  exit 1
fi
echo "GHCR lag gate passed."
exit 0
