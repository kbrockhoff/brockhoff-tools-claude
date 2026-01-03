---
name: Signature Verification
description: Verify GPG and SSH commit signatures on pull, merge, and log operations
---

# Signature Verification

This skill provides commit signature verification capabilities for git operations. It verifies GPG and SSH signatures on commits during pull, merge, and when viewing history, helping ensure code authenticity and integrity.

## When to Use This Skill

Use this skill when you need to:
- Verify commit signatures after pulling changes
- Check signature status before merging
- Audit commit signatures in history
- Configure signature verification policies
- Troubleshoot signature verification issues

## Prerequisites

### For GPG Signatures
- GPG installed (`gpg --version`)
- Public keys of signers imported
- Trust level set for keys

### For SSH Signatures
- Git 2.34+ for SSH signature support
- Allowed signers file configured
- Public keys of signers in allowed signers file

## Implementation Steps

### Step 1: Verify Single Commit

```bash
verify_commit() {
    local commit="${1:-HEAD}"

    echo "=== Verifying Commit: $commit ==="
    echo ""

    # Get commit info
    git log -1 --format="Commit:  %H%nAuthor:  %an <%ae>%nDate:    %ai%nSubject: %s" "$commit"
    echo ""

    # Check signature
    local sig_status=$(git log -1 --format="%G?" "$commit")
    local signer=$(git log -1 --format="%GS" "$commit")
    local key=$(git log -1 --format="%GK" "$commit")
    local trust=$(git log -1 --format="%GT" "$commit")

    echo "Signature Status:"
    case "$sig_status" in
        G)
            echo "  ✓ Good signature"
            echo "  Signer: $signer"
            echo "  Key:    $key"
            echo "  Trust:  $trust"
            ;;
        B)
            echo "  ✗ Bad signature (invalid)"
            echo "  Key:    $key"
            return 1
            ;;
        U)
            echo "  ⚠ Good signature, untrusted key"
            echo "  Signer: $signer"
            echo "  Key:    $key"
            echo "  Action: Import and trust the public key"
            ;;
        X)
            echo "  ⚠ Good signature, expired key"
            echo "  Signer: $signer"
            echo "  Key:    $key"
            ;;
        Y)
            echo "  ⚠ Good signature, expired key (at time of signing)"
            echo "  Signer: $signer"
            ;;
        R)
            echo "  ✗ Good signature, revoked key"
            echo "  Key:    $key"
            return 1
            ;;
        E)
            echo "  ✗ Cannot verify (missing key)"
            echo "  Key ID: $key"
            echo "  Action: Import the public key"
            return 1
            ;;
        N)
            echo "  ○ No signature"
            ;;
        *)
            echo "  ? Unknown status: $sig_status"
            ;;
    esac
}
```

### Step 2: Verify Commit Range

```bash
verify_range() {
    local range="${1:-HEAD~10..HEAD}"
    local strict="${2:-false}"

    echo "=== Verifying Commits: $range ==="
    echo ""

    local total=0
    local signed=0
    local unsigned=0
    local invalid=0

    # Table header
    printf "%-10s %-8s %-20s %s\n" "Commit" "Status" "Signer" "Subject"
    printf "%s\n" "$(printf '%.0s-' {1..70})"

    git log "$range" --format="%h|%G?|%GS|%s" | while IFS='|' read -r hash status signer subject; do
        ((total++))

        local status_icon=""
        case "$status" in
            G) status_icon="✓ Good"; ((signed++)) ;;
            B) status_icon="✗ Bad"; ((invalid++)) ;;
            U) status_icon="⚠ Untrust"; ((signed++)) ;;
            X|Y) status_icon="⚠ Expired"; ((signed++)) ;;
            R) status_icon="✗ Revoked"; ((invalid++)) ;;
            E) status_icon="✗ No Key"; ((invalid++)) ;;
            N) status_icon="○ None"; ((unsigned++)) ;;
            *) status_icon="? Unknown" ;;
        esac

        # Truncate fields for display
        local short_signer="${signer:0:18}"
        local short_subject="${subject:0:30}"

        printf "%-10s %-8s %-20s %s\n" "$hash" "$status_icon" "$short_signer" "$short_subject"
    done

    echo ""
    echo "Summary: $total commits, $signed signed, $unsigned unsigned, $invalid invalid"

    if [[ "$strict" == "true" && ( "$unsigned" -gt 0 || "$invalid" -gt 0 ) ]]; then
        echo ""
        echo "⚠ Strict mode: Found unsigned or invalid commits"
        return 1
    fi
}
```

