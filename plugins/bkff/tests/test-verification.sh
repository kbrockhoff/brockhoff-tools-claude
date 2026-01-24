#!/usr/bin/env bash
# test-verification.sh - Tests for verification.sh library functions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/../lib/verification.sh"

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

create_makefile_with_validate() {
    cat > Makefile << 'EOF'
.PHONY: validate verify

validate:
	@echo "Running validation..."
	@exit 0

verify:
	@echo "Running verification..."
	@exit 0
EOF
}

create_makefile_with_failing_validate() {
    cat > Makefile << 'EOF'
.PHONY: validate

validate:
	@echo "lib/example.sh:42:10: error: SC2086: Double quote to prevent globbing"
	@exit 1
EOF
}

create_makefile_with_test_failure() {
    cat > Makefile << 'EOF'
.PHONY: validate

validate:
	@echo "Running tests..."
	@echo "FAIL: test_something_important"
	@exit 1
EOF
}

# =============================================================================
# Build Target Detection Tests
# =============================================================================

test_has_make_target_exists() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_makefile_with_validate

    local result
    result=$(has_make_target "validate" && echo "found" || echo "not-found")

    assert_equals "$result" "found" "Should find validate target"

    cleanup_test_repo "$test_dir"
}

test_has_make_target_missing() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_makefile_with_validate

    local result
    result=$(has_make_target "nonexistent" && echo "found" || echo "not-found")

    assert_equals "$result" "not-found" "Should not find nonexistent target"

    cleanup_test_repo "$test_dir"
}

test_has_validate_target() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_makefile_with_validate

    local result
    result=$(has_validate_target && echo "found" || echo "not-found")

    assert_equals "$result" "found" "Should find validate target"

    cleanup_test_repo "$test_dir"
}

test_has_verify_target() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_makefile_with_validate

    local result
    result=$(has_verify_target && echo "found" || echo "not-found")

    assert_equals "$result" "found" "Should find verify target"

    cleanup_test_repo "$test_dir"
}

test_no_makefile() {
    local test_dir
    test_dir=$(setup_test_repo)
    # Don't create Makefile

    local result
    result=$(has_validate_target && echo "found" || echo "not-found")

    assert_equals "$result" "not-found" "Should return not-found when no Makefile"

    cleanup_test_repo "$test_dir"
}

# =============================================================================
# Failure Object Tests
# =============================================================================

test_create_failure() {
    local failure
    failure=$(create_failure "lib/test.sh" "42" "quality" "error" "SC2086: Double quote" "Use quotes")

    local file
    file=$(echo "$failure" | jq -r '.file')
    local line
    line=$(echo "$failure" | jq -r '.line')
    local type
    type=$(echo "$failure" | jq -r '.type')

    assert_equals "$file" "lib/test.sh" "File should be correct"
    assert_equals "$line" "42" "Line should be correct"
    assert_equals "$type" "quality" "Type should be correct"
}

test_create_failure_null_line() {
    local failure
    failure=$(create_failure "tests/test.sh" "null" "test" "error" "Test failed" "")

    local line
    line=$(echo "$failure" | jq -r '.line')

    assert_equals "$line" "null" "Line should be null"
}

# =============================================================================
# Output Parsing Tests
# =============================================================================

test_parse_shellcheck_output() {
    local output="lib/example.sh:42:10: error: SC2086: Double quote to prevent globbing"

    local failures
    failures=$(parse_validation_output "$output")

    local count
    count=$(echo "$failures" | jq 'length')

    assert_equals "$count" "1" "Should parse one failure"

    local type
    type=$(echo "$failures" | jq -r '.[0].type')
    assert_equals "$type" "quality" "Should be quality type"
}

test_parse_test_failure_output() {
    local output="FAIL: test_important_function"

    local failures
    failures=$(parse_validation_output "$output")

    local count
    count=$(echo "$failures" | jq 'length')

    assert_equals "$count" "1" "Should parse one test failure"

    local type
    type=$(echo "$failures" | jq -r '.[0].type')
    assert_equals "$type" "test" "Should be test type"
}

