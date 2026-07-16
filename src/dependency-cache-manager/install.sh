#!/bin/bash
set -e

# dependency-cache-manager install script
# Auto-detects project types and configures package manager caches.

AUTO_DETECT="__AUTODETECT__"
TOOLS="__TOOLS__"
CACHE_PATH="__CACHEPATH__"
PRINT_MOUNT="__PRINTMOUNT__"

setup_npm_cache() {
    local npm_cache="${CACHE_PATH}/npm"
    mkdir -p "$npm_cache"
    if command -v npm >/dev/null 2>&1; then
        npm config set cache "$npm_cache" --global
        echo "INFO [dependency-cache-manager]: npm cache configured -> $npm_cache"
    fi
}

setup_yarn_cache() {
    local yarn_cache="${CACHE_PATH}/yarn"
    mkdir -p "$yarn_cache"
    if command -v yarn >/dev/null 2>&1; then
        yarn config set cache-folder "$yarn_cache" --global 2>/dev/null || true
        echo "INFO [dependency-cache-manager]: yarn cache configured -> $yarn_cache"
    fi
}

setup_pnpm_cache() {
    local pnpm_cache="${CACHE_PATH}/pnpm"
    mkdir -p "$pnpm_cache"
    if command -v pnpm >/dev/null 2>&1; then
        pnpm config set store-dir "$pnpm_cache" --global 2>/dev/null || true
        echo "INFO [dependency-cache-manager]: pnpm cache configured -> $pnpm_cache"
    fi
}

setup_pip_cache() {
    local pip_cache="${CACHE_PATH}/pip"
    mkdir -p "$pip_cache"
    # Set environment variable for pip cache
    cat > /etc/profile.d/pip-cache.sh <<EOF
export PIP_CACHE_DIR="$pip_cache"
EOF
    echo "INFO [dependency-cache-manager]: pip cache configured -> $pip_cache"
}

setup_uv_cache() {
    local uv_cache="${CACHE_PATH}/uv"
    mkdir -p "$uv_cache"
    cat > /etc/profile.d/uv-cache.sh <<EOF
export UV_CACHE_DIR="$uv_cache"
EOF
    echo "INFO [dependency-cache-manager]: uv cache configured -> $uv_cache"
}

setup_cargo_cache() {
    local cargo_cache="${CACHE_PATH}/cargo"
    mkdir -p "$cargo_cache"
    cat > /etc/profile.d/cargo-cache.sh <<EOF
export CARGO_HOME="$cargo_cache"
EOF
    echo "INFO [dependency-cache-manager]: cargo cache configured -> $cargo_cache"
}

setup_gradle_cache() {
    local gradle_cache="${CACHE_PATH}/gradle"
    mkdir -p "$gradle_cache"
    cat > /etc/profile.d/gradle-cache.sh <<EOF
export GRADLE_USER_HOME="$gradle_cache"
EOF
    echo "INFO [dependency-cache-manager]: gradle cache configured -> $gradle_cache"
}

setup_maven_cache() {
    local m2_cache="${CACHE_PATH}/m2"
    mkdir -p "$m2_cache"
    cat > /etc/profile.d/maven-cache.sh <<EOF
export MAVEN_OPTS="-Dmaven.repo.local=$m2_cache"
EOF
    echo "INFO [dependency-cache-manager]: maven cache configured -> $m2_cache"
}

setup_go_cache() {
    local go_cache="${CACHE_PATH}/go"
    mkdir -p "$go_cache"
    cat > /etc/profile.d/go-cache.sh <<EOF
export GOMODCACHE="$go_cache/pkg/mod"
export GOCACHE="$go_cache/build"
EOF
    echo "INFO [dependency-cache-manager]: go cache configured -> $go_cache"
}

detect_projects() {
    local detected=""
    if [ -f "package.json" ]; then
        detected="${detected}npm,"
        if command -v yarn >/dev/null 2>&1; then detected="${detected}yarn,"; fi
        if command -v pnpm >/dev/null 2>&1; then detected="${detected}pnpm,"; fi
    fi
    if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        detected="${detected}pip,"
        if command -v uv >/dev/null 2>&1; then detected="${detected}uv,"; fi
    fi
    if [ -f "Cargo.toml" ]; then
        detected="${detected}cargo,"
    fi
    if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        detected="${detected}gradle,"
    fi
    if [ -f "pom.xml" ]; then
        detected="${detected}maven,"
    fi
    if [ -f "go.mod" ]; then
        detected="${detected}go,"
    fi
    # Remove trailing comma
    echo "$detected" | sed 's/,$//'
}

main() {
    echo "=== Dependency Cache Manager ==="
    echo "Base cache path: $CACHE_PATH"

    mkdir -p "$CACHE_PATH"

    local tools_to_configure=""
    if [ -n "$TOOLS" ]; then
        tools_to_configure="$TOOLS"
        echo "Configuring explicit tools: $tools_to_configure"
    elif [ "$AUTO_DETECT" = "true" ]; then
        tools_to_configure=$(detect_projects)
        if [ -n "$tools_to_configure" ]; then
            echo "Auto-detected project types: $tools_to_configure"
        else
            echo "INFO [dependency-cache-manager]: No project types auto-detected."
        fi
    fi

    IFS=',' read -ra TOOL_LIST <<< "$tools_to_configure"
    for tool in "${TOOL_LIST[@]}"; do
        case "$tool" in
            npm) setup_npm_cache ;;
            yarn) setup_yarn_cache ;;
            pnpm) setup_pnpm_cache ;;
            pip) setup_pip_cache ;;
            uv) setup_uv_cache ;;
            cargo) setup_cargo_cache ;;
            gradle) setup_gradle_cache ;;
            maven) setup_maven_cache ;;
            go) setup_go_cache ;;
            *) echo "WARN [dependency-cache-manager]: Unknown tool '$tool'"; ;;
        esac
    done

    if [ "$PRINT_MOUNT" = "true" ]; then
        echo ""
        echo "=== Required devcontainer.json mounts ==="
        echo "Add the following to your devcontainer.json 'mounts' array:"
        echo ""
        echo "  \"source=devcontainer-cache,target=${CACHE_PATH},type=volume\""
        echo ""
        echo "Or, for a scoped cache per project:"
        echo "  \"source=\${localWorkspaceFolderBasename}-cache,target=${CACHE_PATH},type=volume\""
        echo ""
        echo "INFO [dependency-cache-manager]: auto-detect runs at build time before the workspace is mounted. If project files are not present during build, use the 'tools' option to specify them explicitly."
        echo ""
    fi

    echo "=== Dependency Cache Manager complete ==="
}

main
