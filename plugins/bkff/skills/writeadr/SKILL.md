---
name: writeadr
description: Generate MADR-format Architectural Decision Records using a multi-agent pipeline
invocation: /bkff:writeadr
arguments:
  - name: decision
    description: Brief description of the architectural decision to document
    required: true
  - name: context
    description: Additional context or constraints for the ADR
    required: false
  - name: sources
    description: Comma-separated list of grounding source files or directories
    required: false
    default: "."
  - name: output
    description: Output directory for ADRs (default: docs/adr)
    required: false
    default: docs/adr
---

# Write Architectural Decision Record

Generates high-quality Architectural Decision Records (ADRs) using the MADR (Markdown Architectural Decision Records) template through a multi-agent pipeline.

## Usage

```bash
# Basic usage
/bkff:writeadr --decision="Use PostgreSQL for primary data storage"

# With context and specific sources
/bkff:writeadr --decision="Implement event sourcing" --context="High audit requirements" --sources="src/domain,docs/requirements.md"

# Custom output directory
/bkff:writeadr --decision="Adopt microservices" --output="architecture/decisions"
```

## Multi-Agent Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                     ADR GENERATION PIPELINE                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    1. ADR Writer Agent                       │
│  • Analyzes codebase and context                            │
│  • Generates initial ADR content using MADR template        │
│  • Documents options, decision drivers, and consequences    │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                   2. ADR Validator Agent                     │
│  • Validates claims against grounding sources               │
│  • Checks technical accuracy                                │
│  • Identifies unsupported assertions                        │
│  • Suggests corrections or clarifications                   │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                  3. ADR Formatter Agent                      │
│  • Assigns sequential ADR number                            │
│  • Formats for consistency with existing ADRs               │
│  • Generates final markdown output                          │
│  • Creates index entry if needed                            │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     OUTPUT                                   │
│  • ADR file: docs/adr/NNNN-decision-title.md                │
│  • Updated index (if exists)                                │
└─────────────────────────────────────────────────────────────┘
```

## MADR Template

The generated ADRs follow the MADR template:

```markdown
# [ADR-NNNN] Title

* Status: [proposed | accepted | deprecated | superseded]
* Date: YYYY-MM-DD
* Deciders: [list of people involved]
* Technical Story: [optional link to issue/story]

## Context and Problem Statement

[Describe the context and problem]

## Decision Drivers

* [driver 1]
* [driver 2]

## Considered Options

* [option 1]
* [option 2]
* [option 3]

## Decision Outcome

Chosen option: "[option N]", because [justification].

### Positive Consequences

* [e.g., improvement of quality attribute satisfaction]

### Negative Consequences

* [e.g., compromising quality attribute, follow-up decisions required]

## Pros and Cons of the Options

### [option 1]

[description]

* Good, because [argument a]
* Bad, because [argument b]

### [option 2]

[description]

* Good, because [argument a]
* Bad, because [argument b]

## Links

* [Link type] [Link to ADR]
* ...
```

## Output

### Success

```
Info: Generating ADR for decision: Use PostgreSQL for primary data storage

Pipeline Progress
─────────────────────────────────────
  Writer:     ✓ Draft generated
  Validator:  ✓ Claims verified (3 sources checked)
  Formatter:  ✓ ADR-0005 created

✓ ADR generated successfully

Output: docs/adr/0005-use-postgresql-for-primary-data-storage.md
```

### Validation Warnings

```
Info: Generating ADR for decision: Use PostgreSQL for primary data storage

Pipeline Progress
─────────────────────────────────────
  Writer:     ✓ Draft generated
  Validator:  ⚠ 2 claims need verification
              - "PostgreSQL supports 10M TPS" - not found in sources
              - "License is MIT" - actually PostgreSQL License

Validation warnings incorporated into final ADR.

✓ ADR generated with notes

Output: docs/adr/0005-use-postgresql-for-primary-data-storage.md
```

## Requirements

- Git repository with valid worktree
- Write access to output directory
- Optional: Existing ADRs for sequential numbering

## Exit Codes

- `0` - ADR generated successfully
- `1` - Generation failed
- `2` - Invalid decision description
- `3` - Output directory not writable

## Related Skills

- `/bkff:chkcompliance` - Check repository compliance
- `/bkff:verifytask` - Verify task completion

## Implementation

This skill orchestrates three specialized agents in sequence:

1. **adr-writer**: Generates initial ADR content
2. **adr-validator**: Validates claims against sources
3. **adr-formatter**: Assigns numbers and formats output

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PLUGIN_DIR/lib/common.sh"

# Parse arguments
decision=""
context=""
sources="."
output_dir="docs/adr"

for arg in "$@"; do
    case "$arg" in
        --decision=*) decision="${arg#--decision=}" ;;
        --context=*) context="${arg#--context=}" ;;
        --sources=*) sources="${arg#--sources=}" ;;
        --output=*) output_dir="${arg#--output=}" ;;
    esac
done

# Validate prerequisites
require_worktree

if [[ -z "$decision" ]]; then
    error_exit "Decision description required. Use --decision=\"...\""
fi

# Ensure output directory exists
root=$(get_worktree_path)
mkdir -p "$root/$output_dir"

info "Generating ADR for decision: $decision"

# Pipeline execution is handled by Claude invoking the agents in sequence:
# 1. bkff:adr-writer - generates initial content
# 2. bkff:adr-validator - validates claims
# 3. bkff:adr-formatter - formats and numbers

# The orchestration is performed by Claude based on this skill's instructions
echo "Pipeline ready. Invoke agents: adr-writer -> adr-validator -> adr-formatter"
```
