---
name: prfeedback
description: Parse PR review comments, categorize them, and create beads tasks for required changes
invocation: /bkff:prfeedback
arguments:
  - name: pr
    description: PR number or URL to process
    required: true
  - name: ready
    description: Mark PR as ready for re-review after addressing comments
    required: false
    default: "false"
  - name: format
    description: Output format (human or json)
    required: false
    default: human
---

# Handle PR Review Feedback

Parses PR review comments from GitHub, categorizes them by type and priority, and creates beads tasks for required changes. Supports marking the PR ready for re-review once all blocking comments are addressed.

## Usage

```bash
# Process PR feedback
/bkff:prfeedback --pr=123

# Process by URL
/bkff:prfeedback --pr=https://github.com/owner/repo/pull/123

# Mark ready for re-review after addressing comments
/bkff:prfeedback --pr=123 --ready=true

# Output as JSON for automation
/bkff:prfeedback --pr=123 --format=json
```

## Comment Categorization Logic

Comments are categorized by type and priority based on content analysis:

```
┌─────────────────────────────────────────────────────────────┐
│               COMMENT CATEGORIZATION                         │
└─────────────────────────────────────────────────────────────┘

┌────────────────────────────────────┐
│         FETCH PR COMMENTS          │
│  • Review comments                 │
│  • Inline code comments            │
│  • Conversation threads            │
└─────────────┬──────────────────────┘
              │
              ▼
┌────────────────────────────────────┐
│        ANALYZE EACH COMMENT        │
│  • Extract action indicators       │
│  • Detect blocking keywords        │
│  • Identify suggestions            │
│  • Check resolution status         │
└─────────────┬──────────────────────┘
              │
              ▼
┌────────────────────────────────────┐
│          CATEGORIZE                │
├────────────────────────────────────┤
│ Type:                              │
│  • BLOCKING - Must fix             │
│  • SUGGESTION - Should consider    │
│  • QUESTION - Needs response       │
│  • PRAISE - No action needed       │
│  • NIT - Minor/optional            │
│                                    │
│ Priority:                          │
│  • P0 - Critical/Security          │
│  • P1 - Must fix before merge      │
│  • P2 - Should fix                 │
│  • P3 - Nice to have               │
└────────────────────────────────────┘
```

### Category Detection Rules

| Category | Detected By | Priority |
|----------|-------------|----------|
| BLOCKING | "must", "required", "fix", "blocker", changes_requested review | P1 |
| SECURITY | "vulnerability", "security", "XSS", "injection", "CVE" | P0 |
| SUGGESTION | "suggest", "consider", "could", "might", "optional" | P2 |
| QUESTION | "?", "why", "how", "what", "can you explain" | P2 |
| NIT | "nit:", "nitpick", "minor", "style" | P3 |
| PRAISE | "LGTM", "nice", "great", "well done", approved review | None |

### Keyword Patterns

```
BLOCKING patterns:
  - "please fix"
  - "this needs to"
  - "must be"
  - "required"
  - "blocker"
  - "cannot merge until"
  - Review state: CHANGES_REQUESTED

SECURITY patterns:
  - "security"
  - "vulnerability"
  - "injection"
  - "XSS"
  - "CSRF"
  - "authentication"
  - "authorization"
  - "CVE-"

SUGGESTION patterns:
  - "consider"
  - "suggestion:"
  - "you could"
  - "might want to"
  - "alternatively"
  - "optional:"

NIT patterns:
  - "nit:"
  - "nitpick"
  - "minor:"
  - "style:"
  - "formatting"
```

## Beads Task Creation for Required Changes

When blocking or high-priority comments are found, beads tasks are created:

```
┌─────────────────────────────────────────────────────────────┐
│                TASK CREATION FLOW                            │
└─────────────────────────────────────────────────────────────┘

Categorized Comments:
┌────────────────────────────────────┐
│ BLOCKING: 2 comments               │
│ SECURITY: 1 comment                │
│ SUGGESTION: 3 comments             │
│ NIT: 2 comments                    │
└─────────────┬──────────────────────┘
              │
              │ Create tasks for P0-P2
              ▼
┌────────────────────────────────────┐
│         CREATE BEADS TASKS         │
├────────────────────────────────────┤
│                                    │
│ bd create --type=task              │
│   --title="PR #123: Fix SQL        │
│            injection in query"     │
│   --priority=0                     │
│   --description="..."              │
│                                    │
│ bd create --type=task              │
│   --title="PR #123: Add input      │
│            validation"             │
│   --priority=1                     │
│   --description="..."              │
│                                    │
└─────────────┬──────────────────────┘
              │
              │ Link to parent issue
              ▼
┌────────────────────────────────────┐
│     SET DEPENDENCIES               │
│                                    │
│ • Link tasks to PR feature/epic    │
│ • Add dependency on PR approval    │
└────────────────────────────────────┘
```

