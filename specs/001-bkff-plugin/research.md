# Research: Brockhoff Cloud (bkff) Claude Plugin

**Date**: 2026-01-23
**Spec**: [spec.md](./spec.md)
**Plan**: [plan.md](./plan.md)

## Overview

This document captures technical research for implementing the bkff Claude plugin, covering existing codebase patterns, Claude plugin architecture, and integration points with beads, git, and GitHub.

## Existing Plugin Analysis: bkff-git

The `bkff-git` plugin provides a reference implementation for the plugin structure and patterns.

### Plugin Structure

```
plugins/bkff-git/
├── .claude-plugin/plugin.json    # Metadata: name, version, description, author
├── skills/                       # Skill definitions
│   └── [skill-name]/SKILL.md
├── lib/                          # Shared bash libraries
│   ├── common.sh                 # Error handling, formatting, worktree detection
│   ├── git-helpers.sh            # Git-specific helpers
│   ├── pr-analysis.sh            # PR analysis helpers
│   └── validation.sh             # Build validation helpers
├── tests/                        # Test framework
│   ├── test-helpers.sh           # Test utilities
│   └── test-*.sh                 # Test scripts
└── README.md                     # Plugin documentation
```

### Key Patterns from bkff-git

1. **Error Handling**: All scripts use `set -e` for immediate exit on error
2. **Library Sourcing**: Skills source shared libraries from `lib/` using `${CLAUDE_PLUGIN_ROOT}`
3. **JSON Output**: `jq` is used for structured data parsing
4. **Worktree Detection**: `common.sh` provides `get_worktree_root()` function
5. **Skill Format**: Each skill has a `SKILL.md` with frontmatter and implementation steps

### Skill File Structure (from bkff-git)

```markdown
---
description: "Brief skill description for discovery"
---

## Name
bkff:skill-name

## Synopsis
/bkff:skill-name [args]

## Description
Detailed description of what the skill does.

## Implementation
1. Step-by-step instructions for Claude to execute
2. Bash commands using ${CLAUDE_PLUGIN_ROOT}/lib/...
3. Expected outputs and error handling
```

## Claude Plugin Architecture

### Required Components

| Component | Path | Purpose |
|-----------|------|---------|
| Manifest | `.claude-plugin/plugin.json` | Plugin metadata and discovery |
| Skills | `skills/[name]/SKILL.md` | User-invokable commands |
| Agents | `agents/[name]/AGENT.md` | Autonomous agents (optional) |
| Hooks | `hooks/[event]/HOOK.md` | Event-triggered actions (optional) |

### Plugin Manifest Schema

```json
{
  "name": "bkff",                      // Required: lowercase kebab-case
  "description": "...",                 // Required: brief description
  "version": "0.1.0",                   // Required: semver
  "author": { "name": "..." },          // Required: author info
  "repository": "...",                  // Optional: source repo URL
  "license": "MIT",                     // Optional: license
  "keywords": [...]                     // Optional: discovery keywords
}
```

## Beads Integration

### Commands Used

| Command | Purpose | Used By |
|---------|---------|---------|
| `bd ready` | List tasks with no blockers | startloop, task selection |
| `bd list --status=open` | List open issues | status reporting |
| `bd show <id>` | Get issue details | task context |
| `bd create` | Create new issue | tasks2issues |
| `bd update <id> --status=...` | Update issue status | loop state |
| `bd close <id>` | Close completed issue | verification |
| `bd dep add <a> <b>` | Add dependency | tasks2issues |
| `bd doctor --fix` | Fix beads health issues | fixcompliance |
| `bd init` | Initialize beads | fixcompliance |

### Issue Types

- `task`: Individual work item
- `feature`: Collection of tasks
- `epic`: Collection of features
- `bug`: Defect fix

### Priority Mapping

| SpecKit | Beads | Description |
|---------|-------|-------------|
| P0 | 0 | Critical/blocker |
| P1 | 1 | High priority |
| P2 | 2 | Medium priority |
| P3 | 3 | Low priority |
| P4 | 4 | Backlog |

## SpecKit Tasks.md Format

The `tasks2issues` skill parses SpecKit-generated tasks.md files.

### Expected Format

```markdown
## Phase N: [Phase Name]

- [ ] T001 [P] [USn] Task description with file path
- [ ] T002 [USn] Task description (depends on T001)
```

### Parsing Requirements

1. **Task ID**: `T###` prefix for unique identification
2. **Parallel Marker**: `[P]` indicates parallelizable task
3. **Story Reference**: `[US#]` links to user story
4. **Checkbox**: `- [ ]` for pending, `- [x]` for done
5. **Hierarchy**: Phase headers create dependency groups
6. **Dependencies**: Implicit from phase order, explicit in task text

