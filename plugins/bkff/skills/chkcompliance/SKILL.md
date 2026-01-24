---
name: chkcompliance
description: Check repository compliance with Brockhoff Cloud spec-driven development standards
invocation: /bkff:chkcompliance
arguments:
  - name: format
    description: Output format (human or json)
    required: false
    default: human
---

# Check Repository Compliance

Validates that the current repository meets Brockhoff Cloud spec-driven development standards. Reports which components are compliant and which need attention.

## Usage

```
/bkff:chkcompliance
/bkff:chkcompliance --format=json
```

## Compliance Checks

The following components are validated:

### GitHub Configuration (.github/)
| Check | Path | Description |
|-------|------|-------------|
| github-dir | `.github/` | GitHub configuration directory |
| github-codeowners | `.github/CODEOWNERS` | Code review ownership rules |
| github-contributing | `.github/CONTRIBUTING.md` | Contribution guidelines |
| github-dependabot | `.github/dependabot.yml` | Automated dependency updates |
| github-pr-template | `.github/pull_request_template.md` | PR template for consistency |
| github-issue-templates | `.github/ISSUE_TEMPLATE/` | Issue templates directory |
| github-bug-template | `.github/ISSUE_TEMPLATE/bug_report.md` | Bug report template |
| github-feature-template | `.github/ISSUE_TEMPLATE/feature_request.md` | Feature request template |

### Agent Instructions
| Check | Path | Description |
|-------|------|-------------|
| agents-md | `AGENTS.md` | Agent instructions file with project overview |
| claude-md | `CLAUDE.md` | Must reference AGENTS.md |
| copilot-instructions | `.github/copilot-instructions.md` | Must reference AGENTS.md |

### Beads Issue Tracking
| Check | Path | Description |
|-------|------|-------------|
| beads-init | `.beads/` | Beads must be initialized |
| beads-health | `bd doctor` | Beads health check must pass |

## Output

### Human-Readable (default)
```
Compliance Report
─────────────────────────────────────
  ✓ github-dir
  ✓ github-codeowners
  ✗ github-contributing
    → File missing: .github/CONTRIBUTING.md
  ✓ agents-md
  ✓ claude-md
  ✓ beads-init
  ○ beads-health (skipped)
    → Beads not initialized
─────────────────────────────────────
2 check(s) failed (10 passed, 2 failed)

Run 'bkff:fixcompliance' to automatically fix issues
```

### JSON Format
```json
{
  "timestamp": "2026-01-24T10:30:00Z",
  "repository": "/path/to/repo",
  "overall_status": "fail",
  "checks_passed": 10,
  "checks_failed": 2,
  "checks_skipped": 1,
  "checks_total": 13,
  "checks": [
    {
      "name": "github-codeowners",
      "path": ".github/CODEOWNERS",
      "status": "pass",
      "message": null,
      "description": "Code review ownership rules",
      "remediation": "Create CODEOWNERS with team ownership patterns"
    }
  ]
}
```

## Requirements

- Must be run inside a git repository
- `jq` for JSON processing
- `bd` CLI for beads health check (optional - gracefully skips if not available)

## Exit Codes

- `0` - All checks passed
- `1` - One or more checks failed
- `2` - Not a git repository or other error

## Related Skills

- `/bkff:fixcompliance` - Automatically fix compliance issues

## Implementation

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PLUGIN_DIR/lib/common.sh"
source "$PLUGIN_DIR/lib/compliance.sh"

# Parse arguments
format="human"
for arg in "$@"; do
    case "$arg" in
        --format=json) format="json" ;;
        --format=human) format="human" ;;
        --json) format="json" ;;
    esac
done

# Validate git repository
if ! is_git_worktree; then
    error_exit "Not a git repository. This command must be run inside a git repository."
fi

# Run all compliance checks
report=$(run_all_checks)

# Output based on format
if [[ "$format" == "json" ]]; then
    echo "$report"
else
    echo "$report" | print_compliance_report
fi

# Exit with appropriate code
overall_status=$(echo "$report" | jq -r '.overall_status')
if [[ "$overall_status" == "pass" ]]; then
    exit 0
else
    exit 1
fi
```
