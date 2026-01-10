#!/usr/bin/env bash
# git-helpers.sh - Git-specific helper functions for bkff-git plugin
# Source this file after common.sh

# Ensure common.sh is sourced
if ! declare -F error_exit &>/dev/null; then
    echo "Error: common.sh must be sourced before git-helpers.sh" >&2
    exit 1
fi

# =============================================================================
# T010: Branch Status Detection
# =============================================================================

# Check if current branch has been pushed to origin
# Returns 0 if pushed, 1 if not
is_branch_pushed() {
    local branch="${1:-$(get_current_branch)}"
    git rev-parse --verify "origin/$branch" &>/dev/null
}

# Get number of commits ahead of origin
# Returns 0 if not pushed or at same commit
get_ahead_count() {
    local branch="${1:-$(get_current_branch)}"
    if is_branch_pushed "$branch"; then
        git rev-list --count "origin/$branch..HEAD" 2>/dev/null || echo "0"
    else
        # Count all commits since branching from main
        git rev-list --count "$(get_main_branch)..HEAD" 2>/dev/null || echo "0"
    fi
}

# Get number of commits behind origin
# Returns 0 if not pushed or at same commit
get_behind_count() {
    local branch="${1:-$(get_current_branch)}"
    if is_branch_pushed "$branch"; then
        git rev-list --count "HEAD..origin/$branch" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Get branch status as human-readable string
# Returns: "up to date", "ahead by N", "behind by N", "diverged", or "not pushed"
get_branch_status() {
    local branch="${1:-$(get_current_branch)}"

    if ! is_branch_pushed "$branch"; then
        echo "not pushed"
        return
    fi

    local ahead behind
    ahead=$(get_ahead_count "$branch")
    behind=$(get_behind_count "$branch")

    if [[ "$ahead" -eq 0 && "$behind" -eq 0 ]]; then
        echo "up to date"
    elif [[ "$ahead" -gt 0 && "$behind" -eq 0 ]]; then
        echo "ahead by $ahead"
    elif [[ "$ahead" -eq 0 && "$behind" -gt 0 ]]; then
        echo "behind by $behind"
    else
        echo "diverged (+$ahead/-$behind)"
    fi
}

# Get the main branch name (main or master)
get_main_branch() {
    if git rev-parse --verify main &>/dev/null; then
        echo "main"
    elif git rev-parse --verify master &>/dev/null; then
        echo "master"
    else
        error_exit "Could not determine main branch (neither 'main' nor 'master' exists)"
    fi
}

# =============================================================================
# T011: Branch Name Parsing
# =============================================================================

# Valid branch prefixes
readonly BRANCH_PREFIXES=("feature" "bugfix" "hotfix")

# Extract prefix from branch name
# Returns: "feature", "bugfix", "hotfix", or empty if no valid prefix
get_branch_prefix() {
    local branch="${1:-$(get_current_branch)}"

    for prefix in "${BRANCH_PREFIXES[@]}"; do
        if [[ "$branch" == "$prefix/"* ]]; then
            echo "$prefix"
            return
        fi
    done
    echo ""
}

# Extract short name (without prefix) from branch name
# Returns the part after the prefix, or full name if no prefix
get_branch_short_name() {
    local branch="${1:-$(get_current_branch)}"
    local prefix
    prefix=$(get_branch_prefix "$branch")

    if [[ -n "$prefix" ]]; then
        echo "${branch#$prefix/}"
    else
        echo "$branch"
    fi
}

# Check if branch name follows naming convention
# Returns 0 if valid, 1 if not
is_valid_branch_name() {
    local branch="${1:-$(get_current_branch)}"
    local prefix
    prefix=$(get_branch_prefix "$branch")

    # Must have a valid prefix
    [[ -n "$prefix" ]]
}

# Get branch prefix for a beads issue type
# Args: issue_type, priority (optional, default 2)
get_prefix_for_issue_type() {
    local issue_type="$1"
    local priority="${2:-2}"

    case "$issue_type" in
        feature|task|epic|chore)
            echo "feature"
            ;;
        bug)
            if [[ "$priority" -le 1 ]]; then
                echo "hotfix"
            else
                echo "bugfix"
            fi
            ;;
        *)
            echo "feature"
            ;;
    esac
}

# =============================================================================
# T012: Git Status Parsing Helpers
# =============================================================================

# Get list of staged files
# Format: status<tab>filename per line
get_staged_files() {
    git diff --cached --name-status 2>/dev/null || true
}

# Get list of unstaged (modified) files
# Format: status<tab>filename per line
get_unstaged_files() {
    git diff --name-status 2>/dev/null || true
}

# Get list of untracked files
# One filename per line
get_untracked_files() {
    git ls-files --others --exclude-standard 2>/dev/null || true
}

# Check if working directory has any changes
has_changes() {
    ! git diff --quiet 2>/dev/null || \
    ! git diff --cached --quiet 2>/dev/null || \
    [[ -n "$(get_untracked_files)" ]]
}

# Check if there are staged changes
has_staged_changes() {
    ! git diff --cached --quiet 2>/dev/null
}

# Check if there are unstaged changes
has_unstaged_changes() {
    ! git diff --quiet 2>/dev/null
}

# Get last commit info as JSON-like format
# Returns: hash, subject, author, date
get_last_commit_info() {
    git log -1 --format='hash:%h|subject:%s|author:%an|date:%ar' 2>/dev/null || echo ""
}

# Get last commit hash (short)
get_last_commit_hash() {
    git rev-parse --short HEAD 2>/dev/null || echo ""
}

# Get last commit subject line
get_last_commit_subject() {
    git log -1 --format='%s' 2>/dev/null || echo ""
}

# Get last commit author
get_last_commit_author() {
    git log -1 --format='%an' 2>/dev/null || echo ""
}

# Get last commit relative date
get_last_commit_date() {
    git log -1 --format='%ar' 2>/dev/null || echo ""
}

# Count files by status
# Usage: count_files_by_status "M" (for modified)
count_files_by_status() {
    local status="$1"
    git status --porcelain 2>/dev/null | grep -c "^$status" || echo "0"
}

# Get total count of changed files (staged + unstaged + untracked)
get_total_changes_count() {
    git status --porcelain 2>/dev/null | wc -l | tr -d ' '
}

# Parse git status porcelain output into readable format
# Outputs: type (staged/unstaged/untracked), status, filename
parse_git_status() {
    git status --porcelain 2>/dev/null | while IFS= read -r line; do
        local index_status="${line:0:1}"
        local worktree_status="${line:1:1}"
        local filename="${line:3}"

        if [[ "$index_status" != " " && "$index_status" != "?" ]]; then
            echo "staged|$index_status|$filename"
        fi
        if [[ "$worktree_status" != " " && "$worktree_status" != "?" ]]; then
            echo "unstaged|$worktree_status|$filename"
        fi
        if [[ "$index_status" == "?" ]]; then
            echo "untracked|?|$filename"
        fi
    done
}
