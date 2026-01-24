# bkff Plugin

Spec-driven development workflows for Claude Code.

## Features

- **Compliance Checking**: Check and fix repository compliance with project standards
- **Task-to-Issue Conversion**: Convert SpecKit tasks.md to beads issues
- **Agentic Development Loop**: Autonomous task execution with verification
- **Verification Skills**: Verify task, feature, epic, and bug fix completion
- **ADR Generation**: Generate Architecture Decision Records using MADR template
- **Test Generation**: Generate unit tests for source code
- **README Generation**: Generate documentation from source code
- **PR Feedback Handling**: Process and address PR review comments

## Installation

This plugin is part of the brockhoff-tools-claude plugin collection.

## Requirements

- Bash 4.0+
- Git 2.25+
- GitHub CLI (gh) 2.0+
- Beads CLI (bd)
- jq

## Skills

| Skill | Description |
|-------|-------------|
| `/chkcompliance` | Check repository compliance |
| `/fixcompliance` | Fix compliance issues |
| `/tasks2issues` | Convert SpecKit tasks to beads issues |
| `/startloop` | Start agentic development loop |
| `/cancelloop` | Cancel development loop |
| `/verifytask` | Verify task completion |
| `/verifyfeat` | Verify feature completion |
| `/verifyepic` | Verify epic completion |
| `/verifybug` | Verify bug fix |
| `/gentests` | Generate unit tests |
| `/genreadme` | Generate README documentation |
| `/prfeedback` | Handle PR review feedback |

## License

MIT
