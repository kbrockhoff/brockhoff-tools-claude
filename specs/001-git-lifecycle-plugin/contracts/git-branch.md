# Contract: /bkff:git-branch

**Command**: Create Feature Branch
**Priority**: P2

## Synopsis

```
/bkff:git-branch <issue-id>
```

## Description

Creates a new git branch and worktree from a beads issue. Automatically determines the branch type prefix based on issue type and priority, pushes to origin, and initializes beads database.

## Input

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `issue-id` | string | Yes | Beads issue identifier (e.g., `beads-042`) |

## Output

### Success Response

```
## Branch Created

- **Issue**: beads-042 - Implement user authentication
- **Branch**: feature/beads-042-user-auth
- **Worktree**: /path/to/repo/beads-042-user-auth
- **Pushed**: Yes (origin/feature/beads-042-user-auth)
- **Beads**: Initialized and synced

To start working:
  cd /path/to/repo/beads-042-user-auth
```

### Hotfix Response

```
## Hotfix Branch Created

- **Issue**: beads-099 - Critical security vulnerability
- **Priority**: P0 (Critical)
- **Branch**: hotfix/beads-099-security-fix
- **Worktree**: /path/to/repo/beads-099-security-fix
- **Pushed**: Yes (origin/hotfix/beads-099-security-fix)
- **Beads**: Initialized and synced

⚠️ Hotfix branch created from main. Remember to backport if needed.

To start working:
  cd /path/to/repo/beads-099-security-fix
```

## Branch Prefix Logic

| Issue Type | Priority | Prefix |
|------------|----------|--------|
| `feature` | any | `feature/` |
| `bug` | 2-4 (medium-backlog) | `bugfix/` |
| `bug` | 0-1 (critical-high) | `hotfix/` |
| `task` | any | `feature/` |

## Error Responses

| Condition | Message |
|-----------|---------|
| Not in git worktree | "Error: Command must be run within a git worktree" |
| Invalid issue ID | "Error: Issue 'xyz' not found. Valid issues:\n- beads-001: Title 1\n- beads-002: Title 2" |
| Branch exists | "Error: Branch 'feature/beads-042-user-auth' already exists" |
| Worktree path exists | "Error: Directory '/path/to/worktree' already exists" |
| Push failed | "Error: Failed to push branch to origin. Check network connection." |

## Implementation Requirements

- FR-006: Accept beads issue ID as input
- FR-007: Analyze issue to determine branch prefix
- FR-008: Create new local branch in worktree directory
- FR-009: Push new branch to origin
- FR-010: Initialize beads database
- FR-011: Sync beads database
- FR-033: Verify worktree context

## Dependencies

- `git` CLI
- `bd` CLI (for issue retrieval and beads init)

## Side Effects

1. Creates new directory at `../<issue-id>-<short-title>`
2. Creates new git branch with appropriate prefix
3. Pushes branch to origin remote
4. Initializes `.beads/` directory in new worktree
5. Syncs beads database with remote
