---
description: Configure commit signing with GPG or SSH keys including hardware key support
argument-hint: [status|setup|disable] [--global] [--ssh] [--gpg]
---

## Name
bkff-git:git-signing

## Synopsis
```
/bkff-git:git-signing [status|setup|disable|test] [--global] [--ssh] [--gpg] [--key=KEYID]
```

## Description
The `git-signing` command configures commit signing using GPG or SSH keys. It detects available keys, validates their status, and sets up git configuration for automatic commit signing. Supports both software keys and hardware security keys (Yubikey, etc.).

## Signing Methods

| Method | Best For | Requirements |
|--------|----------|--------------|
| GPG | Traditional, widely supported | GPG installed, key pair generated |
| SSH | Modern, simpler setup | SSH key, Git 2.34+ |
| Hardware (Yubikey) | Maximum security | Hardware key, GPG or SSH configured |

## Implementation

### Status Operation (Default)
```bash
show_signing_status() {
    echo "=== Commit Signing Status ==="
    echo ""

    # Check current configuration
    local gpgsign=$(git config --get commit.gpgsign)
    local signingkey=$(git config --get user.signingkey)
    local gpg_format=$(git config --get gpg.format)

    if [[ "$gpgsign" == "true" ]]; then
        echo "Signing: ENABLED"
        echo "Format:  ${gpg_format:-gpg}"
        echo "Key:     ${signingkey:-<not set>}"
    else
        echo "Signing: DISABLED"
    fi

    echo ""
    echo "=== Available Keys ==="

    # List GPG keys
    echo ""
    echo "GPG Keys:"
    if command -v gpg &>/dev/null; then
        gpg --list-secret-keys --keyid-format=long 2>/dev/null | \
            grep -E "^sec|^uid" | head -20
        if [[ $? -ne 0 ]]; then
            echo "  No GPG keys found"
        fi
    else
        echo "  GPG not installed"
    fi

    # List SSH keys
    echo ""
    echo "SSH Keys:"
    if command -v ssh-add &>/dev/null; then
        ssh-add -l 2>/dev/null || echo "  No SSH keys in agent"
    fi

    # Check for hardware keys
    echo ""
    echo "Hardware Keys:"
    detect_hardware_keys
}

detect_hardware_keys() {
    # Check for Yubikey via GPG
    if command -v gpg &>/dev/null; then
        local card_status=$(gpg --card-status 2>/dev/null)
        if [[ -n "$card_status" ]]; then
            echo "  Yubikey/SmartCard detected:"
            echo "$card_status" | grep -E "^(Name|Serial|Signature key)" | sed 's/^/    /'
            return 0
        fi
    fi

    # Check for FIDO2/hardware SSH keys
    if ssh-add -l 2>/dev/null | grep -q "sk-"; then
        echo "  FIDO2/Security Key detected (SSH)"
        ssh-add -l | grep "sk-" | sed 's/^/    /'
        return 0
    fi

    echo "  No hardware keys detected"
}
```

