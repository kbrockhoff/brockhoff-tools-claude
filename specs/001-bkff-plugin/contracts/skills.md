# Skill Contracts: bkff Plugin

**Date**: 2026-01-23

This document defines the interface contracts for all bkff plugin skills.

## Skill Interface Pattern

All skills follow this structure:

```markdown
---
description: "Brief description for skill discovery"
---

## Name
bkff:[skill-name]

## Synopsis
/bkff:[skill-name] [arguments]

## Preconditions
- List of requirements that must be true before execution

## Implementation
1. Numbered steps for Claude to execute
2. Each step includes bash commands or tool calls
3. Error handling for each failure mode

## Outputs
- Success: Description of success output
- Failure: Description of failure output with exit codes

## Exit Codes
- 0: Success
- 1: General error
- 2: Precondition failure
```

---

## Compliance Skills

### bkff:chkcompliance

**Purpose**: Check repository compliance with Brockhoff Cloud standards.

**Preconditions**:
- Current directory is a git repository
- `jq` is available

**Arguments**: None

**Output** (JSON):
```json
{
  "overall_status": "pass|fail",
  "checks_passed": 8,
  "checks_failed": 2,
  "checks_total": 10,
  "checks": [...]
}
```

**Exit Codes**:
- 0: All checks pass
- 1: One or more checks fail
- 2: Not a git repository

---

### bkff:fixcompliance

**Purpose**: Fix repository compliance issues.

**Preconditions**:
- Current directory is a git repository
- `jq`, `bd` are available
- Write permissions to repository

**Arguments**: None

**Output**:
```
Fixed: .github/CODEOWNERS
Fixed: AGENTS.md
Fixed: CLAUDE.md (added reference to AGENTS.md)
Fixed: .beads (initialized)
Fixed: beads health (ran bd doctor --fix)

Summary: 5 issues fixed, 0 issues remaining
```

**Exit Codes**:
- 0: All issues fixed
- 1: Some issues could not be fixed
- 2: Not a git repository

---

## Task Management Skills

### bkff:tasks2issues

**Purpose**: Convert SpecKit tasks.md to beads issues.

**Preconditions**:
- Current directory is a git repository
- `bd` is available and initialized
- `specs/[branch]/tasks.md` exists

**Arguments**:
- `[path]`: Optional path to tasks.md (default: auto-detect from branch)

**Output**:
```
Parsed: 25 tasks from specs/001-feature/tasks.md
Created: beads-abc123 "T001 Create project structure" (P2)
Created: beads-def456 "T002 Initialize project" (P2)
...
Dependencies: Added 12 dependency relationships

Summary: 25 issues created, 12 dependencies added
```

**Exit Codes**:
- 0: All tasks converted successfully
- 1: Partial conversion (some tasks failed)
- 2: tasks.md not found
- 3: beads not initialized

---

## Development Loop Skills

### bkff:startloop

**Purpose**: Start the agentic development loop.

**Preconditions**:
- Current directory is a git repository
- `bd` is available with ready tasks
- No loop currently running

**Arguments**: None

**Behavior**:
1. Check for ready tasks (`bd ready`)
2. If no ready tasks, exit with message
3. Select highest priority task
4. Begin implementation cycle
5. Run tests → verify → close → next task
6. Pause on blocking issues, report, wait for input

**Output** (on pause/stop):
```json
{
  "status": "paused|stopped",
  "reason": "Blocking issue encountered",
  "current_task": "beads-abc123",
  "completed": 3,
  "duration_minutes": 45
}
```

**Exit Codes**:
- 0: Loop completed (all tasks done) or stopped gracefully
- 1: Loop paused (blocking issue)
- 2: No ready tasks available

---

### bkff:cancelloop

**Purpose**: Cancel the running development loop.

**Preconditions**: None (handles gracefully if no loop running)

**Arguments**: None

**Output**:
```
Loop cancelled after completing current operation.
Status: 3 tasks completed, 1 task in progress (will be resumed)
```

Or if no loop running:
```
No development loop is currently running.
```

**Exit Codes**:
- 0: Success (loop cancelled or no loop running)

---

## Verification Skills

### bkff:verifytask

**Purpose**: Verify a beads task is complete.

**Preconditions**:
- Current directory is a git repository
- `bd` is available
- Build system has `validate` target
- Task has acceptance criteria

**Arguments**:
- `<issue-id>`: beads issue ID to verify

