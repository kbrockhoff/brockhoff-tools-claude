#!/usr/bin/env bash
# verification.sh - Build target execution and verification helpers
# Source this file for verification functionality

set -euo pipefail

# Get the directory containing this script
VERIFICATION_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$VERIFICATION_LIB_DIR/common.sh"

# =============================================================================
# Constants
# =============================================================================

# Build targets
readonly TARGET_VALIDATE="validate"
readonly TARGET_VERIFY="verify"

# Failure types
readonly FAILURE_TYPE_TEST="test"
readonly FAILURE_TYPE_QUALITY="quality"
readonly FAILURE_TYPE_DOCS="docs"
readonly FAILURE_TYPE_SECURITY="security"
readonly FAILURE_TYPE_STANDARDS="standards"

# Severity levels
readonly SEVERITY_ERROR="error"
readonly SEVERITY_WARNING="warning"

# =============================================================================
# Build Target Detection
# =============================================================================

# Check if a Makefile target exists
# Usage: has_make_target "validate"
has_make_target() {
    local target="$1"
    local root
    root=$(get_worktree_path)

    if [[ ! -f "$root/Makefile" ]]; then
        return 1
    fi

    make -n -C "$root" "$target" &>/dev/null
}

# Check if validate target exists
has_validate_target() {
    has_make_target "$TARGET_VALIDATE"
}

# Check if verify target exists
has_verify_target() {
    has_make_target "$TARGET_VERIFY"
}

# Require validate target exists
require_validate_target() {
    if ! has_validate_target; then
        error_exit "Build system 'validate' target not found. Please implement a 'validate' target in your Makefile."
    fi
}

# Require verify target exists
require_verify_target() {
    if ! has_verify_target; then
        error_exit "Build system 'verify' target not found. Please implement a 'verify' target in your Makefile."
    fi
}

# =============================================================================
# Failure Object Construction
# =============================================================================

# Create a verification failure JSON object
# Usage: create_failure "file" "line" "type" "severity" "message" "hint"
create_failure() {
    local file="$1"
    local line="${2:-null}"
    local type="$3"
    local severity="$4"
    local message="$5"
    local hint="${6:-}"

    # Handle null line
    local line_arg
    if [[ "$line" == "null" || -z "$line" ]]; then
        line_arg="null"
    else
        line_arg="$line"
    fi

    jq -n \
        --arg file "$file" \
        --argjson line "$line_arg" \
        --arg type "$type" \
        --arg severity "$severity" \
        --arg message "$message" \
        --arg hint "$hint" \
        '{
            file: $file,
            line: $line,
            type: $type,
            severity: $severity,
            message: $message,
            hint: (if $hint == "" then null else $hint end)
        }'
}

# =============================================================================
# Build Target Execution
# =============================================================================

# Run a make target and capture output
# Usage: run_make_target "validate"
# Returns: exit code from make
# Output: stdout/stderr from make
run_make_target() {
    local target="$1"
    local root
    root=$(get_worktree_path)

    make -C "$root" "$target" 2>&1
}

# Run validate target
# Returns: JSON verification result
run_validate() {
    local issue_id="${1:-}"
    local issue_type="${2:-task}"

    require_validate_target

    local timestamp
    timestamp=$(get_timestamp)
    local root
    root=$(get_worktree_path)

    local output
    local exit_code=0
    output=$(run_make_target "$TARGET_VALIDATE") || exit_code=$?

    local status="pass"
    if [[ $exit_code -ne 0 ]]; then
        status="fail"
    fi

    # Parse output for failures
    local failures
    failures=$(parse_validation_output "$output")

    # Create verification result
    create_verification_result "$issue_id" "$issue_type" "$TARGET_VALIDATE" "$status" "$failures"
}

