---
description: Create commits with conventional commit format enforcement and optional signing
argument-hint: <type>(<scope>): <description> [--co-author=NAME] [--no-verify]
---

## Name
bkff-git:git-commit

## Synopsis
```
/bkff-git:git-commit <type>(<scope>): <description> [--co-author=NAME <email>] [--no-verify] [--no-sign]
```

## Description
The `git-commit` command creates git commits with enforced conventional commit format. It validates commit messages, runs pre-commit hooks, supports co-authorship attribution, and integrates with commit signing when configured.

Conventional commits follow the format: `type(scope): description`

### Supported Types
| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `style` | Code style changes (formatting, semicolons, etc.) |
| `refactor` | Code refactoring (no feature or fix) |
| `perf` | Performance improvements |
| `test` | Adding or updating tests |
| `build` | Build system or dependency changes |
| `ci` | CI/CD configuration changes |
| `chore` | Maintenance tasks |
| `revert` | Revert a previous commit |

## Implementation

1. **Check for Staged Changes**: Verify there are changes to commit
   ```bash
   git diff --cached --quiet
   ```
   - If no staged changes, prompt user to stage files first
   - Suggest `git add` command

2. **Parse and Validate Commit Message**: Enforce conventional commit format
   - Extract type, scope (optional), and description
   - Validate type is in allowed list
   - Ensure description is present and meaningful (not empty)
   - Check description starts with lowercase (conventional style)
   - Validate total length (type + scope + description < 72 chars for subject line)

   Valid patterns:
   ```
   feat: add user authentication
   fix(auth): resolve token expiration bug
   docs(readme): update installation instructions
   refactor!: restructure API endpoints (breaking change)
   ```

3. **Detect Beads Issue References**: Link commits to issues
   - Scan message for patterns: `tool-xxx`, `fixes tool-xxx`, `closes tool-xxx`
   - If beads issue found, validate it exists
   - Append issue reference to commit body if not already present

4. **Check Signing Configuration**: Detect and use commit signing
   ```bash
   # Check if signing is configured
   git config --get commit.gpgsign
   git config --get user.signingkey

   # Detect available keys
   gpg --list-secret-keys --keyid-format=long 2>/dev/null
   ssh-add -l 2>/dev/null
   ```
   - If signing enabled, commits will be signed automatically
   - If signing required but not configured, warn user
   - Suggest `/bkff-git:git-signing` to configure

5. **Build Commit Command**: Construct the git commit command
   ```bash
   git commit -m "<message>" [--gpg-sign] [--no-verify]
   ```
   - Add `--gpg-sign` or `-S` if signing configured
   - Add `--no-verify` only if explicitly requested
   - Add co-author trailer if specified

6. **Run Pre-commit Hooks**: Execute hooks unless bypassed
   - Let git run pre-commit hooks normally
   - Report hook failures clearly
   - Do NOT suggest `--no-verify` unless user explicitly requests bypass

7. **Add Co-Author Attribution**: Support pair programming
   ```
   Co-Authored-By: Name <email@example.com>
   ```
   - Parse `--co-author` argument
   - Append to commit message body

8. **Execute Commit**: Create the commit
   ```bash
   git commit -m "type(scope): description" -m "Body with details" -m "Co-Authored-By: ..."
   ```
   - Show commit hash on success
   - Display files committed

## Return Value

- **Format**: Commit confirmation with details
- **Includes**:
  - Commit hash (short)
  - Branch name
  - Files changed summary
  - Signature status (if signing enabled)

## Examples

1. **Simple feature commit**:
   ```
   /bkff-git:git-commit feat: add user login endpoint
   ```
   Creates: `feat: add user login endpoint`

2. **Scoped bug fix**:
   ```
   /bkff-git:git-commit fix(auth): resolve session timeout issue
   ```
   Creates: `fix(auth): resolve session timeout issue`

3. **With co-author**:
   ```
   /bkff-git:git-commit feat(api): implement rate limiting --co-author="Alice Smith <alice@example.com>"
   ```
   Creates commit with Co-Authored-By trailer

4. **Breaking change**:
   ```
   /bkff-git:git-commit refactor!: change API response format
   ```
   The `!` indicates a breaking change

5. **With beads issue reference**:
   ```
   /bkff-git:git-commit fix(auth): resolve login bug closes tool-abc
   ```
   Links commit to beads issue tool-abc

6. **Bypass pre-commit hooks** (use sparingly):
   ```
   /bkff-git:git-commit chore: update generated files --no-verify
   ```

## Arguments

- `<message>`: (Required) Commit message in conventional format: `type(scope): description`
- `--co-author=NAME <email>`: (Optional) Add co-author attribution. Can be specified multiple times.
- `--no-verify`: (Optional) Skip pre-commit and commit-msg hooks. Use sparingly.
- `--no-sign`: (Optional) Skip commit signing even if configured.

## Validation Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Invalid type | Type not in allowed list | Use: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert |
| Missing description | Empty or whitespace-only description | Provide meaningful description after colon |
| Subject too long | Subject line > 72 characters | Shorten description, move details to body |
| No staged changes | Nothing to commit | Run `git add <files>` first |
| Hook failed | Pre-commit hook rejected commit | Fix issues reported by hooks |

## Commit Message Body

For complex changes, provide a body by including newlines:

```
/bkff-git:git-commit feat(auth): implement OAuth2 flow

This adds support for OAuth2 authentication with the following providers:
- Google
- GitHub
- Microsoft

Closes tool-xyz
```

## Error Handling

- **No staged changes**: List modified files and suggest staging
- **Invalid format**: Show correct format with examples
- **Hook failure**: Display hook output and suggest fixes
- **Signing failure**: Check key availability and suggest configuration

## Related Commands

- `/bkff-git:git-status` - Check repository state before committing
- `/bkff-git:git-signing` - Configure commit signing
- `/bkff-git:git-pr` - Create pull request after committing
