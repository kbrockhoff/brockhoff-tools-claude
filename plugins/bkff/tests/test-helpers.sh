#!/usr/bin/env bash
# test-helpers.sh - Test utilities for bkff plugin tests
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

# Source the common library
source "$LIB_DIR/common.sh"

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

# Run a test and show output on failure
# Usage: run_test_verbose "description" command
run_test_verbose() {
    local description="$1"
    shift
    local command="$*"
    local output
    local exit_code

    ((TESTS_RUN++))

    set +e
    output=$(eval "$command" 2>&1)
    exit_code=$?
    set -e

    if [[ $exit_code -eq 0 ]]; then
        ((TESTS_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_NC} $description"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${TEST_RED}✗${TEST_NC} $description"
        echo "  Output: $output"
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

# Assert that a file contains string
# Usage: assert_file_contains "/path/to/file" "needle"
assert_file_contains() {
    local file="$1"
    local needle="$2"
    grep -q "$needle" "$file"
}

# Assert JSON field equals value
# Usage: assert_json_equals '{"key":"val"}' '.key' 'val'
assert_json_equals() {
    local json="$1"
    local path="$2"
    local expected="$3"
    local actual
    actual=$(echo "$json" | jq -r "$path")
    [[ "$actual" == "$expected" ]]
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

# Create a test repo with beads initialized
# Returns the path to the repo
create_test_repo_with_beads() {
    local repo_dir
    repo_dir=$(create_test_repo)
    (
        cd "$repo_dir"
        mkdir -p .beads/issues
        echo '{"version":"1.0.0"}' > .beads/config.json
        git add .beads
        git commit -m "Initialize beads"
    ) &>/dev/null
    echo "$repo_dir"
}

# Create a test repo with specs directory
# Usage: create_test_repo_with_specs "001-feature-name"
create_test_repo_with_specs() {
    local feature_id="$1"
    local repo_dir
    repo_dir=$(create_test_repo)
    local specs_dir="$repo_dir/specs/$feature_id"
    mkdir -p "$specs_dir"
    echo "# Spec" > "$specs_dir/spec.md"
    (
        cd "$repo_dir"
        git add specs
        git commit -m "Add specs"
    ) &>/dev/null
    echo "$repo_dir"
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
