#!/bin/bash
# Install Claude Code (@anthropic-ai/claude-code) for all compatible mise Node.js versions
# Claude Code requires Node.js >= 18

set -e

eval "$(mise activate bash)"

echo "Installing Claude Code for compatible mise Node.js versions (>= 18)..."

versions=$(mise list node --installed | awk '{print $2}')

for version in $versions; do
    major=$(echo "$version" | cut -d. -f1)
    if [ "$major" -ge 18 ]; then
        echo "Installing for Node.js $version..."
        MISE_NODE_VERSION=$version npm install -g @anthropic-ai/claude-code
    else
        echo "Skipping Node.js $version (requires >= 18)"
    fi
done

echo "Done! Claude Code is now available for all compatible Node.js versions."
