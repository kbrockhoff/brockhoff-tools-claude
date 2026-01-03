---
description: Branch management with naming conventions, creation, switching, and cleanup
argument-hint: [list|create|switch|delete|compare] [BRANCH] [--remote]
---

## Name
bkff-git:git-branch

## Synopsis
```
/bkff-git:git-branch [list|create|switch|delete|compare|prune] [BRANCH] [--remote] [--force] [--all]
```

## Description
The `git-branch` command provides comprehensive branch management with naming convention enforcement. It handles listing, creating, switching, deleting, and comparing branches while enforcing consistent naming patterns.

## Branch Naming Conventions

Branches must follow these prefixes:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New features | `feature/user-auth` |
| `bugfix/` | Bug fixes | `bugfix/login-timeout` |
| `hotfix/` | Urgent production fixes | `hotfix/security-patch` |
| `release/` | Release preparation | `release/v1.2.0` |
| `docs/` | Documentation changes | `docs/api-reference` |
| `refactor/` | Code refactoring | `refactor/auth-module` |
| `test/` | Test additions | `test/integration-suite` |
| `chore/` | Maintenance tasks | `chore/update-deps` |

## Implementation

### List Operation (Default)
```bash
list_branches() {
    local show_remote="$1"
    local show_all="$2"

    echo "=== Local Branches ==="
    git branch -vv --color=always

    if [[ "$show_remote" == "true" || "$show_all" == "true" ]]; then
        echo ""
        echo "=== Remote Branches ==="
        git branch -r -v --color=always
    fi

    # Show current branch
    echo ""
    echo "Current: $(git branch --show-current)"
}
```

### Create Operation
```bash
create_branch() {
    local branch_name="$1"
    local base_branch="${2:-HEAD}"

    # Validate naming convention
    if ! validate_branch_name "$branch_name"; then
        echo "Error: Invalid branch name '$branch_name'"
        echo ""
        echo "Branch names must start with one of:"
        echo "  feature/, bugfix/, hotfix/, release/,"
        echo "  docs/, refactor/, test/, chore/"
        echo ""
        echo "Example: feature/add-user-auth"
        return 1
    fi

    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "Error: Branch '$branch_name' already exists"
        return 1
    fi

    # Create and switch to branch
    git checkout -b "$branch_name" "$base_branch"
    echo "Created and switched to branch '$branch_name'"
}

validate_branch_name() {
    local name="$1"
    local valid_prefixes="^(feature|bugfix|hotfix|release|docs|refactor|test|chore)/"

    # Allow main/master/develop without prefix
    if [[ "$name" =~ ^(main|master|develop)$ ]]; then
        return 0
    fi

    # Check for valid prefix
    if [[ "$name" =~ $valid_prefixes ]]; then
        # Check for valid characters after prefix
        local suffix="${name#*/}"
        if [[ "$suffix" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]]; then
            return 0
        else
            echo "Hint: Use lowercase letters, numbers, and hyphens only"
            return 1
        fi
    fi

    return 1
}
```

### Switch Operation
```bash
switch_branch() {
    local branch_name="$1"
    local force="$2"

    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        if [[ "$force" != "true" ]]; then
            echo "Error: Uncommitted changes detected"
            echo ""
            echo "Options:"
            echo "  1. Commit changes: /bkff-git:git-commit ..."
            echo "  2. Stash changes:  git stash"
            echo "  3. Force switch:   /bkff-git:git-branch switch $branch_name --force"
            echo "     (Warning: --force discards uncommitted changes)"
            return 1
        else
            echo "Warning: Discarding uncommitted changes..."
        fi
    fi

    # Check if branch exists
    if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
        # Check remote
        if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
            echo "Creating local branch from origin/$branch_name..."
            git checkout -b "$branch_name" "origin/$branch_name"
            return $?
        else
            echo "Error: Branch '$branch_name' not found"
            echo "Create it with: /bkff-git:git-branch create $branch_name"
            return 1
        fi
    fi

    if [[ "$force" == "true" ]]; then
        git checkout --force "$branch_name"
    else
        git checkout "$branch_name"
    fi
}
```

### Delete Operation
```bash
delete_branch() {
    local branch_name="$1"
    local force="$2"
    local delete_remote="$3"

    local current=$(git branch --show-current)

    # Prevent deleting current branch
    if [[ "$branch_name" == "$current" ]]; then
        echo "Error: Cannot delete current branch '$branch_name'"
        echo "Switch to another branch first"
        return 1
    fi

    # Prevent deleting protected branches
    if [[ "$branch_name" =~ ^(main|master|develop)$ ]]; then
        echo "Error: Cannot delete protected branch '$branch_name'"
        return 1
    fi

    # Check if branch is merged
    if ! git branch --merged | grep -q "^\s*$branch_name$"; then
        if [[ "$force" != "true" ]]; then
            echo "Warning: Branch '$branch_name' is not fully merged"
            echo "Use --force to delete anyway"
            return 1
        fi
    fi

    # Delete local branch
    if [[ "$force" == "true" ]]; then
        git branch -D "$branch_name"
    else
        git branch -d "$branch_name"
    fi

    # Delete remote branch if requested
    if [[ "$delete_remote" == "true" ]]; then
        echo "Deleting remote branch..."
        git push origin --delete "$branch_name" 2>/dev/null || true
    fi

    echo "Deleted branch '$branch_name'"
}
```

