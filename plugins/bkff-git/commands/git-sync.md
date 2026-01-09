---
description: Synchronize with remote repositories via fetch, pull, and push operations
argument-hint: [fetch|pull|push|all] [--rebase] [--remote=NAME]
---

## Name
bkff-git:git-sync

## Synopsis
```
/bkff-git:git-sync [fetch|pull|push|all] [--rebase] [--force-with-lease] [--remote=NAME] [--prune]
```

## Description
The `git-sync` command provides streamlined synchronization with remote repositories. It handles fetch, pull, and push operations with intelligent defaults, conflict detection, and status reporting before and after operations.

Default operation is `all` which performs fetch, pull (with rebase), and push in sequence.

## Implementation

### Step 1: Check Repository State
```bash
# Verify git repository
git rev-parse --is-inside-work-tree

# Get current branch
current_branch=$(git branch --show-current)

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Warning: Uncommitted changes detected"
    echo "Consider committing or stashing before sync"
fi

# Get tracking branch
tracking=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
```

### Step 2: Show Pre-Sync Status
```bash
# Fetch to update remote refs (always do this first)
git fetch ${remote:-origin} --quiet

# Show ahead/behind count
git rev-list --left-right --count ${tracking}...HEAD 2>/dev/null

# Format: "2 commits ahead, 3 commits behind origin/main"
```

### Step 3: Execute Requested Operation

#### Fetch Operation
```bash
fetch_remote() {
    local remote="${1:-origin}"

    echo "Fetching from $remote..."
    git fetch "$remote" --progress ${prune:+--prune}

    # Show what was fetched
    git fetch --dry-run "$remote" 2>&1 | grep -v "^$"
}
```

#### Pull Operation
```bash
pull_remote() {
    local remote="${1:-origin}"
    local branch="$current_branch"

    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Error: Uncommitted changes would be overwritten"
        echo "Commit, stash, or discard changes first"
        return 1
    fi

    echo "Pulling from $remote/$branch..."

    if [[ "$rebase" == "true" ]]; then
        git pull --rebase "$remote" "$branch"
    else
        git pull "$remote" "$branch"
    fi

    # Handle conflicts
    if [[ $? -ne 0 ]]; then
        if git diff --name-only --diff-filter=U | grep -q .; then
            echo "Merge conflicts detected in:"
            git diff --name-only --diff-filter=U
            echo ""
            echo "Resolve conflicts then run:"
            echo "  git add <resolved-files>"
            echo "  git rebase --continue  # if rebasing"
            echo "  git commit             # if merging"
            return 1
        fi
    fi
}
```

#### Push Operation
```bash
push_remote() {
    local remote="${1:-origin}"
    local branch="$current_branch"

    # Check if branch has upstream
    if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
        echo "Setting upstream to $remote/$branch..."
        git push -u "$remote" "$branch"
    else
        if [[ "$force_with_lease" == "true" ]]; then
            git push --force-with-lease "$remote" "$branch"
        else
            git push "$remote" "$branch"
        fi
    fi
}
```

#### All Operation (Default)
```bash
sync_all() {
    local remote="${1:-origin}"

    echo "=== Sync Status ==="
    show_status
    echo ""

    echo "=== Fetching ==="
    fetch_remote "$remote"
    echo ""

    echo "=== Pulling ==="
    if ! pull_remote "$remote"; then
        echo "Pull failed. Resolve issues before continuing."
        return 1
    fi
    echo ""

    echo "=== Pushing ==="
    push_remote "$remote"
    echo ""

    echo "=== Final Status ==="
    show_status
}
```

### Step 4: Show Post-Sync Status
```bash
show_status() {
    local tracking=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

    if [[ -z "$tracking" ]]; then
        echo "Branch '$current_branch' has no upstream tracking branch"
        return
    fi

    local ahead=$(git rev-list --count ${tracking}..HEAD)
    local behind=$(git rev-list --count HEAD..${tracking})

    if [[ "$ahead" -eq 0 && "$behind" -eq 0 ]]; then
        echo "✓ Branch is up to date with $tracking"
    else
        [[ "$ahead" -gt 0 ]] && echo "↑ $ahead commit(s) ahead of $tracking"
        [[ "$behind" -gt 0 ]] && echo "↓ $behind commit(s) behind $tracking"
    fi
}
```