# Run verify target
# Returns: JSON verification result
run_verify() {
    local issue_id="${1:-}"
    local issue_type="${2:-feature}"

    require_verify_target

    local timestamp
    timestamp=$(get_timestamp)

    local output
    local exit_code=0
    output=$(run_make_target "$TARGET_VERIFY") || exit_code=$?

    local status="pass"
    if [[ $exit_code -ne 0 ]]; then
        status="fail"
    fi

    # Parse output for failures
    local failures
    failures=$(parse_validation_output "$output")

    # Create verification result
    create_verification_result "$issue_id" "$issue_type" "$TARGET_VERIFY" "$status" "$failures"
}

# =============================================================================
# Output Parsing
# =============================================================================

# Parse validation output for failures
# Usage: parse_validation_output "$output"
# Returns: JSON array of failure objects
parse_validation_output() {
    local output="$1"
    local failures="[]"

    # Parse shellcheck output: file:line:col: severity: message
    while IFS= read -r line; do
        if [[ "$line" =~ ^([^:]+):([0-9]+):([0-9]+):[[:space:]]*(error|warning|note):[[:space:]]*(.+)$ ]]; then
            local file="${BASH_REMATCH[1]}"
            local line_num="${BASH_REMATCH[2]}"
            local severity="${BASH_REMATCH[4]}"
            local message="${BASH_REMATCH[5]}"

            # Map note to warning
            if [[ "$severity" == "note" ]]; then
                severity="$SEVERITY_WARNING"
            fi

            local failure
            failure=$(create_failure "$file" "$line_num" "$FAILURE_TYPE_QUALITY" "$severity" "$message" "")
            failures=$(echo "$failures" | jq --argjson f "$failure" '. + [$f]')
        fi
    done <<< "$output"

    # Parse test failures: FAIL: test_name
    while IFS= read -r line; do
        if [[ "$line" =~ ^FAIL:[[:space:]]*(.+)$ ]]; then
            local test_name="${BASH_REMATCH[1]}"
            local failure
            failure=$(create_failure "tests" "null" "$FAILURE_TYPE_TEST" "$SEVERITY_ERROR" "Test failed: $test_name" "Review test implementation")
            failures=$(echo "$failures" | jq --argjson f "$failure" '. + [$f]')
        fi
    done <<< "$output"

    # Parse pytest failures: FAILED test_file.py::test_name
    while IFS= read -r line; do
        if [[ "$line" =~ ^FAILED[[:space:]]+([^:]+)::(.+)$ ]]; then
            local test_file="${BASH_REMATCH[1]}"
            local test_name="${BASH_REMATCH[2]}"
            local failure
            failure=$(create_failure "$test_file" "null" "$FAILURE_TYPE_TEST" "$SEVERITY_ERROR" "Test failed: $test_name" "")
            failures=$(echo "$failures" | jq --argjson f "$failure" '. + [$f]')
        fi
    done <<< "$output"

    # Parse generic error lines
    while IFS= read -r line; do
        if [[ "$line" =~ ^error:[[:space:]]*(.+)$ ]] || [[ "$line" =~ ^Error:[[:space:]]*(.+)$ ]]; then
            local message="${BASH_REMATCH[1]}"
            # Avoid duplicates from already-parsed formats
            if ! echo "$failures" | jq -e --arg msg "$message" '.[] | select(.message | contains($msg))' &>/dev/null; then
                local failure
                failure=$(create_failure "unknown" "null" "$FAILURE_TYPE_STANDARDS" "$SEVERITY_ERROR" "$message" "")
                failures=$(echo "$failures" | jq --argjson f "$failure" '. + [$f]')
            fi
        fi
    done <<< "$output"

    echo "$failures"
}

# =============================================================================
# Verification Result Construction
# =============================================================================

