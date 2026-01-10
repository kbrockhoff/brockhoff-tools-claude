#!/usr/bin/env bash
# validation.sh - Pre-commit validation helpers for bkff-git plugin
# Source this file after common.sh

# Ensure common.sh is sourced
if ! declare -F error_exit &>/dev/null; then
    echo "Error: common.sh must be sourced before validation.sh" >&2
    exit 1
fi

# =============================================================================
# T013: Build Tool Validation Runner
# =============================================================================

# Detect the build tool in use
# Returns: make, npm, cargo, gradle, maven, or empty
detect_build_tool() {
    local worktree_path
    worktree_path=$(get_worktree_path)

    if [[ -f "$worktree_path/Makefile" ]]; then
        echo "make"
    elif [[ -f "$worktree_path/package.json" ]]; then
        echo "npm"
    elif [[ -f "$worktree_path/Cargo.toml" ]]; then
        echo "cargo"
    elif [[ -f "$worktree_path/build.gradle" || -f "$worktree_path/build.gradle.kts" ]]; then
        echo "gradle"
    elif [[ -f "$worktree_path/pom.xml" ]]; then
        echo "maven"
    else
        echo ""
    fi
}

# Check if build tool has a validate/lint target
# Returns 0 if found, 1 if not
has_validate_target() {
    local build_tool
    build_tool=$(detect_build_tool)

    case "$build_tool" in
        make)
            # Check if Makefile has lint or validate target
            grep -qE '^(lint|validate|check):' "$(get_worktree_path)/Makefile" 2>/dev/null
            ;;
        npm)
            # Check package.json for lint script
            local pkg_json="$(get_worktree_path)/package.json"
            if [[ -f "$pkg_json" ]]; then
                grep -q '"lint"' "$pkg_json" 2>/dev/null || \
                grep -q '"validate"' "$pkg_json" 2>/dev/null
            else
                return 1
            fi
            ;;
        cargo)
            # Cargo always has clippy/check
            return 0
            ;;
        gradle)
            # Gradle typically has check task
            return 0
            ;;
        maven)
            # Maven has validate phase
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Run the validation target for the detected build tool
# Returns 0 on success, 1 on failure
# Outputs validation results to stdout/stderr
run_validation() {
    local build_tool
    build_tool=$(detect_build_tool)
    local worktree_path
    worktree_path=$(get_worktree_path)

    if [[ -z "$build_tool" ]]; then
        warn "No build tool detected, skipping validation"
        return 0
    fi

    info "Running validation with $build_tool..."

    case "$build_tool" in
        make)
            if grep -qE '^lint:' "$worktree_path/Makefile" 2>/dev/null; then
                (cd "$worktree_path" && make lint)
            elif grep -qE '^validate:' "$worktree_path/Makefile" 2>/dev/null; then
                (cd "$worktree_path" && make validate)
            elif grep -qE '^check:' "$worktree_path/Makefile" 2>/dev/null; then
                (cd "$worktree_path" && make check)
            else
                warn "No lint/validate/check target found in Makefile"
                return 0
            fi
            ;;
        npm)
            if grep -q '"lint"' "$worktree_path/package.json" 2>/dev/null; then
                (cd "$worktree_path" && npm run lint)
            elif grep -q '"validate"' "$worktree_path/package.json" 2>/dev/null; then
                (cd "$worktree_path" && npm run validate)
            else
                warn "No lint/validate script found in package.json"
                return 0
            fi
            ;;
        cargo)
            (cd "$worktree_path" && cargo clippy -- -D warnings 2>/dev/null || cargo check)
            ;;
        gradle)
            (cd "$worktree_path" && ./gradlew check 2>/dev/null || gradle check)
            ;;
        maven)
            (cd "$worktree_path" && mvn validate)
            ;;
        *)
            warn "Unknown build tool: $build_tool"
            return 0
            ;;
    esac
}

# =============================================================================
# T014: GPG Signing Availability Check
# =============================================================================

# Check if GPG is installed
is_gpg_installed() {
    command -v gpg &>/dev/null
}

# Check if git is configured for GPG signing
is_gpg_signing_configured() {
    local signing_key
    signing_key=$(git config --get user.signingkey 2>/dev/null || echo "")
    [[ -n "$signing_key" ]]
}

# Check if GPG signing is enabled in git config
is_gpg_signing_enabled() {
    local gpg_sign
    gpg_sign=$(git config --get commit.gpgsign 2>/dev/null || echo "false")
    [[ "$gpg_sign" == "true" ]]
}

# Check if the configured GPG key is available
is_gpg_key_available() {
    local signing_key
    signing_key=$(git config --get user.signingkey 2>/dev/null || echo "")

    if [[ -z "$signing_key" ]]; then
        return 1
    fi

    # Check if key exists in GPG keyring
    gpg --list-secret-keys "$signing_key" &>/dev/null
}

# Check if GPG agent is running and key is unlocked
# This attempts a test sign to verify the key is usable
is_gpg_key_unlocked() {
    echo "test" | gpg --sign --armor --default-key "$(git config --get user.signingkey)" &>/dev/null
}

# Full GPG signing check - returns 0 if signing will work
# Provides detailed error messages
check_gpg_signing() {
    if ! is_gpg_installed; then
        error_exit "GPG is not installed. Please install GPG to enable commit signing."
    fi

    if ! is_gpg_signing_configured; then
        error_exit "GPG signing key not configured. Run: git config --global user.signingkey <KEY_ID>"
    fi

    if ! is_gpg_key_available; then
        local key
        key=$(git config --get user.signingkey)
        error_exit "GPG key '$key' not found in keyring. Check your GPG configuration."
    fi

    # Don't check if key is unlocked - GPG agent will prompt if needed
    return 0
}

# Get GPG signing key ID
get_gpg_signing_key() {
    git config --get user.signingkey 2>/dev/null || echo ""
}

# Check for SSH signing (alternative to GPG)
is_ssh_signing_configured() {
    local format
    format=$(git config --get gpg.format 2>/dev/null || echo "")
    [[ "$format" == "ssh" ]]
}

# Check if any signing method is available
has_signing_available() {
    if is_ssh_signing_configured; then
        local ssh_key
        ssh_key=$(git config --get user.signingkey 2>/dev/null || echo "")
        [[ -n "$ssh_key" && -f "$ssh_key" ]]
    else
        is_gpg_signing_configured && is_gpg_key_available
    fi
}

# Require signing to be available (exit with error if not)
require_signing() {
    if is_ssh_signing_configured; then
        local ssh_key
        ssh_key=$(git config --get user.signingkey 2>/dev/null || echo "")
        if [[ -z "$ssh_key" ]]; then
            error_exit "SSH signing configured but no key specified. Run: git config --global user.signingkey ~/.ssh/id_ed25519.pub"
        fi
        if [[ ! -f "$ssh_key" ]]; then
            error_exit "SSH signing key not found: $ssh_key"
        fi
    else
        check_gpg_signing
    fi
}
