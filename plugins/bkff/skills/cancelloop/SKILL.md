---
name: cancelloop
description: Cancel or pause the agentic development loop
invocation: /bkff:cancelloop
arguments:
  - name: pause
    description: Pause the loop instead of cancelling (can be resumed)
    required: false
    default: false
  - name: reason
    description: Reason for pausing/cancelling
    required: false
---

# Cancel Development Loop

Stops the agentic development loop gracefully. The loop will complete its current atomic operation before stopping.

## Usage

```bash
# Cancel the loop (archives state to history)
/bkff:cancelloop

# Pause the loop (can be resumed later)
/bkff:cancelloop --pause

# Pause with a reason
/bkff:cancelloop --pause --reason="Need to review approach"
```

## Behavior

### Cancel (Default)

- Stops the loop immediately after current operation
- Archives loop state to `.bkff/history/`
- Removes active loop state file
- Current task remains in `in_progress` status in beads

### Pause

- Sets loop status to `paused`
- Preserves all state for later resume
- Records pause reason if provided
- Can be resumed with `/bkff:startloop --resume`

## Output

### Cancelling Active Loop

```
Development Loop Status
─────────────────────────────────────
  Status:         running
  Started:        2026-01-24T10:30:00Z
  Completed:      5 tasks

Current Task
  Task ID:        T018
  Title:          Implement validation helpers
  Started:        2026-01-24T11:15:00Z

✓ Loop cancelled
Debug: Archived loop state to .bkff/history/2026-01-24T11-20-00Z.json
```

### Pausing Loop

```
Development Loop Status
─────────────────────────────────────
  Status:         running
  Started:        2026-01-24T10:30:00Z
  Completed:      5 tasks

Info: Loop paused: Need to review approach

To resume: /bkff:startloop --resume
```

### No Loop Running

```
Info: No loop running
```

## State After Cancel

When cancelled, the loop state is archived to `.bkff/history/`:

```json
{
  "status": "stopped",
  "started_at": "2026-01-24T10:30:00Z",
  "stopped_at": "2026-01-24T11:20:00Z",
  "current_task": {
    "beads_id": "beads-abc123",
    "task_id": "T018",
    "title": "Implement validation helpers",
    "started_at": "2026-01-24T11:15:00Z"
  },
  "completed_tasks": [
    {"beads_id": "beads-xyz789", "task_id": "T014", ...},
    {"beads_id": "beads-def456", "task_id": "T015", ...}
  ],
  "paused_reason": null,
  "retry_count": 0,
  "last_error": null
}
```

## State After Pause

When paused, state remains in `.bkff/loop-state.json`:

```json
{
  "status": "paused",
  "started_at": "2026-01-24T10:30:00Z",
  "current_task": {...},
  "completed_tasks": [...],
  "paused_reason": "Need to review approach",
  "retry_count": 0,
  "last_error": null
}
```

## Handling In-Progress Tasks

When the loop is cancelled with an in-progress task:

1. The task remains `in_progress` in beads
2. You can manually:
   - Complete it: `bd close <id>`
   - Reset it: `bd update <id> --status=open`
   - Continue working on it independently

## Requirements

- Must be run inside a git repository
- `.bkff/` directory must exist

## Exit Codes

- `0` - Loop cancelled/paused successfully or no loop running
- `1` - Error during cancellation

## Related Skills

- `/bkff:startloop` - Start or resume the development loop
- `/bkff:startloop --resume` - Resume a paused loop

## Implementation

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PLUGIN_DIR/lib/common.sh"
source "$PLUGIN_DIR/lib/loop-state.sh"

# Parse arguments
pause_mode=false
reason=""

for arg in "$@"; do
    case "$arg" in
        --pause) pause_mode=true ;;
        --reason=*) reason="${arg#--reason=}" ;;
    esac
done

# Validate prerequisites
require_worktree

# Check if loop exists
if ! has_loop; then
    info "No loop running"
    exit 0
fi

# Show current status
print_loop_status
echo ""

# Pause or cancel
if [[ "$pause_mode" == "true" ]]; then
    if [[ -z "$reason" ]]; then
        reason="Paused by user"
    fi
    pause_loop "$reason"
    echo ""
    echo "To resume: /bkff:startloop --resume"
else
    cancel_loop
fi
```