### Setup Operation
```bash
setup_signing() {
    local scope="${1:---local}"  # --global or --local
    local format="${2:-gpg}"     # gpg or ssh
    local key_id="$3"            # optional specific key

    echo "=== Setting Up Commit Signing ==="
    echo ""

    if [[ "$format" == "ssh" ]]; then
        setup_ssh_signing "$scope" "$key_id"
    else
        setup_gpg_signing "$scope" "$key_id"
    fi
}

setup_gpg_signing() {
    local scope="$1"
    local key_id="$2"

    # Check GPG is installed
    if ! command -v gpg &>/dev/null; then
        echo "Error: GPG is not installed"
        echo "Install: brew install gnupg (macOS) or apt install gnupg (Linux)"
        return 1
    fi

    # Get available keys
    if [[ -z "$key_id" ]]; then
        echo "Available GPG keys:"
        echo ""
        gpg --list-secret-keys --keyid-format=long 2>/dev/null

        # Extract key IDs
        local keys=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | \
            grep "^sec" | sed -E 's/.*\/([A-F0-9]+).*/\1/')

        local key_count=$(echo "$keys" | wc -l | tr -d ' ')

        if [[ -z "$keys" ]]; then
            echo "No GPG keys found. Generate one with:"
            echo "  gpg --full-generate-key"
            return 1
        elif [[ "$key_count" -eq 1 ]]; then
            key_id="$keys"
            echo "Using key: $key_id"
        else
            echo ""
            echo "Multiple keys found. Specify with --key=KEYID"
            return 1
        fi
    fi

    # Validate key
    if ! validate_gpg_key "$key_id"; then
        return 1
    fi

    # Configure git
    echo ""
    echo "Configuring git..."
    git config $scope user.signingkey "$key_id"
    git config $scope commit.gpgsign true
    git config $scope gpg.format gpg

    # Set GPG program (for macOS compatibility)
    if [[ "$(uname)" == "Darwin" ]]; then
        local gpg_path=$(which gpg)
        git config $scope gpg.program "$gpg_path"
    fi

    echo ""
    echo "✓ GPG signing configured successfully"
    echo ""
    echo "Test with: /bkff-git:git-signing test"
}

setup_ssh_signing() {
    local scope="$1"
    local key_file="$2"

    # Check Git version (requires 2.34+)
    local git_version=$(git --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
    if [[ "${git_version%.*}" -lt 2 ]] || [[ "${git_version#*.}" -lt 34 ]]; then
        echo "Error: SSH signing requires Git 2.34+"
        echo "Current version: $(git --version)"
        return 1
    fi

    # Find SSH key
    if [[ -z "$key_file" ]]; then
        # Check common locations
        local ssh_keys=(
            "$HOME/.ssh/id_ed25519.pub"
            "$HOME/.ssh/id_rsa.pub"
            "$HOME/.ssh/id_ecdsa.pub"
        )

        for key in "${ssh_keys[@]}"; do
            if [[ -f "$key" ]]; then
                key_file="$key"
                break
            fi
        done

        if [[ -z "$key_file" ]]; then
            echo "No SSH public key found in ~/.ssh/"
            echo "Generate one with: ssh-keygen -t ed25519"
            return 1
        fi
    fi

    echo "Using SSH key: $key_file"

    # Validate key exists
    if [[ ! -f "$key_file" ]]; then
        echo "Error: Key file not found: $key_file"
        return 1
    fi

    # Configure git for SSH signing
    echo ""
    echo "Configuring git..."
    git config $scope gpg.format ssh
    git config $scope user.signingkey "$key_file"
    git config $scope commit.gpgsign true

    # Set up allowed signers file (for verification)
    local allowed_signers="$HOME/.ssh/allowed_signers"
    if [[ ! -f "$allowed_signers" ]]; then
        local email=$(git config --get user.email)
        echo "$email $(cat "$key_file")" > "$allowed_signers"
        git config $scope gpg.ssh.allowedSignersFile "$allowed_signers"
        echo "Created allowed signers file: $allowed_signers"
    fi

    echo ""
    echo "✓ SSH signing configured successfully"
    echo ""
    echo "Test with: /bkff-git:git-signing test"
}

validate_gpg_key() {
    local key_id="$1"

    # Check key exists
    if ! gpg --list-secret-keys "$key_id" &>/dev/null; then
        echo "Error: Key not found: $key_id"
        return 1
    fi

    # Check key is not expired
    local expiry=$(gpg --list-keys --with-colons "$key_id" 2>/dev/null | \
        grep "^pub" | cut -d: -f7)

    if [[ -n "$expiry" ]]; then
        local now=$(date +%s)
        if [[ "$expiry" -lt "$now" ]]; then
            echo "Error: Key has expired"
            echo "Extend expiry with: gpg --edit-key $key_id"
            return 1
        fi
    fi

    # Check key has signing capability
    local caps=$(gpg --list-keys --with-colons "$key_id" 2>/dev/null | \
        grep "^pub" | cut -d: -f12)

    if [[ "$caps" != *"s"* && "$caps" != *"S"* ]]; then
        echo "Warning: Key may not have signing capability"
    fi

    echo "✓ Key validated: $key_id"
    return 0
}
```

### Test Operation
```bash
test_signing() {
    echo "=== Testing Commit Signing ==="
    echo ""

    # Check configuration
    local gpgsign=$(git config --get commit.gpgsign)
    if [[ "$gpgsign" != "true" ]]; then
        echo "Error: Signing is not enabled"
        echo "Run: /bkff-git:git-signing setup"
        return 1
    fi

    local format=$(git config --get gpg.format)
    format="${format:-gpg}"

    echo "Format: $format"
    echo ""

    # Test signing
    echo "Creating test signature..."
    local test_file=$(mktemp)
    echo "test" > "$test_file"

    if [[ "$format" == "ssh" ]]; then
        local key=$(git config --get user.signingkey)
        if ssh-keygen -Y sign -f "$key" -n git "$test_file" 2>/dev/null; then
            echo "✓ SSH signing works"
            rm -f "$test_file" "${test_file}.sig"
        else
            echo "✗ SSH signing failed"
            rm -f "$test_file"
            return 1
        fi
    else
        local key=$(git config --get user.signingkey)
        if echo "test" | gpg --sign --armor --default-key "$key" >/dev/null 2>&1; then
            echo "✓ GPG signing works"
        else
            echo "✗ GPG signing failed"
            echo ""
            echo "Troubleshooting:"
            echo "  1. Check GPG agent: gpgconf --kill gpg-agent && gpg-agent --daemon"
            echo "  2. For Yubikey: ensure card is inserted"
            echo "  3. Set TTY: export GPG_TTY=\$(tty)"
            rm -f "$test_file"
            return 1
        fi
    fi

    rm -f "$test_file"
    echo ""
    echo "Ready to sign commits!"
}
```

