# Quickstart: Git Lifecycle Plugin

**Date**: 2026-01-10
**Branch**: 001-git-lifecycle-plugin

## Prerequisites

Before using the Git Lifecycle Plugin, ensure you have:

1. **Git** (2.25+) installed and configured
   ```bash
   git --version
   ```

2. **GitHub CLI** (2.0+) installed and authenticated
   ```bash
   gh --version
   gh auth status
   ```

3. **Beads CLI** installed
   ```bash
   bd --version
   ```

4. **GPG key** configured for commit signing
   ```bash
   gpg --list-secret-keys --keyid-format=long
   git config --global user.signingkey <YOUR_KEY_ID>
   git config --global commit.gpgsign true
   ```

5. **Git worktree** environment set up
   ```
   your-repo/
   ├── .bare/        # Bare repository
   ├── .git → .bare  # Symlink
   ├── main/         # Main branch worktree
   └── ...           # Feature worktrees
   ```

---

## Installation

The plugin will be available at:
```
plugins/bkff-git/
```

Ensure the plugin is registered in your Claude Code configuration.

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/bkff:git-st` | Check current status |
| `/bkff:git-branch <issue>` | Create feature branch |
| `/bkff:git-commit` | Commit and push changes |
| `/bkff:git-sync [branch]` | Sync with main/branch |
| `/bkff:git-pr` | Create/update pull request |

---

## Typical Workflow

### 1. Start New Work

First, check the current status:
```
/bkff:git-st
```

Create a branch from a beads issue:
```
/bkff:git-branch beads-042
```

This will:
- Analyze the issue type (feature/bug/hotfix)
- Create appropriate branch (e.g., `feature/beads-042-user-auth`)
- Set up new worktree directory
- Push branch to origin
- Initialize beads database

### 2. Work on Changes

Navigate to your worktree and make changes. When ready to commit:

```
/bkff:git-commit
```

This will:
- Run validation (`make validate`)
- Stage all changes
- Generate conventional commit message
- Create GPG-signed commit
- Push to origin

### 3. Stay in Sync

Keep your branch up to date with main:
```
/bkff:git-sync
```

Or sync with a different branch:
```
/bkff:git-sync develop
```

The command automatically:
- Fetches all remote updates
- Rebases (if unpushed) or merges (if pushed)
- Resolves simple conflicts automatically

### 4. Create Pull Request

When ready for review:
```
/bkff:git-pr
```

This will:
- Push any unpushed commits
- Use PR template if available
- Create or update the PR
- Return the PR URL

---

## Examples

### Check Status Before Starting

```
> /bkff:git-st

## Git Status

### Working Directory
- **Branch**: feature/auth-login
- **Status**: Clean (no uncommitted changes)

### Last Commit
- **Hash**: abc1234
- **Message**: feat(auth): add login endpoint

### Beads Task
- **Issue**: beads-042
- **Title**: Implement user authentication
- **Status**: in_progress

### Pull Request
- No PR exists for this branch
```

### Create Feature Branch

```
> /bkff:git-branch beads-055

## Branch Created

- **Issue**: beads-055 - Add dashboard analytics
- **Branch**: feature/beads-055-dashboard-analytics
- **Worktree**: /Users/you/repo/beads-055-dashboard-analytics
- **Pushed**: Yes

To start working:
  cd /Users/you/repo/beads-055-dashboard-analytics
```

### Commit Changes

```
> /bkff:git-commit

## Commit Created

### Validation
- ✓ Build tool validate target passed

### Changes Committed
- **Files**: 3 files changed (+156, -23)

### Commit
- **Hash**: def5678
- **Message**: feat(dashboard): add analytics widget
- **Signed**: Yes (GPG key: 1234ABCD)

### Push
- **Status**: Success
```

### Sync with Main

```
> /bkff:git-sync

## Sync Complete (Merge)

### Fetch
- ✓ Fetched from origin

### Strategy
- **Mode**: Merge (branch already pushed)
- **Source**: main

### Result
- **Merge commit**: ghi9012
- **Conflicts**: None
```

### Create Pull Request

```
> /bkff:git-pr

## Pull Request Created

### Pull Request
- **Number**: #127
- **Title**: feat(dashboard): add analytics widget
- **URL**: https://github.com/owner/repo/pull/127

### Template
- ✓ Used .github/pull_request_template.md
```

---

## Error Handling

### Not in Git Worktree

```
> /bkff:git-commit

Error: Command must be run within a git worktree
```

**Solution**: Navigate to a valid worktree directory.

### Validation Failed

```
> /bkff:git-commit

## Commit Failed

### Validation
- ✗ Build tool validate target failed

Fix validation errors and try again.
```

**Solution**: Run `make validate` to see errors, fix them, then retry.

### GPG Signing Unavailable

```
> /bkff:git-commit

Error: GPG signing required but unavailable.
Configure GPG key first.
```

**Solution**: Set up GPG key per prerequisites section.

### Merge Conflicts

```
> /bkff:git-sync

## Sync Incomplete (Conflicts Require Resolution)

### Conflicts
1. src/auth/login.ts - lines 45-67

### Next Steps
1. Open conflicted files and resolve
2. Stage resolved files: git add <file>
3. Complete merge: git commit
```

**Solution**: Manually resolve conflicts in listed files.

---

## Configuration

### Build Tool Validate Target

The commit command expects a `validate` target in your build tool:

**Makefile**:
```makefile
validate:
	npm run lint
	npm run typecheck
	npm test
```

**package.json**:
```json
{
  "scripts": {
    "validate": "npm run lint && npm run typecheck && npm test"
  }
}
```

### PR Template

Create `.github/pull_request_template.md` for consistent PR descriptions:

```markdown
## Summary

<!-- Brief description of changes -->

## Changes

<!-- List of changes -->

## Test Plan

- [ ] Unit tests pass
- [ ] Manual testing completed

## Related Issues

<!-- Link to beads issues -->
```

---

## Tips

1. **Check status first**: Always run `/bkff:git-st` to understand current state before other operations.

2. **Sync frequently**: Regular `/bkff:git-sync` keeps your branch up to date and reduces merge conflicts.

3. **Let the tool generate messages**: The auto-generated conventional commit messages are consistent and follow project standards.

4. **Use beads issues**: Creating branches from beads issues ensures proper tracking and naming conventions.

5. **Review before pushing**: The commit command shows what will be committed before pushing.
