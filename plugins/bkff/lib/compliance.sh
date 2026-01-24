#!/usr/bin/env bash
# compliance.sh - Compliance check definitions and utilities
# Source this file for compliance checking and fixing functionality

set -euo pipefail

# Get the directory containing this script
COMPLIANCE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$COMPLIANCE_LIB_DIR/common.sh"

# =============================================================================
# Compliance Check Definitions
# =============================================================================

# Each check is defined as: name|type|path|description|remediation
# Types: file, directory, content, command
COMPLIANCE_CHECKS=(
    "github-dir|directory|.github|GitHub configuration directory|Create .github directory"
    "github-codeowners|file|.github/CODEOWNERS|Code review ownership rules|Create CODEOWNERS with team ownership patterns"
    "github-contributing|file|.github/CONTRIBUTING.md|Contribution guidelines|Create CONTRIBUTING.md with project contribution standards"
    "github-dependabot|file|.github/dependabot.yml|Automated dependency updates|Create dependabot.yml with update configuration"
    "github-pr-template|file|.github/pull_request_template.md|PR template for consistency|Create pull_request_template.md"
    "github-issue-templates|directory|.github/ISSUE_TEMPLATE|Issue templates directory|Create ISSUE_TEMPLATE directory"
    "github-bug-template|file|.github/ISSUE_TEMPLATE/bug_report.md|Bug report template|Create bug_report.md template"
    "github-feature-template|file|.github/ISSUE_TEMPLATE/feature_request.md|Feature request template|Create feature_request.md template"
    "agents-md|file|AGENTS.md|Agent instructions file|Create AGENTS.md with project overview and tool instructions"
    "claude-md|content|CLAUDE.md|Claude instructions referencing AGENTS.md|Create/update CLAUDE.md to reference AGENTS.md"
    "copilot-instructions|content|.github/copilot-instructions.md|Copilot instructions referencing AGENTS.md|Create/update copilot-instructions.md to reference AGENTS.md"
    "beads-init|directory|.beads|Beads issue tracking|Initialize beads with 'bd init'"
    "beads-health|command|bd doctor|Beads health check|Run 'bd doctor --fix' to resolve issues"
)

# =============================================================================
# Check Execution Functions
# =============================================================================

# Run a single compliance check
# Usage: run_check "name|type|path|description|remediation"
# Returns: 0 if pass, 1 if fail
# Output: JSON object to stdout
run_check() {
    local check_def="$1"
    local root
    root=$(get_worktree_path)

    IFS='|' read -r name type path description remediation <<< "$check_def"

    local status="pass"
    local message=""

    case "$type" in
        file)
            if [[ ! -f "$root/$path" ]]; then
                status="fail"
                message="File missing: $path"
            elif [[ ! -s "$root/$path" ]]; then
                status="fail"
                message="File empty: $path"
            fi
            ;;
        directory)
            if [[ ! -d "$root/$path" ]]; then
                status="fail"
                message="Directory missing: $path"
            fi
            ;;
        content)
            if [[ ! -f "$root/$path" ]]; then
                status="fail"
                message="File missing: $path"
            elif ! grep -q "AGENTS.md" "$root/$path" 2>/dev/null; then
                status="fail"
                message="File does not reference AGENTS.md: $path"
            fi
            ;;
        command)
            # For bd doctor, we check if it reports issues
            if [[ "$path" == "bd doctor" ]]; then
                if ! has_beads; then
                    status="skip"
                    message="Beads not initialized"
                elif ! bd doctor &>/dev/null; then
                    status="fail"
                    message="Beads health check failed"
                fi
            fi
            ;;
    esac

    # Output JSON
    jq -n \
        --arg name "$name" \
        --arg path "$path" \
        --arg status "$status" \
        --arg message "$message" \
        --arg description "$description" \
        --arg remediation "$remediation" \
        '{name: $name, path: $path, status: $status, message: (if $message == "" then null else $message end), description: $description, remediation: $remediation}'

    [[ "$status" == "pass" ]]
}

