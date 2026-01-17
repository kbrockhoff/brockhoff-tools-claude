#!/usr/bin/env bash
# common.sh - Shared utility functions for bkff-git plugin
# Source this file in all skill scripts

set -euo pipefail

# =============================================================================
# T007: Worktree Detection
# =============================================================================

# Check if current directory is inside a git worktree
# Returns 0 if valid worktree, 1 otherwise
is_git_worktree() {
    git rev-parse --show-toplevel &>/dev/null
}

# Get the absolute path to the worktree root
# Exits with error if not in a worktree
get_worktree_path() {
    if ! is_git_worktree; then
        error_exit "Command must be run within a git worktree"
    fi
    git rev-parse --show-toplevel
}

# Get the path to the shared .bare directory
get_bare_path() {
    if ! is_git_worktree; then
        error_exit "Command must be run within a git worktree"
    fi
    git rev-parse --git-common-dir
}

# Get the current branch name
# Returns empty string if in detached HEAD state
get_current_branch() {
    git branch --show-current 2>/dev/null || echo ""
}

# Check if current HEAD is in detached state
is_detached_head() {
    [[ -z "$(get_current_branch)" ]]
}

# Validate worktree context - call at start of each command
# Exits with error if not in valid worktree or in detached HEAD
require_worktree() {
    if ! is_git_worktree; then
        error_exit "Command must be run within a git worktree"
    fi

    if is_detached_head; then
        error_exit "Cannot operate in detached HEAD state. Please checkout a branch."
    fi
}

# Check if this is the main worktree (not a linked worktree)
is_main_worktree() {
    local git_dir common_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null)
    common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    [[ "$git_dir" == "$common_dir" ]]
}

# =============================================================================
# T008: Error Handling Utilities
# =============================================================================

# Colors for output (disabled if not a terminal)
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly YELLOW='\033[0;33m'
    readonly GREEN='\033[0;32m'
    readonly BLUE='\033[0;34m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m' # No Color
else
    readonly RED=''
    readonly YELLOW=''
    readonly GREEN=''
    readonly BLUE=''
    readonly BOLD=''
    readonly NC=''
fi

# Print error message and exit with code 1
# Usage: error_exit "message"
error_exit() {
    local message="$1"
    echo -e "${RED}Error:${NC} $message" >&2
    exit 1
}

# Print warning message (does not exit)
# Usage: warn "message"
warn() {
    local message="$1"
    echo -e "${YELLOW}Warning:${NC} $message" >&2
}

# Print info message
# Usage: info "message"
info() {
    local message="$1"
    echo -e "${BLUE}Info:${NC} $message"
}

# Print success message
# Usage: success "message"
success() {
    local message="$1"
    echo -e "${GREEN}✓${NC} $message"
}

# =============================================================================
# T009: Output Formatting Functions
# =============================================================================

# Print a section header
# Usage: print_header "Section Title"
print_header() {
    local title="$1"
    echo -e "\n${BOLD}${title}${NC}"
    echo "─────────────────────────────────────"
}

# Print a key-value pair
# Usage: print_kv "Key" "Value"
print_kv() {
    local key="$1"
    local value="$2"
    printf "  %-16s %s\n" "${key}:" "$value"
}

# Print a list item
# Usage: print_item "item text"
print_item() {
    local item="$1"
    echo "  • $item"
}

# Print a numbered list item
# Usage: print_numbered 1 "item text"
print_numbered() {
    local num="$1"
    local item="$2"
    printf "  %2d. %s\n" "$num" "$item"
}

# Print file status with color
# Usage: print_file_status "M" "path/to/file"
print_file_status() {
    local status="$1"
    local file="$2"
    local color

    case "$status" in
        A|"??") color="$GREEN" ;;  # Added/Untracked
        M)      color="$YELLOW" ;; # Modified
        D)      color="$RED" ;;    # Deleted
        R)      color="$BLUE" ;;   # Renamed
        *)      color="$NC" ;;
    esac

    printf "  ${color}%s${NC}  %s\n" "$status" "$file"
}

# Print a horizontal divider
print_divider() {
    echo "─────────────────────────────────────"
}

# Print an empty line for spacing
print_spacer() {
    echo ""
}

# Format a commit hash (short form)
format_commit_hash() {
    local hash="$1"
    echo "${hash:0:7}"
}

# Format a date in relative form
# Usage: format_relative_date "2026-01-10T12:00:00"
format_relative_date() {
    local date="$1"
    git log -1 --format="%ar" --date=relative "$date" 2>/dev/null || echo "$date"
}
