---
name: genreadme
description: Generate or update comprehensive project README based on codebase analysis
invocation: /bkff:genreadme
arguments:
  - name: update
    description: Update existing README preserving marked sections
    required: false
    default: "false"
  - name: sections
    description: Comma-separated list of sections to include (default: all)
    required: false
  - name: output
    description: Output file path (default: README.md)
    required: false
    default: README.md
---

# Generate Project README

Generates or updates a comprehensive project README based on codebase analysis, specifications, and existing documentation. Integrates with ADRs and other project artifacts.

## Usage

```bash
# Generate new README
/bkff:genreadme

# Update existing README preserving custom sections
/bkff:genreadme --update=true

# Generate specific sections only
/bkff:genreadme --sections="overview,installation,usage"

# Custom output location
/bkff:genreadme --output=docs/PROJECT.md
```

## Section Generation Logic

The skill analyzes the codebase to generate appropriate sections:

```
┌─────────────────────────────────────────────────────────────┐
│                 SECTION GENERATION FLOW                      │
└─────────────────────────────────────────────────────────────┘

┌────────────────────────────────────┐
│         ANALYZE CODEBASE           │
├────────────────────────────────────┤
│ • Package files (package.json,     │
│   Cargo.toml, pyproject.toml)      │
│ • Source structure                 │
│ • Existing documentation           │
│ • CI/CD configuration              │
│ • License file                     │
└─────────────┬──────────────────────┘
              │
              ▼
┌────────────────────────────────────┐
│       DETERMINE SECTIONS           │
├────────────────────────────────────┤
│ Based on what's found:             │
│ • Has CLI → Usage section          │
│ • Has API → API Reference          │
│ • Has tests → Testing section      │
│ • Has Docker → Docker section      │
│ • Has ADRs → Architecture section  │
└─────────────┬──────────────────────┘
              │
              ▼
┌────────────────────────────────────┐
│        GENERATE CONTENT            │
├────────────────────────────────────┤
│ For each section:                  │
│ 1. Extract relevant info           │
│ 2. Generate markdown               │
│ 3. Add examples from codebase      │
│ 4. Link to related files           │
└────────────────────────────────────┘
```

### Section Detection Rules

| Section | Detected When |
|---------|---------------|
| Overview | Always included (from package description or first comment) |
| Installation | package.json, requirements.txt, Cargo.toml, go.mod found |
| Usage | CLI detected, bin field, main entry point |
| API Reference | Public exports, documented interfaces |
| Configuration | Config files, environment variables |
| Development | Makefile, scripts, contributing guidelines |
| Testing | Test files, test scripts, CI configuration |
| Architecture | docs/adr/ directory exists |
| Contributing | CONTRIBUTING.md exists or detected patterns |
| License | LICENSE file exists |

### Section Order

```markdown
1. Title & Badges
2. Overview/Description
3. Table of Contents (if > 5 sections)
4. Installation
5. Quick Start
6. Usage
7. Configuration
8. API Reference
9. Architecture (with ADR links)
10. Development
11. Testing
12. Contributing
13. License
14. Acknowledgments
```

## --update Flag with Preserve Markers

When `--update=true`, the skill preserves sections marked for manual maintenance:

### Preserve Markers

```markdown
<!-- bkff:preserve:start -->
This section is manually maintained and will not be modified.
Custom content goes here.
<!-- bkff:preserve:end -->
```

### Named Sections

```markdown
<!-- bkff:preserve:custom-section:start -->
## My Custom Section

This entire section is preserved during updates.
<!-- bkff:preserve:custom-section:end -->
```

### Update Behavior

```
┌─────────────────────────────────────────────────────────────┐
│                    UPDATE MODE                               │
└─────────────────────────────────────────────────────────────┘

Original README:
┌────────────────────────────────────┐
│ # Project Name                     │  ← Will be updated
│                                    │
│ ## Overview                        │  ← Will be updated
│ Auto-generated content...          │
│                                    │
│ <!-- bkff:preserve:start -->       │
│ ## Special Thanks                  │  ← PRESERVED
│ Custom acknowledgments...          │
│ <!-- bkff:preserve:end -->         │
│                                    │
│ ## Installation                    │  ← Will be updated
│ Old installation steps...          │
└────────────────────────────────────┘

After Update:
┌────────────────────────────────────┐
│ # Project Name (v2.0)              │  ← Updated
│                                    │
│ ## Overview                        │  ← Updated
│ New auto-generated content...      │
│                                    │
│ <!-- bkff:preserve:start -->       │
│ ## Special Thanks                  │  ← UNCHANGED
│ Custom acknowledgments...          │
│ <!-- bkff:preserve:end -->         │
│                                    │
│ ## Installation                    │  ← Updated
│ New installation steps...          │
│ Now includes Docker option...      │
└────────────────────────────────────┘
```

### Preservation Rules

1. **Exact match**: Content between markers is preserved exactly
2. **Position maintained**: Preserved sections stay in their relative position
3. **Nested markers**: Not supported (outer marker takes precedence)
4. **Orphaned markers**: Warned but content still preserved
5. **New preserved sections**: Added to end if not in generation template

## ADR Section Linking

When ADRs exist in `docs/adr/`, an Architecture section is generated:

### ADR Discovery