# Run all compliance checks
# Output: JSON compliance report to stdout
run_all_checks() {
    local root
    root=$(get_worktree_path)
    local timestamp
    timestamp=$(get_timestamp)

    local checks_json="[]"
    local passed=0
    local failed=0
    local skipped=0
    local total=${#COMPLIANCE_CHECKS[@]}

    for check_def in "${COMPLIANCE_CHECKS[@]}"; do
        local check_result
        check_result=$(run_check "$check_def")
        checks_json=$(echo "$checks_json" | jq --argjson check "$check_result" '. + [$check]')

        local status
        status=$(echo "$check_result" | jq -r '.status')
        case "$status" in
            pass) ((passed++)) ;;
            fail) ((failed++)) ;;
            skip) ((skipped++)) ;;
        esac
    done

    local overall_status="pass"
    if [[ $failed -gt 0 ]]; then
        overall_status="fail"
    fi

    jq -n \
        --arg timestamp "$timestamp" \
        --arg repository "$root" \
        --arg overall_status "$overall_status" \
        --argjson checks_passed "$passed" \
        --argjson checks_failed "$failed" \
        --argjson checks_skipped "$skipped" \
        --argjson checks_total "$total" \
        --argjson checks "$checks_json" \
        '{
            timestamp: $timestamp,
            repository: $repository,
            overall_status: $overall_status,
            checks_passed: $checks_passed,
            checks_failed: $checks_failed,
            checks_skipped: $checks_skipped,
            checks_total: $checks_total,
            checks: $checks
        }'
}

# =============================================================================
# Human-Readable Output
# =============================================================================

# Print compliance report in human-readable format
# Usage: print_compliance_report < json_report
print_compliance_report() {
    local report
    report=$(cat)

    local overall_status
    overall_status=$(echo "$report" | jq -r '.overall_status')
    local passed
    passed=$(echo "$report" | jq -r '.checks_passed')
    local failed
    failed=$(echo "$report" | jq -r '.checks_failed')
    local total
    total=$(echo "$report" | jq -r '.checks_total')

    print_header "Compliance Report"

    # Print each check result
    echo "$report" | jq -r '.checks[] | "\(.status)|\(.name)|\(.description)|\(.message // "")"' | while IFS='|' read -r status name desc message; do
        case "$status" in
            pass)
                echo -e "  ${GREEN}✓${NC} $name"
                ;;
            fail)
                echo -e "  ${RED}✗${NC} $name"
                if [[ -n "$message" ]]; then
                    echo -e "    ${YELLOW}→${NC} $message"
                fi
                ;;
            skip)
                echo -e "  ${YELLOW}○${NC} $name (skipped)"
                if [[ -n "$message" ]]; then
                    echo -e "    ${YELLOW}→${NC} $message"
                fi
                ;;
        esac
    done

    print_divider

    if [[ "$overall_status" == "pass" ]]; then
        echo -e "${GREEN}All checks passed!${NC} ($passed/$total)"
    else
        echo -e "${RED}$failed check(s) failed${NC} ($passed passed, $failed failed)"
        echo ""
        echo "Run 'bkff:fixcompliance' to automatically fix issues"
    fi
}

# =============================================================================
# Fix Functions
# =============================================================================

# Create default CODEOWNERS file
create_codeowners() {
    local root
    root=$(get_worktree_path)
    local file="$root/.github/CODEOWNERS"

    mkdir -p "$(dirname "$file")"
    cat > "$file" << 'EOF'
# Default owners for everything in the repo
* @OWNER

# Specific path ownership examples:
# /docs/ @docs-team
# /src/api/ @api-team
EOF
    info "Created $file"
}

# Create default CONTRIBUTING.md
create_contributing() {
    local root
    root=$(get_worktree_path)
    local file="$root/.github/CONTRIBUTING.md"

    mkdir -p "$(dirname "$file")"
    cat > "$file" << 'EOF'
# Contributing Guidelines

Thank you for your interest in contributing!

## Getting Started

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Code Standards

- Follow existing code style
- Write tests for new functionality
- Update documentation as needed

## Pull Request Process

1. Ensure all tests pass
2. Update the README.md if needed
3. Request review from maintainers
EOF
    info "Created $file"
}

# Create default dependabot.yml
create_dependabot() {
    local root
    root=$(get_worktree_path)
    local file="$root/.github/dependabot.yml"

    mkdir -p "$(dirname "$file")"
    cat > "$file" << 'EOF'
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
EOF
    info "Created $file"
}

# Create default PR template
create_pr_template() {
    local root
    root=$(get_worktree_path)
    local file="$root/.github/pull_request_template.md"

    mkdir -p "$(dirname "$file")"
    cat > "$file" << 'EOF'
## Summary

Brief description of the changes.

## Test Plan

- [ ] Tests added/updated
- [ ] Manual testing completed

## Checklist

- [ ] Code follows project style
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
EOF
    info "Created $file"
}

# Create bug report template
create_bug_template() {
    local root
    root=$(get_worktree_path)
    local dir="$root/.github/ISSUE_TEMPLATE"
    local file="$dir/bug_report.md"

    mkdir -p "$dir"
    cat > "$file" << 'EOF'
---
name: Bug Report
about: Report a bug or unexpected behavior
title: '[BUG] '
labels: bug
assignees: ''
---

## Description

A clear description of the bug.

## Steps to Reproduce

1. Step one
2. Step two
3. ...

## Expected Behavior

What you expected to happen.

## Actual Behavior

What actually happened.

## Environment

- OS:
- Version:
EOF
    info "Created $file"
}