### Disable Operation
```bash
disable_signing() {
    local scope="${1:---local}"

    echo "Disabling commit signing..."

    git config $scope --unset commit.gpgsign 2>/dev/null
    git config $scope --unset user.signingkey 2>/dev/null
    git config $scope --unset gpg.format 2>/dev/null

    echo "✓ Commit signing disabled"
}
```

## Return Value

- **Format**: Configuration status and results
- **Includes**:
  - Current signing status
  - Available keys (GPG, SSH, Hardware)
  - Configuration changes made
  - Test results

## Examples

1. **Check current status**:
   ```
   /bkff-git:git-signing status
   ```
   Shows signing config and available keys.

2. **Setup GPG signing (auto-detect key)**:
   ```
   /bkff-git:git-signing setup --gpg
   ```

3. **Setup GPG signing (specific key)**:
   ```
   /bkff-git:git-signing setup --gpg --key=ABCD1234EFGH5678
   ```

4. **Setup SSH signing**:
   ```
   /bkff-git:git-signing setup --ssh
   ```

5. **Setup with specific SSH key**:
   ```
   /bkff-git:git-signing setup --ssh --key=~/.ssh/id_ed25519.pub
   ```

6. **Configure globally**:
   ```
   /bkff-git:git-signing setup --gpg --global
   ```

7. **Test signing configuration**:
   ```
   /bkff-git:git-signing test
   ```

8. **Disable signing**:
   ```
   /bkff-git:git-signing disable
   ```

9. **Disable globally**:
   ```
   /bkff-git:git-signing disable --global
   ```

## Arguments

- `status`: (Default) Show current signing configuration
- `setup`: Configure commit signing
- `test`: Test that signing works
- `disable`: Remove signing configuration

### Flags
- `--global`: Apply to global git config (all repositories)
- `--gpg`: Use GPG signing (default)
- `--ssh`: Use SSH signing (requires Git 2.34+)
- `--key=ID`: Specify key ID or path

## Hardware Key Setup (Yubikey)

### GPG with Yubikey
```bash
# 1. Install dependencies
brew install gnupg yubikey-manager  # macOS
apt install gnupg2 yubikey-manager  # Linux

# 2. Check Yubikey is detected
gpg --card-status

# 3. Generate or import key to Yubikey
gpg --edit-card
# > admin
# > generate

# 4. Configure signing
/bkff-git:git-signing setup --gpg
```

### SSH with FIDO2/Yubikey
```bash
# 1. Generate resident key on Yubikey
ssh-keygen -t ed25519-sk -O resident -O verify-required

# 2. Add to SSH agent
ssh-add -K  # Load from hardware

# 3. Configure signing
/bkff-git:git-signing setup --ssh --key=~/.ssh/id_ed25519_sk.pub
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| GPG signing fails | Agent not running | `gpgconf --kill gpg-agent && gpg-agent --daemon` |
| "No secret key" | Wrong key ID | Check `gpg --list-secret-keys` for correct ID |
| Yubikey not detected | Not inserted/driver | Insert key, install ykman |
| SSH signing fails | Old Git version | Upgrade to Git 2.34+ |
| "Inappropriate ioctl" | TTY not set | `export GPG_TTY=$(tty)` |
| Pinentry fails | GUI not available | Set `pinentry-program` in gpg-agent.conf |

### GPG Agent Configuration
```bash
# ~/.gnupg/gpg-agent.conf
default-cache-ttl 600
max-cache-ttl 7200
pinentry-program /usr/local/bin/pinentry-mac  # macOS
```

### Shell Configuration
```bash
# Add to ~/.bashrc or ~/.zshrc
export GPG_TTY=$(tty)
```

## Verification

To verify signed commits:
```bash
# Verify last commit
git log --show-signature -1

# Verify specific commit
git verify-commit <commit-hash>
```

## Related Commands

- `/bkff-git:git-commit` - Creates signed commits automatically
- `/bkff-git:git-status` - Shows signing configuration status

## Notes

- GPG signing is more widely supported
- SSH signing is simpler but requires Git 2.34+
- Hardware keys provide strongest security
- Global config applies to all repositories
- Local config overrides global for specific repos