### Task Format

```markdown
Title: PR #123: [Comment summary]

Description:
From PR review comment by @reviewer:

> [Original comment text]

File: src/api/query.ts
Line: 42

Action Required:
[Extracted action from comment]

---
PR: https://github.com/owner/repo/pull/123
Comment: https://github.com/owner/repo/pull/123#discussion_r123456
```

### Task Creation Rules

| Comment Type | Task Created | Priority |
|--------------|--------------|----------|
| SECURITY | Yes | P0 |
| BLOCKING | Yes | P1 |
| SUGGESTION (with "should") | Yes | P2 |
| SUGGESTION (with "could") | No (logged only) | - |
| QUESTION | No (needs response) | - |
| NIT | No (logged only) | - |
| PRAISE | No | - |

## --ready Flag for Re-Review

When `--ready=true` is specified:

```
┌─────────────────────────────────────────────────────────────┐
│                  RE-REVIEW FLOW                              │
└─────────────────────────────────────────────────────────────┘

┌────────────────────────────────────┐
│     CHECK BLOCKING COMMENTS        │
│                                    │
│ Scan for unresolved BLOCKING and   │
│ SECURITY comments                  │
└─────────────┬──────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
    ▼                   ▼
┌──────────┐     ┌──────────────────┐
│ All      │     │ Unresolved       │
│ Resolved │     │ Comments Remain  │
└────┬─────┘     └────────┬─────────┘
     │                    │
     ▼                    ▼
┌──────────────┐  ┌──────────────────┐
│ Request      │  │ List unresolved  │
│ Re-review    │  │ Exit with error  │
│ via gh CLI   │  │                  │
└──────────────┘  └──────────────────┘

Re-review request:
  gh pr ready 123
  gh pr edit 123 --add-reviewer @original-reviewer
```

### Re-Review Checklist

Before marking ready:
1. All BLOCKING comments resolved
2. All SECURITY comments resolved
3. All created beads tasks closed
4. Tests passing (checked via CI status)
5. Optional: Response to all QUESTION comments

## Stale Comment Handling

Comments may become stale when code changes after the review:

```
┌─────────────────────────────────────────────────────────────┐
│                 STALE DETECTION                              │
└─────────────────────────────────────────────────────────────┘

Comment on src/api/query.ts:42
┌────────────────────────────────────┐
│ @reviewer: "Fix the SQL injection" │
│ Posted: 2 days ago                 │
│ Line content: "SELECT * FROM..."   │
└────────────────────────────────────┘
              │
              │ Compare with current
              ▼
Current src/api/query.ts:42
┌────────────────────────────────────┐
│ // Using parameterized queries     │
│ Line changed since comment         │
└────────────────────────────────────┘
              │
              ▼
┌────────────────────────────────────┐
│ STALE COMMENT DETECTED             │
│                                    │
│ Possible reasons:                  │
│ • Already addressed                │
│ • Code refactored                  │
│ • Line moved                       │
│                                    │
│ Action: Mark as potentially stale  │
│ Require manual verification        │
└────────────────────────────────────┘
```

### Stale Indicators

| Indicator | Confidence | Action |
|-----------|------------|--------|
| Line deleted | High | Mark as likely resolved |
| Line content changed | Medium | Mark as potentially resolved |
| Commit after comment | Low | Needs verification |
| Resolved in GitHub | Certain | Skip comment |

### Stale Output Format

```
Stale Comments (require verification):
─────────────────────────────────────
  src/api/query.ts:42 - BLOCKING
    Comment: "Fix the SQL injection"
    Status: LINE_CHANGED
    Reason: Line content no longer matches
    Recommendation: Verify fix and resolve in GitHub
```

