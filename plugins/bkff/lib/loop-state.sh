#!/usr/bin/env bash
# loop-state.sh - Development loop state management
# Source this file for loop state functionality

set -euo pipefail

# Get the directory containing this script
LOOP_STATE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LOOP_STATE_LIB_DIR/common.sh"

# =============================================================================
# Constants
# =============================================================================

readonly LOOP_STATE_FILE="loop-state.json"
readonly LOOP_HISTORY_DIR="history"

# Loop status values
readonly LOOP_STATUS_RUNNING="running"
readonly LOOP_STATUS_PAUSED="paused"
readonly LOOP_STATUS_STOPPED="stopped"

# =============================================================================
# State File Management
# =============================================================================

# Get the path to the loop state file
get_loop_state_path() {
    local bkff_dir
    bkff_dir=$(get_bkff_dir)
    echo "$bkff_dir/$LOOP_STATE_FILE"
}

# Check if a loop is currently running
is_loop_running() {
    local state_file
    state_file=$(get_loop_state_path)

    if [[ ! -f "$state_file" ]]; then
        return 1
    fi

    local status
    status=$(jq -r '.status // "stopped"' "$state_file" 2>/dev/null || echo "stopped")
    [[ "$status" == "$LOOP_STATUS_RUNNING" ]]
}

# Check if a loop exists (running or paused)
has_loop() {
    local state_file
    state_file=$(get_loop_state_path)

    if [[ ! -f "$state_file" ]]; then
        return 1
    fi

    local status
    status=$(jq -r '.status // "stopped"' "$state_file" 2>/dev/null || echo "stopped")
    [[ "$status" == "$LOOP_STATUS_RUNNING" || "$status" == "$LOOP_STATUS_PAUSED" ]]
}

# =============================================================================
# Loop Initialization
# =============================================================================

# Initialize a new development loop
# Usage: init_loop
# Returns: JSON loop state
init_loop() {
    require_bkff_dir

    if has_loop; then
        error_exit "A development loop is already active. Cancel it first with 'bkff:cancelloop'"
    fi

    local state_file
    state_file=$(get_loop_state_path)
    local timestamp
    timestamp=$(get_timestamp)

    local state
    state=$(jq -n \
        --arg status "$LOOP_STATUS_RUNNING" \
        --arg started_at "$timestamp" \
        '{
            status: $status,
            started_at: $started_at,
            current_task: null,
            completed_tasks: [],
            paused_reason: null,
            retry_count: 0,
            last_error: null
        }')

    echo "$state" > "$state_file"
    debug "Initialized loop state at $state_file"
    echo "$state"
}

# =============================================================================
# State Reading
# =============================================================================

# Get the current loop state
# Returns: JSON loop state or empty if no state
get_loop_state() {
    local state_file
    state_file=$(get_loop_state_path)

    if [[ ! -f "$state_file" ]]; then
        echo ""
        return 1
    fi

    cat "$state_file"
}

# Get current task from loop state
# Returns: JSON task object or null
get_current_task() {
    local state
    state=$(get_loop_state) || return 1
    echo "$state" | jq '.current_task'
}

# Get completed tasks from loop state
# Returns: JSON array of completed tasks
get_completed_tasks() {
    local state
    state=$(get_loop_state) || return 1
    echo "$state" | jq '.completed_tasks'
}

# Get retry count
get_retry_count() {
    local state
    state=$(get_loop_state) || return 1
    echo "$state" | jq -r '.retry_count // 0'
}

# =============================================================================
# State Updates
# =============================================================================

# Save loop state
# Usage: save_loop_state "$state_json"
save_loop_state() {
    local state="$1"
    local state_file
    state_file=$(get_loop_state_path)
    echo "$state" > "$state_file"
}

# Set the current task
# Usage: set_current_task "$beads_id" "$task_id" "$title"
set_current_task() {
    local beads_id="$1"
    local task_id="$2"
    local title="$3"
    local timestamp
    timestamp=$(get_timestamp)

    local state
    state=$(get_loop_state) || error_exit "No active loop"

    state=$(echo "$state" | jq \
        --arg beads_id "$beads_id" \
        --arg task_id "$task_id" \
        --arg title "$title" \
        --arg started_at "$timestamp" \
        '.current_task = {
            beads_id: $beads_id,
            task_id: $task_id,
            title: $title,
            started_at: $started_at
        }')

    save_loop_state "$state"
    debug "Set current task: $task_id"
}

