#!/usr/bin/env bash
# test-common.sh - Tests for common.sh worktree detection and utilities
# Run with: bash tests/test-common.sh

set -euo pipefail

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test helpers
source "$SCRIPT_DIR/test-helpers.sh"

# =============================================================================
# T016: Test Worktree Detection
# =============================================================================

test_is_git_worktree_in_repo() {
    local repo_dir
    repo_dir=$(create_test_repo)

    run_test "is_git_worktree returns true in git repo" \
        "cd '$repo_dir' && is_git_worktree"
}

test_is_git_worktree_outside_repo() {
    run_test "is_git_worktree returns false outside git repo" \
        "cd /tmp && ! is_git_worktree"
}

test_get_worktree_path() {
    local repo_dir
    repo_dir=$(create_test_repo)

    local result
    result=$(cd "$repo_dir" && get_worktree_path)

    run_test "get_worktree_path returns correct path" \
        "assert_equals '$repo_dir' '$result'"
}

test_get_current_branch() {
    local repo_dir
    repo_dir=$(create_test_repo)

    local result
    result=$(cd "$repo_dir" && get_current_branch)

    run_test "get_current_branch returns 'main'" \
        "assert_equals 'main' '$result'"
}

test_is_detached_head_false() {
    local repo_dir
    repo_dir=$(create_test_repo)

    run_test "is_detached_head returns false on branch" \
        "cd '$repo_dir' && ! is_detached_head"
}

test_is_detached_head_true() {
    local repo_dir
    repo_dir=$(create_test_repo)

    # Create detached HEAD state
    (cd "$repo_dir" && git checkout --detach HEAD) &>/dev/null

    run_test "is_detached_head returns true when detached" \
        "cd '$repo_dir' && is_detached_head"
}

# =============================================================================
# Test Error Handling
# =============================================================================

test_error_exit_exits_with_code_1() {
    run_test "error_exit exits with code 1" \
        "! (error_exit 'test error' 2>/dev/null)"
}

test_warn_does_not_exit() {
    run_test "warn does not exit" \
        "(warn 'test warning' 2>/dev/null; true)"
}

# =============================================================================
# Test Output Formatting
# =============================================================================

test_print_header_outputs_title() {
    local output
    output=$(print_header "Test Header")

    run_test "print_header includes title" \
        "assert_contains '$output' 'Test Header'"
}

test_print_kv_formats_correctly() {
    local output
    output=$(print_kv "Key" "Value")

    run_test "print_kv includes key and value" \
        "assert_contains '$output' 'Key' && assert_contains '$output' 'Value'"
}

test_format_commit_hash_truncates() {
    local result
    result=$(format_commit_hash "abcdef1234567890")

    run_test "format_commit_hash returns 7 chars" \
        "assert_equals 'abcdef1' '$result'"
}

# =============================================================================
# Run Tests
# =============================================================================

run_all_tests
