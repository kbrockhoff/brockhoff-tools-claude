#!/usr/bin/env bash
# tasks-parser.sh - Parse SpecKit tasks.md format
# Source this file for tasks.md parsing functionality

set -euo pipefail

# Get the directory containing this script
TASKS_PARSER_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TASKS_PARSER_LIB_DIR/common.sh"

# =============================================================================
# Task Parsing Functions
# =============================================================================

# Parse a tasks.md file and output JSON array of tasks
# Usage: parse_tasks_file "/path/to/tasks.md"
# Output: JSON array of task objects
parse_tasks_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        error_exit "Tasks file not found: $file"
    fi

    require_jq

    local tasks_json="[]"
    local current_phase=""
    local current_user_story=""
    local in_task_block=false
    local task_id=""
    local task_title=""
    local task_description=""
    local task_priority=2
    local task_parallel=false
    local task_depends_on="[]"

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Phase header: ## Phase N: Name
        if [[ "$line" =~ ^##[[:space:]]+Phase[[:space:]]+([0-9]+):[[:space:]]+(.+)$ ]]; then
            current_phase="Phase ${BASH_REMATCH[1]}: ${BASH_REMATCH[2]}"
            continue
        fi

        # User story header: ### USN - Name or ### User Story N
        if [[ "$line" =~ ^###[[:space:]]+US([0-9]+) ]] || [[ "$line" =~ ^###[[:space:]]+User[[:space:]]+Story[[:space:]]+([0-9]+) ]]; then
            current_user_story="US${BASH_REMATCH[1]}"
            continue
        fi

        # Task line: - [ ] **TXXX**: Description (Priority) [parallel]
        # Or: - [ ] TXXX: Description
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\[[[:space:]]*\][[:space:]]*\*?\*?([Tt][0-9]+)\*?\*?:?[[:space:]]*(.+)$ ]]; then
            # Save previous task if exists
            if [[ -n "$task_id" ]]; then
                local task_obj
                task_obj=$(jq -n \
                    --arg task_id "$task_id" \
                    --arg phase "$current_phase" \
                    --argjson parallel "$task_parallel" \
                    --arg user_story "$current_user_story" \
                    --arg title "$task_title" \
                    --arg description "$task_description" \
                    --argjson priority "$task_priority" \
                    --argjson depends_on "$task_depends_on" \
                    '{
                        task_id: $task_id,
                        phase: $phase,
                        parallel: $parallel,
                        user_story: $user_story,
                        title: $title,
                        description: $description,
                        priority: $priority,
                        depends_on: $depends_on,
                        beads_issue_id: null,
                        status: "pending"
                    }')
                tasks_json=$(echo "$tasks_json" | jq --argjson task "$task_obj" '. + [$task]')
            fi

            # Extract new task
            task_id=$(echo "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')
            local rest="${BASH_REMATCH[2]}"

            # Extract priority from (P0), (P1), etc.
            task_priority=2
            if [[ "$rest" =~ \(P([0-4])\) ]]; then
                task_priority="${BASH_REMATCH[1]}"
                rest="${rest//(P${BASH_REMATCH[1]})/}"
            fi

            # Check for [parallel] marker
            task_parallel=false
            if [[ "$rest" =~ \[parallel\] ]]; then
                task_parallel=true
                rest="${rest//\[parallel\]/}"
            fi

            # Clean up title
            task_title=$(echo "$rest" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            task_description=""
            task_depends_on="[]"

            in_task_block=true
            continue
        fi

        # Dependency line: Depends on: T001, T002 or depends_on: [T001, T002]
        if [[ $in_task_block == true ]] && [[ "$line" =~ [Dd]epends[[:space:]]*[oO]n:?[[:space:]]*(.+)$ ]]; then
            local deps_str="${BASH_REMATCH[1]}"
            # Extract task IDs (T followed by digits)
            local deps_array="[]"
            while [[ "$deps_str" =~ ([Tt][0-9]+) ]]; do
                local dep_id
                dep_id=$(echo "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')
                deps_array=$(echo "$deps_array" | jq --arg dep "$dep_id" '. + [$dep]')
                deps_str="${deps_str#*${BASH_REMATCH[1]}}"
            done
            task_depends_on="$deps_array"
            continue
        fi

        # Description continuation (indented lines after task)
        if [[ $in_task_block == true ]] && [[ "$line" =~ ^[[:space:]]{2,} ]] && [[ -n "$line" ]]; then
            local desc_line
            desc_line=$(echo "$line" | sed 's/^[[:space:]]*//')
            if [[ -n "$task_description" ]]; then
                task_description="$task_description $desc_line"
            else
                task_description="$desc_line"
            fi
            continue
        fi

        # Empty line or non-indented line ends task block
        if [[ $in_task_block == true ]] && [[ ! "$line" =~ ^[[:space:]]{2,} ]]; then
            in_task_block=false
        fi

    done < "$file"

    # Save last task
    if [[ -n "$task_id" ]]; then
        local task_obj
        task_obj=$(jq -n \
            --arg task_id "$task_id" \
            --arg phase "$current_phase" \
            --argjson parallel "$task_parallel" \
            --arg user_story "$current_user_story" \
            --arg title "$task_title" \
            --arg description "$task_description" \
            --argjson priority "$task_priority" \
            --argjson depends_on "$task_depends_on" \
            '{
                task_id: $task_id,
                phase: $phase,
                parallel: $parallel,
                user_story: $user_story,
                title: $title,
                description: $description,
                priority: $priority,
                depends_on: $depends_on,
                beads_issue_id: null,
                status: "pending"
            }')
        tasks_json=$(echo "$tasks_json" | jq --argjson task "$task_obj" '. + [$task]')
    fi

    echo "$tasks_json"
}

# Get task count from parsed tasks
# Usage: get_task_count "$tasks_json"
get_task_count() {
    local tasks_json="$1"
    echo "$tasks_json" | jq 'length'
}

# Get tasks by phase
# Usage: get_tasks_by_phase "$tasks_json" "Phase 1: Setup"
get_tasks_by_phase() {
    local tasks_json="$1"
    local phase="$2"
    echo "$tasks_json" | jq --arg phase "$phase" '[.[] | select(.phase == $phase)]'
}

# Get tasks by user story
# Usage: get_tasks_by_user_story "$tasks_json" "US1"
get_tasks_by_user_story() {
    local tasks_json="$1"
    local user_story="$2"
    echo "$tasks_json" | jq --arg us "$user_story" '[.[] | select(.user_story == $us)]'
}

# Get task by ID
# Usage: get_task_by_id "$tasks_json" "T001"
get_task_by_id() {
    local tasks_json="$1"
    local task_id="$2"
    echo "$tasks_json" | jq --arg id "$task_id" '.[] | select(.task_id == $id)'
}

# Get unique phases from tasks
# Usage: get_phases "$tasks_json"
get_phases() {
    local tasks_json="$1"
    echo "$tasks_json" | jq -r '[.[].phase] | unique | .[]'
}

# Get unique user stories from tasks
# Usage: get_user_stories "$tasks_json"
get_user_stories() {
    local tasks_json="$1"
    echo "$tasks_json" | jq -r '[.[].user_story] | unique | sort | .[]'
}

# =============================================================================
# Validation Functions
# =============================================================================

# Validate task dependencies exist
# Usage: validate_dependencies "$tasks_json"
# Returns: 0 if valid, 1 if invalid (with errors to stderr)
validate_dependencies() {
    local tasks_json="$1"
    local valid=true

    # Get all task IDs
    local task_ids
    task_ids=$(echo "$tasks_json" | jq -r '.[].task_id')

    # Check each task's dependencies
    while IFS= read -r task_id; do
        local deps
        deps=$(echo "$tasks_json" | jq -r --arg id "$task_id" '.[] | select(.task_id == $id) | .depends_on[]')
        while IFS= read -r dep; do
            if [[ -n "$dep" ]] && ! echo "$task_ids" | grep -q "^${dep}$"; then
                warn "Task $task_id depends on unknown task: $dep"
                valid=false
            fi
        done <<< "$deps"
    done <<< "$task_ids"

    $valid
}

# Check for circular dependencies
# Usage: check_circular_deps "$tasks_json"
# Returns: 0 if no cycles, 1 if cycles found
check_circular_deps() {
    local tasks_json="$1"

    # Simple cycle detection using visited tracking
    local task_ids
    task_ids=$(echo "$tasks_json" | jq -r '.[].task_id')

    while IFS= read -r start_id; do
        local visited=""
        local queue="$start_id"

        while [[ -n "$queue" ]]; do
            local current
            current=$(echo "$queue" | head -1)
            queue=$(echo "$queue" | tail -n +2)

            if echo "$visited" | grep -q "^${current}$"; then
                if [[ "$current" == "$start_id" ]]; then
                    warn "Circular dependency detected involving: $start_id"
                    return 1
                fi
                continue
            fi

            visited="$visited
$current"

            local deps
            deps=$(echo "$tasks_json" | jq -r --arg id "$current" '.[] | select(.task_id == $id) | .depends_on[]' 2>/dev/null || true)
            if [[ -n "$deps" ]]; then
                queue="$queue
$deps"
            fi
        done
    done <<< "$task_ids"

    return 0
}

# =============================================================================
# Human-Readable Output
# =============================================================================

# Print parsed tasks in human-readable format
# Usage: print_tasks "$tasks_json"
print_tasks() {
    local tasks_json="$1"

    local count
    count=$(get_task_count "$tasks_json")
    print_header "Parsed Tasks ($count total)"

    local current_phase=""
    echo "$tasks_json" | jq -r '.[] | "\(.phase)|\(.task_id)|\(.title)|\(.priority)|\(.depends_on | join(","))"' | while IFS='|' read -r phase task_id title priority deps; do
        if [[ "$phase" != "$current_phase" ]]; then
            current_phase="$phase"
            echo ""
            echo -e "${BOLD}$phase${NC}"
        fi

        local priority_color="$NC"
        case "$priority" in
            0) priority_color="$RED" ;;
            1) priority_color="$YELLOW" ;;
            2) priority_color="$NC" ;;
            3|4) priority_color="$BLUE" ;;
        esac

        printf "  %s ${priority_color}[P%s]${NC} %s" "$task_id" "$priority" "$title"
        if [[ -n "$deps" ]]; then
            echo -e " ${CYAN}(depends: $deps)${NC}"
        else
            echo ""
        fi
    done
}

