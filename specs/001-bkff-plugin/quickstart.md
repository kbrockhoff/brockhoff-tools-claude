# Quickstart: bkff Claude Plugin

**Date**: 2026-01-23
**Spec**: [spec.md](./spec.md)
**Plan**: [plan.md](./plan.md)

## Overview

The bkff (Brockhoff Cloud) plugin provides spec-driven development workflows for Claude Code, integrating compliance checking, task management, agentic development loops, and documentation generation.

## Prerequisites

Before using the bkff plugin, ensure you have:

```bash
# Required dependencies
git --version           # >= 2.25
gh --version            # GitHub CLI >= 2.0
bd --version            # beads CLI (any version)
jq --version            # JSON parser (any version)

# Authenticate GitHub CLI
gh auth login

# Initialize beads in your repository
bd init
```

## Installation

1. **Clone the plugin repository**:
   ```bash
   git clone https://github.com/kbrockhoff/brockhoff-tools-claude.git
   ```

2. **Add to Claude Code plugins**:
   ```bash
   # Copy plugin to Claude Code plugins directory
   cp -r brockhoff-tools-claude/bkff-plugin/plugins/bkff ~/.claude/plugins/
   ```

3. **Verify installation**:
   ```bash
   # In Claude Code, run:
   /bkff:chkcompliance
   ```

## Quick Start Workflow

### 1. Check Repository Compliance

Verify your repository meets Brockhoff Cloud standards:

```
/bkff:chkcompliance
```

Expected output:
```
Compliance Report
=================
✓ .github/CODEOWNERS
✓ .github/CONTRIBUTING.md
✓ .github/dependabot.yml
✓ .github/pull_request_template.md
✓ .github/ISSUE_TEMPLATE/
✓ AGENTS.md
✓ CLAUDE.md (references AGENTS.md)
✓ .github/copilot-instructions.md
✓ .beads/ initialized
✓ bd doctor (no issues)

Status: PASS (10/10 checks)
```

### 2. Fix Compliance Issues

If checks fail, automatically fix them:

```
/bkff:fixcompliance
```

This creates missing files and initializes beads.

### 3. Convert Tasks to Issues

After generating tasks with SpecKit:

```
/bkff:tasks2issues
```

This parses `specs/[branch]/tasks.md` and creates beads issues with proper dependencies.

### 4. Start Development Loop

Begin autonomous development:

```
/bkff:startloop
```

The agent will:
- Select the highest priority ready task
- Implement the solution
- Generate tests
- Run verification
- Close completed tasks
- Move to the next task

The loop pauses on blocking issues and waits for your input.

### 5. Cancel Development Loop

To stop the loop:

```
/bkff:cancelloop
```

The agent completes its current atomic operation before stopping.

## Verification Workflow

### Verify Task Completion

```
/bkff:verifytask beads-abc123
```

Runs the `validate` build target and checks acceptance criteria.

### Verify Feature Completion

```
/bkff:verifyfeat beads-def456
```

Runs the `verify` build target and checks all child tasks.

## ADR Generation

Generate an Architectural Decision Record:

```
/bkff:writeadr
```

Claude will:
1. Ask about your decision context
2. Generate a MADR-formatted ADR
3. Validate against existing ADRs and codebase
4. Write to `docs/adr/NNNN-title.md`

## Test Generation

Generate tests for implemented code:

```
/bkff:gentests lib/compliance.sh
```

Or update existing tests:

```
/bkff:gentests --update
```

## README Generation

Generate project documentation:

```
/bkff:genreadme
```

Or update existing README:

```
/bkff:genreadme --update
```

## PR Feedback

Process PR review comments:

```
/bkff:prfeedback
```

After addressing feedback:

```
/bkff:prfeedback --ready
```

## Typical Development Session

```bash
# 1. Start in your feature branch
git checkout -b feature/my-feature

# 2. Check compliance
/bkff:chkcompliance

# 3. Generate spec (using SpecKit)
/speckit.specify

# 4. Clarify ambiguities
/speckit.clarify

# 5. Generate plan
/speckit.plan

# 6. Generate tasks
/speckit.tasks

# 7. Convert to beads issues
/bkff:tasks2issues

# 8. Start development loop
/bkff:startloop

# ... loop runs, pauses when needed ...

# 9. Generate README
/bkff:genreadme

# 10. Create PR
/bkff:git-pr

# 11. Address PR feedback
/bkff:prfeedback
```

## Build System Integration

The bkff plugin expects these Makefile targets:

```makefile
# Required for task/bug verification
.PHONY: validate
validate:
	@echo "Running validation..."
	$(MAKE) lint
	$(MAKE) test
	$(MAKE) docs-check
	$(MAKE) security-scan

# Required for feature/epic verification
.PHONY: verify
verify: validate
	@echo "Running comprehensive verification..."
	$(MAKE) integration-test
	$(MAKE) feature-docs-check
```

## Troubleshooting

### "Not a git repository"

All bkff commands require a git repository. Navigate to your repo:
```bash
cd /path/to/your/repo
```

### "beads not initialized"

Initialize beads:
```bash
bd init
```

### "No ready tasks"

Check task status:
```bash
bd ready           # Show ready tasks
bd blocked         # Show blocked tasks
bd list --status=open
```

### "Build target not found"

Add required targets to your Makefile:
```makefile
.PHONY: validate verify
validate: lint test
verify: validate integration-test
```

### "GitHub CLI not authenticated"

Authenticate with GitHub:
```bash
gh auth login
```

## Configuration

### ADR Directory

Default: `docs/adr/`

To customize, create `.bkff/config.json`:
```json
{
  "adr_directory": "architecture/decisions"
}
```

### Loop State

Development loop state is stored in `.bkff/loop-state.json`. This file is automatically managed by the plugin.

## Next Steps

1. **Explore Commands**: Run `/bkff:` and press Tab to see all available commands
2. **Read Skill Docs**: Each skill has detailed documentation in its SKILL.md file
3. **Customize Workflows**: Modify build targets to match your project's validation needs
