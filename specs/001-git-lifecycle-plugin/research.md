# Research: Git Lifecycle Plugin

**Date**: 2026-01-10
**Branch**: 001-git-lifecycle-plugin

## Executive Summary

Research completed for implementing a Claude Code plugin with 5 Git/GitHub lifecycle commands. Key findings establish the plugin architecture, git worktree operation patterns, and conventional commit generation strategies.

---

## 1. Claude Code Plugin Structure

### Decision: Use standard plugin structure with skills directory

**Rationale**: The repository already contains working plugins (`bkff-git`, `example-plugin`) that follow the established pattern. Consistency ensures compatibility with validation tooling.

**Alternatives Considered**:
- Commands-only structure: Rejected because skills provide better code organization for complex multi-step operations
- Monolithic script approach: Rejected because it violates constitution principle IV (simplicity and minimal dependencies)

### Plugin Directory Structure

```text
plugins/bkff-git/
├── .claude-plugin/
│   └── plugin.json           # Required: name, version, description, author
├── skills/
│   └── <skill-name>/
│       └── SKILL.md          # Skill documentation with bash implementation
├── commands/                  # Optional: command definitions
├── lib/                       # Shared bash utilities
├── README.md
└── tests/
```

### plugin.json Schema

```json
{
  "name": "bkff-git",
  "description": "Git lifecycle commands for worktree environments",
  "version": "1.0.0",
  "author": {
    "name": "Kevin Brockhoff"
  }
}
```

### Skill Definition Format (SKILL.md)

```markdown
---
name: Skill Display Name
description: Clear description of the skill's purpose
---

# Skill Name

[Documentation including bash code examples]
```

**Key Finding**: Bash scripts are NOT stored as separate `.sh` files. Instead, they are documented within the `.md` files' Implementation sections, and Claude interprets and executes them when a command is invoked.

---

## 2. Git Worktree Operations

### Decision: Use git rev-parse for worktree detection and standard worktree commands

**Rationale**: Git provides native commands for worktree operations that work reliably across platforms. Using built-in commands ensures compatibility and reduces dependencies.

**Alternatives Considered**:
- Custom directory traversal: Rejected because git native commands handle edge cases better
- External worktree management tools: Rejected to minimize dependencies per constitution principle IV

### Worktree Detection Pattern

```bash
# Check if inside any git repository (worktree or standard)
verify_in_worktree() {
    if ! git rev-parse --is-inside-work-tree 2>/dev/null; then
        echo "Error: Command must be run within a git worktree" >&2
        return 1
    fi
}

# Get the common directory (shared across worktrees)
git_common=$(git rev-parse --git-common-dir 2>/dev/null)
```

### Branch Push Status Detection

```bash
# Check if branch has been pushed to origin (for rebase vs merge decision)
has_been_pushed() {
    local branch_name="${1:=$(git branch --show-current)}"

    # Check if remote tracking branch exists
    if git rev-parse --verify "origin/$branch_name" &>/dev/null; then
        return 0  # Branch is pushed - use merge
    else
        return 1  # Branch is local only - use rebase
    fi
}
```

### Worktree Creation Pattern

```bash
# Create new worktree with branch
create_worktree() {
    local branch_name="$1"
    local worktree_dir="$2"
    local base_branch="${3:-main}"

    git worktree add -b "$branch_name" "$worktree_dir" "$base_branch"
    git -C "$worktree_dir" push -u origin "$branch_name"
}
```

### Fetch for All Worktrees

```bash
# Single fetch updates all worktrees via shared git directory
git fetch origin --prune
```

---

## 3. Conventional Commit Message Generation

### Decision: Analyze staged changes via git diff to determine type and scope

**Rationale**: Git diff provides comprehensive change information that can be parsed to infer commit type and generate meaningful descriptions.

**Alternatives Considered**:
- User input only: Rejected because automation is a key requirement (FR-015)
- AI-only generation: Accepted as primary approach, with bash pre-analysis providing context

### Commit Type Detection Strategy

| File Pattern | Inferred Type |
|--------------|---------------|
| `src/`, `lib/` (new files) | `feat` |
| `src/`, `lib/` (modifications) | `fix` or `refactor` |
| `test/`, `spec/`, `tests/` | `test` |
| `docs/`, `*.md`, `README` | `docs` |
| `.github/`, CI config | `ci` |
| `package.json`, `Makefile`, build files | `build` |
| Whitespace/formatting only | `style` |
| Performance optimization context | `perf` |
| Version bumps, dependencies | `chore` |

### Scope Extraction Pattern

```bash
# Extract scope from changed files directory structure
extract_scope() {
    local files=$(git diff --cached --name-only)

    # Check plugin context
    if echo "$files" | grep -q "^plugins/bkff-git/"; then
        echo "bkff-git"
        return
    fi

    # Check subsystem patterns
    if echo "$files" | grep -q "auth\|login\|session"; then
        echo "auth"
    elif echo "$files" | grep -q "api\|endpoint"; then
        echo "api"
    fi
}
```

### Message Format Requirements

- **Subject line**: `<type>(<scope>): <description>` (< 72 chars)
- **Description**: Lowercase, imperative mood, no period
- **Body**: Optional, wrapped at 72 chars
- **Footer**: Issue references, co-author attribution