# Mark current task as completed and move to completed_tasks
# Usage: complete_current_task
complete_current_task() {
    local state
    state=$(get_loop_state) || error_exit "No active loop"

    local current_task
    current_task=$(echo "$state" | jq '.current_task')

    if [[ "$current_task" == "null" ]]; then
        warn "No current task to complete"
        return 1
    fi

    local timestamp
    timestamp=$(get_timestamp)
    local started_at
    started_at=$(echo "$current_task" | jq -r '.started_at')

    # Calculate duration (simple approximation)
    local duration=0
    if [[ -n "$started_at" ]]; then
        local start_epoch end_epoch
        # Try BSD/macOS format first, then GNU/Linux format
        start_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" "+%s" 2>/dev/null || \
                      date -d "$started_at" "+%s" 2>/dev/null || \
                      echo 0)
        end_epoch=$(date -u "+%s")
        duration=$((end_epoch - start_epoch))
    fi

    state=$(echo "$state" | jq \
        --arg completed_at "$timestamp" \
        --argjson duration "$duration" \
        '.completed_tasks += [{
            beads_id: .current_task.beads_id,
            task_id: .current_task.task_id,
            completed_at: $completed_at,
            duration_seconds: $duration
        }] | .current_task = null | .retry_count = 0 | .last_error = null')

    save_loop_state "$state"
    debug "Completed task and cleared current"
}

# Increment retry count and record error
# Usage: record_retry "$error_message"
record_retry() {
    local error_message="$1"

    local state
    state=$(get_loop_state) || error_exit "No active loop"

    state=$(echo "$state" | jq \
        --arg error "$error_message" \
        '.retry_count = (.retry_count + 1) | .last_error = $error')

    save_loop_state "$state"
}

# =============================================================================
# Loop Control
# =============================================================================

# Pause the loop with a reason
# Usage: pause_loop "$reason"
pause_loop() {
    local reason="$1"

    local state
    state=$(get_loop_state) || error_exit "No active loop"

    state=$(echo "$state" | jq \
        --arg status "$LOOP_STATUS_PAUSED" \
        --arg reason "$reason" \
        '.status = $status | .paused_reason = $reason')

    save_loop_state "$state"
    info "Loop paused: $reason"
}

# Resume a paused loop
# Usage: resume_loop
resume_loop() {
    local state
    state=$(get_loop_state) || error_exit "No loop to resume"

    local status
    status=$(echo "$state" | jq -r '.status')

    if [[ "$status" != "$LOOP_STATUS_PAUSED" ]]; then
        error_exit "Loop is not paused (status: $status)"
    fi

    state=$(echo "$state" | jq \
        --arg status "$LOOP_STATUS_RUNNING" \
        '.status = $status | .paused_reason = null | .retry_count = 0 | .last_error = null')

    save_loop_state "$state"
    info "Loop resumed"
}

# Stop the loop and archive to history
# Usage: cancel_loop
cancel_loop() {
    local state_file
    state_file=$(get_loop_state_path)

    if [[ ! -f "$state_file" ]]; then
        info "No loop running"
        return 0
    fi

    local state
    state=$(cat "$state_file")

    local status
    status=$(echo "$state" | jq -r '.status // "stopped"')

    if [[ "$status" == "$LOOP_STATUS_STOPPED" ]]; then
        info "No loop running"
        return 0
    fi

    # Archive to history
    local bkff_dir
    bkff_dir=$(get_bkff_dir)
    local history_dir="$bkff_dir/$LOOP_HISTORY_DIR"
    mkdir -p "$history_dir"

    local archive_name
    archive_name=$(get_filename_timestamp)
    local archive_file="$history_dir/${archive_name}.json"

    # Update final state
    local stopped_at
    stopped_at=$(get_timestamp)
    state=$(echo "$state" | jq \
        --arg status "$LOOP_STATUS_STOPPED" \
        --arg stopped_at "$stopped_at" \
        '.status = $status | .stopped_at = $stopped_at')

    echo "$state" > "$archive_file"
    debug "Archived loop state to $archive_file"

    # Remove current state file
    rm "$state_file"
    success "Loop cancelled"
}

