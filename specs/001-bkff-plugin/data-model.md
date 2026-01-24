# Data Model: Brockhoff Cloud (bkff) Claude Plugin

**Date**: 2026-01-23
**Spec**: [spec.md](./spec.md)
**Plan**: [plan.md](./plan.md)

## Overview

This document defines the data structures and entities used by the bkff plugin. All entities are represented as markdown, JSON, or shell data structures - there is no persistent database.

## Core Entities

### 1. Compliance Check

Represents a single validation rule for repository compliance.

```bash
# Shell representation in compliance.sh
declare -A COMPLIANCE_CHECK=(
  [name]="github-codeowners"
  [path]=".github/CODEOWNERS"
  [type]="file"              # file | directory | content | command
  [required]=true
  [description]="GitHub CODEOWNERS file for review routing"
  [remediation]="Create .github/CODEOWNERS with team ownership rules"
)
```

**JSON Output Format**:
```json
{
  "name": "github-codeowners",
  "path": ".github/CODEOWNERS",
  "status": "pass",
  "message": null
}
```

### 2. Compliance Report

Aggregated compliance check results.

```json
{
  "timestamp": "2026-01-23T10:30:00Z",
  "repository": "/path/to/repo",
  "overall_status": "fail",
  "checks_passed": 8,
  "checks_failed": 2,
  "checks_total": 10,
  "checks": [
    {
      "name": "github-codeowners",
      "path": ".github/CODEOWNERS",
      "status": "pass",
      "message": null
    },
    {
      "name": "agents-md",
      "path": "AGENTS.md",
      "status": "fail",
      "message": "File missing or empty"
    }
  ]
}
```

### 3. Task Mapping

Represents a parsed task from SpecKit tasks.md mapped to beads issue.

```json
{
  "task_id": "T001",
  "phase": "Phase 1: Setup",
  "parallel": true,
  "user_story": "US1",
  "description": "Create project structure per implementation plan",
  "priority": 2,
  "depends_on": [],
  "beads_issue_id": null,
  "status": "pending"
}
```

### 4. Development Loop State

Tracks the current state of the agentic development loop.

```json
{
  "status": "running",
  "started_at": "2026-01-23T10:00:00Z",
  "current_task": {
    "beads_id": "beads-abc123",
    "task_id": "T015",
    "title": "Implement compliance check logic",
    "started_at": "2026-01-23T10:30:00Z"
  },
  "completed_tasks": [
    {
      "beads_id": "beads-xyz789",
      "task_id": "T014",
      "completed_at": "2026-01-23T10:28:00Z",
      "duration_seconds": 420
    }
  ],
  "paused_reason": null,
  "retry_count": 0,
  "last_error": null
}
```

**State File Location**: `.bkff/loop-state.json`

### 5. Verification Failure

Structured output from verification skills.

```json
{
  "file": "lib/compliance.sh",
  "line": 42,
  "type": "quality",
  "severity": "error",
  "message": "shellcheck: SC2086 - Double quote to prevent globbing",
  "hint": "Change $var to \"$var\" to prevent word splitting"
}
```

### 6. Verification Result

Complete verification output.

```json
{
  "issue_id": "beads-abc123",
  "issue_type": "task",
  "target": "validate",
  "status": "fail",
  "timestamp": "2026-01-23T11:00:00Z",
  "acceptance_criteria_checked": true,
  "failures": [
    {
      "file": "lib/compliance.sh",
      "line": 42,
      "type": "quality",
      "severity": "error",
      "message": "shellcheck: SC2086",
      "hint": "Double quote to prevent globbing"
    }
  ],
  "summary": {
    "tests": { "passed": 15, "failed": 0 },
    "quality": { "errors": 1, "warnings": 3 },
    "docs": { "complete": true },
    "security": { "issues": 0 }
  }
}
```

### 7. Architectural Decision Record (ADR)

MADR-format document structure.

```json
{
  "number": 42,
  "title": "Use Event Sourcing for Order Management",
  "filename": "0042-use-event-sourcing.md",
  "status": "proposed",
  "context": "The order management system needs to track all state changes...",
  "decision": "We will use event sourcing pattern...",
  "consequences": {
    "positive": ["Full audit trail", "Temporal queries"],
    "negative": ["Increased complexity", "Storage overhead"]
  },
  "alternatives": [
    {
      "name": "Traditional CRUD",
      "pros": ["Simpler implementation"],
      "cons": ["No history", "Audit complexity"]
    }
  ],
  "references": ["ADR-0038", "RFC-2024-001"],
  "supersedes": null,
  "superseded_by": null
}
```

### 8. ADR Validation Finding

Output from the Validator Agent.

