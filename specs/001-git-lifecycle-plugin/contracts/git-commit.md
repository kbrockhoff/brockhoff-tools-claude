# Contract: /bkff:git-commit

**Command**: Commit Changes
**Priority**: P2

## Synopsis

```
/bkff:git-commit [--message "custom message"] [--co-author "Name <email>"]
```

## Description

Validates changes, stages all new and modified files, generates a conventional commit message, creates a GPG-signed commit, and pushes to origin.

## Input

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `--message` | string | No | Override auto-generated commit message |
| `--co-author` | string | No | Add co-author attribution |

## Output

### Success Response

```
## Commit Created

### Validation
- ✓ Build tool validate target passed

### Changes Committed
- **Files**: 5 files changed (+234, -45)
  - M src/auth/login.ts
  - M src/auth/session.ts
  - A src/auth/tokens.ts
  - M tests/auth.test.ts
  - M README.md

### Commit
- **Hash**: abc1234def5678
- **Message**: feat(auth): implement JWT token authentication
- **Signed**: Yes (GPG key: 1234ABCD)
- **Co-Author**: Alice Smith <alice@example.com>

### Push
- **Remote**: origin/feature/auth-login
- **Status**: Success

Commit pushed to origin.
```

### Validation Failure Response

```
## Commit Failed

### Validation
- ✗ Build tool validate target failed

### Errors
```
lint: 3 errors found
  src/auth.ts:45 - Missing semicolon
  src/auth.ts:67 - Unused variable 'token'
  src/utils.ts:12 - Type error: string not assignable to number
```

Fix validation errors and try again.
```

## Conventional Commit Generation

The command analyzes staged changes to generate appropriate commit messages:

| Change Pattern | Generated Type |
|----------------|----------------|
| New files in `src/` | `feat` |
| Modifications to existing code | `fix` or `refactor` |
| Test file changes only | `test` |
| Documentation changes | `docs` |
| Build/config changes | `build` or `ci` |

**Scope**: Derived from changed file paths (e.g., `auth`, `api`, `db`)

## Error Responses

| Condition | Message |
|-----------|---------|
| Not in git worktree | "Error: Command must be run within a git worktree" |
| No changes | "Nothing to commit. Working directory is clean." |
| Validation failed | "Error: Validation failed. Fix errors before committing." |
| GPG unavailable | "Error: GPG signing required but unavailable. Configure GPG key first." |
| Push failed | "Error: Push failed (commit preserved locally).\nRun 'git push' to retry." |

## Implementation Requirements

- FR-012: Run build tool validate target before committing
- FR-013: Halt if validation fails
- FR-014: Stage all new and changed files
- FR-015: Generate conventional commit message
- FR-016: Create signed commit using GPG
- FR-017: Push to origin after commit
- FR-033: Verify worktree context

## Dependencies

- `git` CLI
- GPG (for commit signing)
- Project build tool with `validate` target

## Side Effects

1. Runs `make validate` or equivalent
2. Stages all changes (`git add -A`)
3. Creates GPG-signed commit
4. Pushes commit to origin remote
5. Updates remote tracking branch
