# Contract: /bkff:git-sync

**Command**: Sync with Remote
**Priority**: P3

## Synopsis

```
/bkff:git-sync [source-branch]
```

## Description

Fetches from origin for the entire worktree and integrates changes from a source branch (default: `main`). Automatically chooses rebase (for unpushed branches) or merge (for pushed branches) strategy.

## Input

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source-branch` | string | No | Branch to sync from (default: `main`) |

## Output

### Rebase Success Response

```
## Sync Complete (Rebase)

### Fetch
- ✓ Fetched from origin (all branches updated)

### Strategy
- **Mode**: Rebase (branch not yet pushed to origin)
- **Source**: main
- **Target**: feature/auth-login

### Result
- **Commits rebased**: 3
- **Conflicts**: None
- **Status**: Up to date with main

Branch rebased successfully. Ready to push.
```

### Merge Success Response

```
## Sync Complete (Merge)

### Fetch
- ✓ Fetched from origin (all branches updated)

### Strategy
- **Mode**: Merge (branch already pushed to origin)
- **Source**: main
- **Target**: feature/auth-login

### Result
- **Merge commit**: abc1234
- **Conflicts**: None
- **Status**: Up to date with main

Branch merged successfully.
```

### Auto-Resolved Conflicts Response

```
## Sync Complete (Merge with Auto-Resolution)

### Fetch
- ✓ Fetched from origin (all branches updated)

### Strategy
- **Mode**: Merge
- **Source**: main
- **Target**: feature/auth-login

### Conflicts Resolved
- src/config.ts: Auto-resolved (kept both changes)
- README.md: Auto-resolved (used rerere)

### Result
- **Merge commit**: abc1234
- **Auto-resolved**: 2 files
- **Manual resolution needed**: 0 files

Branch merged successfully with auto-resolved conflicts.
```

### Manual Resolution Required Response

```
## Sync Incomplete (Conflicts Require Resolution)

### Fetch
- ✓ Fetched from origin (all branches updated)

### Strategy
- **Mode**: Merge
- **Source**: main
- **Target**: feature/auth-login

### Conflicts
The following files have conflicts that require manual resolution:

1. **src/auth/login.ts**
   - Conflict at lines 45-67
   - Main changed: Added rate limiting
   - Your change: Modified error handling

2. **src/utils/helpers.ts**
   - Conflict at lines 12-20
   - Main changed: Updated function signature
   - Your change: Added new parameter

### Next Steps
1. Open conflicted files and resolve conflicts
2. Stage resolved files: `git add <file>`
3. Complete merge: `git commit`

Or abort: `git merge --abort`
```

## Strategy Selection Logic

| Condition | Strategy |
|-----------|----------|
| Branch not pushed to origin | Rebase |
| Branch already pushed to origin | Merge |

## Error Responses

| Condition | Message |
|-----------|---------|
| Not in git worktree | "Error: Command must be run within a git worktree" |
| Source branch not found | "Error: Branch 'develop' not found. Available branches:\n- main\n- staging" |
| Network error | "Error: Fetch failed. Check network connection." |
| Uncommitted changes | "Error: You have uncommitted changes. Commit or stash before syncing." |

## Implementation Requirements

- FR-018: Fetch from origin for entire worktree
- FR-019: Determine if branch has commits pushed to origin
- FR-020: Use rebase when no commits pushed
- FR-021: Use merge when commits already pushed
- FR-022: Accept optional branch parameter (default: `main`)
- FR-023: Attempt automatic conflict resolution
- FR-033: Verify worktree context

## Dependencies

- `git` CLI (with rerere enabled)

## Side Effects

1. Fetches all remote refs (`git fetch origin --prune`)
2. Either rebases or merges from source branch
3. May create merge commit (merge strategy)
4. May modify working directory files (during conflict resolution)
5. Updates rerere cache for resolved conflicts
