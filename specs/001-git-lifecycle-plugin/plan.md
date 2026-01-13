# Implementation Plan: Git Lifecycle Plugin

**Branch**: `001-git-lifecycle-plugin` | **Date**: 2026-01-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-git-lifecycle-plugin/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a Claude Code plugin providing 5 Git/GitHub lifecycle commands (`git-st`, `git-branch`, `git-commit`, `git-sync`, `git-pr`) for git worktree environments. The plugin integrates with beads issue tracking, enforces conventional commits with GPG signing, and provides intelligent PR management including draft workflows, review comment retrieval, and AI-powered comment analysis against spec requirements.

## Technical Context

**Language/Version**: Bash 4.0+ (POSIX-compatible where possible)
**Primary Dependencies**: `git` (2.25+), `gh` (GitHub CLI 2.0+), `bd` (beads CLI), `jq` (JSON parsing)
**Storage**: N/A (relies on git repository and beads `.beads/` directory)
**Testing**: Shell assertions with test fixtures (BATS considered for future)
**Target Platform**: macOS/Linux with git worktree environments
**Project Type**: Claude Code plugin (skills/commands directory structure)
**Performance Goals**: Status check <5s, branch creation <30s, review comment analysis <30s for 50 comments
**Constraints**: GPG signing required, conventional commits enforced, worktree context required
**Scale/Scope**: Single developer workflow, 5 commands, 45 functional requirements

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Check ✅

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Plugin Standards Compliance | ✅ Pass | Using existing `bkff-git` plugin structure with `.claude-plugin/plugin.json`, skills directory |
| II. Validation First | ✅ Pass | FR-012 requires running `make validate` before commits |
| III. Conventional Commits | ✅ Pass | FR-015 generates conventional commit messages, Constitution III alignment |
| IV. Simplicity and Minimal Dependencies | ✅ Pass | Only `git`, `gh`, `bd`, `jq` - all core tools already in use |
| V. Documentation Accuracy | ✅ Pass | Contracts define exact command behavior, README will be updated |

### Post-Design Check ✅

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Plugin Standards Compliance | ✅ Pass | Skills in `skills/` directory with SKILL.md files |
| II. Validation First | ✅ Pass | Commit command validates before creating commits |
| III. Conventional Commits | ✅ Pass | Commit type analysis from file paths per research.md |
| IV. Simplicity and Minimal Dependencies | ✅ Pass | Single-purpose commands, composable, no new dependencies |
| V. Documentation Accuracy | ✅ Pass | Contracts, quickstart, and data model all aligned |

## Project Structure

### Documentation (this feature)

```text
specs/001-git-lifecycle-plugin/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output - completed
├── data-model.md        # Phase 1 output - completed, needs update for review comments
├── quickstart.md        # Phase 1 output - completed, needs update for new PR options
├── contracts/           # Phase 1 output - completed, git-pr.md needs update
│   ├── git-st.md
│   ├── git-branch.md
│   ├── git-commit.md
│   ├── git-sync.md
│   └── git-pr.md
├── checklists/
│   └── requirements.md  # Quality checklist - updated 2026-01-13
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
plugins/bkff-git/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── skills/
│   ├── git-st/
│   │   └── SKILL.md          # Status command skill
│   ├── git-branch/
│   │   └── SKILL.md          # Branch creation skill
│   ├── git-commit/
│   │   └── SKILL.md          # Commit skill
│   ├── git-sync/
│   │   └── SKILL.md          # Sync skill
│   └── git-pr/
│       └── SKILL.md          # PR management skill
├── lib/
│   ├── git-utils.sh          # Shared git utilities
│   ├── beads-utils.sh        # Beads integration utilities
│   └── pr-analysis.sh        # PR comment analysis utilities
├── tests/
│   ├── test-helpers.sh       # Test utilities
│   ├── test-git-st.sh
│   ├── test-git-branch.sh
│   ├── test-git-commit.sh
│   ├── test-git-sync.sh
│   └── test-git-pr.sh
└── README.md
```

**Structure Decision**: Claude Code plugin using skills directory pattern with shared lib utilities. Each command is a separate skill with SKILL.md containing documentation and bash implementation patterns.

## Phase 0: Research Summary

Research completed in [research.md](research.md). Key decisions:

| Topic | Decision | Rationale |
|-------|----------|-----------|
| Plugin Structure | Skills directory with SKILL.md files | Matches existing patterns |
| Worktree Detection | `git rev-parse --is-inside-work-tree` | Native git, cross-platform |
| Push Status | `git rev-parse --verify origin/$branch` | Determines rebase vs merge |
| Commit Type | Analyze diff file paths and content | Enables FR-015 automation |
| Conflict Resolution | Git rerere + AI assistance | Per FR-023 |
| Beads Integration | `bd` CLI commands | Simplest path |
| GitHub Operations | `gh` CLI | Official tool, handles auth |
| Error Handling | Fail fast, preserve state | Per clarifications |

## Phase 1: Design Artifacts Summary

### Data Model ([data-model.md](data-model.md))

Entities defined:
- **Git Worktree**: path, branch, bare_path, is_main
- **Branch**: name, prefix, short_name, is_pushed, ahead/behind counts
- **Beads Issue**: id, type, title, status, priority, labels
- **Conventional Commit**: type, scope, description, body, breaking, footer, is_signed
- **Pull Request**: number, title, body, state, head/base branches, url, checks_status
- **Git Status**: staged/unstaged/untracked files, last_commit, branch_status

**Update Required**: Add Review Comment entity for FR-037 through FR-045

### Contracts ([contracts/](contracts/))

| Contract | Status | Requirements Covered |
|----------|--------|---------------------|
| git-st.md | ✅ Complete | FR-001 to FR-005, FR-033 |
| git-branch.md | ✅ Complete | FR-006 to FR-011, FR-033 |
| git-commit.md | ✅ Complete | FR-012 to FR-017, FR-033 |
| git-sync.md | ✅ Complete | FR-018 to FR-023, FR-033 |
| git-pr.md | ⚠️ Needs Update | FR-024 to FR-028, FR-033; **Missing: FR-034 to FR-045** |

### Quickstart ([quickstart.md](quickstart.md))

**Update Required**: Add documentation for:
- `--draft` flag for creating draft PRs
- `--ready` flag for marking PRs ready for review
- `--comments` flag for retrieving review comments
- `--comments --analyze` flags for AI-powered comment analysis

## Complexity Tracking

No constitution violations requiring justification. All design decisions align with simplicity principle.

## Phase 1 Artifacts Update Required

The following updates are needed to incorporate FR-034 through FR-045 (added 2026-01-13):

### 1. git-pr.md Contract Updates
- Add `--draft` flag documentation (FR-034)
- Add `--ready` flag documentation (FR-035, FR-036)
- Add `--comments` flag documentation (FR-037, FR-038, FR-039)
- Add `--comments --analyze` flag documentation (FR-040 through FR-045)
- Add review comment output format
- Add analysis output format with probability scores and rationale

### 2. data-model.md Updates
- Add **Review Comment** entity with attributes: id, author, body, path, line, created_at
- Add **Comment Analysis** entity with attributes: probability_score, rationale, is_stylistic, requirements_referenced

### 3. quickstart.md Updates
- Add examples for draft PR workflow
- Add examples for review comment retrieval
- Add examples for comment analysis

### 4. research.md (Optional Enhancement)
- Document spec file detection pattern for FR-044
- Document fallback evaluation strategy for FR-045
