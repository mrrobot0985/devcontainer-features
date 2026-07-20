#!/bin/bash
set -e

echo "Installing Grok Build CLI..."
curl -fsSL https://x.ai/cli/install.sh | bash

echo "Grok Build installed."
echo "Run 'grok login' to authenticate."