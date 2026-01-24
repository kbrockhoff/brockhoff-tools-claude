---
name: tasks2issues
description: Convert SpecKit tasks.md to beads issues with proper hierarchy and dependencies
invocation: /bkff:tasks2issues
arguments:
  - name: file
    description: Path to tasks.md file (default: auto-detect from specs/)
    required: false
  - name: parent
    description: Parent beads issue ID for created tasks
    required: false
  - name: dry-run
    description: Parse and validate without creating issues
    required: false
    default: false
---

# Convert SpecKit Tasks to Beads Issues

Parses a SpecKit-generated tasks.md file and creates corresponding beads issues with:
- Proper parent-child hierarchy
- Priority mapping (P0-P4 → 0-4)
- Dependency relationships (blocks/blocked-by)
- Phase and user story metadata

## Usage

```bash
# Auto-detect tasks.md from current feature branch
/bkff:tasks2issues

# Specify tasks.md file explicitly
/bkff:tasks2issues --file=specs/001-feature/tasks.md

# Create tasks under a parent epic
/bkff:tasks2issues --parent=beads-abc123

# Preview without creating issues
/bkff:tasks2issues --dry-run
```

## Input Format

The skill parses SpecKit tasks.md format:

```markdown
## Phase 1: Setup (Shared Infrastructure)

### US1 - Check Repository Compliance

- [ ] **T001**: Create plugin directory structure (P2)
  Description of the task goes here
  Depends on: T000

- [ ] **T002**: Create plugin manifest (P2) [parallel]
  Another task description
```

### Supported Elements

| Element | Pattern | Example |
|---------|---------|---------|
| Phase | `## Phase N: Name` | `## Phase 1: Setup` |
| User Story | `### USN` or `### User Story N` | `### US1 - Compliance` |
| Task | `- [ ] **TXXX**: Title` | `- [ ] **T001**: Create structure` |
| Priority | `(P0)` to `(P4)` | `(P2)` |
| Parallel | `[parallel]` | `[parallel]` |
| Dependency | `Depends on: TXXX` | `Depends on: T001, T002` |

## Output

### Normal Execution

```
Converting 15 tasks to beads issues
─────────────────────────────────────
  ✓ T001 -> beads-abc123
  ✓ T002 -> beads-def456
  ✓ T003 -> beads-ghi789
  ...

Adding dependencies
─────────────────────────────────────
  ✓ beads-def456 depends on beads-abc123
  ✓ beads-ghi789 depends on beads-def456
─────────────────────────────────────
Created: 15 issues
Failed: 0 issues
Dependencies: 8 added
```

### Dry Run

```
Parsed Tasks (15 total)
─────────────────────────────────────

Phase 1: Setup
  T001 [P2] Create plugin directory structure
  T002 [P2] Create plugin manifest (depends: T001)

Phase 2: Implementation
  T003 [P1] Implement core feature (depends: T002)
  ...
─────────────────────────────────────
Validation: OK
Dependencies: Valid (no cycles)

Dry run complete - no issues created
```

## Priority Mapping

| tasks.md | beads |
|----------|-------|
| `(P0)` | Priority 0 (Critical) |
| `(P1)` | Priority 1 (High) |
| `(P2)` | Priority 2 (Medium) - default |
| `(P3)` | Priority 3 (Low) |
| `(P4)` | Priority 4 (Backlog) |

## Dependency Handling

Dependencies are converted to beads `blocks`/`blocked-by` relationships:

- `T002 depends on T001` → `beads-T002` is blocked by `beads-T001`
- Multiple dependencies supported: `Depends on: T001, T003, T005`

### Validation

Before creating issues, the skill validates:
1. All referenced dependencies exist
2. No circular dependencies
3. Task IDs are unique

## Requirements

- Must be run inside a git repository
- Beads must be initialized (`.beads/` directory)
- `bd` CLI must be available
- `jq` for JSON processing

## Auto-Detection

When no `--file` is specified, the skill attempts to find tasks.md by:

1. Looking for `specs/<branch-name>/tasks.md`
2. Looking for `specs/*/tasks.md` (uses first match)
3. Looking for `tasks.md` in repository root

## Exit Codes

- `0` - All tasks converted successfully
- `1` - Some tasks failed to convert
- `2` - Validation error (missing deps, cycles)
- `3` - Tasks file not found

## Related Skills

- `/speckit.tasks` - Generate tasks.md from specification
- `/bkff:startloop` - Start agentic development loop on created issues

## Implementation

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PLUGIN_DIR/lib/common.sh"
source "$PLUGIN_DIR/lib/tasks-parser.sh"

# Parse arguments
tasks_file=""
parent_id=""
dry_run=false

for arg in "$@"; do
    case "$arg" in
        --file=*) tasks_file="${arg#--file=}" ;;
        --parent=*) parent_id="${arg#--parent=}" ;;
        --dry-run) dry_run=true ;;
    esac
done

# Validate prerequisites
require_worktree
require_beads
require_jq

root=$(get_worktree_path)

# Auto-detect tasks.md if not specified
if [[ -z "$tasks_file" ]]; then
    branch=$(get_current_branch)

    # Try branch-specific specs
    if [[ -f "$root/specs/$branch/tasks.md" ]]; then
        tasks_file="$root/specs/$branch/tasks.md"
    # Try any specs directory
    elif ls "$root"/specs/*/tasks.md &>/dev/null 2>&1; then
        tasks_file=$(ls "$root"/specs/*/tasks.md 2>/dev/null | head -1)
    # Try root
    elif [[ -f "$root/tasks.md" ]]; then
        tasks_file="$root/tasks.md"
    else
        error_exit "No tasks.md found. Specify with --file=<path>"
    fi
fi

if [[ ! -f "$tasks_file" ]]; then
    error_exit "Tasks file not found: $tasks_file"
fi

info "Using tasks file: $tasks_file"

# Parse tasks
tasks_json=$(parse_tasks_file "$tasks_file")
task_count=$(get_task_count "$tasks_json")

if [[ "$task_count" -eq 0 ]]; then
    warn "No tasks found in $tasks_file"
    exit 0
fi

# Dry run mode
if [[ "$dry_run" == "true" ]]; then
    print_tasks "$tasks_json"

    echo ""
    if validate_dependencies "$tasks_json" 2>/dev/null; then
        echo -e "${GREEN}Validation: OK${NC}"
    else
        echo -e "${RED}Validation: Failed (invalid dependencies)${NC}"
        exit 2
    fi

    if check_circular_deps "$tasks_json" 2>/dev/null; then
        echo -e "${GREEN}Dependencies: Valid (no cycles)${NC}"
    else
        echo -e "${RED}Dependencies: Circular dependency detected${NC}"
        exit 2
    fi

    echo ""
    echo "Dry run complete - no issues created"
    exit 0
fi

# Convert tasks to issues
mapping=$(convert_tasks_to_issues "$tasks_json" "$parent_id")

# Output mapping for reference
echo ""
echo "Task to Issue Mapping:"
echo "$mapping" | jq -r 'to_entries[] | "  \(.key) -> \(.value)"'
```
