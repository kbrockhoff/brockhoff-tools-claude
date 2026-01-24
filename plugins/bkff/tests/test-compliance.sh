#!/usr/bin/env bash
# test-compliance.sh - Tests for compliance.sh library functions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/../lib/compliance.sh"

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

# =============================================================================
# Compliance Check Tests
# =============================================================================

test_check_codeowners_missing() {
    local test_dir
    test_dir=$(setup_test_repo)

    local result
    result=$(check_codeowners 2>/dev/null || echo "failed")

    assert_contains "$result" "failed" "Should fail when CODEOWNERS missing"

    cleanup_test_repo "$test_dir"
}

test_check_codeowners_exists() {
    local test_dir
    test_dir=$(setup_test_repo)
    mkdir -p .github
    echo "* @owner" > .github/CODEOWNERS

    local result
    result=$(check_codeowners 2>/dev/null && echo "passed" || echo "failed")

    assert_equals "$result" "passed" "Should pass when CODEOWNERS exists"

    cleanup_test_repo "$test_dir"
}

test_check_contributing_missing() {
    local test_dir
    test_dir=$(setup_test_repo)

    local result
    result=$(check_contributing 2>/dev/null || echo "failed")

    assert_contains "$result" "failed" "Should fail when CONTRIBUTING.md missing"

    cleanup_test_repo "$test_dir"
}

test_check_contributing_exists() {
    local test_dir
    test_dir=$(setup_test_repo)
    echo "# Contributing" > CONTRIBUTING.md

    local result
    result=$(check_contributing 2>/dev/null && echo "passed" || echo "failed")

    assert_equals "$result" "passed" "Should pass when CONTRIBUTING.md exists"

    cleanup_test_repo "$test_dir"
}

test_check_pr_template_missing() {
    local test_dir
    test_dir=$(setup_test_repo)

    local result
    result=$(check_pr_template 2>/dev/null || echo "failed")

    assert_contains "$result" "failed" "Should fail when PR template missing"

    cleanup_test_repo "$test_dir"
}

test_check_pr_template_exists() {
    local test_dir
    test_dir=$(setup_test_repo)
    mkdir -p .github
    echo "## Description" > .github/pull_request_template.md

    local result
    result=$(check_pr_template 2>/dev/null && echo "passed" || echo "failed")

    assert_equals "$result" "passed" "Should pass when PR template exists"

    cleanup_test_repo "$test_dir"
}

# =============================================================================
# Compliance Fix Tests
# =============================================================================

test_create_codeowners() {
    local test_dir
    test_dir=$(setup_test_repo)

    create_codeowners

    assert_file_exists ".github/CODEOWNERS" "CODEOWNERS should be created"
    assert_file_contains ".github/CODEOWNERS" "* @" "Should have default owner"

    cleanup_test_repo "$test_dir"
}

test_create_contributing() {
    local test_dir
    test_dir=$(setup_test_repo)

    create_contributing

    assert_file_exists "CONTRIBUTING.md" "CONTRIBUTING.md should be created"
    assert_file_contains "CONTRIBUTING.md" "Contributing" "Should have header"

    cleanup_test_repo "$test_dir"
}

test_create_pr_template() {
    local test_dir
    test_dir=$(setup_test_repo)

    create_pr_template

    assert_file_exists ".github/pull_request_template.md" "PR template should be created"
    assert_file_contains ".github/pull_request_template.md" "Description" "Should have description section"

    cleanup_test_repo "$test_dir"
}

# =============================================================================
# Run All Checks Tests
# =============================================================================

test_run_all_checks_empty_repo() {
    local test_dir
    test_dir=$(setup_test_repo)

    local result
    result=$(run_all_checks 2>/dev/null || true)

    # Should return JSON with failures
    assert_contains "$result" "\"status\"" "Should return JSON result"

    cleanup_test_repo "$test_dir"
}

test_run_all_checks_compliant_repo() {
    local test_dir
    test_dir=$(setup_test_repo)

    # Create all required files
    mkdir -p .github/ISSUE_TEMPLATE
    echo "* @owner" > .github/CODEOWNERS
    echo "# Contributing" > CONTRIBUTING.md
    echo "version: 2" > .github/dependabot.yml
    echo "## Description" > .github/pull_request_template.md
    echo "---" > .github/ISSUE_TEMPLATE/bug_report.md
    echo "---" > .github/ISSUE_TEMPLATE/feature_request.md
    echo "# Agents" > AGENTS.md
    echo "# Claude" > CLAUDE.md
    echo "# Instructions" > .github/copilot-instructions.md
    mkdir -p .beads
    echo "{}" > .beads/config.json

    local result
    result=$(run_all_checks 2>/dev/null || true)

    # Should pass most checks
    assert_contains "$result" "\"status\"" "Should return JSON result"

    cleanup_test_repo "$test_dir"
}

# =============================================================================
# Fix All Tests
# =============================================================================

test_fix_all() {
    local test_dir
    test_dir=$(setup_test_repo)

    fix_all 2>/dev/null || true

    assert_file_exists ".github/CODEOWNERS" "Should create CODEOWNERS"
    assert_file_exists "CONTRIBUTING.md" "Should create CONTRIBUTING.md"
    assert_file_exists ".github/dependabot.yml" "Should create dependabot.yml"

    cleanup_test_repo "$test_dir"
}

# =============================================================================
# Run Tests
# =============================================================================

run_test_suite() {
    echo "Running compliance.sh tests..."
    echo ""

    run_test "test_check_codeowners_missing"
    run_test "test_check_codeowners_exists"
    run_test "test_check_contributing_missing"
    run_test "test_check_contributing_exists"
    run_test "test_check_pr_template_missing"
    run_test "test_check_pr_template_exists"
    run_test "test_create_codeowners"
    run_test "test_create_contributing"
    run_test "test_create_pr_template"
    run_test "test_run_all_checks_empty_repo"
    run_test "test_run_all_checks_compliant_repo"
    run_test "test_fix_all"

    print_test_summary
}

run_test_suite
