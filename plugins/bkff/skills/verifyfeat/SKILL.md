---
name: verifyfeat
description: Verify feature completion by checking child tasks and running verify target
invocation: /bkff:verifyfeat
arguments:
  - name: issue
    description: Beads feature issue ID to verify
    required: true
  - name: format
    description: Output format (human or json)
    required: false
    default: human
---

# Verify Feature Completion

Verifies that a beads feature is complete by:
1. Checking all child tasks are closed
2. Executing the build system `verify` target
3. Running comprehensive validation including integration tests

## Usage

```bash
# Verify feature
/bkff:verifyfeat --issue=beads-abc123

# Output as JSON
/bkff:verifyfeat --issue=beads-abc123 --format=json
```

## Verification Process

```
┌─────────────────────────────────────────────────────────┐
│            CHECK ACCEPTANCE CRITERIA                    │
│         (must be defined on the feature)                │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│              CHECK CHILD TASKS                          │
│         (all must be in 'closed' status)                │
└─────────────────────┬───────────────────────────────────┘
                      │
           ┌──────────┴──────────┐
           │                     │
           ▼                     ▼
    ┌─────────────┐       ┌─────────────┐
    │ All Closed  │       │ Open Tasks  │
    └──────┬──────┘       └──────┬──────┘
           │                     │
           ▼                     ▼
    ┌─────────────┐       ┌─────────────┐
    │ Run verify  │       │ FAIL        │
    │ target      │       │ (list open) │
    └──────┬──────┘       └─────────────┘
           │
           ▼
    ┌─────────────────────────────────────────────────────┐
    │              VERIFICATION RESULT                    │
    │  (pass/fail based on verify target exit code)       │
    └─────────────────────────────────────────────────────┘
```

## What Gets Checked

The `verify` target should run comprehensive validation:

| Check Type | Description |
|------------|-------------|
| Integration Tests | Cross-component tests |
| Feature Documentation | Feature-level docs complete |
| API Contracts | API compatibility verified |
| Performance | Performance benchmarks (if defined) |
| All validate checks | Tests, quality, security, standards |

## Output

### With Open Child Tasks

```
Warning: Feature has 2 open child task(s)

Verification Result
─────────────────────────────────────
  Issue:          beads-abc123
  Target:         verify

✗ Verification failed

Summary:

Failures:
  beads:-: [standards] Feature has 2 open child task(s) that must be completed first
```

### Verification Passed

```
Info: Verifying feature: beads-abc123

Verification Result
─────────────────────────────────────
  Issue:          beads-abc123
  Target:         verify

✓ Verification passed
```

## Requirements

- Beads feature must have acceptance criteria defined
- All child tasks must be in 'closed' status
- Build system must have a `verify` target in Makefile
- `bd` CLI must be available

## Exit Codes

- `0` - Verification passed
- `1` - Verification failed (open children or verify target failed)
- `2` - Missing acceptance criteria
- `3` - Missing verify target

## Related Skills

- `/bkff:verifytask` - Verify task completion
- `/bkff:verifyepic` - Verify epic completion

## Implementation

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PLUGIN_DIR/lib/common.sh"
source "$PLUGIN_DIR/lib/verification.sh"

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

if [[ -z "$issue_id" ]]; then
    error_exit "Issue ID required. Use --issue=<id>"
fi

# Run verification
result=$(verify_feature "$issue_id")

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
