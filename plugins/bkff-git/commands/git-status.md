---
description: Comprehensive repository status showing working tree, branch, commits, and stashes
argument-hint: [--commits=N]
---

## Name
bkff-git:git-status

## Synopsis
```
/bkff-git:git-status [--commits=N]
```

## Description
The `git-status` command provides a comprehensive view of the current git repository state. It combines multiple git commands to give a complete picture of the working directory, staging area, branch status, recent history, and stashes.

This command is useful before performing operations like commits, merges, or rebases to understand the current state of the repository.

## Implementation

1. **Verify Git Repository**: Check that the current directory is inside a git repository
   ```bash
   git rev-parse --is-inside-work-tree
   ```
   - If not a git repo, output an error message and stop

2. **Get Branch Information**: Display current branch and tracking status
   ```bash
   git branch -vv --contains HEAD
   ```
   - Show current branch name
   - Show tracking branch (if any)
   - Show ahead/behind count relative to upstream

3. **Show Working Tree Status**: Display staged, unstaged, and untracked files
   ```bash
   git status --short --branch
   ```
   - Staged changes (green/ready to commit)
   - Unstaged changes (red/modified but not staged)
   - Untracked files

4. **List Recent Commits**: Show recent commit history
   ```bash
   git log --oneline -n ${commits:-5}
   ```
   - Default to 5 commits if `--commits` not specified
   - Show commit hash and message
   - Include author for context

5. **Show Stash Count**: Display number of stashed changes
   ```bash
   git stash list | wc -l
   ```
   - If stashes exist, show count and hint about `git stash list`

6. **Check for Uncommitted Changes**: Summarize repository cleanliness
   - Report if working directory is clean
   - Warn about uncommitted changes that could be lost

## Return Value

- **Format**: Structured text report with sections
- **Sections**:
  - Branch: Current branch and tracking info
  - Status: Working tree changes summary
  - Recent Commits: Last N commits
  - Stashes: Count of stashed changes
  - Summary: Clean/dirty state indicator

## Examples

1. **Basic status check**:
   ```
   /bkff-git:git-status
   ```
   Output:
   ```
   ## Branch
   main (tracking origin/main, up to date)

   ## Working Tree
   Clean - no uncommitted changes

   ## Recent Commits (5)
   a1b2c3d feat: add user authentication
   d4e5f6g fix: resolve login timeout
   h7i8j9k docs: update API documentation
   l0m1n2o refactor: simplify error handling
   p3q4r5s chore: update dependencies

   ## Stashes
   No stashes
   ```

2. **With uncommitted changes**:
   ```
   /bkff-git:git-status
   ```
   Output:
   ```
   ## Branch
   feature/new-feature (tracking origin/feature/new-feature, 2 ahead)

   ## Working Tree
   Staged:
     M src/auth.ts
     A src/utils/helper.ts

   Unstaged:
     M README.md

   Untracked:
     ?? temp.log

   ## Recent Commits (5)
   ...

   ## Stashes
   2 stash(es) - run `git stash list` for details
   ```

3. **Show more commits**:
   ```
   /bkff-git:git-status --commits=10
   ```
   Shows last 10 commits instead of default 5.

## Arguments

- `--commits=N`: (Optional) Number of recent commits to display. Defaults to 5.

## Error Handling

- **Not a git repository**: Output clear error message directing user to initialize or navigate to a git repository
- **Detached HEAD**: Indicate detached HEAD state and show the commit hash
- **No commits yet**: Handle new repositories with no commit history

## Related Commands

- `/bkff-git:git-commit` - Create a new commit
- `/bkff-git:git-sync` - Fetch, pull, or push changes
- `/bkff-git:git-branch` - Manage branches
