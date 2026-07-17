#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Running Pandoc Document Converter tests..."

# Verify pandoc is available
if ! command -v pandoc >/dev/null 2>&1; then
    echo "FAILED: pandoc not found"
    exit 1
fi

PANDOC_VERSION="$(pandoc --version | head -n1)"
if [ -z "$PANDOC_VERSION" ]; then
    echo "FAILED: could not get pandoc version"
    exit 1
fi
echo "pandoc version: $PANDOC_VERSION"

# Verify helper script
if [ -f /usr/local/bin/devcontainer-pandoc ]; then
    echo "Helper script found"
    devcontainer-pandoc status || true
else
    echo "WARNING: Helper script not found"
fi

# Basic markdown conversion smoke test
TMP_MD="$(mktemp).md"
TMP_OUT="$(mktemp).html"
trap "rm -f '$TMP_MD' '$TMP_OUT'" EXIT

echo "# Hello World" > "$TMP_MD"
pandoc "$TMP_MD" -o "$TMP_OUT"
if [ ! -s "$TMP_OUT" ]; then
    echo "FAILED: pandoc conversion produced empty output"
    exit 1
fi

echo "Pandoc Document Converter tests passed."