# Create feature request template
create_feature_template() {
    local root
    root=$(get_worktree_path)
    local dir="$root/.github/ISSUE_TEMPLATE"
    local file="$dir/feature_request.md"

    mkdir -p "$dir"
    cat > "$file" << 'EOF'
---
name: Feature Request
about: Suggest a new feature or enhancement
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Summary

Brief description of the feature.

## Use Case

Why is this feature needed? What problem does it solve?

## Proposed Solution

How should this feature work?

## Alternatives Considered

Any alternative solutions or features you've considered.
EOF
    info "Created $file"
}

# Create default AGENTS.md
create_agents_md() {
    local root
    root=$(get_worktree_path)
    local file="$root/AGENTS.md"

    cat > "$file" << 'EOF'
# Agent Instructions

This file provides instructions for AI coding agents working on this project.

## Project Overview

Describe your project here.

## Development Workflow

### Using bkff-git Skills

- `/git-st` - Check repository status
- `/git-branch` - Create feature branches
- `/git-commit` - Commit changes with conventional commits
- `/git-sync` - Sync with remote
- `/git-pr` - Create pull requests

### Using Beads Issue Tracking

- `bd ready` - Show issues ready to work on
- `bd show <id>` - View issue details
- `bd update <id> --status=in_progress` - Claim work
- `bd close <id>` - Complete work

## Code Standards

Document your project's coding standards here.
EOF
    info "Created $file"
}

# Create or update CLAUDE.md to reference AGENTS.md
fix_claude_md() {
    local root
    root=$(get_worktree_path)
    local file="$root/CLAUDE.md"
    local reference="Follow all instructions in AGENTS.md"

    if [[ ! -f "$file" ]]; then
        echo "$reference" > "$file"
        info "Created $file"
    elif ! grep -q "AGENTS.md" "$file"; then
        # Prepend the reference
        local content
        content=$(cat "$file")
        echo -e "$reference\n\n$content" > "$file"
        info "Updated $file to reference AGENTS.md"
    fi
}

# Create or update copilot-instructions.md
fix_copilot_instructions() {
    local root
    root=$(get_worktree_path)
    local file="$root/.github/copilot-instructions.md"
    local reference="Follow all instructions in AGENTS.md"

    mkdir -p "$(dirname "$file")"

    if [[ ! -f "$file" ]]; then
        echo "$reference" > "$file"
        info "Created $file"
    elif ! grep -q "AGENTS.md" "$file"; then
        local content
        content=$(cat "$file")
        echo -e "$reference\n\n$content" > "$file"
        info "Updated $file to reference AGENTS.md"
    fi
}

# Initialize beads if not present
fix_beads_init() {
    if ! has_beads; then
        info "Initializing beads..."
        bd init
        success "Beads initialized"
    fi
}

# Run bd doctor --fix
fix_beads_health() {
    if has_beads; then
        info "Running beads health check..."
        if ! bd doctor &>/dev/null; then
            bd doctor --fix || warn "Some beads issues could not be auto-fixed"
        fi
    fi
}

# Fix all compliance issues
fix_all() {
    local root
    root=$(get_worktree_path)

    print_header "Fixing Compliance Issues"

    # Create .github directory structure
    [[ ! -d "$root/.github" ]] && mkdir -p "$root/.github"
    [[ ! -d "$root/.github/ISSUE_TEMPLATE" ]] && mkdir -p "$root/.github/ISSUE_TEMPLATE"

    # Fix each type of issue
    [[ ! -f "$root/.github/CODEOWNERS" ]] && create_codeowners
    [[ ! -f "$root/.github/CONTRIBUTING.md" ]] && create_contributing
    [[ ! -f "$root/.github/dependabot.yml" ]] && create_dependabot
    [[ ! -f "$root/.github/pull_request_template.md" ]] && create_pr_template
    [[ ! -f "$root/.github/ISSUE_TEMPLATE/bug_report.md" ]] && create_bug_template
    [[ ! -f "$root/.github/ISSUE_TEMPLATE/feature_request.md" ]] && create_feature_template
    [[ ! -f "$root/AGENTS.md" ]] && create_agents_md

    fix_claude_md
    fix_copilot_instructions
    fix_beads_init
    fix_beads_health

    print_divider
    success "Compliance fixes applied"
    echo ""
    echo "Run 'bkff:chkcompliance' to verify all issues are resolved"
}
