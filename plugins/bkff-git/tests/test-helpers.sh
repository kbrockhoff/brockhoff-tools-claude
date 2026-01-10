#!/usr/bin/env bash
# test-helpers.sh - Test utilities for bkff-git plugin tests
# Source this file in all test scripts

set -euo pipefail

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for test output
readonly TEST_GREEN='\033[0;32m'
readonly TEST_RED='\033[0;31m'
readonly TEST_YELLOW='\033[0;33m'
readonly TEST_NC='\033[0m'

# Get the directory containing this script
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$TEST_DIR")/lib"

# Source the library files
source "$LIB_DIR/common.sh"
source "$LIB_DIR/git-helpers.sh"
source "$LIB_DIR/validation.sh"

# =============================================================================
# Test Framework Functions
# =============================================================================

# Run a test with description
# Usage: run_test "description" command
run_test() {
    local description="$1"
    shift
    local command="$*"

    ((TESTS_RUN++))

    if eval "$command" &>/dev/null; then
        ((TESTS_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_NC} $description"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${TEST_RED}✗${TEST_NC} $description"
        return 1
    fi
}

# Assert that a command succeeds
# Usage: assert_success command
assert_success() {
    "$@"
}

# Assert that a command fails
# Usage: assert_failure command
assert_failure() {
    ! "$@"
}

# Assert that output equals expected
# Usage: assert_equals "expected" "actual"
assert_equals() {
    local expected="$1"
    local actual="$2"
    [[ "$expected" == "$actual" ]]
}

# Assert that output contains string
# Usage: assert_contains "haystack" "needle"
assert_contains() {
    local haystack="$1"
    local needle="$2"
    [[ "$haystack" == *"$needle"* ]]
}

# Assert that output matches regex
# Usage: assert_matches "string" "regex"
assert_matches() {
    local string="$1"
    local regex="$2"
    [[ "$string" =~ $regex ]]
}

# Assert that a variable is not empty
# Usage: assert_not_empty "$variable"
assert_not_empty() {
    local value="$1"
    [[ -n "$value" ]]
}

# Assert that a variable is empty
# Usage: assert_empty "$variable"
assert_empty() {
    local value="$1"
    [[ -z "$value" ]]
}

# Assert that a file exists
# Usage: assert_file_exists "/path/to/file"
assert_file_exists() {
    local file="$1"
    [[ -f "$file" ]]
}

# Assert that a directory exists
# Usage: assert_dir_exists "/path/to/dir"
assert_dir_exists() {
    local dir="$1"
    [[ -d "$dir" ]]
}

# =============================================================================
# Test Environment Setup/Teardown
# =============================================================================

# Temporary directory for test fixtures
TEST_TEMP_DIR=""

# Setup test environment
setup_test_env() {
    TEST_TEMP_DIR=$(mktemp -d)
    export TEST_TEMP_DIR
}

# Teardown test environment
teardown_test_env() {
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Create a temporary git repository for testing
# Returns the path to the repo
create_test_repo() {
    local repo_dir="$TEST_TEMP_DIR/test-repo"
    mkdir -p "$repo_dir"
    (
        cd "$repo_dir"
        git init --initial-branch=main
        git config user.email "test@example.com"
        git config user.name "Test User"
        echo "test" > README.md
        git add README.md
        git commit -m "Initial commit"
    ) &>/dev/null
    echo "$repo_dir"
}

# Create a bare repository with worktree structure
# Returns the path to the worktree
create_test_worktree() {
    local base_dir="$TEST_TEMP_DIR/worktree-test"
    local bare_dir="$base_dir/.bare"
    local worktree_dir="$base_dir/main"

    mkdir -p "$base_dir"

    # Create bare repo
    git clone --bare "$(create_test_repo)" "$bare_dir" &>/dev/null

    # Create main worktree
    (
        cd "$bare_dir"
        git worktree add "$worktree_dir" main
    ) &>/dev/null

    echo "$worktree_dir"
}

# =============================================================================
# Test Results Summary
# =============================================================================

# Print test summary and exit with appropriate code
print_test_summary() {
    echo ""
    echo "─────────────────────────────────────"
    echo "Test Results: $TESTS_PASSED/$TESTS_RUN passed"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${TEST_RED}$TESTS_FAILED test(s) failed${TEST_NC}"
        return 1
    else
        echo -e "${TEST_GREEN}All tests passed!${TEST_NC}"
        return 0
    fi
}

# Run all tests and print summary
# Usage: run_all_tests (after defining test functions)
run_all_tests() {
    setup_test_env
    trap teardown_test_env EXIT

    # Run all functions starting with "test_"
    for test_func in $(declare -F | awk '{print $3}' | grep '^test_'); do
        "$test_func"
    done

    print_test_summary
}
