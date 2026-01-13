# Contract: /bkff:git-pr

**Command**: Manage Pull Request
**Priority**: P3

## Synopsis

```
/bkff:git-pr [--title "PR title"] [--draft] [--ready] [--comments] [--analyze]
```

## Description

Creates or updates a pull request for the current branch. Uses the repository's PR template if available, or generates a default description based on commits. Supports draft PRs, marking drafts as ready, retrieving review comments, and analyzing comments for requirements compliance.

## Input

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `--title` | string | No | Override auto-generated PR title |
| `--draft` | flag | No | Create as draft PR (not ready for review) |
| `--ready` | flag | No | Mark existing draft PR as ready for review |
| `--comments` | flag | No | Retrieve and display review comments |
| `--analyze` | flag | No | Analyze comments for requirements compliance (requires `--comments`) |

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

### Create Draft PR Response

```
## Draft Pull Request Created

### Branch
- **Head**: feature/auth-login
- **Base**: main
- **Pushed**: Yes

### Pull Request
- **Number**: #123
- **Title**: feat(auth): implement user authentication
- **Status**: Draft (not ready for review)
- **URL**: https://github.com/owner/repo/pull/123

### Commits Included
1. feat(auth): add login endpoint
2. feat(auth): implement session management

Draft PR created. Use `/bkff:git-pr --ready` when ready for review.
```

### Mark PR Ready Response

```
## Pull Request Ready for Review

### Pull Request
- **Number**: #123
- **Title**: feat(auth): implement user authentication
- **Status**: Open (was Draft)
- **URL**: https://github.com/owner/repo/pull/123

PR is now ready for review.
```

### PR Already Ready Response

```
## Pull Request Already Ready

### Pull Request
- **Number**: #123
- **Title**: feat(auth): implement user authentication
- **Status**: Open

PR is already ready for review. No changes made.
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

### Review Comments Response

```
## Review Comments for PR #123

### Summary
- **Total Comments**: 5
- **Reviewers**: @alice (3), @bob (2)

### Comments

#### @alice on src/auth/login.ts:45
> Consider using a constant for the timeout value instead of a magic number.

---

#### @alice on src/auth/session.ts:78-82
> This block should handle the case where the session has expired.

---

#### @bob on src/auth/tokens.ts:23
> Good implementation! Minor: variable name could be more descriptive.

---

#### @alice on (general)
> Overall looks good. A few minor suggestions above.

---

#### @bob on (general)
> Approved with minor comments.

---

Use `/bkff:git-pr --comments --analyze` for compliance analysis.
```

### No Review Comments Response

```
## Review Comments for PR #123

No review comments exist for this pull request.
```

### Review Comments with Analysis Response

```
## Review Comments Analysis for PR #123

### Summary
- **Total Comments**: 5
- **Requirements-Related**: 3 (60%)
- **Stylistic/Preference**: 2 (40%)

### Analysis

#### @alice on src/auth/login.ts:45
> Consider using a constant for the timeout value instead of a magic number.

**Compliance Score**: 25%
**Category**: Stylistic/Preference
**Rationale**: This is a code style suggestion for maintainability. Not directly tied to functional requirements or security principles.

---

#### @alice on src/auth/session.ts:78-82
> This block should handle the case where the session has expired.

**Compliance Score**: 95%
**Category**: Requirements-Related
**Rationale**: Addresses FR-016 (session management) and security principle of proper session lifecycle handling. Missing error handling could lead to undefined behavior.
**Requirements**: FR-016

---

#### @bob on src/auth/tokens.ts:23
> Good implementation! Minor: variable name could be more descriptive.

**Compliance Score**: 15%
**Category**: Stylistic/Preference
**Rationale**: Naming suggestion for code readability. No impact on requirements compliance or security.

---

#### @alice on (general)
> Overall looks good. A few minor suggestions above.

