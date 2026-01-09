<!--
SYNC IMPACT REPORT
==================
Version change: 0.0.0 → 1.0.0 (MAJOR - initial constitution ratification)
Modified principles: N/A (initial creation)
Added sections:
  - Core Principles (5 principles)
  - Additional Constraints
  - Development Workflow
  - Governance
Removed sections: N/A
Templates requiring updates:
  - .specify/templates/plan-template.md: ✅ compatible (Constitution Check section exists)
  - .specify/templates/spec-template.md: ✅ compatible (functional requirements align)
  - .specify/templates/tasks-template.md: ✅ compatible (phase structure aligns)
Follow-up TODOs: None
-->

# Brockhoff Claude Plugin Marketplace Constitution

## Core Principles

### I. Plugin Standards Compliance

All plugins MUST adhere to the Claude Plugin Marketplace specification. This includes:
- Required directory structure: `.claude-plugin/`, `commands/` (required), `skills/`, `agents/`, `hooks/` (optional)
- Valid `plugin.json` with required fields: `name`, `version`, `description`, `author`
- Semantic versioning format (MAJOR.MINOR.PATCH)
- Plugin directory name MUST match the `name` field in `plugin.json`

**Rationale**: Consistent structure enables automated validation, discoverability, and reliable installation across the marketplace.

### II. Validation First

All changes MUST pass validation before merge. This is non-negotiable:
- Run `make lint` before committing any plugin changes
- CI/CD pipeline validates all pull requests automatically
- Invalid plugins MUST NOT be merged regardless of feature value
- Validation includes JSON syntax, required fields, naming conventions, and directory structure

**Rationale**: Early validation catches structural issues before they propagate, ensuring marketplace reliability.

### III. Conventional Commits

All commits MUST follow Conventional Commits format:
- Format: `<type>[optional scope]: <description>`
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- Scope SHOULD reference the plugin name when applicable (e.g., `feat(bkff-git): add changelog command`)
- Breaking changes MUST include `BREAKING CHANGE:` in footer or `!` after type

**Rationale**: Standardized commit messages enable automated changelog generation, semantic versioning, and clear project history.

### IV. Simplicity and Minimal Dependencies

Plugins MUST remain lightweight and focused:
- Each plugin SHOULD have a single, clear purpose
- Avoid unnecessary external dependencies
- Core marketplace dependencies: `jq`, `bash`, `git` only
- Prefer composability over monolithic plugins
- YAGNI (You Aren't Gonna Need It) - implement only what is explicitly required

**Rationale**: Lightweight plugins are easier to maintain, test, and install. Composition of simple plugins provides flexibility without complexity.

### V. Documentation Accuracy

Documentation MUST remain synchronized with implementation:
- `README.md` MUST reflect current plugin capabilities
- `PLUGINS.md` auto-generated via `make update` - NEVER edit manually
- Command/skill markdown files MUST accurately describe behavior
- Breaking changes MUST update all affected documentation in the same PR

**Rationale**: Accurate documentation builds trust and reduces support burden. Stale docs are worse than no docs.

## Additional Constraints

### Technology Stack

- **Shell scripts**: Bash with `set -e` for error handling
- **Validation**: `jq` for JSON parsing
- **Version control**: Git with conventional branch naming (`feature/`, `bugfix/`, `hotfix/`)
- **CI/CD**: GitHub Actions for automated validation

### Naming Conventions

- Plugin names: lowercase kebab-case (e.g., `bkff-git`, `example-plugin`)
- Command names: lowercase with hyphens (e.g., `git-status`, `git-commit`)
- Skill directories: lowercase with hyphens (e.g., `github-cli`, `signature-verification`)

### Security

- Plugins MUST NOT execute arbitrary user-provided shell commands without validation
- Secrets and credentials MUST NOT be committed to the repository
- Plugins SHOULD use environment variables for sensitive configuration

## Development Workflow

### Contributing New Plugins

1. Create plugin using `make new-plugin NAME=<name>`
2. Implement required structure and metadata
3. Run `make lint` to validate
4. Update documentation via `make update`
5. Submit PR with conventional commit message
6. CI validates automatically; address any failures
7. Merge after approval and passing validation

### Modifying Existing Plugins

1. Increment version according to semantic versioning:
   - PATCH: Bug fixes, documentation updates
   - MINOR: New commands/features, backward-compatible changes
   - MAJOR: Breaking changes, removed functionality
2. Update relevant documentation
3. Run `make lint` before committing
4. Follow same PR process as new plugins

### Session Completion Protocol

Work is NOT complete until pushed to remote:
1. Run quality gates: `make lint`
2. Commit with conventional format
3. Sync beads if using: `bd sync`
4. Push to remote: `git push`
5. Verify: `git status` shows up-to-date with origin

## Governance

This constitution supersedes all other development practices for this repository. All contributors, including AI agents, MUST comply with these principles.

### Amendment Process

1. Propose amendment via PR modifying this file
2. Document rationale for change
3. Update version according to semantic versioning:
   - MAJOR: Removing principles or backward-incompatible governance changes
   - MINOR: Adding principles or expanding existing guidance
   - PATCH: Clarifications, typo fixes, non-semantic refinements
4. Update dependent templates if principles change
5. Require maintainer approval for merge

### Compliance Review

- PRs MUST be validated against constitution principles
- Complexity additions MUST be justified in PR description
- Violations discovered post-merge SHOULD be remediated promptly

**Version**: 1.0.0 | **Ratified**: 2026-01-09 | **Last Amended**: 2026-01-09