test_parse_pytest_failure_output() {
    local output="FAILED tests/test_module.py::test_function"

    local failures
    failures=$(parse_validation_output "$output")

    local count
    count=$(echo "$failures" | jq 'length')

    assert_equals "$count" "1" "Should parse pytest failure"

    local file
    file=$(echo "$failures" | jq -r '.[0].file')
    assert_equals "$file" "tests/test_module.py" "Should extract test file"
}

test_parse_mixed_output() {
    local output="lib/test.sh:10:5: error: SC2086: Quote this
FAIL: test_something
error: General error message"

    local failures
    failures=$(parse_validation_output "$output")

    local count
    count=$(echo "$failures" | jq 'length')

    assert_equals "$count" "3" "Should parse all three failures"
}

# =============================================================================
# Verification Result Tests
# =============================================================================

test_create_verification_result_pass() {
    local failures="[]"

    local result
    result=$(create_verification_result "beads-123" "task" "validate" "pass" "$failures")

    local status
    status=$(echo "$result" | jq -r '.status')
    assert_equals "$status" "pass" "Status should be pass"

    local issue_id
    issue_id=$(echo "$result" | jq -r '.issue_id')
    assert_equals "$issue_id" "beads-123" "Issue ID should match"
}

test_create_verification_result_fail() {
    local failure
    failure=$(create_failure "test.sh" "10" "test" "error" "Test failed" "")
    local failures="[$failure]"

    local result
    result=$(create_verification_result "beads-456" "task" "validate" "fail" "$failures")

    local status
    status=$(echo "$result" | jq -r '.status')
    assert_equals "$status" "fail" "Status should be fail"

    local test_failed
    test_failed=$(echo "$result" | jq '.summary.tests.failed')
    assert_equals "$test_failed" "1" "Should have 1 test failure"
}

# =============================================================================
# Run Validate Tests
# =============================================================================

test_run_validate_success() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_makefile_with_validate

    local result
    result=$(run_validate "beads-test" "task" 2>/dev/null || echo "{}")

    local status
    status=$(echo "$result" | jq -r '.status')
    assert_equals "$status" "pass" "Should pass validation"

    cleanup_test_repo "$test_dir"
}

test_run_validate_failure() {
    local test_dir
    test_dir=$(setup_test_repo)
    create_makefile_with_failing_validate

    local result
    result=$(run_validate "beads-test" "task" 2>/dev/null || echo "{}")

    local status
    status=$(echo "$result" | jq -r '.status')
    assert_equals "$status" "fail" "Should fail validation"

    cleanup_test_repo "$test_dir"
}

# =============================================================================
# Print Result Tests
# =============================================================================

test_print_verification_result_pass() {
    local result
    result=$(create_verification_result "beads-123" "task" "validate" "pass" "[]")

    local output
    output=$(echo "$result" | print_verification_result 2>&1)

    assert_contains "$output" "Verification passed" "Should show passed message"
}

test_print_verification_result_fail() {
    local failure
    failure=$(create_failure "test.sh" "10" "test" "error" "Test failed" "")
    local failures="[$failure]"

    local result
    result=$(create_verification_result "beads-456" "task" "validate" "fail" "$failures")

    local output
    output=$(echo "$result" | print_verification_result 2>&1)

    assert_contains "$output" "Verification failed" "Should show failed message"
    assert_contains "$output" "Tests failed" "Should show failure summary"
}

# =============================================================================
# Run Tests
# =============================================================================

run_test_suite() {
    echo "Running verification.sh tests..."
    echo ""

    run_test "test_has_make_target_exists"
    run_test "test_has_make_target_missing"
    run_test "test_has_validate_target"
    run_test "test_has_verify_target"
    run_test "test_no_makefile"
    run_test "test_create_failure"
    run_test "test_create_failure_null_line"
    run_test "test_parse_shellcheck_output"
    run_test "test_parse_test_failure_output"
    run_test "test_parse_pytest_failure_output"
    run_test "test_parse_mixed_output"
    run_test "test_create_verification_result_pass"
    run_test "test_create_verification_result_fail"
    run_test "test_run_validate_success"
    run_test "test_run_validate_failure"
    run_test "test_print_verification_result_pass"
    run_test "test_print_verification_result_fail"

    print_test_summary
}

run_test_suite
