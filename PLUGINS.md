# Available Plugins

This document lists all available Claude Code plugins and their commands in the ai-helpers repository.

- [Bkff Git](#bkff-git-plugin)
- [Example Plugin](#example-plugin-plugin)

### Bkff Git Plugin

Git operations skills for repository management, commits, PRs, and signing

**Commands:**
- **`/bkff-git:git-branch` `[list|create|switch|delete|compare] [BRANCH] [--remote]`** - Branch management with naming conventions, creation, switching, and cleanup
- **`/bkff-git:git-changelog` `[FROM..TO] [--output=FILE] [--format=md|json]`** - Generate changelogs from conventional commits with grouping and formatting
- **`/bkff-git:git-commit` `<type>(<scope>): <description> [--co-author=NAME] [--no-verify]`** - Create commits with conventional commit format enforcement and optional signing
- **`/bkff-git:git-pr` `[--title=TITLE] [--draft] [--base=BRANCH]`** - Create pull requests with templates, auto-populated content, and reviewer assignment
- **`/bkff-git:git-signing` `[status|setup|disable] [--global] [--ssh] [--gpg]`** - Configure commit signing with GPG or SSH keys including hardware key support
- **`/bkff-git:git-status` `[--commits=N]`** - Comprehensive repository status showing working tree, branch, commits, and stashes
- **`/bkff-git:git-sync` `[fetch|pull|push|all] [--rebase] [--remote=NAME]`** - Synchronize with remote repositories via fetch, pull, and push operations

See [plugins/bkff-git/README.md](plugins/bkff-git/README.md) for detailed documentation.

### Example Plugin Plugin

Example plugin demonstrating command structure

**Commands:**
- **`/example-plugin:hello` `[name]`** - Say hello to someone

See [plugins/example-plugin/README.md](plugins/example-plugin/README.md) for detailed documentation.