### Step 3: Verify on Pull

```bash
verify_pull() {
    local remote="${1:-origin}"
    local branch="${2:-$(git branch --show-current)}"
    local policy="${3:-warn}"  # none, warn, require

    echo "=== Pre-Pull Signature Check ==="
    echo ""

    # Fetch first to see incoming commits
    git fetch "$remote" "$branch" --quiet

    local tracking="$remote/$branch"
    local incoming=$(git rev-list HEAD.."$tracking" --count)

    if [[ "$incoming" -eq 0 ]]; then
        echo "No incoming commits to verify"
        return 0
    fi

    echo "Incoming commits: $incoming"
    echo ""

    # Check signatures on incoming commits
    local unsigned=0
    local invalid=0

    git log HEAD.."$tracking" --format="%h %G? %s" | while read -r hash status subject; do
        case "$status" in
            N) ((unsigned++)) ;;
            B|R|E) ((invalid++)) ;;
        esac
    done

    # Apply policy
    case "$policy" in
        none)
            echo "Policy: No verification required"
            ;;
        warn)
            if [[ "$unsigned" -gt 0 ]]; then
                echo "⚠ Warning: $unsigned unsigned commit(s)"
            fi
            if [[ "$invalid" -gt 0 ]]; then
                echo "⚠ Warning: $invalid commit(s) with invalid signatures"
            fi
            ;;
        require)
            if [[ "$unsigned" -gt 0 || "$invalid" -gt 0 ]]; then
                echo "✗ Error: All commits must have valid signatures"
                echo "   Unsigned: $unsigned, Invalid: $invalid"
                echo ""
                echo "Pull aborted. Override with --no-verify-signatures"
                return 1
            fi
            echo "✓ All incoming commits are properly signed"
            ;;
    esac
}
```

### Step 4: Verify on Merge

```bash
verify_merge() {
    local branch="$1"
    local policy="${2:-warn}"

    echo "=== Pre-Merge Signature Check ==="
    echo ""

    # Get commits that would be merged
    local base=$(git merge-base HEAD "$branch")
    local incoming=$(git rev-list "$base..$branch" --count)

    echo "Branch: $branch"
    echo "Commits to merge: $incoming"
    echo ""

    if [[ "$incoming" -eq 0 ]]; then
        echo "Nothing to merge"
        return 0
    fi

    # Verify all commits in the branch
    verify_range "$base..$branch" "$( [[ "$policy" == "require" ]] && echo true || echo false )"
}
```

### Step 5: Configure Verification Policy

```bash
configure_policy() {
    local scope="${1:---local}"
    local policy="$2"  # none, warn, require

    case "$policy" in
        none)
            git config $scope merge.verifySignatures false
            git config $scope pull.verifySignatures false
            echo "Signature verification disabled"
            ;;
        warn)
            git config $scope merge.verifySignatures false
            git config $scope pull.verifySignatures false
            # Warning handled by this skill, not git
            echo "Signature verification: warn mode"
            ;;
        require)
            git config $scope merge.verifySignatures true
            # Note: pull.verifySignatures doesn't exist, use merge config
            echo "Signature verification required for merges"
            ;;
        *)
            echo "Invalid policy. Use: none, warn, require"
            return 1
            ;;
    esac
}
```

### Step 6: Setup Allowed Signers (SSH)

```bash
setup_allowed_signers() {
    local file="${1:-$HOME/.ssh/allowed_signers}"

    echo "=== SSH Allowed Signers Setup ==="
    echo ""

    if [[ -f "$file" ]]; then
        echo "Existing file: $file"
        echo ""
        echo "Current entries:"
        cat "$file" | head -10
        echo ""
    else
        echo "Creating new allowed signers file: $file"
        touch "$file"
    fi

    echo "To add a signer:"
    echo "  echo 'email@example.com ssh-ed25519 AAAA...' >> $file"
    echo ""
    echo "Configure git to use this file:"
    echo "  git config gpg.ssh.allowedSignersFile $file"
}
```

### Step 7: Import GPG Keys