```bash
# Scans for ADRs
docs/adr/
├── 0001-use-postgresql.md
├── 0002-implement-event-sourcing.md
├── 0003-adopt-kubernetes.md
└── README.md  # Index (optional)
```

### Generated Architecture Section

```markdown
## Architecture

This project's architecture is documented through Architectural Decision Records (ADRs).

### Key Decisions

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-0001](docs/adr/0001-use-postgresql.md) | Use PostgreSQL for Primary Database | Accepted |
| [ADR-0002](docs/adr/0002-implement-event-sourcing.md) | Implement Event Sourcing | Accepted |
| [ADR-0003](docs/adr/0003-adopt-kubernetes.md) | Adopt Kubernetes for Deployment | Proposed |

For the complete list of architectural decisions, see [docs/adr/](docs/adr/).
```

### ADR Parsing

Each ADR is parsed to extract:
- **Number**: From filename (NNNN-title.md)
- **Title**: From H1 heading
- **Status**: From frontmatter or status line
- **Date**: From frontmatter or content

```
┌─────────────────────────────────────────────────────────────┐
│                   ADR INTEGRATION                            │
└─────────────────────────────────────────────────────────────┘

ADR File:
┌────────────────────────────────────┐
│ # ADR-0001: Use PostgreSQL         │ → Title
│                                    │
│ * Status: accepted                 │ → Status
│ * Date: 2024-01-15                │ → Date
│                                    │
│ ## Context                         │
│ ...                                │ → Summary (first paragraph)
└────────────────────────────────────┘
              │
              ▼
README Architecture Section:
┌────────────────────────────────────┐
│ ## Architecture                    │
│                                    │
│ ### Key Decisions                  │
│ | ADR | Title | Status |           │
│ |-----|-------|--------|           │
│ | 0001 | Use PostgreSQL | ✓ |      │ ← Linked entry
└────────────────────────────────────┘
```

## Available Sections

### `overview`
Project description from package file or first file comment.

### `installation`
Package manager commands, system requirements, prerequisites.

### `quickstart`
Minimal example to get started quickly.

### `usage`
Detailed usage examples, CLI commands, API examples.

### `configuration`
Environment variables, config files, options.

### `api`
Public API documentation (if detected).

### `architecture`
ADR links, system diagrams (if available).

### `development`
Setup for contributors, build commands.

### `testing`
How to run tests, coverage.

### `contributing`
Link to CONTRIBUTING.md or generated guidelines.

### `license`
License information.

## Output

### Success (New README)

```
Info: Generating README for project

README Generation
─────────────────────────────────────
  Project:    my-awesome-project
  Type:       Node.js (npm)
  Output:     README.md

Sections Generated:
  ✓ Overview (from package.json)
  ✓ Installation
  ✓ Quick Start
  ✓ Usage (CLI detected)
  ✓ Configuration (3 env vars found)
  ✓ Architecture (4 ADRs linked)
  ✓ Development
  ✓ Testing (jest)
  ✓ License (MIT)

✓ README generated successfully

Output: README.md (287 lines)
```

### Success (Update)

```
Info: Updating README

README Update
─────────────────────────────────────
  Existing:   README.md (312 lines)
  Mode:       Update with preserve

Sections:
  ↻ Overview - Updated
  ↻ Installation - Updated (added Docker)
  ✓ Quick Start - Preserved (manual)
  ↻ Usage - Updated
  ↻ Architecture - Updated (1 new ADR)
  ✓ Acknowledgments - Preserved (manual)

✓ README updated successfully

Changes: 4 sections updated, 2 preserved
Output: README.md (328 lines)
```

## Requirements

- Git repository with valid worktree
- Write access to output location
- At least one parseable project file (package.json, etc.)

## Exit Codes

- `0` - README generated/updated successfully
- `1` - Generation failed
- `2` - No project metadata found
- `3` - Output location not writable

## Related Skills

- `/bkff:writeadr` - Write architectural decision records
- `/bkff:chkcompliance` - Check repository compliance

## Implementation

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PLUGIN_DIR/lib/common.sh"

# Parse arguments
update_mode="false"
sections=""
output_file="README.md"

for arg in "$@"; do
    case "$arg" in
        --update=*) update_mode="${arg#--update=}" ;;
        --sections=*) sections="${arg#--sections=}" ;;
        --output=*) output_file="${arg#--output=}" ;;
    esac
done

# Validate prerequisites
require_worktree

root=$(get_worktree_path)
output_path="$root/$output_file"

info "Generating README for project"

# Detect project type
detect_project_type() {
    if [[ -f "$root/package.json" ]]; then
        echo "nodejs"
    elif [[ -f "$root/pyproject.toml" ]] || [[ -f "$root/setup.py" ]]; then
        echo "python"
    elif [[ -f "$root/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$root/go.mod" ]]; then
        echo "go"
    elif [[ -f "$root/pom.xml" ]] || [[ -f "$root/build.gradle" ]]; then
        echo "java"
    else
        echo "unknown"
    fi
}

# Check for ADRs
has_adrs() {
    [[ -d "$root/docs/adr" ]] && ls "$root/docs/adr"/*.md &>/dev/null
}

# Get existing preserved sections if updating
if [[ "$update_mode" == "true" && -f "$output_path" ]]; then
    info "Update mode: preserving marked sections"
fi

# README generation is performed by Claude analyzing the codebase
# and generating appropriate markdown content
echo "Analysis ready. Generate README content based on project structure."
```
