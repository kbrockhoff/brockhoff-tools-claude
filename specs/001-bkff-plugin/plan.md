# Implementation Plan: Brockhoff Cloud (bkff) Claude Plugin

**Branch**: `001-bkff-plugin` | **Date**: 2026-01-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-bkff-plugin/spec.md`

## Summary

Build a Claude Code plugin (`bkff`) that provides spec-driven development workflows including compliance checking, task-to-issue conversion, agentic development loops, verification skills, ADR generation, test generation, README generation, and PR feedback handling. The plugin follows Claude Plugin Marketplace standards and integrates with git, GitHub CLI, and beads issue tracking.

## Technical Context

**Language/Version**: Bash 4.0+ (POSIX-compatible where possible) with `set -e` error handling
**Primary Dependencies**: `git` (2.25+), `gh` (GitHub CLI 2.0+), `bd` (beads CLI), `jq` (JSON parsing)
**Storage**: File-based (markdown files, JSON for structured output, `.beads/` directory for issue tracking)
**Testing**: `make lint` (claudelint), shell script unit tests (test-helpers.sh framework)
**Target Platform**: CLI/terminal (macOS, Linux) within Claude Code environment
**Project Type**: Single project (Claude Plugin)
**Performance Goals**: Commands complete within 30 seconds for normal operations; development loop processes tasks autonomously
**Constraints**: Must work offline for local operations; GitHub operations require network
**Scale/Scope**: Single developer workflow; supports repositories with typical project sizes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Plugin Standards Compliance | ✅ PASS | Using standard Claude Plugin structure: `.claude-plugin/`, `skills/`, `agents/`, `lib/` |
| II. Validation First | ✅ PASS | All changes validated via `make lint` before merge; CI/CD validates PRs |
| III. Conventional Commits | ✅ PASS | All commits follow `<type>[scope]: <description>` format |
| IV. Simplicity and Minimal Dependencies | ✅ PASS | Only core dependencies: jq, bash, git, gh, bd |
| V. Documentation Accuracy | ✅ PASS | README.md reflects plugin capabilities; SKILL.md files describe each skill |

## Project Structure

### Documentation (this feature)

```text
specs/001-bkff-plugin/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
plugins/bkff/
├── .claude-plugin/
│   └── plugin.json           # Plugin metadata (name, version, description, author)
├── skills/
│   ├── chkcompliance/        # Check repository compliance
│   │   └── SKILL.md
│   ├── fixcompliance/        # Fix compliance issues
│   │   └── SKILL.md
│   ├── tasks2issues/         # Convert SpecKit tasks to beads issues
│   │   └── SKILL.md
│   ├── startloop/            # Start agentic development loop
│   │   └── SKILL.md
│   ├── cancelloop/           # Cancel development loop
│   │   └── SKILL.md
│   ├── verifytask/           # Verify task completion
│   │   └── SKILL.md
│   ├── verifyfeat/           # Verify feature completion
│   │   └── SKILL.md
│   ├── verifyepic/           # Verify epic completion
│   │   └── SKILL.md
│   ├── verifybug/            # Verify bug fix
│   │   └── SKILL.md
│   ├── gentests/             # Generate unit tests
│   │   └── SKILL.md
│   ├── genreadme/            # Generate README documentation
│   │   └── SKILL.md
│   └── prfeedback/           # Handle PR review feedback
│       └── SKILL.md
├── agents/
│   ├── adr-writer/           # ADR Writer Agent (MADR template)
│   │   └── AGENT.md
│   ├── adr-validator/        # ADR Validator Agent (grounding)
│   │   └── AGENT.md
│   └── adr-formatter/        # ADR Formatter Agent (numbering, naming)
│       └── AGENT.md
├── lib/
│   ├── common.sh             # Shared utilities (error handling, formatting)
│   ├── compliance.sh         # Compliance check/fix helpers
│   ├── tasks-parser.sh       # SpecKit tasks.md parser
│   ├── loop-state.sh         # Development loop state management
│   └── verification.sh       # Verification helpers (build system integration)
├── tests/
│   ├── test-helpers.sh       # Test framework (from bkff-git)
│   ├── test-compliance.sh    # Compliance tests
│   ├── test-tasks-parser.sh  # Tasks parser tests
│   └── test-verification.sh  # Verification tests
└── README.md                 # Plugin documentation
```

**Structure Decision**: Using Claude Plugin Marketplace single-project structure following the existing `bkff-git` plugin pattern. Skills are organized by functional area with shared library code in `lib/`. The ADR generation uses a multi-agent pipeline with three specialized agents (writer, validator, formatter) in the `agents/` directory.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. All constitution principles are satisfied:
- Single plugin with focused purpose (spec-driven development workflow)
- Core dependencies only (jq, bash, git, gh, bd)
- Standard Claude Plugin structure
- No external frameworks or complex patterns