```bash
import_gpg_key() {
    local key_source="$1"  # URL, file, or keyserver ID

    echo "=== Importing GPG Key ==="
    echo ""

    if [[ "$key_source" =~ ^https?:// ]]; then
        # URL
        echo "Fetching from URL: $key_source"
        curl -sSL "$key_source" | gpg --import
    elif [[ -f "$key_source" ]]; then
        # File
        echo "Importing from file: $key_source"
        gpg --import "$key_source"
    else
        # Keyserver
        echo "Fetching from keyserver: $key_source"
        gpg --keyserver keyserver.ubuntu.com --recv-keys "$key_source"
    fi

    if [[ $? -eq 0 ]]; then
        echo ""
        echo "✓ Key imported successfully"
        echo ""
        echo "To trust this key:"
        echo "  gpg --edit-key <key-id>"
        echo "  > trust"
        echo "  > 5 (ultimate trust) or 4 (full trust)"
        echo "  > quit"
    else
        echo "✗ Failed to import key"
        return 1
    fi
}
```

## Signature Status Codes

| Code | Meaning | Icon | Action Required |
|------|---------|------|-----------------|
| G | Good, trusted signature | ✓ | None |
| B | Bad signature | ✗ | Investigate, may be tampered |
| U | Good, untrusted key | ⚠ | Import and trust key |
| X | Good, expired key | ⚠ | Key owner should renew |
| Y | Good, expired at signing | ⚠ | Historical, review context |
| R | Good, revoked key | ✗ | Key was compromised |
| E | Cannot verify, no key | ✗ | Import public key |
| N | No signature | ○ | Consider signing policy |

## Verification Policies

### None
- No verification performed
- Suitable for development branches

### Warn (Default)
- Verifies signatures
- Warns about unsigned/invalid commits
- Does not block operations

### Require
- Verifies all signatures
- Blocks merge if any unsigned/invalid
- Suitable for protected branches

## Usage Examples

### Verify Last Commit
```bash
# Check current commit signature
verify_commit HEAD

# Check specific commit
verify_commit abc123
```

### Verify Recent History
```bash
# Last 10 commits
verify_range HEAD~10..HEAD

# Since last tag
verify_range v1.0.0..HEAD

# Strict mode (fails if any unsigned)
verify_range HEAD~10..HEAD true
```

### Pre-Pull Verification
```bash
# Check incoming commits before pulling
verify_pull origin main warn

# Require all signed
verify_pull origin main require
```

### Pre-Merge Verification
```bash
# Check branch before merging
verify_merge feature/branch warn

# Require all signed
verify_merge feature/branch require
```

### Configure Repository Policy
```bash
# Local policy
configure_policy --local require

# Global policy
configure_policy --global warn
```

## Integration with Git Status

Add to `/bkff-git:git-status` output:

```
## Signature Status
Last commit: ✓ Signed by user@example.com (GPG: ABC123...)

## Incoming Changes
origin/main: 3 commits, 2 signed, 1 unsigned ⚠
```

## Troubleshooting

### "No public key" Error
```bash
# Find the key ID
git log -1 --format="%GK"

# Import from keyserver
gpg --keyserver keyserver.ubuntu.com --recv-keys <key-id>
```

### SSH Signature Not Verified
```bash
# Check allowed signers file
git config --get gpg.ssh.allowedSignersFile

# Add signer
echo "user@email.com $(cat ~/.ssh/id_ed25519.pub)" >> ~/.ssh/allowed_signers
```

### "Untrusted Key" Warning
```bash
# Trust the key
gpg --edit-key <key-id>
# > trust
# > 4 (or 5 for ultimate trust)
# > quit
```

## Best Practices

1. **Import team keys**: Add all team member public keys
2. **Set trust levels**: Configure trust for known signers
3. **Use warn policy**: Start with warnings before requiring
4. **Sign your commits**: Lead by example
5. **Document key fingerprints**: Maintain a KEYS file

## Related Commands

- `/bkff-git:git-signing` - Configure commit signing
- `/bkff-git:git-commit` - Create signed commits
- `/bkff-git:git-status` - Shows signature status
- `/bkff-git:git-sync` - Pull with verification

## Notes

- GPG verification requires public keys to be imported
- SSH verification requires allowed_signers file
- Untrusted signatures may still be valid (just not trusted locally)
- Revoked key signatures should be investigated
