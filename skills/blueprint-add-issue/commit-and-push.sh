#!/bin/bash
# Helper script for blueprint-add-issue skill
# Usage: ./commit-and-push.sh <branch-name> <commit-message>

set -e  # Exit on any error

BRANCH_NAME="$1"
COMMIT_MESSAGE="$2"

if [ -z "$BRANCH_NAME" ] || [ -z "$COMMIT_MESSAGE" ]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 <branch-name> <commit-message>"
    exit 1
fi

# Find script directory and resolve the issues.md symlink
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISSUES_FILE_REAL="$(readlink -f "$SCRIPT_DIR/issues.md")"

# Find the repository containing the real issues file
REPO_ROOT="$(git -C "$(dirname "$ISSUES_FILE_REAL")" rev-parse --show-toplevel)"

# Navigate to that repository
cd "$REPO_ROOT"

# Create and checkout new branch
git checkout -b "$BRANCH_NAME"

# Get the file path relative to the repository root
ISSUES_FILE_RELATIVE="$(realpath --relative-to="$REPO_ROOT" "$ISSUES_FILE_REAL")"

# Stage the modified issues file
git add "$ISSUES_FILE_RELATIVE"

# Commit with message
git commit -m "$COMMIT_MESSAGE"

# Push to remote
git push -u origin "$BRANCH_NAME"

echo ""
echo "✓ Changes pushed to branch: $BRANCH_NAME"
echo ""
echo "Please create a PR at:"
echo "  $(git remote get-url origin | sed 's/\.git$//')/compare/$BRANCH_NAME"