# =============================================================================
# Beads Issue Conversion Functions
# =============================================================================

# Map task type to beads issue type
# Usage: get_issue_type "$phase"
get_issue_type() {
    local phase="$1"
    # Features/epics are typically in setup phases, tasks are in implementation
    if [[ "$phase" =~ [Ss]etup|[Ff]oundation ]]; then
        echo "task"
    else
        echo "task"
    fi
}

# Create a single beads issue from a task
# Usage: create_beads_issue "$task_json" "$parent_id"
# Returns: beads issue ID
create_beads_issue() {
    local task_json="$1"
    local parent_id="${2:-}"

    require_bd

    local task_id title description priority phase user_story
    task_id=$(echo "$task_json" | jq -r '.task_id')
    title=$(echo "$task_json" | jq -r '.title')
    description=$(echo "$task_json" | jq -r '.description // ""')
    priority=$(echo "$task_json" | jq -r '.priority')
    phase=$(echo "$task_json" | jq -r '.phase // ""')
    user_story=$(echo "$task_json" | jq -r '.user_story // ""')

    # Build full title with task ID
    local full_title="$task_id $title"

    # Build description with metadata
    local full_description="$description"
    if [[ -n "$phase" ]]; then
        full_description="Phase: $phase"$'\n'"$full_description"
    fi
    if [[ -n "$user_story" ]]; then
        full_description="User Story: $user_story"$'\n'"$full_description"
    fi

    # Create the issue
    local bd_args=(
        --title="$full_title"
        --type=task
        --priority="$priority"
    )

    if [[ -n "$full_description" ]]; then
        bd_args+=(--description="$full_description")
    fi

    if [[ -n "$parent_id" ]]; then
        bd_args+=(--parent="$parent_id")
    fi

    # Run bd create and capture the issue ID
    local output
    output=$(bd create "${bd_args[@]}" 2>&1)

    # Extract issue ID from output (format: "Created issue: beads-xxx")
    local issue_id
    issue_id=$(echo "$output" | grep -oE 'beads-[a-z0-9]+|tool-[a-z0-9.]+' | head -1)

    if [[ -z "$issue_id" ]]; then
        warn "Failed to create issue for $task_id: $output"
        echo ""
        return 1
    fi

    echo "$issue_id"
}