### Breaking Change Indicators

- `!` after type: `feat!: change API format`
- `BREAKING CHANGE:` in footer

---

## 4. Automatic Conflict Resolution

### Decision: Use git rerere with fallback to manual resolution

**Rationale**: Git rerere (reuse recorded resolution) can automatically resolve conflicts that have been resolved before. For new conflicts, AI-assisted resolution provides the best user experience.

**Alternatives Considered**:
- Always manual: Rejected per FR-023 requirement
- Third-party merge tools: Rejected to minimize dependencies

### Resolution Strategy

1. Enable `git rerere` for automatic resolution of previously-seen conflicts
2. For new conflicts, analyze conflict markers and attempt semantic resolution
3. Present unresolvable conflicts clearly with context for user decision

```bash
# Enable rerere
git config rerere.enabled true

# Check for conflicts after merge/rebase
if git diff --name-only --diff-filter=U | grep -q .; then
    # Conflicts exist - attempt resolution
    attempt_auto_resolve
fi
```

---

## 5. Beads Integration

### Decision: Use bd CLI commands for issue operations

**Rationale**: The beads system is already available via `bd` commands. Direct CLI integration is simpler than parsing beads files directly.

**Alternatives Considered**:
- Direct file parsing: Rejected because bd CLI handles all edge cases
- GitHub Issues API: Out of scope - beads is the issue tracker

### Issue Type to Branch Prefix Mapping

| Beads Issue Type | Branch Prefix |
|------------------|---------------|
| `feature` | `feature/` |
| `bug` | `bugfix/` |
| Priority 0-1 (critical) | `hotfix/` |
| Default | `feature/` |

### Issue Information Retrieval

```bash
# Get issue details
bd show <issue-id> --json | jq -r '.type, .title, .priority'

# List valid issues
bd list --status=open --format=json
```

---

## 6. GitHub CLI Integration

### Decision: Use gh CLI for all GitHub operations

**Rationale**: GitHub CLI is already a documented dependency and provides comprehensive PR management capabilities.

**Alternatives Considered**:
- Direct GitHub API calls: Rejected because gh handles authentication and edge cases
- Hub CLI: Rejected because gh is the official GitHub CLI

### PR Operations

```bash
# Check for existing PR
gh pr list --head "$(git branch --show-current)" --json number

# Create PR
gh pr create --title "..." --body "..."

# Update PR
gh pr edit <number> --title "..." --body "..."
```

### PR Template Integration

```bash
# Check for PR template
if [[ -f ".github/pull_request_template.md" ]]; then
    template_body=$(cat ".github/pull_request_template.md")
fi
```

---

## 7. Error Handling Strategy

### Decision: Fail fast with clear error messages, preserve local state

**Rationale**: Per clarifications, network failures should fail immediately while preserving local state for manual retry.

### Error Categories and Responses

| Error Type | Response |
|------------|----------|
| Not in worktree | Fail with worktree requirement message |
| Invalid beads issue | Fail with list of valid issues |
| GPG signing unavailable | Fail, do not create unsigned commit |
| Network failure (push) | Fail, preserve local commit |
| Validation failure | Fail, report specific failures |
| Merge conflicts | Attempt auto-resolve, then request user input |

### Error Message Format

```bash
error_exit() {
    echo "Error: $1" >&2
    echo "Suggestion: $2" >&2
    exit 1
}
```

---

## 8. Testing Strategy

### Decision: Use shell assertions with test fixtures

**Rationale**: BATS (Bash Automated Testing System) provides a robust framework for testing bash scripts, but simple shell assertions work for initial validation.

**Alternatives Considered**:
- Manual testing only: Rejected because automated tests are essential for reliability
- BATS framework: Considered for future enhancement

### Test Structure

```text
tests/
├── test-helpers.sh       # Setup/teardown utilities
├── test-git-st.sh        # Status command tests
├── test-git-branch.sh    # Branch command tests
├── test-git-commit.sh    # Commit command tests
├── test-git-sync.sh      # Sync command tests
└── test-git-pr.sh        # PR command tests
```

### Test Fixture Approach

- Create temporary git repositories for each test
- Set up various states (clean, dirty, with/without PR)
- Verify command output and side effects
- Clean up after each test

---

## Summary of Key Decisions

| Topic | Decision | Rationale |
|-------|----------|-----------|
| Plugin Structure | Skills directory with SKILL.md files | Matches existing patterns, enables validation |
| Worktree Detection | `git rev-parse --is-inside-work-tree` | Native git, cross-platform |
| Push Status | `git rev-parse --verify origin/$branch` | Determines rebase vs merge |
| Commit Type | Analyze diff file paths and content | Enables automation per FR-015 |
| Conflict Resolution | Git rerere + AI assistance | Balances automation and accuracy |
| Beads Integration | `bd` CLI commands | Simplest integration path |
| GitHub Operations | `gh` CLI | Official tool, handles auth |
| Error Handling | Fail fast, preserve state | Per clarifications |
| Testing | Shell assertions with fixtures | Adequate for bash scripts |