# =============================================================================
# Human-Readable Output
# =============================================================================

# Print loop status
print_loop_status() {
    local state
    state=$(get_loop_state)

    if [[ -z "$state" ]]; then
        info "No active development loop"
        return
    fi

    local status
    status=$(echo "$state" | jq -r '.status')
    local started_at
    started_at=$(echo "$state" | jq -r '.started_at')
    local completed_count
    completed_count=$(echo "$state" | jq '.completed_tasks | length')

    print_header "Development Loop Status"
    print_kv "Status" "$status"
    print_kv "Started" "$started_at"
    print_kv "Completed" "$completed_count tasks"

    local current_task
    current_task=$(echo "$state" | jq -r '.current_task // empty')
    if [[ -n "$current_task" && "$current_task" != "null" ]]; then
        echo ""
        echo -e "${BOLD}Current Task${NC}"
        local task_id title task_started
        task_id=$(echo "$state" | jq -r '.current_task.task_id')
        title=$(echo "$state" | jq -r '.current_task.title')
        task_started=$(echo "$state" | jq -r '.current_task.started_at')
        print_kv "Task ID" "$task_id"
        print_kv "Title" "$title"
        print_kv "Started" "$task_started"
    fi

    local paused_reason
    paused_reason=$(echo "$state" | jq -r '.paused_reason // empty')
    if [[ -n "$paused_reason" ]]; then
        echo ""
        echo -e "${YELLOW}Paused:${NC} $paused_reason"
    fi

    local last_error
    last_error=$(echo "$state" | jq -r '.last_error // empty')
    if [[ -n "$last_error" ]]; then
        local retry_count
        retry_count=$(echo "$state" | jq -r '.retry_count')
        echo ""
        echo -e "${RED}Last Error (retry $retry_count):${NC} $last_error"
    fi
}

# Get max retries from config
get_max_retries() {
    local max_retries
    max_retries=$(get_bkff_config ".loop.max_retries")
    echo "${max_retries:-3}"
}

# Get retry backoff seconds from config
get_retry_backoff() {
    local backoff
    backoff=$(get_bkff_config ".loop.retry_backoff_seconds")
    echo "${backoff:-5}"
}

# Check if we've exceeded max retries
exceeds_max_retries() {
    local current
    current=$(get_retry_count)
    local max
    max=$(get_max_retries)
    [[ "$current" -ge "$max" ]]
}

# =============================================================================
# Task Selection
# =============================================================================

