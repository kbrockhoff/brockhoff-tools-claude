---
name: verifybug
description: Verify bug fix by running validate target and confirming fix
invocation: /bkff:verifybug
arguments:
  - name: issue
    description: Beads bug issue ID to verify
    required: true
  - name: format
    description: Output format (human or json)
    required: false
    default: human
---

# Verify Bug Fix

Verifies that a beads bug is fixed by:
1. Checking acceptance criteria (reproduction steps and fix verification)
2. Executing the build system `validate` target
3. Confirming the bug no longer reproduces

## Usage

```bash
# Verify bug fix
/bkff:verifybug --issue=beads-abc123

# Output as JSON
/bkff:verifybug --issue=beads-abc123 --format=json
```

## Verification Process

1. **Acceptance Criteria Check**: Bug must have:
   - Reproduction steps (how to trigger the bug)
   - Fix verification steps (how to confirm the fix)

2. **Validate Target**: Runs tests to ensure:
   - The bug no longer reproduces
   - No regression in existing functionality
   - Code quality standards maintained

## What Gets Checked

The `validate` target for bugs should verify:

| Check Type | Description |
|------------|-------------|
| Regression Tests | Bug-specific regression test passes |
| Unit Tests | All related unit tests pass |
| Quality | No new quality issues introduced |
| Standards | Fix follows coding standards |

## Output

### Verification Passed

```
Info: Verifying bug fix: beads-abc123

Verification Result
─────────────────────────────────────
  Issue:          beads-abc123
  Target:         validate

✓ Verification passed
```

### Verification Failed

```
Info: Verifying bug fix: beads-abc123

Verification Result
─────────────────────────────────────
  Issue:          beads-abc123
  Target:         validate

✗ Verification failed

Summary:
  • Tests failed: 1

Failures:
  tests/test-regression.sh:-: [test] Test failed: test_bug_123_does_not_reproduce
```

## Bug Issue Best Practices

For effective bug verification, ensure your bug issue includes:

```markdown
## Description
Clear description of the bug behavior.

## Reproduction Steps
1. Step to reproduce
2. Step to reproduce
3. Observe the bug

## Expected Behavior
What should happen instead.

## Fix Verification
1. Step to verify fix
2. Confirm expected behavior
3. Check no regression
```

## Requirements

- Beads bug must have acceptance criteria (reproduction/verification steps)
- Build system must have a `validate` target in Makefile
- `bd` CLI must be available

## Exit Codes

- `0` - Verification passed (bug is fixed)
- `1` - Verification failed (bug still reproduces or other failures)
- `2` - Missing acceptance criteria
- `3` - Missing validate target

## Related Skills

- `/bkff:verifytask` - Verify task completion
- `/bkff:verifyfeat` - Verify feature completion

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
result=$(verify_bug "$issue_id")

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