## Build System Integration

### Required Targets

| Target | Purpose | Runs |
|--------|---------|------|
| `validate` | Task/bug validation | tests, lint, docs check, security scan |
| `verify` | Feature/epic validation | integration tests, feature docs, cross-component |

### Output Format

Build targets should exit with:
- `0`: Success
- Non-zero: Failure

Failures should be parseable for structured output.

### Structured Failure Format

```json
{
  "failures": [
    {
      "file": "path/to/file.sh",
      "line": 42,
      "type": "test|quality|docs|security|standards",
      "severity": "error|warning",
      "message": "Human-readable description",
      "hint": "Suggested fix"
    }
  ]
}
```

## ADR Pipeline Architecture

### Agent Sequence

```
User Input → Writer Agent → Validator Agent → Formatter Agent → ADR File
```

### Writer Agent

- **Input**: User context describing architectural decision
- **Template**: MADR (Markdown Architectural Decision Records)
- **Output**: Draft ADR content

### Validator Agent

- **Grounding Sources**:
  - Existing ADRs in `docs/adr/`
  - Codebase files referenced in decision
  - External documentation URLs
- **Checks**:
  - Conflicts with existing decisions
  - Consistency with codebase
  - Completeness of required sections
- **Output**: Validation findings or approval

### Formatter Agent

- **Numbering**: Next sequential ADR number (`NNNN`)
- **Naming**: `NNNN-kebab-case-title.md`
- **Location**: `docs/adr/` (configurable)
- **Output**: Formatted ADR file

### MADR Template

```markdown
# [ADR-NNNN] [Title]

## Status
[proposed | accepted | deprecated | superseded by ADR-XXXX]

## Context
[Problem statement and driving forces]

## Decision
[The change being proposed/made]

## Consequences
### Positive
- [Benefit 1]
- [Benefit 2]

### Negative
- [Drawback 1]
- [Drawback 2]

## Alternatives Considered
### [Alternative 1]
- Pros: ...
- Cons: ...
```

## Test Generation Integration

### Supported Languages

| Language | Testing Framework | Detection |
|----------|-------------------|-----------|
| JavaScript/TypeScript | Jest, Vitest, Mocha | package.json |
| Python | pytest, unittest | pytest.ini, setup.py |
| Go | go test | go.mod |
| Rust | cargo test | Cargo.toml |
| Java | JUnit | pom.xml, build.gradle |
| Shell | test-helpers.sh | Makefile, *.sh |

### Coverage Target

- Minimum: 70% code coverage
- Focus: Primary code paths + edge cases from acceptance criteria

## GitHub CLI Integration

### Commands Used

| Command | Purpose | Used By |
|---------|---------|---------|
| `gh pr list` | List PRs | prfeedback |
| `gh pr view` | Get PR details | prfeedback |
| `gh api repos/.../pulls/.../comments` | Get PR comments | prfeedback |
| `gh pr create` | Create PR | integration |
| `gh pr review` | Submit review | prfeedback |

### Comment Categories

| Category | Indicators | Action |
|----------|------------|--------|
| Required | "must", "need to", request changes | Create P1 beads task |
| Suggestion | "consider", "could", "might" | Present for approval |
| Question | "?", "why", "how" | Draft response |
| Nitpick | "nit", "minor", style comments | Low priority |

## Error Handling Strategy

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Missing prerequisites |
| 3 | Validation failure |
| 4 | User cancellation |

### Retry Strategy (for transient failures)

```bash
MAX_RETRIES=3
BACKOFF_BASE=2  # seconds

for attempt in $(seq 1 $MAX_RETRIES); do
  if command; then
    break
  fi
  if [[ $attempt -lt $MAX_RETRIES ]]; then
    sleep $((BACKOFF_BASE ** attempt))
  else
    echo "Failed after $MAX_RETRIES attempts"
    exit 1
  fi
done
```

## Security Considerations

1. **No arbitrary command execution**: Validate all inputs before execution
2. **Environment variables for secrets**: Never hardcode credentials
3. **Input sanitization**: Quote all variables, validate paths
4. **Minimal permissions**: Request only necessary access

## Next Steps

1. **Phase 1**: Create data-model.md defining key entities
2. **Phase 1**: Create contracts/ with skill interfaces
3. **Phase 1**: Create quickstart.md with getting started guide
4. **Phase 2**: Generate tasks.md via /speckit.tasks