### Step 5: Handle Multiple Remotes
```bash
list_remotes() {
    echo "Available remotes:"
    git remote -v | grep "(fetch)" | awk '{print "  " $1 ": " $2}'
}

# If --remote not specified and multiple remotes exist
remote_count=$(git remote | wc -l)
if [[ "$remote_count" -gt 1 && -z "$specified_remote" ]]; then
    echo "Multiple remotes detected. Using 'origin'."
    echo "Specify with --remote=NAME to use a different remote."
    list_remotes
fi
```

## Return Value

- **Format**: Sync operation summary
- **Includes**:
  - Pre-sync status (ahead/behind)
  - Operation results (fetch/pull/push)
  - Post-sync status
  - Conflict information (if any)

## Examples

1. **Full sync (default)**:
   ```
   /bkff-git:git-sync
   ```
   Fetches, pulls (with rebase), and pushes.

2. **Fetch only**:
   ```
   /bkff-git:git-sync fetch
   ```
   Updates remote refs without modifying working directory.

3. **Pull with rebase**:
   ```
   /bkff-git:git-sync pull --rebase
   ```
   Pulls and rebases local commits on top.

4. **Pull with merge** (no rebase):
   ```
   /bkff-git:git-sync pull
   ```
   Standard merge pull.

5. **Push only**:
   ```
   /bkff-git:git-sync push
   ```
   Pushes current branch to remote.

6. **Force push with safety**:
   ```
   /bkff-git:git-sync push --force-with-lease
   ```
   Force push that fails if remote has new commits.

7. **Sync with specific remote**:
   ```
   /bkff-git:git-sync all --remote=upstream
   ```
   Syncs with 'upstream' instead of 'origin'.

8. **Fetch and prune stale branches**:
   ```
   /bkff-git:git-sync fetch --prune
   ```
   Removes local refs to deleted remote branches.

## Arguments

- `fetch`: Fetch from remote only (update refs, no local changes)
- `pull`: Pull changes from remote (fetch + merge/rebase)
- `push`: Push local commits to remote
- `all`: (Default) Fetch, pull, then push
- `--rebase`: Use rebase instead of merge for pull (recommended)
- `--force-with-lease`: Safe force push (fails if remote changed)
- `--remote=NAME`: Specify remote (default: origin)
- `--prune`: Remove stale remote-tracking references

## Conflict Handling

When conflicts occur during pull:

```
Merge conflicts detected in:
  src/auth.ts
  src/utils.ts

Resolve conflicts then run:
  git add <resolved-files>
  git rebase --continue  # if rebasing
  git commit             # if merging
```

### Resolving Conflicts
1. Open conflicted files
2. Look for conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
3. Edit to resolve
4. Stage resolved files: `git add <file>`
5. Continue: `git rebase --continue` or `git commit`

### Aborting
```bash
git rebase --abort  # if rebasing
git merge --abort   # if merging
```

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| Uncommitted changes | Dirty working directory | Commit or stash changes first |
| Merge conflicts | Divergent histories | Resolve conflicts manually |
| Push rejected | Remote has new commits | Pull first, then push |
| No upstream | Branch not tracking remote | Will auto-set with `-u` |
| Authentication failed | Invalid credentials | Re-authenticate with remote |
| Remote not found | Invalid remote name | Check `git remote -v` |

## Best Practices

1. **Always fetch first**: See what's changed before pulling
2. **Use rebase for feature branches**: Keeps history clean
3. **Don't force push shared branches**: Use `--force-with-lease` if necessary
4. **Commit before syncing**: Avoid uncommitted change issues
5. **Prune regularly**: Remove stale remote refs with `--prune`

## Multiple Remote Workflow

For fork-based development:

```bash
# Add upstream remote
git remote add upstream https://github.com/original/repo.git

# Sync with upstream
/bkff-git:git-sync pull --remote=upstream --rebase

# Push to your fork
/bkff-git:git-sync push --remote=origin
```

## Related Commands

- `/bkff-git:git-status` - Check repository state
- `/bkff-git:git-branch` - Manage branches
- `/bkff-git:git-commit` - Create commits before pushing

## Notes

- Default uses `--rebase` for pull (configurable)
- Automatically sets upstream on first push
- Shows progress for long operations
- Safe by default: no force push without explicit flag
