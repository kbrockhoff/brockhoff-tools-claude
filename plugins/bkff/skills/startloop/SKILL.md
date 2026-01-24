---
name: startloop
description: Start the agentic development loop to autonomously work through beads issues
invocation: /bkff:startloop
arguments:
  - name: resume
    description: Resume a paused loop instead of starting new
    required: false
    default: false
---

# Start Agentic Development Loop

Initiates an autonomous development loop that iteratively works through beads issues. The loop automatically selects the highest priority ready task (no blockers), claims it, and presents it for implementation.

## Usage

```bash
# Start a new development loop
/bkff:startloop

# Resume a paused loop
/bkff:startloop --resume
```

## How It Works

1. **Task Selection**: Finds the highest priority task with no blockers (`bd ready`)
2. **Task Claiming**: Sets the task status to `in_progress`
3. **Work Presentation**: Displays the task details for implementation
4. **Completion**: After work is done, verification passes, and task is closed
5. **Iteration**: Automatically selects the next ready task

## Loop Lifecycle

```
┌─────────────────────────────────────────────────────────┐
│                    START LOOP                           │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│              SELECT READY TASK                          │
│         (highest priority, no blockers)                 │
└─────────────────────┬───────────────────────────────────┘
                      │
           ┌──────────┴──────────┐
           │                     │
           ▼                     ▼
    ┌─────────────┐       ┌─────────────┐
    │ Task Found  │       │ No Tasks    │
    └──────┬──────┘       └──────┬──────┘
           │                     │
           ▼                     ▼
    ┌─────────────┐       ┌─────────────┐
    │ Claim Task  │       │ LOOP STOPS  │
    │ (in_progress│       │ (complete)  │
    └──────┬──────┘       └─────────────┘
           │
           ▼
    ┌─────────────────────────────────────────────────────┐
    │              WORK ON TASK                           │
    │  • Implement changes                                │
    │  • Generate tests (/bkff:gentests)                  │
    │  • Run verification (/bkff:verifytask)              │
    └─────────────────────┬───────────────────────────────┘
                          │
               ┌──────────┴──────────┐
               │                     │
               ▼                     ▼
        ┌─────────────┐       ┌─────────────┐
        │ Success     │       │ Failure     │
        └──────┬──────┘       └──────┬──────┘
               │                     │
               ▼                     ▼
        ┌─────────────┐       ┌─────────────┐
        │ Close Task  │       │ Retry with  │
        │ Continue    │◄──────│ Backoff     │
        │ Loop        │       └──────┬──────┘
        └──────┬──────┘              │
               │              ┌──────┴──────┐
               │              │ Max Retries │
               │              │ Exceeded    │
               │              └──────┬──────┘
               │                     │
               │                     ▼
               │              ┌─────────────┐
               │              │ LOOP PAUSES │
               │              │ (user input)│
               │              └─────────────┘
               │
               └──────────────────────┐
                                      │
                                      ▼
                              (back to SELECT)
```

## Output

### Starting New Loop

```
Development Loop Status
─────────────────────────────────────
  Status:         running
  Started:        2026-01-24T10:30:00Z
  Completed:      0 tasks

─────────────────────────────────────
Working on: T015 Implement compliance check logic
Issue: beads-abc123
─────────────────────────────────────

The development loop has selected this task.
Work on implementing the task, then run verification.
When complete, the loop will automatically select the next task.

To pause: /bkff:cancelloop
```

### No Ready Tasks

```
Development Loop Status
─────────────────────────────────────
  Status:         running
  Started:        2026-01-24T10:30:00Z
  Completed:      5 tasks

Info: No ready tasks available
✓ Loop completed - all tasks done or blocked
```

### Resuming Paused Loop

```
Info: Loop resumed

Development Loop Status
─────────────────────────────────────
  Status:         running
  Started:        2026-01-24T10:30:00Z
  Completed:      3 tasks

─────────────────────────────────────
Working on: T018 Fix failing test
Issue: beads-def456
─────────────────────────────────────
```

## State Management

Loop state is persisted in `.bkff/loop-state.json`:

```json
{
  "status": "running",
  "started_at": "2026-01-24T10:30:00Z",
  "current_task": {
    "beads_id": "beads-abc123",
    "task_id": "T015",
    "title": "Implement compliance check logic",
    "started_at": "2026-01-24T10:35:00Z"
  },
  "completed_tasks": [
    {
      "beads_id": "beads-xyz789",
      "task_id": "T014",
      "completed_at": "2026-01-24T10:34:00Z",
      "duration_seconds": 240
    }
  ],
  "paused_reason": null,
  "retry_count": 0,
  "last_error": null
}
```

## Retry Behavior

When errors occur, the loop implements exponential backoff:

| Attempt | Wait Time |
|---------|-----------|
| 1 | 5 seconds |
| 2 | 10 seconds |
| 3 | 20 seconds |
| Max | Pause loop |

After max retries (default: 3), the loop pauses and waits for user input.

## Requirements

- Must be run inside a git repository
- Beads must be initialized with tasks
- `bd` CLI must be available
- No other loop currently running (or use `--resume`)

## Exit Codes

- `0` - Loop started/resumed successfully
- `1` - Loop paused (issue encountered)
- `2` - No ready tasks (all done or blocked)
- `3` - Another loop already running

## Related Skills

- `/bkff:cancelloop` - Stop the development loop
- `/bkff:verifytask` - Verify task completion
- `/bkff:gentests` - Generate tests for implemented code

## Implementation

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PLUGIN_DIR/lib/common.sh"
source "$PLUGIN_DIR/lib/loop-state.sh"

# Parse arguments
resume=false
for arg in "$@"; do
    case "$arg" in
        --resume) resume=true ;;
    esac
done

# Validate prerequisites
require_worktree
require_beads
require_bd

# Handle resume
if [[ "$resume" == "true" ]]; then
    if ! has_loop; then
        error_exit "No loop to resume"
    fi
    resume_loop
    print_loop_status
    run_loop_cycle
    exit $?
fi

# Check for existing loop
if has_loop; then
    error_exit "A development loop is already active. Use --resume or run /bkff:cancelloop first."
fi

# Initialize new loop
init_loop
print_loop_status

# Start first cycle
run_loop_cycle
exit_code=$?

case $exit_code in
    0) exit 0 ;;  # Task selected, continue
    1) exit 1 ;;  # Paused
    2)            # No tasks
        success "Loop completed - all tasks done or blocked"
        cancel_loop
        exit 0
        ;;
esac
```
