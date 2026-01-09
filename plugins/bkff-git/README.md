# bkff-git Plugin

Git operations skills for Claude Code providing comprehensive repository management, conventional commits, pull request creation, and commit signing.

## Commands

### Core (P0)
- `/bkff-git:git-status` - Comprehensive repository status
- `/bkff-git:git-commit` - Commit with conventional commit enforcement
- `/bkff-git:git-pr` - Create pull requests with templates

### Extended (P1)
- `/bkff-git:git-sync` - Fetch, pull, and push operations
- `/bkff-git:git-branch` - Branch management with naming conventions
- `/bkff-git:git-signing` - Configure commit signing (GPG/SSH)

### Advanced (P2)
- `/bkff-git:git-changelog` - Generate changelogs from commits

## Features

- Conventional commit format enforcement
- Branch naming convention validation (`feature/`, `bugfix/`, `hotfix/`)
- GitHub CLI integration for PR/issue operations
- Commit signing support (GPG and SSH keys)
- CODEOWNERS-based reviewer assignment
- Beads issue linking

## Requirements

- Git 2.x+
- GitHub CLI (`gh`) for PR operations
- GPG or SSH keys for commit signing (optional)

## Development

Key files:
- `.claude-plugin/plugin.json` - Plugin metadata
- `commands/` - Command definitions
- `skills/` - Reusable skill implementations
