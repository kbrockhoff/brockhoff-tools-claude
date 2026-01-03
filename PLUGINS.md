# Available Plugins

This document lists all available Claude Code plugins and their commands in the ai-helpers repository.

- [Bkff Git](#bkff-git-plugin)
- [Example Plugin](#example-plugin-plugin)

### Bkff Git Plugin

Git operations skills for repository management, commits, PRs, and signing

**Commands:**
- **`/bkff-git:git-commit` `<type>(<scope>): <description> [--co-author=NAME] [--no-verify]`** - Create commits with conventional commit format enforcement and optional signing
- **`/bkff-git:git-status` `[--commits=N]`** - Comprehensive repository status showing working tree, branch, commits, and stashes

See [plugins/bkff-git/README.md](plugins/bkff-git/README.md) for detailed documentation.

### Example Plugin Plugin

Example plugin demonstrating command structure

**Commands:**
- **`/example-plugin:hello` `[name]`** - Say hello to someone

See [plugins/example-plugin/README.md](plugins/example-plugin/README.md) for detailed documentation.