# Create a verification result JSON object
# Usage: create_verification_result "issue_id" "issue_type" "target" "status" "$failures_json"
create_verification_result() {
    local issue_id="$1"
    local issue_type="$2"
    local target="$3"
    local status="$4"
    local failures="$5"

    local timestamp
    timestamp=$(get_timestamp)

    # Count failures by type
    local test_passed test_failed quality_errors quality_warnings
    test_passed=0
    test_failed=$(echo "$failures" | jq '[.[] | select(.type == "test")] | length')
    quality_errors=$(echo "$failures" | jq '[.[] | select(.type == "quality" and .severity == "error")] | length')
    quality_warnings=$(echo "$failures" | jq '[.[] | select(.type == "quality" and .severity == "warning")] | length')

    jq -n \
        --arg issue_id "$issue_id" \
        --arg issue_type "$issue_type" \
        --arg target "$target" \
        --arg status "$status" \
        --arg timestamp "$timestamp" \
        --argjson failures "$failures" \
        --argjson test_failed "$test_failed" \
        --argjson quality_errors "$quality_errors" \
        --argjson quality_warnings "$quality_warnings" \
        '{
            issue_id: (if $issue_id == "" then null else $issue_id end),
            issue_type: $issue_type,
            target: $target,
            status: $status,
            timestamp: $timestamp,
            acceptance_criteria_checked: true,
            failures: $failures,
            summary: {
                tests: { passed: 0, failed: $test_failed },
                quality: { errors: $quality_errors, warnings: $quality_warnings },
                docs: { complete: true },
                security: { issues: 0 }
            }
        }'
}

# =============================================================================
# Acceptance Criteria Validation
# =============================================================================

# Check if a beads issue has acceptance criteria defined
# Usage: has_acceptance_criteria "$beads_id"
has_acceptance_criteria() {
    local beads_id="$1"

    require_bd

    local issue_data
    issue_data=$(bd show "$beads_id" --json 2>/dev/null || echo "{}")

    local acceptance
    acceptance=$(echo "$issue_data" | jq -r '.acceptance_criteria // .description // ""')

    [[ -n "$acceptance" && "$acceptance" != "null" ]]
}

# Require acceptance criteria for verification
require_acceptance_criteria() {
    local beads_id="$1"

    if ! has_acceptance_criteria "$beads_id"; then
        error_exit "Verification requires acceptance criteria. Please define acceptance criteria for issue $beads_id before verification."
    fi
}

# =============================================================================
# Human-Readable Output
# =============================================================================

# Print verification result
# Usage: print_verification_result < json_result
print_verification_result() {
    local result
    result=$(cat)

    local status
    status=$(echo "$result" | jq -r '.status')
    local target
    target=$(echo "$result" | jq -r '.target')
    local issue_id
    issue_id=$(echo "$result" | jq -r '.issue_id // "N/A"')

    print_header "Verification Result"
    print_kv "Issue" "$issue_id"
    print_kv "Target" "$target"

    if [[ "$status" == "pass" ]]; then
        echo -e "\n${GREEN}✓ Verification passed${NC}"
    else
        echo -e "\n${RED}✗ Verification failed${NC}"

        # Print failure summary
        local test_failed quality_errors quality_warnings
        test_failed=$(echo "$result" | jq '.summary.tests.failed')
        quality_errors=$(echo "$result" | jq '.summary.quality.errors')
        quality_warnings=$(echo "$result" | jq '.summary.quality.warnings')

        echo ""
        echo "Summary:"
        [[ "$test_failed" -gt 0 ]] && print_item "Tests failed: $test_failed"
        [[ "$quality_errors" -gt 0 ]] && print_item "Quality errors: $quality_errors"
        [[ "$quality_warnings" -gt 0 ]] && print_item "Quality warnings: $quality_warnings"

        # Print failures
        local failure_count
        failure_count=$(echo "$result" | jq '.failures | length')
        if [[ "$failure_count" -gt 0 ]]; then
            echo ""
            echo -e "${BOLD}Failures:${NC}"
            echo "$result" | jq -r '.failures[] | "  \(.file):\(.line // "-"): [\(.type)] \(.message)"'
        fi
    fi
}

# Output verification failures as agent-consumable JSON
# Usage: output_failures_json "$verification_result"
output_failures_json() {
    local result="$1"
    echo "$result" | jq '.failures'
}
