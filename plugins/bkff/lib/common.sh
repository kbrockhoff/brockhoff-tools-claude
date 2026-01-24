#!/usr/bin/env bash
# common.sh - Shared utility functions for bkff plugin
# Source this file in all skill scripts

set -euo pipefail

# =============================================================================
# Repository Detection
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
        error_exit "Command must be run within a git repository"
    fi
    git rev-parse --show-toplevel
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
        error_exit "Command must be run within a git repository"
    fi

    if is_detached_head; then
        error_exit "Cannot operate in detached HEAD state. Please checkout a branch."
    fi
}

# Check if beads is initialized in this repository
has_beads() {
    local root
    root=$(get_worktree_path)
    [[ -d "$root/.beads" ]]
}

# Require beads to be initialized
require_beads() {
    if ! has_beads; then
        error_exit "Beads not initialized. Run 'bd init' first."
    fi
}

# =============================================================================
# Error Handling Utilities
# =============================================================================

# Colors for output (disabled if not a terminal)
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly YELLOW='\033[0;33m'
    readonly GREEN='\033[0;32m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m' # No Color
else
    readonly RED=''
    readonly YELLOW=''
    readonly GREEN=''
    readonly BLUE=''
    readonly CYAN=''
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

# Print debug message (only if BKFF_DEBUG is set)
# Usage: debug "message"
debug() {
    if [[ "${BKFF_DEBUG:-}" == "1" ]]; then
        local message="$1"
        echo -e "${CYAN}Debug:${NC} $message" >&2
    fi
}

# =============================================================================
# Output Formatting Functions
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

# Print a horizontal divider
print_divider() {
    echo "─────────────────────────────────────"
}

# Print an empty line for spacing
print_spacer() {
    echo ""
}

# =============================================================================
# File Path Utilities
# =============================================================================

# Get the specs directory for a feature
# Usage: get_specs_dir "001-feature-name"
get_specs_dir() {
    local feature_id="$1"
    local root
    root=$(get_worktree_path)
    echo "$root/specs/$feature_id"
}

# Check if a spec exists
# Usage: spec_exists "001-feature-name"
spec_exists() {
    local feature_id="$1"
    local specs_dir
    specs_dir=$(get_specs_dir "$feature_id")
    [[ -f "$specs_dir/spec.md" ]]
}

# Check if tasks.md exists for a feature
# Usage: tasks_exist "001-feature-name"
tasks_exist() {
    local feature_id="$1"
    local specs_dir
    specs_dir=$(get_specs_dir "$feature_id")
    [[ -f "$specs_dir/tasks.md" ]]
}

# =============================================================================
# JSON Utilities (requires jq)
# =============================================================================

# Check if jq is available
require_jq() {
    if ! command -v jq &>/dev/null; then
        error_exit "jq is required but not installed. Install with: brew install jq"
    fi
}

# Safely extract JSON field
# Usage: json_get '{"key": "value"}' '.key'
json_get() {
    local json="$1"
    local path="$2"
    echo "$json" | jq -r "$path" 2>/dev/null || echo ""
}

# =============================================================================
# Command Availability Checks
# =============================================================================

# Check if gh CLI is available and authenticated
require_gh() {
    if ! command -v gh &>/dev/null; then
        error_exit "GitHub CLI (gh) is required but not installed"
    fi
    if ! gh auth status &>/dev/null; then
        error_exit "GitHub CLI is not authenticated. Run 'gh auth login'"
    fi
}

# Check if bd (beads) CLI is available
require_bd() {
    if ! command -v bd &>/dev/null; then
        error_exit "Beads CLI (bd) is required but not installed"
    fi
}
