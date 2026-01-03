---
description: Generate changelogs from conventional commits with grouping and formatting
argument-hint: [FROM..TO] [--output=FILE] [--format=md|json]
---

## Name
bkff-git:git-changelog

## Synopsis
```
/bkff-git:git-changelog [FROM..TO] [--output=FILE] [--format=md|json] [--version=TAG] [--unreleased] [--full]
```

## Description
The `git-changelog` command generates changelogs from conventional commit messages. It parses commits, groups them by type (Features, Bug Fixes, etc.), and outputs formatted markdown or JSON. Supports version ranges, PR references, and CHANGELOG.md updates.

## Conventional Commit Mapping

| Commit Type | Changelog Section | Emoji |
|-------------|------------------|-------|
| `feat` | Features | ✨ |
| `fix` | Bug Fixes | 🐛 |
| `docs` | Documentation | 📚 |
| `style` | Styling | 💄 |
| `refactor` | Code Refactoring | ♻️ |
| `perf` | Performance | ⚡ |
| `test` | Tests | ✅ |
| `build` | Build System | 📦 |
| `ci` | CI/CD | 👷 |
| `chore` | Chores | 🔧 |
| `revert` | Reverts | ⏪ |

Breaking changes (marked with `!`) are highlighted in a separate section.

## Implementation

### Parse Commit Range
```bash
get_commit_range() {
    local range="$1"
    local from=""
    local to=""

    if [[ -z "$range" ]]; then
        # Default: last tag to HEAD
        from=$(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)
        to="HEAD"
    elif [[ "$range" == *".."* ]]; then
        from="${range%..*}"
        to="${range#*..}"
    else
        # Single ref means from that ref to HEAD
        from="$range"
        to="HEAD"
    fi

    echo "$from $to"
}
```

### Parse Conventional Commits
```bash
parse_commits() {
    local from="$1"
    local to="$2"

    git log "$from..$to" --pretty=format:"%H|%s|%b|%an|%ae|%aI" | while IFS='|' read -r hash subject body author email date; do
        # Parse conventional commit format
        # Pattern: type(scope)!: description
        if [[ "$subject" =~ ^([a-z]+)(\(([^)]+)\))?(!)?\:\ (.+)$ ]]; then
            local type="${BASH_REMATCH[1]}"
            local scope="${BASH_REMATCH[3]}"
            local breaking="${BASH_REMATCH[4]}"
            local description="${BASH_REMATCH[5]}"

            # Extract PR reference from subject or body
            local pr=""
            if [[ "$subject" =~ \(#([0-9]+)\) ]]; then
                pr="${BASH_REMATCH[1]}"
            elif [[ "$body" =~ [Pp]ull\ [Rr]equest\ #([0-9]+) ]]; then
                pr="${BASH_REMATCH[1]}"
            fi

            # Extract issue references
            local issues=""
            if [[ "$body" =~ [Cc]loses?:?\ *(#[0-9]+|tool-[a-z0-9]+) ]]; then
                issues="${BASH_REMATCH[1]}"
            fi

            # Output parsed commit
            echo "${type}|${scope}|${breaking}|${description}|${hash:0:7}|${pr}|${issues}|${author}"
        fi
    done
}
```

### Group by Type
```bash
group_commits() {
    local commits="$1"

    declare -A groups
    declare -a breaking_changes

    while IFS='|' read -r type scope breaking desc hash pr issues author; do
        [[ -z "$type" ]] && continue

        local entry="- ${desc}"
        [[ -n "$scope" ]] && entry="- **${scope}:** ${desc}"
        [[ -n "$pr" ]] && entry="${entry} ([#${pr}](../../pull/${pr}))"
        entry="${entry} (${hash})"

        if [[ -n "$breaking" ]]; then
            breaking_changes+=("$entry")
        fi

        groups["$type"]+="${entry}\n"
    done <<< "$commits"

    # Output grouped results
    echo "BREAKING:${breaking_changes[*]}"
    for type in feat fix docs style refactor perf test build ci chore revert; do
        [[ -n "${groups[$type]}" ]] && echo "${type}:${groups[$type]}"
    done
}
```

### Generate Markdown Output
```bash
generate_markdown() {
    local version="$1"
    local date="$2"
    local grouped="$3"

    # Header
    if [[ -n "$version" ]]; then
        echo "## [${version}] - ${date}"
    else
        echo "## [Unreleased]"
    fi
    echo ""

    # Section headers mapping
    declare -A headers=(
        ["BREAKING"]="⚠️ BREAKING CHANGES"
        ["feat"]="✨ Features"
        ["fix"]="🐛 Bug Fixes"
        ["docs"]="📚 Documentation"
        ["style"]="💄 Styling"
        ["refactor"]="♻️ Code Refactoring"
        ["perf"]="⚡ Performance"
        ["test"]="✅ Tests"
        ["build"]="📦 Build System"
        ["ci"]="👷 CI/CD"
        ["chore"]="🔧 Chores"
        ["revert"]="⏪ Reverts"
    )

    # Output sections
    while IFS=':' read -r type entries; do
        [[ -z "$entries" ]] && continue

        echo "### ${headers[$type]:-$type}"
        echo ""
        echo -e "$entries"
        echo ""
    done <<< "$grouped"
}
```

### Generate JSON Output
```bash
generate_json() {
    local version="$1"
    local date="$2"
    local from="$3"
    local to="$4"

    echo "{"
    echo "  \"version\": \"${version:-unreleased}\","
    echo "  \"date\": \"${date}\","
    echo "  \"range\": \"${from}..${to}\","
    echo '  "changes": [',

    # Parse and output as JSON
    git log "$from..$to" --pretty=format:'{
    "hash": "%H",
    "short": "%h",
    "subject": "%s",
    "author": "%an",
    "date": "%aI"
  },' | sed '$ s/,$//'

    echo '  ]',
    echo "}"
}
```

