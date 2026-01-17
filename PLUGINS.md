# Available Plugins

This document lists all available Claude Code plugins and their commands in the ai-helpers repository.

- [Bkff Git](#bkff-git-plugin)
- [Example Plugin](#example-plugin-plugin)

### Bkff Git Plugin

Git lifecycle commands for worktree-based development: status, branch, commit, sync, and PR management.

**Skills:**
- **`/bkff:git-st`** - Check development status (changes, commits, beads tasks, PR status)
- **`/bkff:git-branch` `<issue-id>`** - Create feature branch from beads issue with worktree
- **`/bkff:git-commit` `[-m "message"] [--co-author "Name <email>"]`** - Commit with validation, conventional message, GPG signing
- **`/bkff:git-sync` `[source-branch]`** - Sync with remote using smart rebase/merge selection
- **`/bkff:git-pr` `[-t "title"] [-d]`** - Create or update pull request

See [plugins/bkff-git/README.md](plugins/bkff-git/README.md) for detailed documentation.

### Example Plugin Plugin

Example plugin demonstrating command structure

**Commands:**
- **`/example-plugin:hello` `[name]`** - Say hello to someone

See [plugins/example-plugin/README.md](plugins/example-plugin/README.md) for detailed documentation.