```json
{
  "finding_type": "conflict",
  "severity": "warning",
  "section": "Decision",
  "source_type": "existing_adr",
  "source_ref": "docs/adr/0038-use-postgresql.md",
  "message": "Decision mentions MySQL but ADR-0038 established PostgreSQL as standard",
  "suggestion": "Update database reference to PostgreSQL or explicitly address deviation"
}
```

### 9. Generated Test

Test artifact from test generation.

```json
{
  "target_file": "lib/compliance.sh",
  "target_function": "check_file_exists",
  "test_file": "tests/test-compliance.sh",
  "test_name": "test_check_file_exists_returns_true_for_existing_file",
  "test_type": "unit",
  "coverage_lines": [15, 16, 17, 18, 19],
  "framework": "test-helpers.sh",
  "status": "generated"
}
```

### 10. Test Coverage Gap

Identified area needing tests.

```json
{
  "file": "lib/tasks-parser.sh",
  "function": "parse_task_dependencies",
  "line_start": 45,
  "line_end": 72,
  "coverage_percent": 0,
  "suggested_scenarios": [
    "Task with no dependencies",
    "Task with single dependency",
    "Task with multiple dependencies",
    "Circular dependency detection"
  ]
}
```

### 11. PR Review Comment

Parsed GitHub review comment.

```json
{
  "comment_id": 12345678,
  "author": "reviewer-username",
  "category": "required",
  "file": "lib/compliance.sh",
  "line": 42,
  "body": "This needs error handling for the case when the file doesn't exist",
  "created_at": "2026-01-23T14:00:00Z",
  "resolution_status": "pending",
  "beads_task_id": null
}
```

### 12. README Section

Component of generated documentation.

```json
{
  "name": "installation",
  "order": 2,
  "content": "## Installation\n\n1. Clone the repository...",
  "preserve": false,
  "sources": ["package.json", "Makefile", "docs/setup.md"]
}
```

## Configuration Files

### Plugin Configuration

**Location**: `plugins/bkff/.claude-plugin/plugin.json`

```json
{
  "name": "bkff",
  "description": "Brockhoff Cloud spec-driven development workflow plugin",
  "version": "0.1.0",
  "author": {
    "name": "kbrockhoff"
  },
  "repository": "https://github.com/kbrockhoff/brockhoff-tools-claude",
  "license": "MIT",
  "keywords": [
    "compliance",
    "beads",
    "speckit",
    "development-loop",
    "adr",
    "testing"
  ]
}
```

### Loop State Directory

**Location**: `.bkff/` (at repository root)

```
.bkff/
├── loop-state.json      # Current development loop state
├── history/             # Historical loop runs
│   └── 2026-01-23T10-00-00Z.json
└── config.json          # Plugin configuration overrides
```

### ADR Configuration

**Default Location**: `docs/adr/`

**Naming Convention**: `NNNN-kebab-case-title.md`

## Relationships

```
┌─────────────────┐
│ Compliance      │
│ Report          │
├─────────────────┤
│ 1:N             │
│ ↓               │
│ Compliance      │
│ Check           │
└─────────────────┘

┌─────────────────┐
│ Task Mapping    │
├─────────────────┤
│ N:1             │
│ ↓               │
│ beads Issue     │
│ (external)      │
└─────────────────┘

┌─────────────────┐     ┌─────────────────┐
│ Dev Loop State  │────▶│ Task Mapping    │
├─────────────────┤     │ (current_task)  │
│ 1:N             │     └─────────────────┘
│ ↓               │
│ completed_tasks │
└─────────────────┘

┌─────────────────┐
│ Verification    │
│ Result          │
├─────────────────┤
│ 1:N             │
│ ↓               │
│ Verification    │
│ Failure         │
└─────────────────┘

┌─────────────────┐     ┌─────────────────┐
│ ADR             │────▶│ ADR Validation  │
│                 │     │ Finding         │
├─────────────────┤     └─────────────────┘
│ N:N             │
│ ↓               │
│ ADR (supersedes)│
└─────────────────┘

┌─────────────────┐
│ PR Review       │
│ Comment         │
├─────────────────┤
│ 1:1             │
│ ↓               │
│ beads Task      │
│ (for required)  │
└─────────────────┘
```

## Validation Rules

### Compliance Check

- `name`: Required, unique identifier
- `path`: Required, relative to repository root
- `type`: Required, one of: file, directory, content, command
- `status`: Required output, one of: pass, fail, skip

### Task Mapping

- `task_id`: Required, format `T###`
- `priority`: Required, integer 0-4
- `depends_on`: Array of task_id strings

### Verification Failure

- `file`: Required, relative path
- `line`: Optional, integer > 0
- `type`: Required, one of: test, quality, docs, security, standards
- `severity`: Required, one of: error, warning

### ADR

- `number`: Required, positive integer, sequential
- `status`: Required, one of: proposed, accepted, deprecated, superseded
- `title`: Required, non-empty string
- `context`: Required, non-empty string
- `decision`: Required, non-empty string