# Select the highest priority ready task from beads
# Returns: JSON object with beads_id, title, priority or empty if none
select_ready_task() {
    require_bd

    # Get ready tasks from beads (no blockers, not in progress)
    local ready_output
    ready_output=$(bd ready --json 2>/dev/null || echo "[]")

    if [[ "$ready_output" == "[]" || -z "$ready_output" ]]; then
        echo ""
        return 1
    fi

    # Filter to only tasks (not features or epics) and sort by priority
    local task
    task=$(echo "$ready_output" | jq -r '
        [.[] | select(.type == "task")] |
        sort_by(.priority) |
        first // empty
    ' 2>/dev/null)

    if [[ -z "$task" || "$task" == "null" ]]; then
        # Fall back to any ready issue if no tasks
        task=$(echo "$ready_output" | jq -r '
            sort_by(.priority) |
            first // empty
        ' 2>/dev/null)
    fi

    if [[ -z "$task" || "$task" == "null" ]]; then
        echo ""
        return 1
    fi

    echo "$task"
}

# Claim a task by setting it to in_progress
# Usage: claim_task "$beads_id"
claim_task() {
    local beads_id="$1"

    require_bd

    bd update "$beads_id" --status=in_progress &>/dev/null || {
        warn "Failed to claim task: $beads_id"
        return 1
    }

    debug "Claimed task: $beads_id"
}

# Complete a task by closing it
# Usage: close_task "$beads_id" ["$reason"]
close_task() {
    local beads_id="$1"
    local reason="${2:-Completed by development loop}"

    require_bd

    bd close "$beads_id" --reason="$reason" &>/dev/null || {
        warn "Failed to close task: $beads_id"
        return 1
    }

    debug "Closed task: $beads_id"
}

# =============================================================================
# Retry Logic
# =============================================================================

# Execute with exponential backoff retry
# Usage: retry_with_backoff command [args...]
# Returns: exit code of command (0 on success, 1 after max retries)
retry_with_backoff() {
    local max_retries
    max_retries=$(get_max_retries)
    local base_backoff
    base_backoff=$(get_retry_backoff)

    local attempt=0
    local exit_code=0

    while [[ $attempt -lt $max_retries ]]; do
        # Run the command
        set +e
        "$@"
        exit_code=$?
        set -e

        if [[ $exit_code -eq 0 ]]; then
            return 0
        fi

        ((attempt++))

        if [[ $attempt -lt $max_retries ]]; then
            # Exponential backoff: base * 2^attempt
            local backoff=$((base_backoff * (2 ** (attempt - 1))))
            warn "Attempt $attempt failed, retrying in ${backoff}s..."
            record_retry "Command failed with exit code $exit_code"
            sleep "$backoff"
        fi
    done

    return 1
}

# =============================================================================
# Development Loop Cycle
# =============================================================================

# Run a single development loop cycle
# Returns: 0 to continue, 1 to pause, 2 to stop (no tasks)
run_loop_cycle() {
    # Check if loop is still running
    if ! is_loop_running; then
        return 2
    fi

    # Select next ready task
    local task
    task=$(select_ready_task)

    if [[ -z "$task" ]]; then
        info "No ready tasks available"
        return 2
    fi

    local beads_id title priority
    beads_id=$(echo "$task" | jq -r '.id // .beads_id // empty')
    title=$(echo "$task" | jq -r '.title // .subject // empty')
    priority=$(echo "$task" | jq -r '.priority // 2')

    if [[ -z "$beads_id" ]]; then
        warn "Could not extract task ID"
        return 1
    fi

    info "Selected task: $beads_id - $title (P$priority)"

    # Claim the task
    if ! claim_task "$beads_id"; then
        record_retry "Failed to claim task $beads_id"
        if exceeds_max_retries; then
            pause_loop "Failed to claim task after max retries"
            return 1
        fi
        return 0  # Continue to retry
    fi

    # Extract task_id from title if present (format: "T001 Title")
    local task_id=""
    if [[ "$title" =~ ^([Tt][0-9]+)[[:space:]] ]]; then
        task_id="${BASH_REMATCH[1]}"
    else
        task_id="$beads_id"
    fi

    # Set as current task
    set_current_task "$beads_id" "$task_id" "$title"

    # Return success - the calling skill/agent should now work on this task
    # The loop will be continued by the agent after task completion
    echo ""
    echo "─────────────────────────────────────"
    echo -e "${BOLD}Working on:${NC} $title"
    echo -e "${BOLD}Issue:${NC} $beads_id"
    echo "─────────────────────────────────────"
    echo ""
    echo "The development loop has selected this task."
    echo "Work on implementing the task, then run verification."
    echo "When complete, the loop will automatically select the next task."
    echo ""
    echo "To pause: /bkff:cancelloop"

    return 0
}

# Mark current task complete and continue loop
# Usage: complete_and_continue
complete_and_continue() {
    local state
    state=$(get_loop_state) || {
        warn "No active loop"
        return 1
    }

    local current_task
    current_task=$(echo "$state" | jq '.current_task')

    if [[ "$current_task" == "null" ]]; then
        warn "No current task to complete"
        return 1
    fi

    local beads_id
    beads_id=$(echo "$current_task" | jq -r '.beads_id')

    # Close the task in beads
    close_task "$beads_id" "Completed by development loop"

    # Mark complete in loop state
    complete_current_task

    success "Task completed: $beads_id"

    # Continue to next task
    run_loop_cycle
}
