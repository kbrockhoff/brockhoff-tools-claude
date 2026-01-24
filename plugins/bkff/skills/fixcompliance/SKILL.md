---
name: fixcompliance
description: Automatically fix repository compliance issues to meet Brockhoff Cloud standards
invocation: /bkff:fixcompliance
arguments:
  - name: check
    description: Only fix specific check (e.g., github-codeowners, agents-md, beads-init)
    required: false
  - name: dry-run
    description: Show what would be fixed without making changes
    required: false
    default: false
---

# Fix Repository Compliance

Automatically creates or updates files to bring the repository into compliance with Brockhoff Cloud spec-driven development standards.

## Usage

```
/bkff:fixcompliance
/bkff:fixcompliance --check=agents-md
/bkff:fixcompliance --dry-run
```

## What Gets Fixed

### GitHub Configuration (.github/)

| File | Action |
|------|--------|
| `.github/CODEOWNERS` | Creates with default ownership pattern (`* @OWNER`) |
| `.github/CONTRIBUTING.md` | Creates with standard contribution guidelines |
| `.github/dependabot.yml` | Creates with GitHub Actions update configuration |
| `.github/pull_request_template.md` | Creates with summary, test plan, and checklist sections |
| `.github/ISSUE_TEMPLATE/bug_report.md` | Creates bug report template with frontmatter |
| `.github/ISSUE_TEMPLATE/feature_request.md` | Creates feature request template with frontmatter |

### Agent Instructions

| File | Action |
|------|--------|
| `AGENTS.md` | Creates with project overview, bkff-git skills, and beads workflow sections |
| `CLAUDE.md` | Creates or prepends "Follow all instructions in AGENTS.md" |
| `.github/copilot-instructions.md` | Creates or prepends "Follow all instructions in AGENTS.md" |

### Beads Issue Tracking

| Component | Action |
|-----------|--------|
| `.beads/` | Runs `bd init` to initialize beads |
| Beads health | Runs `bd doctor --fix` to resolve issues |

## Output

```
Fixing Compliance Issues
─────────────────────────────────────
Info: Created .github/CODEOWNERS
Info: Created .github/CONTRIBUTING.md
Info: Created .github/dependabot.yml
Info: Created .github/pull_request_template.md
Info: Created .github/ISSUE_TEMPLATE/bug_report.md
Info: Created .github/ISSUE_TEMPLATE/feature_request.md
Info: Created AGENTS.md
Info: Created CLAUDE.md
Info: Created .github/copilot-instructions.md
Info: Initializing beads...
✓ Beads initialized
Info: Running beads health check...
─────────────────────────────────────
✓ Compliance fixes applied

Run 'bkff:chkcompliance' to verify all issues are resolved
```

## Selective Fixing

Fix only specific components:

```bash
# Fix only AGENTS.md
/bkff:fixcompliance --check=agents-md

# Fix only GitHub files
/bkff:fixcompliance --check=github-codeowners
/bkff:fixcompliance --check=github-contributing

# Fix only beads
/bkff:fixcompliance --check=beads-init
```

## Dry Run Mode

Preview changes without modifying files:

```bash
/bkff:fixcompliance --dry-run
```

Output:
```
Dry Run - No changes will be made
─────────────────────────────────────
Would create: .github/CODEOWNERS
Would create: .github/CONTRIBUTING.md
Would create: AGENTS.md
Would update: CLAUDE.md (add AGENTS.md reference)
Would run: bd init
─────────────────────────────────────
5 actions would be performed
```

## Requirements

- Must be run inside a git repository
- Write permissions to repository files
- `bd` CLI for beads initialization (optional - skips if not available)

## Behavior Notes

- **Non-destructive**: Existing files with correct content are not modified
- **Content preservation**: When updating CLAUDE.md or copilot-instructions.md, existing content is preserved
- **Idempotent**: Running multiple times produces the same result
- **Incremental**: Only missing or incorrect files are fixed

## Exit Codes

- `0` - All fixes applied successfully
- `1` - Some fixes failed (partial success)
- `2` - Not a git repository or permission error

## Related Skills

- `/bkff:chkcompliance` - Check repository compliance status

## Implementation

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PLUGIN_DIR/lib/common.sh"
source "$PLUGIN_DIR/lib/compliance.sh"

# Parse arguments
dry_run=false
specific_check=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) dry_run=true ;;
        --check=*) specific_check="${arg#--check=}" ;;
    esac
done

# Validate git repository
if ! is_git_worktree; then
    error_exit "Not a git repository. This command must be run inside a git repository."
fi

root=$(get_worktree_path)

# Dry run mode
if [[ "$dry_run" == "true" ]]; then
    print_header "Dry Run - No changes will be made"
    actions=0

    [[ ! -f "$root/.github/CODEOWNERS" ]] && echo "Would create: .github/CODEOWNERS" && ((actions++))
    [[ ! -f "$root/.github/CONTRIBUTING.md" ]] && echo "Would create: .github/CONTRIBUTING.md" && ((actions++))
    [[ ! -f "$root/.github/dependabot.yml" ]] && echo "Would create: .github/dependabot.yml" && ((actions++))
    [[ ! -f "$root/.github/pull_request_template.md" ]] && echo "Would create: .github/pull_request_template.md" && ((actions++))
    [[ ! -f "$root/.github/ISSUE_TEMPLATE/bug_report.md" ]] && echo "Would create: .github/ISSUE_TEMPLATE/bug_report.md" && ((actions++))
    [[ ! -f "$root/.github/ISSUE_TEMPLATE/feature_request.md" ]] && echo "Would create: .github/ISSUE_TEMPLATE/feature_request.md" && ((actions++))
    [[ ! -f "$root/AGENTS.md" ]] && echo "Would create: AGENTS.md" && ((actions++))

    if [[ ! -f "$root/CLAUDE.md" ]]; then
        echo "Would create: CLAUDE.md"
        ((actions++))
    elif ! grep -q "AGENTS.md" "$root/CLAUDE.md" 2>/dev/null; then
        echo "Would update: CLAUDE.md (add AGENTS.md reference)"
        ((actions++))
    fi

    if [[ ! -f "$root/.github/copilot-instructions.md" ]]; then
        echo "Would create: .github/copilot-instructions.md"
        ((actions++))
    elif ! grep -q "AGENTS.md" "$root/.github/copilot-instructions.md" 2>/dev/null; then
        echo "Would update: .github/copilot-instructions.md (add AGENTS.md reference)"
        ((actions++))
    fi

    ! has_beads && echo "Would run: bd init" && ((actions++))

    print_divider
    echo "$actions action(s) would be performed"
    exit 0
fi

# Fix specific check or all
if [[ -n "$specific_check" ]]; then
    case "$specific_check" in
        github-codeowners) create_codeowners ;;
        github-contributing) create_contributing ;;
        github-dependabot) create_dependabot ;;
        github-pr-template) create_pr_template ;;
        github-bug-template) create_bug_template ;;
        github-feature-template) create_feature_template ;;
        agents-md) [[ ! -f "$root/AGENTS.md" ]] && create_agents_md ;;
        claude-md) fix_claude_md ;;
        copilot-instructions) fix_copilot_instructions ;;
        beads-init) fix_beads_init ;;
        beads-health) fix_beads_health ;;
        *) error_exit "Unknown check: $specific_check" ;;
    esac
    success "Fixed: $specific_check"
else
    fix_all
fi
```
