---
name: gentests
description: Generate unit tests for code based on structure and acceptance criteria
invocation: /bkff:gentests
arguments:
  - name: file
    description: Source file or directory to generate tests for
    required: true
  - name: framework
    description: Test framework to use (auto-detected if not specified)
    required: false
  - name: update
    description: Update existing tests instead of creating new ones
    required: false
    default: "false"
  - name: coverage
    description: Target coverage percentage (default: 80)
    required: false
    default: "80"
---

# Generate Unit Tests

Generates unit tests for newly implemented code based on code structure, acceptance criteria, and testing best practices. Automatically detects the appropriate test framework based on the project's existing configuration.

## Usage

```bash
# Generate tests for a specific file
/bkff:gentests --file=src/lib/compliance.sh

# Generate tests for a directory
/bkff:gentests --file=src/services/

# Specify test framework
/bkff:gentests --file=src/app.py --framework=pytest

# Update existing tests to cover new code paths
/bkff:gentests --file=src/utils.ts --update=true

# Target specific coverage
/bkff:gentests --file=lib/parser.go --coverage=90
```

## Supported Languages and Frameworks

| Language | Detected By | Default Framework | Supported Frameworks |
|----------|-------------|-------------------|---------------------|
| Bash/Shell | `.sh`, `.bash` | bats | bats, shunit2 |
| Python | `.py` | pytest | pytest, unittest |
| JavaScript | `.js`, `.mjs` | jest | jest, mocha, vitest |
| TypeScript | `.ts`, `.tsx` | jest | jest, vitest |
| Go | `.go` | go test | go test |
| Rust | `.rs` | cargo test | cargo test |
| Java | `.java` | junit | junit4, junit5, testng |
| Ruby | `.rb` | rspec | rspec, minitest |

### Framework Detection Logic

```
┌─────────────────────────────────────────────────────────────┐
│                FRAMEWORK DETECTION                           │
└─────────────────────────────────────────────────────────────┘

1. Check explicit --framework argument
   └── Use specified framework

2. Check project configuration files:
   ├── package.json → jest.config, vitest.config
   ├── pyproject.toml → pytest section
   ├── Cargo.toml → Rust project
   ├── go.mod → Go module
   ├── pom.xml / build.gradle → JUnit
   └── Gemfile → rspec/minitest

3. Check existing test files:
   ├── *.test.js, *.spec.js → jest/mocha
   ├── test_*.py, *_test.py → pytest/unittest
   ├── *_test.go → go test
   └── *_spec.rb → rspec

4. Fall back to language default
```

## Test Generation Process

```
┌─────────────────────────────────────────────────────────────┐
│                   TEST GENERATION FLOW                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────┐
│   Analyze Source    │
│   - Parse functions │
│   - Extract types   │
│   - Find exports    │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  Check Acceptance   │
│  - Find beads issue │
│  - Extract criteria │
│  - Map to tests     │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  Generate Tests     │
│  - Unit tests       │
│  - Edge cases       │
│  - Error handling   │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  Validate Tests     │
│  - Syntax check     │
│  - Import check     │
│  - Execute tests    │
└─────────────────────┘
```

## Test Structure

Generated tests follow best practices for each framework:

### Bash (bats)

```bash
#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    source "${BATS_TEST_DIRNAME}/../lib/compliance.sh"
}

@test "check_codeowners returns success when CODEOWNERS exists" {
    # Arrange
    mkdir -p .github
    echo "* @owner" > .github/CODEOWNERS

    # Act & Assert
    run check_codeowners
    assert_success
}

@test "check_codeowners returns failure when CODEOWNERS missing" {
    # Act & Assert
    run check_codeowners
    assert_failure
}
```

### Python (pytest)

```python
import pytest
from src.parser import parse_config, ConfigError

class TestParseConfig:
    """Tests for parse_config function."""

    def test_parse_valid_config(self, tmp_path):
        """Should parse valid configuration file."""
        # Arrange
        config_file = tmp_path / "config.yaml"
        config_file.write_text("key: value")

        # Act
        result = parse_config(config_file)

        # Assert
        assert result["key"] == "value"

    def test_parse_missing_file_raises_error(self):
        """Should raise ConfigError for missing file."""
        with pytest.raises(ConfigError, match="not found"):
            parse_config("nonexistent.yaml")
```

### TypeScript (jest)

```typescript
import { validateInput, ValidationError } from '../src/validator';

describe('validateInput', () => {
  describe('with valid input', () => {
    it('should return validated data', () => {
      // Arrange
      const input = { name: 'test', value: 42 };

      // Act
      const result = validateInput(input);

      // Assert
      expect(result).toEqual({ name: 'test', value: 42 });
    });
  });

  describe('with invalid input', () => {
    it('should throw ValidationError for missing name', () => {
      // Arrange
      const input = { value: 42 };

      // Act & Assert
      expect(() => validateInput(input)).toThrow(ValidationError);
    });
  });
});
```

## --update Flag Behavior

When `--update=true` is specified:

