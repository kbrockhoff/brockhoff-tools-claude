# bkff Plugin

Spec-driven development workflows for Claude Code. Provides comprehensive tooling for repository compliance, issue management, verification, documentation generation, and PR feedback handling.

## Features

### Repository Compliance
- **Check Compliance** (`/bkff:chkcompliance`): Scan repository for missing files and configuration issues
- **Fix Compliance** (`/bkff:fixcompliance`): Automatically create missing files and fix issues

### Issue Management
- **Convert Tasks** (`/bkff:tasks2issues`): Convert SpecKit tasks.md to beads issues with dependencies
- **Start Development Loop** (`/bkff:startloop`): Begin autonomous task execution cycle
- **Cancel Loop** (`/bkff:cancelloop`): Stop or pause development loop

### Verification
- **Verify Task** (`/bkff:verifytask`): Run validation for task completion
- **Verify Feature** (`/bkff:verifyfeat`): Check all child tasks closed and run verify target
- **Verify Epic** (`/bkff:verifyepic`): Check all child features closed and run epic verification
- **Verify Bug** (`/bkff:verifybug`): Validate bug fix with regression testing

### Documentation
- **Write ADR** (`/bkff:writeadr`): Generate Architecture Decision Records using multi-agent pipeline
- **Generate Tests** (`/bkff:gentests`): Create unit tests for source code
- **Generate README** (`/bkff:genreadme`): Generate project documentation

### PR Workflow
- **PR Feedback** (`/bkff:prfeedback`): Parse review comments, create tasks, manage re-review

## Installation

This plugin is part of the brockhoff-tools-claude plugin collection.

```bash
# Clone the repository
git clone https://github.com/kbrockhoff/brockhoff-tools-claude.git

# The plugin is located at:
# brockhoff-tools-claude/bkff-plugin/plugins/bkff/
```

## Requirements

- Bash 4.0+ (POSIX-compatible where possible)
- Git 2.25+
- GitHub CLI (gh) 2.0+
- Beads CLI (bd)
- jq (JSON processing)
- make (for build targets)

## Quick Start

### 1. Check Repository Compliance

```bash
/bkff:chkcompliance
```

This checks for required files like CODEOWNERS, CONTRIBUTING.md, PR templates, etc.

### 2. Fix Compliance Issues

```bash
/bkff:fixcompliance --check=all
```

Automatically creates missing files with sensible defaults.

### 3. Convert Tasks to Issues

```bash
/bkff:tasks2issues --file=tasks.md
```

Parses SpecKit format and creates beads issues with proper hierarchy.

### 4. Start Development Loop

```bash
/bkff:startloop
```

Begins autonomous task execution, picking up ready tasks from beads.

### 5. Verify Completion

```bash
/bkff:verifytask --issue=beads-abc123
```

Runs the `validate` make target and checks acceptance criteria.

## Skills Reference

| Skill | Description | Key Arguments |
|-------|-------------|---------------|
| `/bkff:chkcompliance` | Check repository compliance | `--format`, `--check` |
| `/bkff:fixcompliance` | Fix compliance issues | `--check`, `--dry-run` |
| `/bkff:tasks2issues` | Convert tasks to issues | `--file`, `--parent` |
| `/bkff:startloop` | Start development loop | `--strategy`, `--verify-only` |
| `/bkff:cancelloop` | Cancel development loop | `--pause` |
| `/bkff:verifytask` | Verify task completion | `--issue`, `--format` |
| `/bkff:verifyfeat` | Verify feature completion | `--issue`, `--format` |
| `/bkff:verifyepic` | Verify epic completion | `--issue`, `--format` |
| `/bkff:verifybug` | Verify bug fix | `--issue`, `--format` |
| `/bkff:writeadr` | Write ADR | `--decision`, `--context`, `--sources` |
| `/bkff:gentests` | Generate unit tests | `--file`, `--framework`, `--update` |
| `/bkff:genreadme` | Generate README | `--update`, `--sections` |
| `/bkff:prfeedback` | Handle PR feedback | `--pr`, `--ready`, `--format` |

## Agents

The plugin includes specialized agents for complex tasks:

| Agent | Purpose |
|-------|---------|
| `adr-writer` | Generates initial ADR content using MADR template |
| `adr-validator` | Validates ADR claims against grounding sources |
| `adr-formatter` | Assigns sequential numbers and formats output |

## Library Functions

The plugin provides reusable library functions in `lib/`:

- **common.sh**: Error handling, output formatting, worktree detection
- **compliance.sh**: Compliance checks and fix functions
- **tasks-parser.sh**: SpecKit tasks.md parsing and conversion
- **loop-state.sh**: Development loop state management
- **verification.sh**: Build target execution and verification

## Build Targets

The plugin integrates with Makefile targets:

| Target | Used By | Purpose |
|--------|---------|---------|
| `validate` | verifytask, verifybug | Run tests, linting, quality checks |
| `verify` | verifyfeat, verifyepic | Full verification including integration |

## Development

### Running Tests

```bash
cd plugins/bkff
make test
```

### Linting

```bash
make lint
```

### Structure

```
plugins/bkff/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest
├── agents/
│   ├── adr-writer.md     # ADR generation agent
│   ├── adr-validator.md  # ADR validation agent
│   └── adr-formatter.md  # ADR formatting agent
├── skills/
│   ├── chkcompliance/    # Compliance checking
│   ├── fixcompliance/    # Compliance fixing
│   ├── tasks2issues/     # Task conversion
│   ├── startloop/        # Development loop
│   ├── cancelloop/       # Loop cancellation
│   ├── verifytask/       # Task verification
│   ├── verifyfeat/       # Feature verification
│   ├── verifyepic/       # Epic verification
│   ├── verifybug/        # Bug verification
│   ├── writeadr/         # ADR generation
│   ├── gentests/         # Test generation
│   ├── genreadme/        # README generation
│   └── prfeedback/       # PR feedback handling
├── lib/
│   ├── common.sh         # Shared utilities
│   ├── compliance.sh     # Compliance functions
│   ├── tasks-parser.sh   # Task parsing
│   ├── loop-state.sh     # Loop management
│   └── verification.sh   # Verification helpers
├── tests/
│   └── test-helpers.sh   # Test framework
└── README.md
```

## License

MIT
