---
name: verifyepic
description: Verify epic completion by checking child features and running verify target
invocation: /bkff:verifyepic
arguments:
  - name: issue
    description: Beads epic issue ID to verify
    required: true
  - name: format
    description: Output format (human or json)
    required: false
    default: human
---

# Verify Epic Completion

Verifies that a beads epic is complete by:
1. Checking all child features are closed
2. Executing the build system `verify` target for epic scope
3. Running comprehensive cross-feature validation

## Usage

```bash
# Verify epic
/bkff:verifyepic --issue=beads-abc123

# Output as JSON
/bkff:verifyepic --issue=beads-abc123 --format=json
```

## Verification Process

1. **Acceptance Criteria Check**: Epic must have defined acceptance criteria
2. **Child Features Check**: All child features must be in 'closed' status
3. **Verify Target**: Run comprehensive verification for epic scope

## What Gets Checked

The `verify` target at epic scope should run:

| Check Type | Description |
|------------|-------------|
| Cross-Feature Tests | Integration across all features |
| Epic Documentation | Epic-level documentation complete |
| System Integration | End-to-end system tests |
| All feature checks | Everything from feature verification |

## Output

### With Open Child Features

```
Warning: Epic has 3 open child feature(s)

Verification Result
─────────────────────────────────────
  Issue:          beads-abc123
  Target:         verify

✗ Verification failed

Summary:

Failures:
  beads:-: [standards] Epic has 3 open child feature(s) that must be completed first
```

### Verification Passed

```
Info: Verifying epic: beads-abc123

Verification Result
─────────────────────────────────────
  Issue:          beads-abc123
  Target:         verify

✓ Verification passed
```

## Requirements

- Beads epic must have acceptance criteria defined
- All child features must be in 'closed' status
- Build system must have a `verify` target in Makefile
- `bd` CLI must be available

## Exit Codes

- `0` - Verification passed
- `1` - Verification failed
- `2` - Missing acceptance criteria
- `3` - Missing verify target

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
result=$(verify_epic "$issue_id")

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
