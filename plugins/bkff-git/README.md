# bkff-git Plugin

Git lifecycle commands for Claude Code, designed for developers working in git worktree environments. Automates branch creation, conventional commits with GPG signing, remote synchronization, PR management, and status reporting.

## Installation

1. **Clone or copy** this plugin to your Claude Code plugins directory:
   ```bash
   # Option 1: Clone the repository
   git clone https://github.com/kbrockhoff/brockhoff-tools-claude.git
   cd brockhoff-tools-claude/git-plugin/plugins/bkff-git

   # Option 2: Copy to your plugins directory
   cp -r plugins/bkff-git ~/.claude/plugins/
   ```

2. **Install dependencies**:
   ```bash
   # Git (2.25+)
   git --version

   # GitHub CLI
   brew install gh  # macOS
   gh auth login

   # Beads CLI
   # Install from: https://github.com/your-org/beads

   # jq for JSON parsing
   brew install jq  # macOS
   ```

3. **Configure GPG signing**:
   ```bash
   # Generate a GPG key if you don't have one
   gpg --gen-key

   # Get your key ID
   gpg --list-secret-keys --keyid-format=long

   # Configure git to use your key
   git config --global user.signingkey YOUR_KEY_ID
   git config --global commit.gpgsign true
   ```

4. **Verify installation**:
   ```bash
   # Run the status command
   /bkff:git-st
   ```

## Commands

| Command | Priority | Description |
|---------|----------|-------------|
| `/bkff:git-st` | P1 | Check development status (changes, commits, tasks, PR) |
| `/bkff:git-branch` | P2 | Create feature branch from beads issue |
| `/bkff:git-commit` | P2 | Commit with validation, conventional message, GPG signing |
| `/bkff:git-sync` | P3 | Sync with remote using smart rebase/merge |
| `/bkff:git-pr` | P3 | Create or update pull request |

## Command Reference

### `/bkff:git-st` - Check Status

Displays comprehensive status of the current git worktree.

```bash
/bkff:git-st
```

**Output includes:**
- Current branch and push status
- Staged, unstaged, and untracked files
- Last commit information
- In-progress beads tasks
- Pull request status (if exists)

### `/bkff:git-branch` - Create Branch

Creates a new branch from a beads issue with automatic prefix detection.

```bash
/bkff:git-branch <issue-id>
```

**Branch prefix logic:**
| Issue Type | Priority | Prefix |
|------------|----------|--------|
| feature/task | any | `feature/` |
| bug | P2-P4 | `bugfix/` |
| bug | P0-P1 | `hotfix/` |

**Actions:**
1. Validates issue exists
2. Creates worktree with new branch
3. Pushes to origin
4. Initializes beads database

### `/bkff:git-commit` - Commit Changes

Validates, stages, commits with conventional message, and pushes.

```bash
/bkff:git-commit [--message "custom message"] [--co-author "Name <email>"]
```

**Options:**
- `--message`: Override auto-generated commit message
- `--co-author`: Add co-author attribution

**Actions:**
1. Runs build validation (make lint, npm run lint, etc.)
2. Stages all changes
3. Generates conventional commit message
4. Creates GPG-signed commit
5. Pushes to origin

### `/bkff:git-sync` - Sync with Remote

Fetches and integrates changes using smart strategy selection.

```bash
/bkff:git-sync [source-branch]
```

**Strategy:**
- **Rebase**: Used when branch not yet pushed (clean history)
- **Merge**: Used when branch already pushed (preserve history)

**Actions:**
1. Fetches from origin
2. Determines push status
3. Rebases or merges from source branch
4. Reports conflicts if any

### `/bkff:git-pr` - Manage Pull Request

Creates or updates a pull request for the current branch.

```bash
/bkff:git-pr [--title "PR title"] [--draft]
```

**Options:**
- `--title`: Override auto-generated PR title
- `--draft`: Create as draft PR

**Actions:**
1. Pushes branch if needed
2. Checks for existing PR
3. Creates new PR or updates existing
4. Uses PR template if available

## Features

- **Worktree-aware**: Designed for git worktree development workflows
- **Conventional commits**: Auto-generates properly formatted commit messages
- **GPG signing**: All commits are signed for security
- **Smart sync**: Chooses rebase (unpushed) or merge (pushed) automatically
- **Beads integration**: Links branches to beads issues for tracking
- **PR templates**: Uses repository PR templates when available

## Requirements

| Dependency | Version | Purpose |
|------------|---------|---------|
| Git | 2.25+ | Version control |
| GitHub CLI (`gh`) | 2.0+ | PR management |
| `bd` (beads CLI) | any | Issue tracking |
| `jq` | any | JSON parsing |
| GPG | any | Commit signing |

## Directory Structure

```
plugins/bkff-git/
├── .claude-plugin/
│   └── plugin.json       # Plugin metadata
├── skills/
│   ├── git-st/SKILL.md        # Status command
│   ├── git-branch/SKILL.md    # Branch command
│   ├── git-commit/SKILL.md    # Commit command
│   ├── git-sync/SKILL.md      # Sync command
│   └── git-pr/SKILL.md        # PR command
├── lib/
│   ├── common.sh         # Shared utilities (worktree, errors, formatting)
│   ├── git-helpers.sh    # Git helper functions (branch status, parsing)
│   └── validation.sh     # Validation helpers (build tools, GPG)
└── tests/
    ├── test-helpers.sh   # Test framework
    └── test-common.sh    # Tests for common.sh
```

## Quick Start

```bash
# 1. Check current status
/bkff:git-st

# 2. Create branch for a beads issue
/bkff:git-branch tool-abc

# 3. Make your changes...

# 4. Commit all changes
/bkff:git-commit

# 5. Sync with main (if needed)
/bkff:git-sync

# 6. Create/update PR
/bkff:git-pr
```

## Troubleshooting

### "Command must be run within a git worktree"

You're not in a git repository. Navigate to a git worktree directory:
```bash
cd /path/to/your/repo
```

### "GPG signing required but unavailable"

GPG is not configured. Set up GPG signing:
```bash
# List your keys
gpg --list-secret-keys --keyid-format=long

# Configure git (replace KEY_ID with your key)
git config --global user.signingkey KEY_ID
git config --global commit.gpgsign true
```

### "gh CLI not available"

Install and authenticate GitHub CLI:
```bash
brew install gh  # macOS
gh auth login
```

### "bd CLI not available"

The beads CLI is not installed. Install it or the beads-related features will be skipped gracefully.

### "Push failed"

Check your network connection and git remote configuration:
```bash
git remote -v
git fetch origin
```

### "Branch already exists"

The branch name conflicts with an existing branch:
```bash
git branch -a | grep <branch-name>
```

### Validation Errors

If `git-commit` reports validation errors, fix them before committing:
```bash
# Check what validation is running
make lint  # or npm run lint, cargo clippy, etc.
```

### Merge/Rebase Conflicts

If `git-sync` reports conflicts:
1. Open conflicted files and resolve conflicts
2. Stage resolved files: `git add <file>`
3. Continue: `git rebase --continue` or `git commit`
4. Or abort: `git rebase --abort` or `git merge --abort`
