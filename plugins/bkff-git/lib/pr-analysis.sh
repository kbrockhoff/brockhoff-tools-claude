#!/usr/bin/env bash
# pr-analysis.sh - PR comment analysis utilities for bkff-git plugin
# Source this file after common.sh and git-helpers.sh

# Ensure dependencies are sourced
if ! declare -F error_exit &>/dev/null; then
    echo "Error: common.sh must be sourced before pr-analysis.sh" >&2
    exit 1
fi

if ! declare -F get_current_branch &>/dev/null; then
    echo "Error: git-helpers.sh must be sourced before pr-analysis.sh" >&2
    exit 1
fi

# =============================================================================
# T075/FR-044: Spec File Detection
# =============================================================================

# Detect spec file for current branch
# Searches in order:
#   1. specs/<branch-name>/spec.md
#   2. specs/<issue-id>/spec.md (extracted from branch name)
#   3. Returns empty if not found
# Returns: path to spec file or empty string
detect_spec_file() {
    local branch="${1:-$(get_current_branch)}"
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)

    if [[ -z "$repo_root" ]]; then
        echo ""
        return
    fi

    # Try 1: specs/<branch-name>/spec.md
    local spec_by_branch="$repo_root/specs/$branch/spec.md"
    if [[ -f "$spec_by_branch" ]]; then
        echo "$spec_by_branch"
        return
    fi

    # Try 2: Extract issue ID from branch name and try specs/<issue-id>/spec.md
    # Common patterns: feature/123-description, bugfix/PROJ-456, feature/issue-789
    local issue_id=""

    # Pattern: prefix/NNN-description or prefix/NNN
    if [[ "$branch" =~ ^[^/]+/([0-9]+) ]]; then
        issue_id="${BASH_REMATCH[1]}"
    # Pattern: prefix/PROJ-NNN or prefix/issue-NNN
    elif [[ "$branch" =~ ^[^/]+/([A-Za-z]+-[0-9]+) ]]; then
        issue_id="${BASH_REMATCH[1]}"
    # Pattern: NNN-description at start of branch short name
    elif [[ "$branch" =~ /([0-9]+-[^/]+)$ ]]; then
        issue_id="${BASH_REMATCH[1]}"
    fi

    if [[ -n "$issue_id" ]]; then
        local spec_by_issue="$repo_root/specs/$issue_id/spec.md"
        if [[ -f "$spec_by_issue" ]]; then
            echo "$spec_by_issue"
            return
        fi
    fi

    # No spec file found
    echo ""
}

# Check if spec file exists for current branch
# Returns 0 if exists, 1 if not
has_spec_file() {
    local spec_file
    spec_file=$(detect_spec_file "$@")
    [[ -n "$spec_file" ]]
}

# =============================================================================
# T076: Requirements Extraction
# =============================================================================

# Extract FR-XXX requirements from a spec file
# Args: path to spec file
# Returns: newline-separated list of requirement IDs (e.g., FR-001, FR-002)
extract_requirements() {
    local spec_file="$1"

    if [[ ! -f "$spec_file" ]]; then
        echo ""
        return
    fi

    # Extract all FR-XXX patterns from the spec file
    grep -oE 'FR-[0-9]+' "$spec_file" 2>/dev/null | sort -u || echo ""
}

# Extract requirement description from spec file
# Args: spec_file, requirement_id (e.g., FR-001)
# Returns: requirement description or empty if not found
get_requirement_description() {
    local spec_file="$1"
    local req_id="$2"

    if [[ ! -f "$spec_file" ]]; then
        echo ""
        return
    fi

    # Look for lines containing the requirement ID and extract description
    # Common formats: "FR-001: Description" or "- FR-001 Description"
    grep -E "(^|[^A-Za-z0-9])$req_id[^0-9]" "$spec_file" 2>/dev/null | head -1 | sed "s/.*$req_id[^A-Za-z0-9]*//" | sed 's/^[: -]*//' || echo ""
}

# =============================================================================
# T080/FR-045: Security Principles Fallback
# =============================================================================

# General security principles for analysis when no spec file exists
# Based on OWASP Top 10 and common security best practices
readonly SECURITY_PRINCIPLES=(
    "Input validation and sanitization"
    "Output encoding to prevent XSS"
    "SQL injection prevention"
    "Authentication and session management"
    "Access control and authorization"
    "Sensitive data exposure prevention"
    "Security misconfiguration avoidance"
    "Cross-site request forgery (CSRF) protection"
    "Using components with known vulnerabilities"
    "Insufficient logging and monitoring"
    "Error handling without information leakage"
    "Secure defaults"
)

