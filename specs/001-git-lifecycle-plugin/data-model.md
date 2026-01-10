# Data Model: Git Lifecycle Plugin

**Date**: 2026-01-10
**Branch**: 001-git-lifecycle-plugin

## Overview

This plugin operates on existing data structures (git repositories, beads issues, GitHub PRs) rather than creating new persistent data. This document defines the entities the plugin interacts with and the relationships between them.

---

## Entities

### 1. Git Worktree

**Description**: A working directory linked to a bare repository, enabling parallel work on multiple branches.

**Attributes**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `path` | string | Absolute path to worktree directory |
| `branch` | string | Current branch name (with prefix) |
| `bare_path` | string | Path to shared `.bare` directory |
| `is_main` | boolean | Whether this is the main worktree |

**Detection**:
```bash
git rev-parse --show-toplevel  # Returns path
git branch --show-current      # Returns branch
git rev-parse --git-common-dir # Returns bare path
```

**Validation Rules**:
- Must be inside a git repository
- Must have valid `.git` directory or symlink
- Branch must not be in detached HEAD state

---

### 2. Branch

**Description**: A git branch following the project's naming convention with type prefix.

**Attributes**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | string | Full branch name (e.g., `feature/auth-login`) |
| `prefix` | enum | `feature/`, `bugfix/`, `hotfix/` |
| `short_name` | string | Branch name without prefix |
| `is_pushed` | boolean | Whether branch exists on origin |
| `ahead_count` | integer | Commits ahead of origin |
| `behind_count` | integer | Commits behind origin |

**Naming Convention**:
```
<prefix>/<short-name>

Prefixes:
- feature/  → New functionality
- bugfix/   → Bug fixes
- hotfix/   → Critical/urgent fixes
```

**State Transitions**:
```
[Created Local] → [Pushed to Origin] → [PR Created] → [Merged]
                                    ↓
                           [Updated/Synced]
```

---

### 3. Beads Issue

**Description**: A tracked work item from the beads issue tracking system.

**Attributes**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | string | Issue identifier (e.g., `beads-001`) |
| `type` | enum | `feature`, `bug`, `task`, `epic` |
| `title` | string | Issue title |
| `status` | enum | `open`, `in_progress`, `closed` |
| `priority` | integer | 0-4 (0=critical, 4=backlog) |
| `labels` | string[] | Associated labels |

**Type to Branch Prefix Mapping**:

| Issue Type | Priority | Branch Prefix |
|------------|----------|---------------|
| `feature` | any | `feature/` |
| `bug` | 2-4 | `bugfix/` |
| `bug` | 0-1 | `hotfix/` |
| `task` | any | `feature/` |

**Retrieval**:
```bash
bd show <issue-id>           # Full details
bd show <issue-id> --json    # JSON format
bd list --status=open        # List open issues
```

---

### 4. Conventional Commit

**Description**: A commit message following the conventional commits specification.

**Attributes**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `type` | enum | `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert` |
| `scope` | string? | Optional scope (e.g., `auth`, `api`) |
| `description` | string | Commit description (imperative mood) |
| `body` | string? | Optional detailed description |
| `breaking` | boolean | Whether this is a breaking change |
| `footer` | string? | Optional footer (issues, co-authors) |
| `is_signed` | boolean | Whether commit is GPG signed |

**Format**:
```
<type>(<scope>)!: <description>

<body>

<footer>
```

**Validation Rules**:
- Type must be from allowed list
- Description must be lowercase, no period
- Total subject line < 72 characters
- Breaking changes indicated by `!` or `BREAKING CHANGE:` footer

---

### 5. Pull Request

**Description**: A GitHub pull request for code review.

**Attributes**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `number` | integer | PR number |
| `title` | string | PR title |
| `body` | string | PR description |
| `state` | enum | `open`, `closed`, `merged` |
| `head_branch` | string | Source branch |
| `base_branch` | string | Target branch (usually `main`) |
| `url` | string | PR URL |
| `checks_status` | enum | `pending`, `success`, `failure` |