# Add dependency relationship between beads issues
# Usage: add_beads_dependency "$blocker_id" "$blocked_id"
add_beads_dependency() {
    local blocker_id="$1"
    local blocked_id="$2"

    require_bd

    # In beads: blocked_id depends on blocker_id
    # So blocker blocks blocked
    bd dep add "$blocked_id" "$blocker_id" &>/dev/null || {
        warn "Failed to add dependency: $blocked_id depends on $blocker_id"
        return 1
    }
}

# Convert all parsed tasks to beads issues
# Usage: convert_tasks_to_issues "$tasks_json" ["$parent_id"]
# Returns: JSON mapping of task_id -> beads_issue_id
convert_tasks_to_issues() {
    local tasks_json="$1"
    local parent_id="${2:-}"

    require_bd
    require_beads

    local task_count
    task_count=$(get_task_count "$tasks_json")

    if [[ "$task_count" -eq 0 ]]; then
        warn "No tasks to convert"
        echo "{}"
        return 0
    fi

    # Validate dependencies first
    if ! validate_dependencies "$tasks_json"; then
        error_exit "Invalid task dependencies detected"
    fi

    if ! check_circular_deps "$tasks_json"; then
        error_exit "Circular dependencies detected"
    fi

    print_header "Converting $task_count tasks to beads issues"

    # Mapping of task_id -> beads_issue_id
    local mapping="{}"
    local created=0
    local failed=0

    # First pass: create all issues
    while IFS= read -r task_id; do
        local task
        task=$(get_task_by_id "$tasks_json" "$task_id")

        local issue_id
        issue_id=$(create_beads_issue "$task" "$parent_id")

        if [[ -n "$issue_id" ]]; then
            mapping=$(echo "$mapping" | jq --arg tid "$task_id" --arg iid "$issue_id" '. + {($tid): $iid}')
            ((created++))
            echo -e "  ${GREEN}✓${NC} $task_id -> $issue_id"
        else
            ((failed++))
            echo -e "  ${RED}✗${NC} $task_id (failed to create)"
        fi
    done < <(echo "$tasks_json" | jq -r '.[].task_id')

    # Second pass: add dependencies
    print_header "Adding dependencies"
    local deps_added=0

    while IFS= read -r task_id; do
        local task
        task=$(get_task_by_id "$tasks_json" "$task_id")

        local blocked_issue_id
        blocked_issue_id=$(echo "$mapping" | jq -r --arg tid "$task_id" '.[$tid] // empty')

        if [[ -z "$blocked_issue_id" ]]; then
            continue
        fi

        # Get dependencies for this task
        local deps
        deps=$(echo "$task" | jq -r '.depends_on[]' 2>/dev/null || true)

        while IFS= read -r dep_task_id; do
            if [[ -z "$dep_task_id" ]]; then
                continue
            fi

            local blocker_issue_id
            blocker_issue_id=$(echo "$mapping" | jq -r --arg tid "$dep_task_id" '.[$tid] // empty')

            if [[ -n "$blocker_issue_id" ]]; then
                if add_beads_dependency "$blocker_issue_id" "$blocked_issue_id"; then
                    ((deps_added++))
                    echo -e "  ${GREEN}✓${NC} $blocked_issue_id depends on $blocker_issue_id"
                fi
            else
                warn "Dependency $dep_task_id not found in mapping for $task_id"
            fi
        done <<< "$deps"
    done < <(echo "$tasks_json" | jq -r '.[].task_id')

    print_divider
    echo "Created: $created issues"
    echo "Failed: $failed issues"
    echo "Dependencies: $deps_added added"

    echo "$mapping"
}

# Convert tasks from a file to beads issues
# Usage: convert_tasks_file_to_issues "/path/to/tasks.md" ["$parent_id"]
convert_tasks_file_to_issues() {
    local file="$1"
    local parent_id="${2:-}"

    local tasks_json
    tasks_json=$(parse_tasks_file "$file")

    convert_tasks_to_issues "$tasks_json" "$parent_id"
}
