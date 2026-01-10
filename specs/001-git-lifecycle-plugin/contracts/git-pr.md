# Contract: /bkff:git-pr

**Command**: Manage Pull Request
**Priority**: P3

## Synopsis

```
/bkff:git-pr [--title "PR title"] [--draft]
```

## Description

Creates or updates a pull request for the current branch. Uses the repository's PR template if available, or generates a default description based on commits.

## Input

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `--title` | string | No | Override auto-generated PR title |
| `--draft` | flag | No | Create as draft PR |

## Output

### Create PR Success Response

```
## Pull Request Created

### Branch
- **Head**: feature/auth-login
- **Base**: main
- **Pushed**: Yes (was already up to date)

### Pull Request
- **Number**: #123
- **Title**: feat(auth): implement user authentication
- **Status**: Open
- **URL**: https://github.com/owner/repo/pull/123

### Template
- ✓ Used .github/pull_request_template.md

### Commits Included
1. feat(auth): add login endpoint
2. feat(auth): implement session management
3. test(auth): add authentication tests

PR created successfully. Awaiting review.
```

### Update PR Success Response

```
## Pull Request Updated

### Branch
- **Head**: feature/auth-login
- **Base**: main

### Pull Request
- **Number**: #123
- **Title**: feat(auth): implement user authentication
- **Status**: Open (updated)
- **URL**: https://github.com/owner/repo/pull/123

### Changes
- Updated description with latest commits
- Added 2 new commits since last update

PR updated successfully.
```

### Push Required Response

```
## Pull Request Created

### Branch
- **Head**: feature/auth-login
- **Base**: main
- **Pushed**: Yes (pushed 3 commits to origin)

### Pull Request
- **Number**: #124
- **Title**: feat(auth): implement user authentication
- **Status**: Open
- **URL**: https://github.com/owner/repo/pull/124

Branch was not pushed. Pushed to origin before creating PR.
```

## PR Description Generation

### With Template

If `.github/pull_request_template.md` exists:
- Template content is used as PR body
- Placeholders are filled with commit information
- Summary section populated from commit messages

### Without Template

Default format:
```markdown
## Summary

- feat(auth): add login endpoint
- feat(auth): implement session management
- test(auth): add authentication tests

## Changes

This PR includes the following changes:
- [Auto-generated from commit messages]

## Test Plan

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Error Responses

| Condition | Message |
|-----------|---------|
| Not in git worktree | "Error: Command must be run within a git worktree" |
| On main/master branch | "Error: Cannot create PR from main branch" |
| No commits | "Error: No commits to include in PR" |
| Push failed | "Error: Failed to push branch. Check network connection." |
| PR creation failed | "Error: Failed to create PR. Check GitHub authentication." |
| Already merged | "Error: Branch has already been merged" |

## Implementation Requirements

- FR-024: Check if PR already exists for branch
- FR-025: Update existing PR if one exists
- FR-026: Create new PR if none exists
- FR-027: Use PR template if available
- FR-028: Ensure branch is pushed before creating PR
- FR-033: Verify worktree context

## Dependencies

- `git` CLI
- `gh` CLI (GitHub CLI, authenticated)

## Side Effects

1. Pushes branch to origin if not already pushed
2. Creates PR on GitHub (if new)
3. Updates PR description on GitHub (if existing)
4. May trigger CI/CD workflows on GitHub
