#!/usr/bin/env bash
# test-tasks-parser.sh - Tests for tasks-parser.sh library functions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/../lib/tasks-parser.sh"

# =============================================================================
# Test Setup
# =============================================================================

setup_test_repo() {
    local test_dir
    test_dir=$(mktemp -d)
    cd "$test_dir"
    git init --quiet
    echo "# Test Project" > README.md
    git add README.md
    git commit --quiet -m "Initial commit"
    echo "$test_dir"
}

cleanup_test_repo() {
    local test_dir="$1"
    rm -rf "$test_dir"
}

create_sample_tasks_file() {
    cat > tasks.md << 'EOF'
# Tasks

## Phase 1: Setup

### US1: Initialize Project

- [ ] T001: Create directory structure
- [ ] T002: Add configuration files (depends on: T001)
- [ ] T003: Set up CI/CD (depends on: T001, T002)

## Phase 2: Implementation

### US2: Core Features

- [ ] T004: Implement feature A (depends on: T003)
- [ ] T005: Implement feature B (depends on: T003)
- [ ] T006: Integration tests (depends on: T004, T005)
EOF
}

create_minimal_tasks_file() {
    cat > tasks.md << 'EOF'
# Tasks

- [ ] T001: Simple task
EOF
}

# =============================================================================
# Parse Tasks Tests
# =============================================================================

test_parse_empty_file() {
    local test_dir
    test_dir=$(setup_test_repo)
    echo "" > tasks.md

    local result
    result=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    assert_equals "$result" "[]" "Empty file should return empty array"

    cleanup_test_repo "$test_dir"
}

test_parse_minimal_tasks() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_minimal_tasks_file

    local result
    result=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    local count
    count=$(echo "$result" | jq 'length')

    assert_equals "$count" "1" "Should parse one task"

    cleanup_test_repo "$test_dir"
}

test_parse_tasks_with_phases() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_sample_tasks_file

    local result
    result=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    local count
    count=$(echo "$result" | jq 'length')

    assert_equals "$count" "6" "Should parse all 6 tasks"

    cleanup_test_repo "$test_dir"
}

test_parse_task_ids() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_sample_tasks_file

    local result
    result=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    local first_id
    first_id=$(echo "$result" | jq -r '.[0].id')

    assert_equals "$first_id" "T001" "First task should have ID T001"

    cleanup_test_repo "$test_dir"
}

test_parse_task_titles() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_sample_tasks_file

    local result
    result=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    local first_title
    first_title=$(echo "$result" | jq -r '.[0].title')

    assert_contains "$first_title" "Create directory structure" "Should extract task title"

    cleanup_test_repo "$test_dir"
}

test_parse_dependencies() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_sample_tasks_file

    local result
    result=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    # T002 depends on T001
    local t002_deps
    t002_deps=$(echo "$result" | jq -r '.[] | select(.id == "T002") | .depends_on | length')

    assert_equals "$t002_deps" "1" "T002 should have 1 dependency"

    # T003 depends on T001 and T002
    local t003_deps
    t003_deps=$(echo "$result" | jq -r '.[] | select(.id == "T003") | .depends_on | length')

    assert_equals "$t003_deps" "2" "T003 should have 2 dependencies"

    cleanup_test_repo "$test_dir"
}

# =============================================================================
# Helper Function Tests
# =============================================================================

test_get_task_count() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_sample_tasks_file

    local tasks
    tasks=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    local count
    count=$(get_task_count "$tasks")

    assert_equals "$count" "6" "Should count 6 tasks"

    cleanup_test_repo "$test_dir"
}

test_get_task_by_id() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_sample_tasks_file

    local tasks
    tasks=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    local task
    task=$(get_task_by_id "$tasks" "T003")

    local title
    title=$(echo "$task" | jq -r '.title')

    assert_contains "$title" "CI/CD" "Should find task T003"

    cleanup_test_repo "$test_dir"
}

test_get_phases() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_sample_tasks_file

    local tasks
    tasks=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    local phases
    phases=$(get_phases "$tasks")

    local count
    count=$(echo "$phases" | jq 'length')

    # Should have 2 phases
    assert_equals "$count" "2" "Should have 2 phases"

    cleanup_test_repo "$test_dir"
}

# =============================================================================
# Dependency Validation Tests
# =============================================================================

test_validate_dependencies_valid() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_sample_tasks_file

    local tasks
    tasks=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    local result
    result=$(validate_dependencies "$tasks" 2>&1 && echo "valid" || echo "invalid")

    assert_equals "$result" "valid" "Valid dependencies should pass"

    cleanup_test_repo "$test_dir"
}

test_validate_dependencies_missing() {
    local test_dir
    test_dir=$(setup_test_repo)

    cat > tasks.md << 'EOF'
# Tasks
- [ ] T001: Task one (depends on: T999)
EOF

    local tasks
    tasks=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    local result
    result=$(validate_dependencies "$tasks" 2>&1 || echo "invalid")

    assert_contains "$result" "invalid" "Missing dependency should fail"

    cleanup_test_repo "$test_dir"
}

# =============================================================================
# Circular Dependency Tests
# =============================================================================

test_check_circular_deps_none() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_sample_tasks_file

    local tasks
    tasks=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    local result
    result=$(check_circular_deps "$tasks" 2>&1 && echo "no-cycle" || echo "cycle")

    assert_equals "$result" "no-cycle" "Should detect no circular dependencies"

    cleanup_test_repo "$test_dir"
}

test_check_circular_deps_self() {
    local test_dir
    test_dir=$(setup_test_repo)

    cat > tasks.md << 'EOF'
# Tasks
- [ ] T001: Task one (depends on: T001)
EOF

    local tasks
    tasks=$(parse_tasks_file "tasks.md" 2>/dev/null || echo "[]")

    local result
    result=$(check_circular_deps "$tasks" 2>&1 || echo "cycle")

    assert_contains "$result" "cycle" "Self-dependency should be detected"

    cleanup_test_repo "$test_dir"
}

# =============================================================================
# Run Tests
# =============================================================================

run_test_suite() {
    echo "Running tasks-parser.sh tests..."
    echo ""

    run_test "test_parse_empty_file"
    run_test "test_parse_minimal_tasks"
    run_test "test_parse_tasks_with_phases"
    run_test "test_parse_task_ids"
    run_test "test_parse_task_titles"
    run_test "test_parse_dependencies"
    run_test "test_get_task_count"
    run_test "test_get_task_by_id"
    run_test "test_get_phases"
    run_test "test_validate_dependencies_valid"
    run_test "test_validate_dependencies_missing"
    run_test "test_check_circular_deps_none"
    run_test "test_check_circular_deps_self"

    print_test_summary
}

run_test_suite