**Retrieval**:
```bash
gh pr list --head "$branch" --json number,title,state,url
gh pr view --json number,title,body,state
```

---

### 6. Git Status

**Description**: Current state of the working directory and staging area.

**Attributes**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `staged_files` | FileChange[] | Files staged for commit |
| `unstaged_files` | FileChange[] | Modified but unstaged files |
| `untracked_files` | string[] | New untracked files |
| `last_commit` | CommitInfo | Information about HEAD commit |
| `branch_status` | string | Ahead/behind origin status |

**FileChange**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `path` | string | File path |
| `status` | enum | `added`, `modified`, `deleted`, `renamed` |
| `additions` | integer | Lines added |
| `deletions` | integer | Lines deleted |

**CommitInfo**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `hash` | string | Commit SHA (short) |
| `message` | string | Commit message subject |
| `author` | string | Author name |
| `date` | string | Commit date |

---

## Relationships

```
┌─────────────────┐       ┌─────────────────┐
│  Beads Issue    │──────▶│     Branch      │
│                 │ 1:1   │                 │
│ - id            │       │ - name          │
│ - type          │       │ - prefix        │
│ - priority      │       │ - is_pushed     │
└─────────────────┘       └────────┬────────┘
                                   │
                                   │ 1:1
                                   ▼
┌─────────────────┐       ┌─────────────────┐
│  Git Worktree   │◀──────│  Pull Request   │
│                 │ 1:1   │                 │
│ - path          │       │ - number        │
│ - branch        │       │ - state         │
│ - bare_path     │       │ - head_branch   │
└────────┬────────┘       └─────────────────┘
         │
         │ contains
         ▼
┌─────────────────┐       ┌─────────────────┐
│   Git Status    │       │ Conventional    │
│                 │       │    Commit       │
│ - staged_files  │──────▶│                 │
│ - last_commit   │ 1:N   │ - type          │
│ - branch_status │       │ - scope         │
└─────────────────┘       │ - description   │
                          └─────────────────┘
```

---

## State Machines

### Branch Lifecycle

```
                    ┌──────────────┐
                    │   Created    │
                    │   (Local)    │
                    └──────┬───────┘
                           │ git push
                           ▼
                    ┌──────────────┐
        ┌──────────│   Pushed     │──────────┐
        │          │   (Remote)   │          │
        │          └──────┬───────┘          │
        │                 │ gh pr create     │
        │                 ▼                  │
        │          ┌──────────────┐          │
        │          │  PR Open     │          │
        │          │              │          │
        │          └──────┬───────┘          │
        │                 │ merge            │
        │                 ▼                  │
        │          ┌──────────────┐          │
        │          │   Merged     │          │
        │          │              │          │
        │          └──────────────┘          │
        │                                    │
        │ git sync (rebase)                  │ git sync (merge)
        └────────────────────────────────────┘
```

### Commit Workflow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Unstaged   │────▶│   Staged    │────▶│  Committed  │
│  Changes    │ add │   Changes   │commit│   (Local)   │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                                               │ push
                                               ▼
                                        ┌─────────────┐
                                        │   Pushed    │
                                        │  (Remote)   │
                                        └─────────────┘
```

---

## Validation Summary

| Entity | Validation Rule | Error Response |
|--------|-----------------|----------------|
| Worktree | Must be inside git repo | "Command must be run within a git worktree" |
| Branch | Must follow naming convention | "Invalid branch name format" |
| Beads Issue | Must exist and be valid | "Issue not found. Valid issues: ..." |
| Commit | Must have valid type | "Invalid commit type. Allowed: feat, fix, ..." |
| Commit | Must be signed | "GPG signing required but unavailable" |
| PR | Branch must be pushed | "Branch must be pushed before creating PR" |
