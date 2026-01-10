# Contract: /bkff:git-st

**Command**: Status Check
**Priority**: P1

## Synopsis

```
/bkff:git-st
```

## Description

Displays comprehensive status of the current git worktree including uncommitted changes, last commit, in-progress beads tasks, and pull request status.

## Input

None required. Operates on current working directory.

## Output

### Success Response

```
## Git Status

### Working Directory
- **Branch**: feature/auth-login
- **Status**: 3 files changed (2 staged, 1 unstaged)

### Staged Changes
- M src/auth.ts (+45, -12)
- A src/utils/helpers.ts (+78)

### Unstaged Changes
- M README.md

### Last Commit
- **Hash**: abc1234
- **Message**: feat(auth): add login endpoint
- **Author**: Kevin Brockhoff
- **Date**: 2026-01-10 14:30:00

### Beads Task
- **Issue**: beads-042
- **Title**: Implement user authentication
- **Status**: in_progress

### Pull Request
- **PR #123**: Add authentication feature
- **Status**: Open (checks passing)
- **URL**: https://github.com/owner/repo/pull/123
```

### Clean State Response

```
## Git Status

### Working Directory
- **Branch**: feature/auth-login
- **Status**: Clean (no uncommitted changes)

### Last Commit
- **Hash**: abc1234
- **Message**: feat(auth): add login endpoint
- **Author**: Kevin Brockhoff
- **Date**: 2026-01-10 14:30:00

### Beads Task
- No in-progress tasks

### Pull Request
- No PR exists for this branch
```

## Error Responses

| Condition | Message |
|-----------|---------|
| Not in git worktree | "Error: Command must be run within a git worktree" |
| Detached HEAD | "Warning: HEAD is detached at abc1234" |
| Network error (PR check) | "Warning: Could not check PR status (network error)" |

## Implementation Requirements

- FR-001: Display uncommitted changes (staged and unstaged)
- FR-002: Display last commit information
- FR-003: Display in-progress beads tasks
- FR-004: Check and display PR information
- FR-005: Generate consolidated status message
- FR-033: Verify worktree context

## Dependencies

- `git` CLI
- `gh` CLI (for PR status)
- `bd` CLI (for beads task status)