**Compliance Score**: N/A
**Category**: General Feedback
**Rationale**: Summary comment without actionable code change.

---

#### @bob on (general)
> Approved with minor comments.

**Compliance Score**: N/A
**Category**: General Feedback
**Rationale**: Approval comment without actionable code change.

---

### Recommendation
**Priority comments to address**:
1. src/auth/session.ts:78-82 (95% compliance score) - Session expiration handling
```

### Analysis Without Spec File Response

```
## Review Comments Analysis for PR #123

### Summary
- **Total Comments**: 3
- **Spec File**: Not found (evaluating against general principles)

### Analysis

#### @alice on src/api/handler.ts:34
> User input should be validated before processing.

**Compliance Score**: 90%
**Category**: Security-Related
**Rationale**: Addresses OWASP input validation principle. User input handling without validation is a security risk.
**Principles**: OWASP Input Validation

---

[Additional comments...]

Note: No spec.md found in specs directory. Analysis based on general security principles and coding best practices.
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
| --ready without existing PR | "Error: No PR exists for this branch. Create one first." |
| --ready on non-draft PR | "PR is already ready for review. No changes made." |
| --comments without existing PR | "Error: No PR exists for this branch." |
| --analyze without --comments | "Error: --analyze requires --comments flag" |

## Implementation Requirements

### Core PR Management
- FR-024: Check if PR already exists for branch
- FR-025: Update existing PR if one exists
- FR-026: Create new PR if none exists
- FR-027: Use PR template if available
- FR-028: Ensure branch is pushed before creating PR
- FR-033: Verify worktree context

### Draft PR Support
- FR-034: Create PR as draft when `--draft` flag provided
- FR-035: Mark draft PR as ready when `--ready` flag provided
- FR-036: Indicate when `--ready` used on already-ready PR

### Review Comments
- FR-037: Retrieve and display all review comments when `--comments` flag provided
- FR-038: Display reviewer attribution (name/username) with each comment
- FR-039: Indicate when no review comments exist

### Comment Analysis
- FR-040: Analyze comments against requirements when `--comments --analyze` provided
- FR-041: Assign compliance probability score (0-100%) to each comment
- FR-042: Provide brief rationale explaining requirements/security addressed
- FR-043: Identify stylistic/preference comments as outside scope
- FR-044: Use spec's functional requirements when spec file exists
- FR-045: Evaluate against general security principles when no spec file

## Dependencies

- `git` CLI
- `gh` CLI (GitHub CLI, authenticated)
- `jq` (for JSON parsing of comments)

## Side Effects

1. Pushes branch to origin if not already pushed
2. Creates PR on GitHub (if new)
3. Updates PR description on GitHub (if existing)
4. Marks PR as ready for review (if --ready flag)
5. May trigger CI/CD workflows on GitHub

## Comment Analysis Details

### Spec File Detection

The command looks for spec files in the following locations (in order):
1. `specs/<branch-name>/spec.md`
2. `specs/<issue-id>/spec.md` (extracted from branch name)
3. No spec file found - falls back to general principles

### Scoring Criteria

| Score Range | Category | Description |
|-------------|----------|-------------|
| 80-100% | High Priority | Directly addresses functional requirements or security |
| 50-79% | Medium Priority | Indirectly improves compliance or addresses edge cases |
| 20-49% | Low Priority | General code quality, may indirectly help |
| 0-19% | Stylistic | Preference-based, no requirements impact |
| N/A | General Feedback | Non-actionable summary/approval comments |

### Requirements Mapping

When a spec file exists, the analysis:
1. Extracts all FR-XXX requirements from the spec
2. Matches comment suggestions to relevant requirements
3. References specific requirement IDs in rationale
4. Considers acceptance scenarios for context

### Security Principles (Fallback)

When no spec file exists, evaluates against:
- OWASP Top 10 vulnerabilities
- Input validation and sanitization
- Authentication and authorization
- Error handling and logging
- Secure defaults
