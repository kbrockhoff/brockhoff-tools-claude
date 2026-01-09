---
name: GitHub CLI Integration
description: Foundation skill for GitHub CLI (gh) operations including authentication, PRs, and issues
---

# GitHub CLI Integration

This skill provides the foundation for all GitHub CLI operations in the bkff-git plugin. It handles detection, authentication verification, and common operations for pull requests and issues.

## When to Use This Skill

Use this skill when you need to:
- Verify GitHub CLI is installed and authenticated
- Create, list, view, or merge pull requests
- Create, list, view, or close GitHub issues
- Check repository permissions
- Interact with GitHub API via the CLI

## Prerequisites

### Required Tools
- **GitHub CLI (`gh`)**: Version 2.0 or later
  - Install: `brew install gh` (macOS) or see https://cli.github.com/
- **Git**: For repository context
- **Network access**: To reach GitHub API

### Authentication
The `gh` CLI must be authenticated before use:
```bash
gh auth login
```

## Implementation Steps

### Step 1: Detect GitHub CLI Installation

Check if `gh` is installed and get version:

```bash
# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed"
    echo "Install: brew install gh (macOS) or https://cli.github.com/"
    exit 1
fi

# Get version
gh --version
```

Expected output: `gh version 2.x.x (YYYY-MM-DD)`

### Step 2: Verify Authentication Status

Check if user is authenticated:

```bash
# Check auth status
gh auth status
```

Possible states:
- **Authenticated**: Shows username and token scopes
- **Not authenticated**: Prompts to run `gh auth login`
- **Token expired**: Prompts to refresh

```bash
# Get authenticated user
gh api user --jq '.login'
```

### Step 3: Verify Repository Context

Ensure we're in a GitHub repository:

```bash
# Check if remote is GitHub
git remote get-url origin | grep -q "github.com"

# Get repo info
gh repo view --json owner,name,defaultBranchRef
```

### Step 4: Common Operations

#### Pull Request Operations

**List PRs:**
```bash
# List open PRs
gh pr list

# List PRs with filters
gh pr list --state=open --author=@me
gh pr list --label="bug" --limit=10
```

**View PR:**
```bash
# View PR details
gh pr view <number>
gh pr view <number> --json title,body,state,reviews

# View PR in browser
gh pr view <number> --web
```

**Create PR:**
```bash
# Interactive create
gh pr create

# Non-interactive create
gh pr create --title "Title" --body "Description" --base main

# Create draft PR
gh pr create --draft --title "WIP: Feature" --body "Work in progress"

# With reviewers and labels
gh pr create --title "Fix bug" --reviewer user1,user2 --label bug
```

**Merge PR:**
```bash
# Merge with default method
gh pr merge <number>

# Squash merge
gh pr merge <number> --squash

# Rebase merge
gh pr merge <number> --rebase

# Auto-merge when checks pass
gh pr merge <number> --auto --squash
```

#### Issue Operations

**List Issues:**
```bash
# List open issues
gh issue list

# With filters
gh issue list --assignee=@me
gh issue list --label="enhancement" --limit=20
```

**View Issue:**
```bash
# View issue details
gh issue view <number>
gh issue view <number> --json title,body,state,labels
```

**Create Issue:**
```bash
# Interactive create
gh issue create

# Non-interactive
gh issue create --title "Bug report" --body "Description"
gh issue create --title "Feature" --label enhancement --assignee @me
```

**Close Issue:**
```bash
# Close issue
gh issue close <number>
gh issue close <number> --comment "Fixed in #123"
```

#### Repository Operations

**Get Repository Info:**
```bash
# Basic info
gh repo view

# JSON output for parsing
gh repo view --json name,owner,defaultBranchRef,description
```

**Check Permissions:**
```bash
# Get current user's permission level
gh api repos/{owner}/{repo}/collaborators/{username}/permission --jq '.permission'
```

## Error Handling

### gh not installed
```
Error: GitHub CLI (gh) is not installed
```
**Solution**: Install via `brew install gh` or from https://cli.github.com/

### Not authenticated
```
Error: gh auth login required
```
**Solution**: Run `gh auth login` and follow prompts

### Token expired
```
Error: authentication token has expired
```
**Solution**: Run `gh auth refresh`

### Insufficient permissions
```
Error: HTTP 403: Must have push access to repository
```
**Solution**: Check repository access or request permissions

### Rate limited
```
Error: HTTP 403: API rate limit exceeded
```
**Solution**: Wait for rate limit reset or authenticate for higher limits

### Not a GitHub repository
```
Error: not a git repository or no GitHub remote
```
**Solution**: Ensure you're in a git repo with a GitHub remote

## Utility Functions

### Check Prerequisites
```bash
check_gh_ready() {
    # Check gh installed
    if ! command -v gh &> /dev/null; then
        echo "Error: GitHub CLI not installed"
        return 1
    fi

    # Check authenticated
    if ! gh auth status &> /dev/null; then
        echo "Error: Not authenticated. Run: gh auth login"
        return 1
    fi

    # Check GitHub remote
    if ! git remote get-url origin 2>/dev/null | grep -q "github.com"; then
        echo "Error: No GitHub remote found"
        return 1
    fi

    return 0
}
```

### Get Current PR
```bash
get_current_pr() {
    gh pr view --json number,title,state --jq '{number, title, state}' 2>/dev/null
}
```

### Get CODEOWNERS Reviewers
```bash
get_codeowners_reviewers() {
    local files="$1"
    # Parse CODEOWNERS for matching patterns
    if [[ -f ".github/CODEOWNERS" ]]; then
        # Extract owners for changed files
        gh api repos/{owner}/{repo}/pulls/{pr}/requested_reviewers
    fi
}
```

## Examples

### Example 1: Full PR Workflow
```bash
# Check prerequisites
gh auth status

# Create feature branch
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Push and create PR
git push -u origin feature/new-feature
gh pr create --title "feat: add new feature" --body "Description here"

# After review, merge
gh pr merge --squash --delete-branch
```

### Example 2: Issue Triage
```bash
# List unassigned bugs
gh issue list --label="bug" --assignee=""

# Assign and add to project
gh issue edit 123 --assignee @me
gh issue edit 123 --add-label "in-progress"

# Close when fixed
gh issue close 123 --comment "Fixed in #456"
```

### Example 3: Check CI Status
```bash
# View PR checks
gh pr checks

# Wait for checks to pass
gh pr checks --watch

# View specific check details
gh run view
```

## Integration Points

This skill is used by:
- `/bkff-git:git-pr` - Pull request creation
- `/bkff-git:git-status` - Show PR status for current branch

## Notes

- Always verify authentication before operations
- Use `--json` flag for parseable output
- Respect rate limits (5000 requests/hour authenticated)
- Use `GH_TOKEN` environment variable for CI/CD
- CODEOWNERS parsing requires repository read access