### Compare Operation
```bash
compare_branches() {
    local branch1="${1:-$(git branch --show-current)}"
    local branch2="${2:-main}"

    echo "=== Comparing $branch1 to $branch2 ==="
    echo ""

    # Ahead/behind count
    local ahead=$(git rev-list --count "$branch2..$branch1")
    local behind=$(git rev-list --count "$branch1..$branch2")

    echo "Commits: $ahead ahead, $behind behind"
    echo ""

    # Show unique commits
    if [[ "$ahead" -gt 0 ]]; then
        echo "Commits in $branch1 not in $branch2:"
        git log --oneline "$branch2..$branch1" | head -10
        [[ "$ahead" -gt 10 ]] && echo "  ... and $((ahead - 10)) more"
        echo ""
    fi

    # Show file changes
    echo "Files changed:"
    git diff --stat "$branch2...$branch1" | tail -1
}
```

### Prune Operation
```bash
prune_branches() {
    echo "=== Pruning Stale Branches ==="

    # Fetch with prune
    git fetch --prune

    # Find local branches with deleted remotes
    echo ""
    echo "Local branches with no remote:"
    git branch -vv | grep ': gone]' | awk '{print $1}'

    echo ""
    echo "To delete these branches, run:"
    echo "  git branch -d <branch-name>"
}
```

## Return Value

- **Format**: Operation result with branch information
- **Includes**:
  - Branch list with tracking info
  - Creation/deletion confirmation
  - Comparison statistics
  - Error messages with suggestions

## Examples

1. **List local branches**:
   ```
   /bkff-git:git-branch list
   ```
   Shows local branches with tracking info.

2. **List all branches (including remote)**:
   ```
   /bkff-git:git-branch list --all
   ```

3. **Create feature branch**:
   ```
   /bkff-git:git-branch create feature/user-authentication
   ```
   Creates and switches to new branch.

4. **Create branch from specific base**:
   ```
   /bkff-git:git-branch create bugfix/login-fix main
   ```
   Creates branch from main instead of current HEAD.

5. **Switch branches**:
   ```
   /bkff-git:git-branch switch feature/other-feature
   ```

6. **Switch with uncommitted changes**:
   ```
   /bkff-git:git-branch switch main --force
   ```
   Warning: Discards uncommitted changes.

7. **Delete merged branch**:
   ```
   /bkff-git:git-branch delete feature/completed-feature
   ```

8. **Force delete unmerged branch**:
   ```
   /bkff-git:git-branch delete feature/abandoned --force
   ```

9. **Delete local and remote**:
   ```
   /bkff-git:git-branch delete feature/done --remote
   ```

10. **Compare branches**:
    ```
    /bkff-git:git-branch compare feature/my-branch main
    ```
    Shows commits ahead/behind and file changes.

11. **Prune stale branches**:
    ```
    /bkff-git:git-branch prune
    ```
    Removes stale remote refs and lists orphaned local branches.

## Arguments

- `list`: (Default) List branches
- `create BRANCH [BASE]`: Create new branch with optional base
- `switch BRANCH`: Switch to branch
- `delete BRANCH`: Delete branch
- `compare [BRANCH1] [BRANCH2]`: Compare two branches
- `prune`: Remove stale remote-tracking refs

### Flags
- `--remote`: Include remote branches in list, or delete remote when deleting
- `--all`: Show all branches (local + remote)
- `--force`: Force operation (discard changes on switch, delete unmerged)

## Naming Convention Enforcement

Invalid branch names are rejected:

```
/bkff-git:git-branch create my-feature

Error: Invalid branch name 'my-feature'

Branch names must start with one of:
  feature/, bugfix/, hotfix/, release/,
  docs/, refactor/, test/, chore/

Example: feature/my-feature
```

### Bypass Convention (Not Recommended)
Use raw git commands to bypass:
```bash
git checkout -b my-branch  # Bypasses validation
```

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| Invalid branch name | Missing/wrong prefix | Use valid prefix (feature/, bugfix/, etc.) |
| Branch exists | Duplicate name | Choose different name or switch to existing |
| Branch not found | Typo or not created | Check spelling or create branch |
| Uncommitted changes | Dirty working directory | Commit, stash, or use --force |
| Not fully merged | Deleting unmerged branch | Merge first or use --force |
| Protected branch | Deleting main/master/develop | Cannot delete protected branches |

## Protected Branches

These branches cannot be deleted:
- `main`
- `master`
- `develop`

## Related Commands

- `/bkff-git:git-status` - Check current branch status
- `/bkff-git:git-sync` - Sync branch with remote
- `/bkff-git:git-commit` - Commit changes before switching

## Notes

- Branch names use kebab-case after prefix
- Creating a branch automatically switches to it
- Remote branches are auto-tracked when switching
- Use `prune` regularly to clean up stale refs
