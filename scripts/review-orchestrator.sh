#!/bin/bash
# Multi-perspective review orchestrator.
# Runs Correctness, Architecture, and Safety in parallel Docker sandcastles
# and aggregates their JSON reports into a single gate report.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TARGET_REF="${1:-HEAD}"
BASE_REF="${2:-main}"
MAX_WARNINGS="${MAX_WARNINGS:-10}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-600}"
RUN_ID="${RUN_ID:-$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)}"

REPORT_DIR="${REPO_ROOT}/.ralph/reports"
mkdir -p "${REPORT_DIR}"

AGGREGATE_REPORT="${REPORT_DIR}/review-${RUN_ID}.json"

log() {
    echo "[review-orchestrator] $*" >&2
}

fail() {
    echo "[review-orchestrator] ERROR: $*" >&2
    exit 1
}

# Resolve refs before mounting so bad refs fail fast.
if ! git rev-parse "${TARGET_REF}" >/dev/null 2>&1; then
    fail "target ref '${TARGET_REF}' does not resolve"
fi
if ! git rev-parse "${BASE_REF}" >/dev/null 2>&1; then
    fail "base ref '${BASE_REF}' does not resolve"
fi

log "starting review run ${RUN_ID} for ${BASE_REF}...${TARGET_REF}"

# Shared output volume for per-perspective reports.
OUT_VOLUME="review-out-${RUN_ID}"
docker volume rm "${OUT_VOLUME}" >/dev/null 2>&1 || true
docker volume create "${OUT_VOLUME}" >/dev/null

cleanup() {
    docker volume rm "${OUT_VOLUME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Build base image if not present.
BASE_IMAGE="mrrobot0985/review-base:latest"
if ! docker image inspect "${BASE_IMAGE}" >/dev/null 2>&1; then
    log "building base sandcastle image"
    docker build -f "${REPO_ROOT}/sandcastle/Dockerfile.base" -t "${BASE_IMAGE}" "${REPO_ROOT}/sandcastle"
fi

# Build per-perspective images if not present.
for perspective in correctness architecture safety; do
    image="mrrobot0985/review-${perspective}:latest"
    if ! docker image inspect "${image}" >/dev/null 2>&1; then
        log "building ${perspective} sandcastle image"
        docker build -f "${REPO_ROOT}/sandcastle/Dockerfile.${perspective}" -t "${image}" "${REPO_ROOT}/sandcastle"
    fi
done

# Start three containers in parallel.
declare -A CONTAINERS
for perspective in correctness architecture safety; do
    script="/usr/local/bin/review-${perspective}.sh"
    container="review-${perspective}-${RUN_ID}"
    log "launching ${perspective} container ${container}"
    docker run --rm --detach \
        --name "${container}" \
        --read-only \
        --tmpfs /tmp:noexec,nosuid,size=100m \
        -v "${REPO_ROOT}:/repo:ro" \
        -v "${OUT_VOLUME}:/out:rw" \
        -e TARGET_REF="${TARGET_REF}" \
        -e BASE_REF="${BASE_REF}" \
        -e RUN_ID="${RUN_ID}" \
        "mrrobot0985/review-${perspective}:latest" \
        "${script}" \
        >"/dev/null"
    CONTAINERS["${perspective}"]="${container}"
done

# Wait for completion with timeout.
log "waiting for perspectives (timeout ${TIMEOUT_SECONDS}s)"
wait_start=$(date +%s)
all_done=false
while [ $(($(date +%s) - wait_start)) -lt "${TIMEOUT_SECONDS}" ]; do
    all_done=true
    for perspective in correctness architecture safety; do
        container="${CONTAINERS[${perspective}]}"
        if docker ps -q -f "name=^${container}$" | grep -q .; then
            all_done=false
        fi
    done
    if ${all_done}; then
        break
    fi
    sleep 2
done

if ! ${all_done}; then
    for perspective in correctness architecture safety; do
        container="${CONTAINERS[${perspective}]}"
        if docker ps -q -f "name=^${container}$" | grep -q .; then
            log "timeout: killing ${perspective} container"
            docker kill "${container}" >/dev/null 2>&1 || true
            docker wait "${container}" >/dev/null 2>&1 || true
        fi
    done
fi

# Collect exit codes and reports.
declare -A EXIT_CODES
for perspective in correctness architecture safety; do
    container="${CONTAINERS[${perspective}]}"
    if EXIT_CODES["${perspective}"]="$(docker inspect -f '{{.State.ExitCode}}' "${container}" 2>/dev/null)"; then
        :
    else
        EXIT_CODES["${perspective}"]=127
    fi
done

# Copy per-perspective reports from the shared volume to the host report directory.
log "copying per-perspective reports"
docker run --rm \
    -v "${OUT_VOLUME}:/src:ro" \
    -v "${REPORT_DIR}:/dst:rw" \
    mcr.microsoft.com/devcontainers/base:ubuntu \
    sh -c 'cp /src/*.json /dst/ 2>/dev/null || true'

# Aggregate.
log "aggregating reports"
python3 - <<'PY' - "${TARGET_REF}" "${BASE_REF}" "${RUN_ID}" "${AGGREGATE_REPORT}" "${MAX_WARNINGS}" "${REPORT_DIR}" correctness "${EXIT_CODES[correctness]}" architecture "${EXIT_CODES[architecture]}" safety "${EXIT_CODES[safety]}"
import json
import os
import sys
from datetime import datetime, timezone

target_ref, base_ref, run_id, aggregate_report, max_warnings, report_dir = sys.argv[1:7]
perspective_args = sys.argv[7:]
exit_codes = {
    perspective_args[i]: int(perspective_args[i + 1])
    for i in range(0, len(perspective_args), 2)
}

perspectives = []
summary = {"critical": 0, "warning": 0, "info": 0}
overall = "pass"

for perspective in ["correctness", "architecture", "safety"]:
    report_path = os.path.join(report_dir, f"{perspective}.json")
    if not os.path.exists(report_path):
        # Timeout or missing report is a failure for that perspective.
        status = "fail"
        findings = [
            {
                "perspective": perspective,
                "severity": "critical",
                "rule": "report-present",
                "message": f"No report generated for {perspective}; container likely timed out or crashed",
                "file": None,
                "line": None,
                "suggestion": None,
            }
        ]
        duration_ms = 0
    else:
        with open(report_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        findings = data.get("findings", [])
        duration_ms = data.get("duration_ms", 0)
        exit_code = exit_codes.get(perspective, 1)
        if exit_code != 0:
            status = "fail"
        else:
            status = "pass"

    for finding in findings:
        severity = finding.get("severity", "info")
        if severity in summary:
            summary[severity] += 1
        if severity == "critical":
            status = "fail"
            overall = "fail"

    if status == "fail":
        overall = "fail"

    perspectives.append(
        {
            "name": perspective,
            "status": status,
            "exit_code": exit_codes.get(perspective, 1),
            "duration_ms": duration_ms,
            "findings": findings,
        }
    )

if summary["warning"] > int(max_warnings):
    overall = "fail"

aggregate = {
    "run_id": run_id,
    "target_ref": target_ref,
    "base_ref": base_ref,
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "overall": overall,
    "perspectives": perspectives,
    "summary": summary,
}

os.makedirs(os.path.dirname(aggregate_report), exist_ok=True)
with open(aggregate_report, "w", encoding="utf-8") as f:
    json.dump(aggregate, f, indent=2)

print(f"Report: {aggregate_report}")
print(json.dumps(summary, indent=2))

sys.exit(0 if overall == "pass" else 1)
PY

log "done"
