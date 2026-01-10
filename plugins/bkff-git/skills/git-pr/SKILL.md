---
name: git-pr
description: Create or update a pull request for the current branch
invocation: /bkff:git-pr
arguments:
  - name: --title
    type: string
    required: false
    description: Override auto-generated PR title
  - name: --draft
    type: flag
    required: false
    description: Create as draft PR
---

# Manage Pull Request

Creates or updates a pull request for the current branch. Uses the repository's PR template if available, or generates a default description.

## Usage

```
/bkff:git-pr [--title "PR title"] [--draft]
```

## Options

| Option | Description |
|--------|-------------|
| `--title` | Override the auto-generated PR title |
| `--draft` | Create as a draft pull request |

## What It Does

1. Checks if PR already exists for branch
2. Pushes branch to origin if needed
3. Creates new PR or updates existing one
4. Uses PR template if available

## Example Output

```
## Pull Request Created

### Branch
- **Head**: feature/auth-login
- **Base**: main

### Pull Request
- **Number**: #123
- **Title**: feat(auth): implement user authentication
- **URL**: https://github.com/owner/repo/pull/123
```

## Requirements

- Must be run inside a git worktree
- `git` CLI for branch operations
- `gh` CLI for PR creation (authenticated)
- Cannot be on main/master branch

## Implementation

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PLUGIN_DIR/lib/common.sh"
source "$PLUGIN_DIR/lib/git-helpers.sh"

# Parse arguments
CUSTOM_TITLE=""
DRAFT_FLAG=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --title|-t)
            CUSTOM_TITLE="$2"
            shift 2
            ;;
        --draft|-d)
            DRAFT_FLAG="--draft"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

require_worktree

# Check if gh is available
command -v gh &>/dev/null || error_exit "gh CLI required but not installed"

CURRENT_BRANCH=$(get_current_branch)
MAIN_BRANCH=$(get_main_branch)

# FR-033: Cannot create PR from main branch
if [[ "$CURRENT_BRANCH" == "$MAIN_BRANCH" || "$CURRENT_BRANCH" == "master" ]]; then
    error_exit "Cannot create PR from $CURRENT_BRANCH branch"
fi

echo "## Pull Request"
echo ""

# FR-024: Check if PR already exists
echo "### Branch"
echo "- **Head**: $CURRENT_BRANCH"
echo "- **Base**: $MAIN_BRANCH"

EXISTING_PR=$(gh pr list --head "$CURRENT_BRANCH" --json number,url --jq '.[0]' 2>/dev/null || echo "")

# FR-028: Ensure branch is pushed
if ! is_branch_pushed "$CURRENT_BRANCH"; then
    info "Pushing branch to origin..."
    if git push -u origin "$CURRENT_BRANCH"; then
        echo "- **Pushed**: Yes (just pushed)"
    else
        error_exit "Failed to push branch. Check network connection."
    fi
else
    # Check if we're ahead of origin
    AHEAD=$(get_ahead_count "$CURRENT_BRANCH")
    if [[ "$AHEAD" -gt 0 ]]; then
        info "Pushing $AHEAD new commits..."
        git push || warn "Push failed"
    fi
    echo "- **Pushed**: Yes"
fi
echo ""

# Generate PR title from commits if not provided
if [[ -z "$CUSTOM_TITLE" ]]; then
    # Use first commit message as title
    CUSTOM_TITLE=$(git log "$MAIN_BRANCH..HEAD" --format="%s" | tail -1)
fi

# FR-027: Check for PR template
TEMPLATE_FILE=""
for tmpl in .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md PULL_REQUEST_TEMPLATE.md; do
    if [[ -f "$tmpl" ]]; then
        TEMPLATE_FILE="$tmpl"
        break
    fi
done

# Generate PR body
generate_pr_body() {
    echo "## Summary"
    echo ""
    git log "$MAIN_BRANCH..HEAD" --format="- %s" | tac
    echo ""
    echo "## Test Plan"
    echo ""
    echo "- [ ] Unit tests pass"
    echo "- [ ] Manual testing completed"
    echo ""
    echo "---"
    echo ""
    echo "🤖 Generated with [Claude Code](https://claude.ai/code)"
}

if [[ -n "$EXISTING_PR" ]]; then
    # FR-025: Update existing PR
    PR_NUMBER=$(echo "$EXISTING_PR" | jq -r '.number')
    PR_URL=$(echo "$EXISTING_PR" | jq -r '.url')

    echo "### Pull Request (Existing)"
    echo "- **Number**: #$PR_NUMBER"
    echo "- **Status**: Updated"
    echo "- **URL**: $PR_URL"
    echo ""
    success "PR already exists. Branch pushed with latest changes."
else
    # FR-026: Create new PR
    echo "### Pull Request"
    info "Creating pull request..."

    PR_BODY=$(generate_pr_body)

    # Build gh pr create command
    GH_CMD="gh pr create --title \"$CUSTOM_TITLE\" --body \"\$PR_BODY\" --base $MAIN_BRANCH"
    [[ -n "$DRAFT_FLAG" ]] && GH_CMD="$GH_CMD $DRAFT_FLAG"
    [[ -n "$TEMPLATE_FILE" ]] && GH_CMD="gh pr create --title \"$CUSTOM_TITLE\" --base $MAIN_BRANCH $DRAFT_FLAG"

    if PR_URL=$(gh pr create --title "$CUSTOM_TITLE" --body "$PR_BODY" --base "$MAIN_BRANCH" $DRAFT_FLAG 2>&1); then
        PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$' || echo "")
        echo "- **Number**: #$PR_NUMBER"
        echo "- **Title**: $CUSTOM_TITLE"
        [[ -n "$DRAFT_FLAG" ]] && echo "- **Status**: Draft" || echo "- **Status**: Open"
        echo "- **URL**: $PR_URL"
        [[ -n "$TEMPLATE_FILE" ]] && echo "- **Template**: Used $TEMPLATE_FILE"
        echo ""
        success "PR created successfully."
    else
        error_exit "Failed to create PR. Check GitHub authentication.\n$PR_URL"
    fi
fi
```
