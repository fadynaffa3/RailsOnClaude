#!/bin/bash

# Script to create all 12 comprehensive Rails skills for RailsOnClaude

SKILLS_DIR="/Users/fadynaffa/work/RailsOnClaude/skills"

echo "Creating 12 comprehensive Rails skills..."

# Create skill directories
mkdir -p "$SKILLS_DIR"/{rails-db-optimizer,rails-test-helper,rails-api-designer,rails-security-audit,rails-performance-optimizer,rails-jobs-helper,rails-docker,rails-monitoring,rails-refactoring-guide,rails-docs-generator,rails-turbo-stimulus,rails-code-reviewer}

echo "✅ Created 12 skill directories"
echo ""
echo "Skills created:"
ls -1 "$SKILLS_DIR" | grep -v "rails-audit\|ruby-help\|rails-help"