1. **Find Existing Tests**: Locate existing test files for the source
2. **Analyze Coverage Gaps**: Identify untested code paths
3. **Add New Test Cases**: Generate tests for uncovered scenarios
4. **Preserve Existing Tests**: Don't modify or remove existing tests
5. **Maintain Style**: Match existing test file style and patterns

```
┌─────────────────────────────────────────────────────────────┐
│                    UPDATE MODE                               │
└─────────────────────────────────────────────────────────────┘

Existing Tests:
┌────────────────────────┐
│ test_function_a() ✓    │
│ test_function_b() ✓    │
│ test_edge_case_1() ✓   │
└────────────────────────┘
          │
          │ Analyze source changes
          ▼
New Code Paths Found:
┌────────────────────────┐
│ function_c() - NEW     │
│ error_handler() - NEW  │
└────────────────────────┘
          │
          │ Generate additions
          ▼
Updated Tests:
┌────────────────────────┐
│ test_function_a() ✓    │  (preserved)
│ test_function_b() ✓    │  (preserved)
│ test_edge_case_1() ✓   │  (preserved)
│ test_function_c() NEW  │  (added)
│ test_error_handler() N │  (added)
└────────────────────────┘
```

## Unsupported Language Handling

When a language is not supported or cannot be auto-detected:

```
Warning: Unable to generate tests for 'src/main.xyz'

Reason: Unsupported language or unknown file extension

Suggestions:
  1. Specify a test framework: --framework=<name>
  2. Check if the file extension is correct
  3. Manual test generation may be required

Supported extensions: .sh, .bash, .py, .js, .mjs, .ts, .tsx, .go, .rs, .java, .rb
```

The skill will:
1. Log a warning with the file path
2. Skip the unsupported file
3. Continue processing other files if a directory was specified
4. Return exit code 0 if some files were processed, 4 if none were

## Output

### Success

```
Info: Generating tests for: src/lib/compliance.sh

Test Generation
─────────────────────────────────────
  Source:     src/lib/compliance.sh
  Framework:  bats
  Functions:  12 found

Generated Tests:
  File: tests/test-compliance.sh
  Tests: 24 test cases
  Coverage: 85% (estimated)

✓ Tests generated successfully

Run tests with: bats tests/test-compliance.sh
```

### Partial Success

```
Info: Generating tests for: src/

Test Generation
─────────────────────────────────────
  Directory:  src/
  Files:      5 source files

Results:
  ✓ src/parser.py → tests/test_parser.py (12 tests)
  ✓ src/validator.py → tests/test_validator.py (8 tests)
  ⚠ src/legacy.py → Skipped (complex dependencies)
  ✓ src/utils.py → tests/test_utils.py (15 tests)
  ✗ src/config.xyz → Unsupported language

Summary: 3 files processed, 1 skipped, 1 unsupported
```

## Requirements

- Git repository with valid worktree
- Source files in supported languages
- Write access to test directory
- Test framework installed (for validation)

## Exit Codes

- `0` - Tests generated successfully
- `1` - Test generation failed
- `2` - Source file not found
- `3` - Test framework not detected
- `4` - Unsupported language (all files)

## Related Skills

- `/bkff:verifytask` - Verify task completion including tests
- `/bkff:chkcompliance` - Check repository compliance

## Implementation

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PLUGIN_DIR/lib/common.sh"

# Parse arguments
source_file=""
framework=""
update_mode="false"
target_coverage="80"

for arg in "$@"; do
    case "$arg" in
        --file=*) source_file="${arg#--file=}" ;;
        --framework=*) framework="${arg#--framework=}" ;;
        --update=*) update_mode="${arg#--update=}" ;;
        --coverage=*) target_coverage="${arg#--coverage=}" ;;
    esac
done

# Validate prerequisites
require_worktree

if [[ -z "$source_file" ]]; then
    error_exit "Source file required. Use --file=<path>"
fi

root=$(get_worktree_path)
full_path="$root/$source_file"

if [[ ! -e "$full_path" ]]; then
    error_exit "Source not found: $source_file"
fi

info "Generating tests for: $source_file"

# Detect language and framework
detect_language() {
    local file="$1"
    case "${file##*.}" in
        sh|bash) echo "bash" ;;
        py) echo "python" ;;
        js|mjs) echo "javascript" ;;
        ts|tsx) echo "typescript" ;;
        go) echo "go" ;;
        rs) echo "rust" ;;
        java) echo "java" ;;
        rb) echo "ruby" ;;
        *) echo "unknown" ;;
    esac
}

detect_framework() {
    local lang="$1"
    case "$lang" in
        bash) echo "bats" ;;
        python) echo "pytest" ;;
        javascript|typescript) echo "jest" ;;
        go) echo "gotest" ;;
        rust) echo "cargo" ;;
        java) echo "junit" ;;
        ruby) echo "rspec" ;;
        *) echo "" ;;
    esac
}

# Test generation is performed by Claude analyzing the source
# and generating appropriate test code based on the detected framework
echo "Analysis ready. Generate tests using detected framework."
```