### Update CHANGELOG.md
```bash
update_changelog_file() {
    local new_content="$1"
    local changelog_file="${2:-CHANGELOG.md}"

    if [[ ! -f "$changelog_file" ]]; then
        # Create new file with header
        cat > "$changelog_file" << 'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

EOF
    fi

    # Insert new content after header
    local header_end=$(grep -n "^## \[" "$changelog_file" | head -1 | cut -d: -f1)

    if [[ -z "$header_end" ]]; then
        # No existing versions, append to end
        echo "" >> "$changelog_file"
        echo "$new_content" >> "$changelog_file"
    else
        # Insert before first version
        local line=$((header_end - 1))
        head -n "$line" "$changelog_file" > "${changelog_file}.tmp"
        echo "$new_content" >> "${changelog_file}.tmp"
        echo "" >> "${changelog_file}.tmp"
        tail -n +"$header_end" "$changelog_file" >> "${changelog_file}.tmp"
        mv "${changelog_file}.tmp" "$changelog_file"
    fi

    echo "Updated: $changelog_file"
}
```

## Return Value

- **Format**: Markdown or JSON changelog
- **Includes**:
  - Version header with date
  - Grouped changes by type
  - Commit hashes (short)
  - PR references (linked)
  - Breaking changes section

## Examples

1. **Generate changelog since last tag**:
   ```
   /bkff-git:git-changelog
   ```
   Shows changes from last tag to HEAD.

2. **Specific version range**:
   ```
   /bkff-git:git-changelog v1.0.0..v1.1.0
   ```

3. **From specific commit/tag to HEAD**:
   ```
   /bkff-git:git-changelog v1.0.0
   ```

4. **Generate for new version**:
   ```
   /bkff-git:git-changelog --version=v1.2.0
   ```
   Adds version header with today's date.

5. **Output to file**:
   ```
   /bkff-git:git-changelog --output=CHANGELOG.md --version=v1.2.0
   ```
   Prepends to CHANGELOG.md.

6. **JSON format**:
   ```
   /bkff-git:git-changelog --format=json
   ```

7. **Unreleased changes**:
   ```
   /bkff-git:git-changelog --unreleased
   ```
   Labels as [Unreleased] instead of version.

8. **Full changelog from beginning**:
   ```
   /bkff-git:git-changelog --full
   ```
   Generates complete changelog for all tags.

## Arguments

- `FROM..TO`: Commit range (default: last tag to HEAD)
- `--version=TAG`: Version label for the header (e.g., v1.2.0)
- `--output=FILE`: Write to file (prepends if exists)
- `--format=md|json`: Output format (default: md)
- `--unreleased`: Label as [Unreleased]
- `--full`: Generate full changelog for all versions

## Output Format

### Markdown (default)
```markdown
## [v1.2.0] - 2024-01-15

### ⚠️ BREAKING CHANGES

- **api:** change authentication flow ([#42](../../pull/42)) (a1b2c3d)

### ✨ Features

- **auth:** add OAuth2 support ([#40](../../pull/40)) (b2c3d4e)
- implement rate limiting (c3d4e5f)

### 🐛 Bug Fixes

- **login:** resolve timeout issue ([#41](../../pull/41)) (d4e5f6g)

### 📚 Documentation

- update API reference (e5f6g7h)
```

### JSON
```json
{
  "version": "v1.2.0",
  "date": "2024-01-15",
  "range": "v1.1.0..v1.2.0",
  "changes": [
    {
      "type": "feat",
      "scope": "auth",
      "description": "add OAuth2 support",
      "hash": "b2c3d4e",
      "pr": 40,
      "breaking": false
    }
  ]
}
```

## Full Changelog Generation

With `--full`, generates sections for each tag:

```markdown
# Changelog

## [v1.2.0] - 2024-01-15
...

## [v1.1.0] - 2024-01-01
...

## [v1.0.0] - 2023-12-15
...
```

## Keep a Changelog Format

The output follows [Keep a Changelog](https://keepachangelog.com/) conventions:

- Versions in reverse chronological order
- [Unreleased] section at top for upcoming changes
- Sections: Added, Changed, Deprecated, Removed, Fixed, Security
- ISO 8601 date format (YYYY-MM-DD)

## Integration with Releases

Typical release workflow:
```bash
# 1. Generate changelog for new version
/bkff-git:git-changelog --version=v1.2.0 --output=CHANGELOG.md

# 2. Commit changelog
/bkff-git:git-commit docs: update changelog for v1.2.0

# 3. Tag release
git tag -a v1.2.0 -m "Release v1.2.0"

# 4. Push with tags
git push --follow-tags
```

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| No tags found | No version tags exist | Specify range manually or use `--unreleased` |
| No conventional commits | Commits don't follow format | Only conventional commits are included |
| Empty changelog | No matching commits in range | Check commit range is correct |

## Non-Conventional Commits

Commits not following conventional format are:
- Excluded from the changelog by default
- Can be included with `--include-all` (as "Other Changes")

## Related Commands

- `/bkff-git:git-commit` - Create conventional commits
- `/bkff-git:git-pr` - Create PRs (provides PR references)

## Notes

- Only parses conventional commit format
- Breaking changes always appear first
- Scopes are displayed in bold
- PR numbers are auto-linked to GitHub
- Empty sections are omitted