# Get security principles as newline-separated list
get_security_principles() {
    printf '%s\n' "${SECURITY_PRINCIPLES[@]}"
}

# Check if a comment relates to security principles
# Args: comment text
# Returns: matching principle or empty
matches_security_principle() {
    local comment="$1"
    local comment_lower
    comment_lower=$(echo "$comment" | tr '[:upper:]' '[:lower:]')

    # Keywords that suggest security-related comments
    local security_keywords=(
        "injection" "sanitize" "validate" "escape" "encode"
        "authentication" "authorization" "permission" "access control"
        "password" "credential" "secret" "token" "session"
        "xss" "csrf" "sql" "command injection"
        "sensitive" "encrypt" "hash" "secure"
        "vulnerability" "exploit" "attack"
        "input" "user input" "untrusted"
        "error handling" "exception" "logging"
    )

    for keyword in "${security_keywords[@]}"; do
        if [[ "$comment_lower" == *"$keyword"* ]]; then
            echo "Security-Related"
            return 0
        fi
    done

    echo ""
    return 1
}

# =============================================================================
# T079/FR-043: Stylistic/Preference Comment Detection
# =============================================================================

# Keywords that suggest stylistic/preference comments (not requirements-related)
readonly STYLISTIC_KEYWORDS=(
    "naming" "name" "rename" "variable name"
    "formatting" "format" "indent" "spacing" "whitespace"
    "style" "convention" "consistent"
    "prefer" "preference" "suggestion" "minor"
    "nitpick" "nit" "optional"
    "readability" "readable" "cleaner" "clearer"
    "descriptive" "self-documenting"
    "comment" "documentation" "docstring"
    "typo" "spelling" "grammar"
)

# Check if a comment is stylistic/preference-based
# Args: comment text
# Returns 0 if stylistic, 1 if not
is_stylistic_comment() {
    local comment="$1"
    local comment_lower
    comment_lower=$(echo "$comment" | tr '[:upper:]' '[:lower:]')

    for keyword in "${STYLISTIC_KEYWORDS[@]}"; do
        if [[ "$comment_lower" == *"$keyword"* ]]; then
            return 0
        fi
    done

    return 1
}

# =============================================================================
# Comment Categorization
# =============================================================================

# Categorize a comment
# Args: comment text, spec_file (optional)
# Returns: "Requirements-Related", "Security-Related", "Stylistic/Preference", or "General Feedback"
categorize_comment() {
    local comment="$1"
    local spec_file="${2:-}"

    # Check if it's a general approval/summary comment
    local comment_lower
    comment_lower=$(echo "$comment" | tr '[:upper:]' '[:lower:]')

    if [[ "$comment_lower" == *"lgtm"* ]] || \
       [[ "$comment_lower" == *"looks good"* ]] || \
       [[ "$comment_lower" == *"approved"* ]] || \
       [[ "$comment_lower" == *"ship it"* ]]; then
        echo "General Feedback"
        return
    fi

    # Check if stylistic
    if is_stylistic_comment "$comment"; then
        echo "Stylistic/Preference"
        return
    fi

    # Check if security-related
    local security_match
    security_match=$(matches_security_principle "$comment")
    if [[ -n "$security_match" ]]; then
        echo "Security-Related"
        return
    fi

    # Check against requirements if spec file provided
    if [[ -n "$spec_file" ]] && [[ -f "$spec_file" ]]; then
        # Extract keywords from requirements and check for matches
        local requirements
        requirements=$(extract_requirements "$spec_file")
        if [[ -n "$requirements" ]]; then
            echo "Requirements-Related"
            return
        fi
    fi

    # Default to requirements-related for substantive comments
    echo "Requirements-Related"
}

# =============================================================================
# Scoring Utilities
# =============================================================================

# Estimate compliance score based on category and content
# Args: comment text, category
# Returns: score 0-100
estimate_compliance_score() {
    local comment="$1"
    local category="$2"

    case "$category" in
        "Security-Related")
            # Security comments are high priority
            echo "90"
            ;;
        "Requirements-Related")
            # Requirements comments are high priority
            echo "85"
            ;;
        "Stylistic/Preference")
            # Stylistic comments are low priority
            echo "20"
            ;;
        "General Feedback")
            # General feedback doesn't have a score
            echo "N/A"
            ;;
        *)
            echo "50"
            ;;
    esac
}
