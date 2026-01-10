# Implementation Plan: Git Lifecycle Plugin

**Branch**: `001-git-lifecycle-plugin` | **Date**: 2026-01-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-git-lifecycle-plugin/spec.md`

## Summary

Create a Claude Code plugin (`bkff-git`) providing five Git/GitHub lifecycle commands for developers working in git worktree environments. Commands execute via bash scripts calling `git`, `gh`, and `bd` utilities. The plugin automates branch creation, conventional commits with GPG signing, remote synchronization with smart rebase/merge selection, PR management, and status reporting.

## Technical Context

**Language/Version**: Bash 4.0+ (POSIX-compatible where possible)
**Primary Dependencies**: `git` (2.25+), `gh` (GitHub CLI 2.0+), `bd` (beads CLI), `jq` (JSON parsing)
**Storage**: N/A (relies on git repository and beads `.beads/` directory)
**Testing**: Bash script testing with BATS (Bash Automated Testing System) or shell assertions
**Target Platform**: Claude Code CLI (macOS/Linux)
**Project Type**: Single plugin with multiple skills/commands
**Performance Goals**: Status check < 5 seconds, branch creation < 30 seconds (per SC-001, SC-002)
**Constraints**: Must work within git worktree layout with `.bare` directory structure
**Scale/Scope**: Single-developer workflow automation, 5 commands, ~500-800 lines of bash

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Plugin Standards Compliance** | PASS | Will use `.claude-plugin/` structure with `plugin.json`, `skills/` directory |
| **II. Validation First** | PASS | Will run `make lint` before commits; plugin validates worktree context before operations |
| **III. Conventional Commits** | PASS | Plugin generates conventional commit messages (FR-015); scope will be `bkff-git` |
| **IV. Simplicity and Minimal Dependencies** | PASS | Single purpose (git lifecycle); only `git`, `gh`, `bd`, `jq` dependencies |
| **V. Documentation Accuracy** | PASS | Will create README.md, command markdown files for each skill |

**Gate Result**: PASS - No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/001-git-lifecycle-plugin/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (command interfaces)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
plugins/bkff-git/
├── .claude-plugin/
│   └── plugin.json           # Plugin metadata (name, version, description, author)
├── skills/
│   ├── git-st/
│   │   ├── skill.md          # Status command documentation
│   │   └── git-st.sh         # Status implementation
│   ├── git-branch/
│   │   ├── skill.md          # Branch command documentation
│   │   └── git-branch.sh     # Branch implementation
│   ├── git-commit/
│   │   ├── skill.md          # Commit command documentation
│   │   └── git-commit.sh     # Commit implementation
│   ├── git-sync/
│   │   ├── skill.md          # Sync command documentation
│   │   └── git-sync.sh       # Sync implementation
│   └── git-pr/
│       ├── skill.md          # PR command documentation
│       └── git-pr.sh         # PR implementation
├── lib/
│   ├── common.sh             # Shared utility functions (worktree detection, error handling)
│   ├── git-helpers.sh        # Git-specific helper functions
│   └── validation.sh         # Pre-commit validation helpers
├── README.md                 # Plugin documentation
└── tests/
    ├── test-helpers.sh       # Test utilities
    ├── test-git-st.sh        # Status command tests
    ├── test-git-branch.sh    # Branch command tests
    ├── test-git-commit.sh    # Commit command tests
    ├── test-git-sync.sh      # Sync command tests
    └── test-git-pr.sh        # PR command tests
```

**Structure Decision**: Single plugin structure with skills directory containing one subdirectory per command. Shared library functions in `lib/` to avoid code duplication across commands. Tests mirror skill structure.

## Complexity Tracking

No constitution violations requiring justification.
