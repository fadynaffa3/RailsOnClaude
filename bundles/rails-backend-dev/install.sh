#!/bin/bash
# Rails Backend Developer Bundle Installer

set -e

SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "📦 Installing Rails Backend Developer Bundle..."
echo "Target: $SKILLS_DIR"

# Create skills directory if it doesn't exist
mkdir -p "$SKILLS_DIR"

# Install skills
for skill in rails-guide ruby-expert rails-audit; do
    echo "Installing $skill..."
    cp -r "$BUNDLE_DIR/skills/$skill" "$SKILLS_DIR/"
done

echo "✅ Rails Backend Developer Bundle installed successfully!"
echo ""
echo "Available commands:"
echo "  /rails-guide  - Rails conventions and best practices"
echo "  /ruby-expert  - Ruby metaprogramming and optimization"
echo "  /rails-audit  - Comprehensive code audits"
