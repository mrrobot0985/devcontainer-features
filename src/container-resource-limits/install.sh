#!/usr/bin/env bash
set -euo pipefail

CPU_LIMIT="${CPULIMIT:-}"
MEMORY_LIMIT="${MEMORYLIMIT:-}"
SWAP_LIMIT="${SWAPLIMIT:-}"
PIDS_LIMIT="${PIDSLIMIT:-0}"

echo "Configuring container resource limits..."

# Validate and write a helper script that applies limits at runtime
HELPER_SCRIPT="/usr/local/bin/devcontainer-resource-limits"

cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

CPU_LIMIT="${1:-}"
MEMORY_LIMIT="${2:-}"
SWAP_LIMIT="${3:-}"
PIDS_LIMIT="${4:-0}"

echo "Applying container resource limits..."

# Detect cgroup version
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    CGROUP_V="v2"
    CGROUP_DIR="/sys/fs/cgroup"
else
    CGROUP_V="v1"
    CGROUP_DIR="/sys/fs/cgroup"
fi

echo "Detected cgroup $CGROUP_V"

# Apply CPU limit
if [ -n "$CPU_LIMIT" ]; then
    CPU_QUOTA_MICRO="$(awk "BEGIN {printf \"%.0f\", $CPU_LIMIT * 100000}")"
    CPU_PERIOD="100000"
    if [ "$CGROUP_V" = "v2" ]; then
        if [ -w "$CGROUP_DIR/cpu.max" ]; then
            echo "$CPU_QUOTA_MICRO $CPU_PERIOD" > "$CGROUP_DIR/cpu.max" 2>/dev/null || echo "WARNING: Could not set cpu.max (may require privileges)"
            echo "CPU limit set to $CPU_LIMIT cores"
        else
            echo "WARNING: Cannot write cpu.max — container may not have cgroup write access"
        fi
    else
        if [ -w "$CGROUP_DIR/cpu/cpu.cfs_quota_us" ]; then
            echo "$CPU_QUOTA_MICRO" > "$CGROUP_DIR/cpu/cpu.cfs_quota_us" 2>/dev/null || echo "WARNING: Could not set cpu.cfs_quota_us"
            echo "$CPU_PERIOD" > "$CGROUP_DIR/cpu/cpu.cfs_period_us" 2>/dev/null || true
            echo "CPU limit set to $CPU_LIMIT cores"
        fi
    fi
fi

# Apply memory limit
if [ -n "$MEMORY_LIMIT" ]; then
    # Convert to bytes for cgroup v2
    MEM_BYTES="$(numfmt --from=iec "$MEMORY_LIMIT" 2>/dev/null || echo "")"
    if [ -z "$MEM_BYTES" ]; then
        # Fallback: parse manually
        if [[ "$MEMORY_LIMIT" =~ ^([0-9]+)([gGmMkK]?)$ ]]; then
            VAL="${BASH_REMATCH[1]}"
            SUFFIX="${BASH_REMATCH[2]}"
            case "${SUFFIX,,}" in
                g) MEM_BYTES=$((VAL * 1024 * 1024 * 1024)) ;;
                m) MEM_BYTES=$((VAL * 1024 * 1024)) ;;
                k) MEM_BYTES=$((VAL * 1024)) ;;
                *) MEM_BYTES="$VAL" ;;
            esac
        fi
    fi
    if [ -n "$MEM_BYTES" ]; then
        if [ "$CGROUP_V" = "v2" ]; then
            if [ -w "$CGROUP_DIR/memory.max" ]; then
                echo "$MEM_BYTES" > "$CGROUP_DIR/memory.max" 2>/dev/null || echo "WARNING: Could not set memory.max"
                echo "Memory limit set to $MEMORY_LIMIT"
            else
                echo "WARNING: Cannot write memory.max"
            fi
        else
            if [ -w "$CGROUP_DIR/memory/memory.limit_in_bytes" ]; then
                echo "$MEM_BYTES" > "$CGROUP_DIR/memory/memory.limit_in_bytes" 2>/dev/null || echo "WARNING: Could not set memory.limit_in_bytes"
                echo "Memory limit set to $MEMORY_LIMIT"
            fi
        fi
    fi
fi

# Apply swap limit
if [ -n "$SWAP_LIMIT" ]; then
    SWAP_BYTES="$(numfmt --from=iec "$SWAP_LIMIT" 2>/dev/null || echo "")"
    if [ -z "$SWAP_BYTES" ]; then
        if [[ "$SWAP_LIMIT" =~ ^([0-9]+)([gGmMkK]?)$ ]]; then
            VAL="${BASH_REMATCH[1]}"
            SUFFIX="${BASH_REMATCH[2]}"
            case "${SUFFIX,,}" in
                g) SWAP_BYTES=$((VAL * 1024 * 1024 * 1024)) ;;
                m) SWAP_BYTES=$((VAL * 1024 * 1024)) ;;
                k) SWAP_BYTES=$((VAL * 1024)) ;;
                *) SWAP_BYTES="$VAL" ;;
            esac
        fi
    fi
    if [ -n "$SWAP_BYTES" ]; then
        if [ "$CGROUP_V" = "v2" ]; then
            if [ -w "$CGROUP_DIR/memory.swap.max" ]; then
                echo "$SWAP_BYTES" > "$CGROUP_DIR/memory.swap.max" 2>/dev/null || echo "WARNING: Could not set memory.swap.max"
                echo "Swap limit set to $SWAP_LIMIT"
            else
                echo "WARNING: Cannot write memory.swap.max"
            fi
        else
            if [ -w "$CGROUP_DIR/memory/memory.memsw.limit_in_bytes" ]; then
                echo "$SWAP_BYTES" > "$CGROUP_DIR/memory/memory.memsw.limit_in_bytes" 2>/dev/null || echo "WARNING: Could not set memory.memsw.limit_in_bytes"
                echo "Swap limit set to $SWAP_LIMIT"
            fi
        fi
    fi
fi

# Apply PID limit
if [ "$PIDS_LIMIT" -gt 0 ]; then
    if [ "$CGROUP_V" = "v2" ]; then
        if [ -w "$CGROUP_DIR/pids.max" ]; then
            echo "$PIDS_LIMIT" > "$CGROUP_DIR/pids.max" 2>/dev/null || echo "WARNING: Could not set pids.max"
            echo "PID limit set to $PIDS_LIMIT"
        else
            echo "WARNING: Cannot write pids.max"
        fi
    else
        if [ -w "$CGROUP_DIR/pids/pids.max" ]; then
            echo "$PIDS_LIMIT" > "$CGROUP_DIR/pids/pids.max" 2>/dev/null || echo "WARNING: Could not set pids.max"
            echo "PID limit set to $PIDS_LIMIT"
        fi
    fi
fi

echo "Resource limits applied."
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

# Apply limits immediately if this is running inside a container with cgroup access
"$HELPER_SCRIPT" "$CPU_LIMIT" "$MEMORY_LIMIT" "$SWAP_LIMIT" "$PIDS_LIMIT" || true

echo "Container Resource Limits configured."
echo "  CLI: devcontainer-resource-limits <cpu> <memory> <swap> <pids>"
echo "  Current: CPU=$CPU_LIMIT, Memory=$MEMORY_LIMIT, Swap=$SWAP_LIMIT, PIDs=$PIDS_LIMIT"