## Output

### Human Format

```
PR Review Feedback Analysis
═══════════════════════════════════════════════════════════════
PR: #123 - Add user authentication
Author: @contributor
Reviewers: @reviewer1, @reviewer2

Comment Summary
─────────────────────────────────────
  SECURITY:    1
  BLOCKING:    2
  SUGGESTION:  3
  QUESTION:    1
  NIT:         2
  PRAISE:      1

Required Actions (tasks created)
─────────────────────────────────────
  ✓ beads-abc123: PR #123: Fix SQL injection vulnerability (P0)
  ✓ beads-def456: PR #123: Add input validation (P1)
  ✓ beads-ghi789: PR #123: Handle edge case in auth flow (P1)

Suggestions (logged, no task)
─────────────────────────────────────
  • src/auth.ts:15 - Consider using bcrypt instead of sha256
  • src/api.ts:42 - Could add rate limiting here
  • src/utils.ts:8 - Might want to extract this to a helper

Questions (need response)
─────────────────────────────────────
  • src/config.ts:22 - Why is this timeout set to 30s?

Stale Comments
─────────────────────────────────────
  ⚠ src/old-code.ts:10 - Line no longer exists (likely resolved)

Status: 3 blocking items require attention
```

### JSON Format

```json
{
  "pr": {
    "number": 123,
    "title": "Add user authentication",
    "author": "contributor",
    "reviewers": ["reviewer1", "reviewer2"],
    "url": "https://github.com/owner/repo/pull/123"
  },
  "summary": {
    "security": 1,
    "blocking": 2,
    "suggestion": 3,
    "question": 1,
    "nit": 2,
    "praise": 1
  },
  "tasks_created": [
    {
      "beads_id": "beads-abc123",
      "title": "PR #123: Fix SQL injection vulnerability",
      "priority": 0,
      "comment_url": "https://github.com/.../discussion_r123"
    }
  ],
  "comments": [
    {
      "id": "123456",
      "type": "SECURITY",
      "priority": 0,
      "file": "src/api/query.ts",
      "line": 42,
      "author": "reviewer1",
      "body": "This query is vulnerable to SQL injection",
      "resolved": false,
      "stale": false,
      "task_created": "beads-abc123"
    }
  ],
  "stale_comments": [
    {
      "id": "789",
      "reason": "LINE_DELETED",
      "file": "src/old-code.ts",
      "line": 10
    }
  ],
  "ready_for_review": false,
  "blocking_count": 3
}
```

## Requirements

- Git repository with valid worktree
- `gh` CLI authenticated with repo access
- Beads initialized (for task creation)
- PR must exist and be accessible

## Exit Codes

- `0` - Success (or ready for re-review)
- `1` - Processing failed
- `2` - PR not found
- `3` - Blocking comments remain (when --ready=true)
- `4` - gh CLI not authenticated

## Related Skills

- `/bkff:verifytask` - Verify task completion
- `/bkff:tasks2issues` - Convert tasks to beads issues

## Implementation

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PLUGIN_DIR/lib/common.sh"

# Parse arguments
pr_ref=""
ready_mode="false"
format="human"

for arg in "$@"; do
    case "$arg" in
        --pr=*) pr_ref="${arg#--pr=}" ;;
        --ready=*) ready_mode="${arg#--ready=}" ;;
        --format=json) format="json" ;;
        --format=human) format="human" ;;
        --json) format="json" ;;
    esac
done

# Validate prerequisites
require_worktree

if [[ -z "$pr_ref" ]]; then
    error_exit "PR reference required. Use --pr=<number|url>"
fi

# Extract PR number from URL if needed
pr_number="$pr_ref"
if [[ "$pr_ref" =~ /pull/([0-9]+) ]]; then
    pr_number="${BASH_REMATCH[1]}"
fi

# Check gh CLI
if ! command -v gh &>/dev/null; then
    error_exit "GitHub CLI (gh) is required but not installed"
fi

if ! gh auth status &>/dev/null; then
    error_exit "GitHub CLI not authenticated. Run 'gh auth login'"
fi

info "Processing PR #$pr_number feedback"

# Fetch PR comments using gh CLI
# Categorization and task creation is performed by Claude
echo "Ready to fetch and analyze PR comments via gh CLI"
```
