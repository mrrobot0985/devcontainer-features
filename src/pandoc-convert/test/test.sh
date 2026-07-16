#!/usr/bin/env bash
set -euo pipefail

# Test: pandoc is installed
if ! command -v pandoc >/dev/null 2>&1; then
    echo "FAILED: pandoc not found"
    exit 1
fi

# Test: pandoc version is available
PANDOC_VERSION="$(pandoc --version | head -n1)"
if [ -z "$PANDOC_VERSION" ]; then
    echo "FAILED: could not get pandoc version"
    exit 1
fi
echo "pandoc version: $PANDOC_VERSION"

# Test: helper CLI exists
if ! command -v devcontainer-pandoc >/dev/null 2>&1; then
    echo "FAILED: devcontainer-pandoc helper not found"
    exit 1
fi

# Test: basic markdown conversion
TMP_MD="$(mktemp).md"
TMP_OUT="$(mktemp).html"
trap "rm -f '$TMP_MD' '$TMP_OUT'" EXIT

echo "# Hello World" > "$TMP_MD"
pandoc "$TMP_MD" -o "$TMP_OUT"
if [ ! -s "$TMP_OUT" ]; then
    echo "FAILED: pandoc conversion produced empty output"
    exit 1
fi

echo "pandoc-convert tests passed."