**Output** (success):
```json
{
  "issue_id": "beads-abc123",
  "status": "pass",
  "target": "validate",
  "summary": {
    "tests": { "passed": 15, "failed": 0 },
    "quality": { "errors": 0, "warnings": 2 },
    "docs": { "complete": true },
    "security": { "issues": 0 }
  }
}
```

**Output** (failure):
```json
{
  "issue_id": "beads-abc123",
  "status": "fail",
  "target": "validate",
  "failures": [
    {
      "file": "lib/compliance.sh",
      "line": 42,
      "type": "quality",
      "severity": "error",
      "message": "shellcheck: SC2086",
      "hint": "Double quote to prevent globbing"
    }
  ]
}
```

**Exit Codes**:
- 0: Verification passed
- 1: Verification failed
- 2: No acceptance criteria defined
- 3: Build target not found

---

### bkff:verifyfeat

**Purpose**: Verify a beads feature is complete.

Same interface as `verifytask` but:
- Uses `verify` target instead of `validate`
- Checks all child tasks are closed
- Runs integration tests

---

### bkff:verifyepic

**Purpose**: Verify a beads epic is complete.

Same interface as `verifyfeat` but:
- Checks all child features are verified
- Runs cross-component verification

---

### bkff:verifybug

**Purpose**: Verify a bug fix is complete.

Same interface as `verifytask` but:
- Checks bug no longer reproduces
- Verifies fix validation steps

---

## ADR Skills

### bkff:writeadr

**Purpose**: Generate an Architectural Decision Record.

**Preconditions**:
- Current directory is a git repository

**Arguments**:
- User provides decision context interactively or via input

**Pipeline**:
1. Writer Agent generates draft ADR
2. Validator Agent checks against grounding sources
3. Formatter Agent assigns number and filename
4. Write to `docs/adr/NNNN-title.md`

**Output**:
```
Generated: docs/adr/0042-use-event-sourcing.md
Status: proposed
Validation: Passed (2 notes)
  - Note: Related to ADR-0038 (PostgreSQL)
  - Note: References 3 codebase components

Review the ADR and update status to 'accepted' when approved.
```

**Exit Codes**:
- 0: ADR generated successfully
- 1: Validation failed (conflicts require resolution)
- 2: Writer agent failed (insufficient context)

---

## Test Generation Skills

### bkff:gentests

**Purpose**: Generate unit tests for implemented code.

**Preconditions**:
- Current directory is a git repository
- Supported language detected
- Testing framework available

**Arguments**:
- `[path]`: Optional path to file or directory to generate tests for
- `--update`: Update existing tests to fill coverage gaps

**Output**:
```
Analyzing: lib/compliance.sh
Framework: test-helpers.sh (shell)
Generated: tests/test-compliance.sh
  - test_check_file_exists_returns_true
  - test_check_file_exists_returns_false
  - test_check_directory_exists
  - test_run_compliance_checks
Coverage: 85% (target: 70%)

Generated: 4 tests in 1 file
```

**Exit Codes**:
- 0: Tests generated successfully
- 1: Partial generation (some failures)
- 2: Unsupported language (warning, not error)

---

## README Generation Skills

### bkff:genreadme

**Purpose**: Generate or update project README.

**Preconditions**:
- Current directory is a git repository

**Arguments**:
- `--update`: Update existing README, preserving marked sections

**Output**:
```
Sources analyzed:
  - spec.md (found)
  - plan.md (found)
  - Makefile (found)
  - docs/adr/ (3 ADRs found)

Generated: README.md
Sections: Overview, Installation, Usage, Configuration, Contributing, License, Architecture

Note: No spec.md found - generated from codebase analysis only
```

**Exit Codes**:
- 0: README generated successfully
- 1: Partial generation (some sections incomplete)

---

## PR Feedback Skills

### bkff:prfeedback

**Purpose**: Process PR review feedback.

**Preconditions**:
- Current directory is a git repository
- `gh` is available and authenticated
- PR exists for current branch

**Arguments**:
- `--ready`: Mark PR ready for re-review after addressing feedback

**Output**:
```
PR #42: "Add compliance checking"
Comments: 8 total
  Required: 2 (creating beads tasks)
  Suggestions: 3 (pending review)
  Questions: 2 (drafting responses)
  Nitpicks: 1 (noted)

Created: beads-abc123 "Address security review comment" (P1)
Created: beads-def456 "Add error handling per review" (P1)

Run /bkff:prfeedback --ready after addressing all required changes.
```

**Exit Codes**:
- 0: Feedback processed successfully
- 1: No PR exists for branch
- 2: GitHub CLI not authenticated
