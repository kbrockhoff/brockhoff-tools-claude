---
name: verifytask
description: Verify task completion by running build system validate target
invocation: /bkff:verifytask
arguments:
  - name: issue
    description: Beads issue ID to verify (default: current task from loop)
    required: false
  - name: format
    description: Output format (human or json)
    required: false
    default: human
---

# Verify Task Completion

Verifies that a beads task is complete by executing the build system `validate` target. Checks acceptance criteria and runs tests, code quality, documentation, security, and standards checks.

## Usage

```bash
# Verify specific task
/bkff:verifytask --issue=beads-abc123

# Verify current task from development loop
/bkff:verifytask

# Output as JSON (for agent consumption)
/bkff:verifytask --format=json
```

## What Gets Checked

The `validate` target should run:

| Check Type | Description |
|------------|-------------|
| Tests | Unit tests, integration tests |
| Quality | Linting, static analysis (shellcheck, eslint, etc.) |
| Docs | Documentation completeness |
| Security | Security scanning, vulnerability checks |
| Standards | Code standards, formatting |

## Output

### Human-Readable (Pass)

```
Info: Verifying task: beads-abc123

Verification Result
─────────────────────────────────────
  Issue:          beads-abc123
  Target:         validate

✓ Verification passed
```

### Human-Readable (Fail)

```
Info: Verifying task: beads-abc123

Verification Result
─────────────────────────────────────
  Issue:          beads-abc123
  Target:         validate

✗ Verification failed

Summary:
  • Tests failed: 2
  • Quality errors: 1

Failures:
  tests/test-compliance.sh:-: [test] Test failed: test_check_file_exists
  lib/compliance.sh:42: [quality] SC2086: Double quote to prevent globbing
```

### JSON Format

```json
{
  "issue_id": "beads-abc123",
  "issue_type": "task",
  "target": "validate",
  "status": "fail",
  "timestamp": "2026-01-24T12:00:00Z",
  "acceptance_criteria_checked": true,
  "failures": [
    {
      "file": "lib/compliance.sh",
      "line": 42,
      "type": "quality",
      "severity": "error",
      "message": "SC2086: Double quote to prevent globbing",
      "hint": null
    }
  ],
  "summary": {
    "tests": {"passed": 0, "failed": 2},
    "quality": {"errors": 1, "warnings": 0},
    "docs": {"complete": true},
    "security": {"issues": 0}
  }
}
```

## Requirements

- Beads issue must have acceptance criteria defined
- Build system must have a `validate` target in Makefile
- `bd` CLI must be available

## Exit Codes

- `0` - Verification passed
- `1` - Verification failed
- `2` - Missing acceptance criteria
- `3` - Missing validate target

## Related Skills

- `/bkff:verifyfeat` - Verify feature completion
- `/bkff:verifyepic` - Verify epic completion
- `/bkff:verifybug` - Verify bug fix

## Implementation

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PLUGIN_DIR/lib/common.sh"
source "$PLUGIN_DIR/lib/verification.sh"
source "$PLUGIN_DIR/lib/loop-state.sh"

# Parse arguments
issue_id=""
format="human"

for arg in "$@"; do
    case "$arg" in
        --issue=*) issue_id="${arg#--issue=}" ;;
        --format=json) format="json" ;;
        --format=human) format="human" ;;
        --json) format="json" ;;
    esac
done

# Validate prerequisites
require_worktree
require_bd

# Get issue ID from current task if not specified
if [[ -z "$issue_id" ]]; then
    current=$(get_current_task 2>/dev/null || echo "null")
    if [[ "$current" != "null" && -n "$current" ]]; then
        issue_id=$(echo "$current" | jq -r '.beads_id // empty')
    fi
fi

if [[ -z "$issue_id" ]]; then
    error_exit "No issue specified. Use --issue=<id> or run from within a development loop."
fi

# Run verification
result=$(verify_task "$issue_id")

# Output based on format
if [[ "$format" == "json" ]]; then
    echo "$result"
else
    echo "$result" | print_verification_result
fi

# Exit with appropriate code
status=$(echo "$result" | jq -r '.status')
[[ "$status" == "pass" ]]
```
