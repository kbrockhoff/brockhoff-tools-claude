---
description: Create pull requests with templates, auto-populated content, and reviewer assignment
argument-hint: [--title=TITLE] [--draft] [--base=BRANCH]
---

## Name
bkff-git:git-pr

## Synopsis
```
/bkff-git:git-pr [--title=TITLE] [--base=BRANCH] [--draft] [--reviewer=USER] [--label=LABEL] [--web]
```

## Description
The `git-pr` command creates GitHub pull requests with intelligent defaults. It uses PR templates, auto-populates descriptions from commit messages, links beads issues, assigns reviewers from CODEOWNERS, and sets labels based on commit types.

This command requires the GitHub CLI (`gh`) to be installed and authenticated. See the `github-cli` skill for setup instructions.

## Implementation

1. **Verify Prerequisites**: Check GitHub CLI and repository state
   ```bash
   # Check gh is ready (uses github-cli skill)
   gh auth status

   # Ensure we're on a feature branch (not main/master)
   current_branch=$(git branch --show-current)
   if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
       echo "Error: Cannot create PR from main/master branch"
       exit 1
   fi

   # Check for unpushed commits
   git status --porcelain
   ```

2. **Determine Base Branch**: Find target branch for PR
   ```bash
   # Use --base if provided, otherwise detect default
   if [[ -z "$base" ]]; then
       base=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
   fi
   ```

3. **Gather Commit Information**: Collect commits for PR description
   ```bash
   # Get commits unique to this branch
   git log ${base}..HEAD --oneline

   # Get commit messages for body
   git log ${base}..HEAD --pretty=format:"- %s"

   # Extract conventional commit types
   git log ${base}..HEAD --pretty=format:"%s" | grep -oE "^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)"
   ```

4. **Generate Title**: Create PR title from commits or branch
   ```bash
   # If --title not provided:
   # Option 1: Use first commit message if single commit
   commit_count=$(git rev-list --count ${base}..HEAD)
   if [[ "$commit_count" == "1" ]]; then
       title=$(git log -1 --pretty=format:"%s")
   else
       # Option 2: Generate from branch name
       # feature/add-auth -> "Add auth"
       title=$(echo "$current_branch" | sed 's|.*/||' | tr '-' ' ' | sed 's/.*/\u&/')
   fi
   ```

5. **Load PR Template**: Use repository template if available
   ```bash
   # Check for PR template
   template_paths=(
       ".github/pull_request_template.md"
       ".github/PULL_REQUEST_TEMPLATE.md"
       "docs/pull_request_template.md"
       "PULL_REQUEST_TEMPLATE.md"
   )

   for path in "${template_paths[@]}"; do
       if [[ -f "$path" ]]; then
           template_content=$(cat "$path")
           break
       fi
   done
   ```

6. **Build PR Body**: Populate template with commit info
   ```
   ## Summary
   <Generated from commits or template>

   ## Changes
   - commit message 1
   - commit message 2

   ## Linked Issues
   Closes tool-xxx (if beads issues referenced)

   ## Test Plan
   <From template or placeholder>
   ```

7. **Detect Beads Issues**: Link related issues
   ```bash
   # Scan commits for beads references
   git log ${base}..HEAD --pretty=format:"%s %b" | grep -oE "tool-[a-z0-9]+"

   # Add to PR body
   # Closes tool-xxx
   ```

8. **Determine Reviewers**: Parse CODEOWNERS for suggestions
   ```bash
   # Get changed files
   changed_files=$(git diff --name-only ${base}..HEAD)

   # Parse CODEOWNERS (if exists)
   if [[ -f ".github/CODEOWNERS" ]]; then
       # Match files to owners
       # Extract reviewers
   fi

   # Use --reviewer if provided
   ```

9. **Determine Labels**: Set labels from commit types
   | Commit Type | Label |
   |-------------|-------|
   | feat | enhancement |
   | fix | bug |
   | docs | documentation |
   | test | testing |
   | perf | performance |
   | refactor | refactor |
   | chore | chore |

10. **Push Branch**: Ensure branch is pushed
    ```bash
    # Check if branch is pushed
    if ! git rev-parse --verify origin/${current_branch} &>/dev/null; then
        git push -u origin ${current_branch}
    fi
    ```

11. **Create Pull Request**: Execute gh pr create
    ```bash
    gh pr create \
        --title "$title" \
        --body "$body" \
        --base "$base" \
        ${draft:+--draft} \
        ${reviewers:+--reviewer "$reviewers"} \
        ${labels:+--label "$labels"}
    ```

12. **Return PR URL**: Show created PR details
    ```bash
    gh pr view --json url,number --jq '"\(.url) (#\(.number))"'
    ```

## Return Value

- **Format**: PR creation confirmation
- **Includes**:
  - PR number and URL
  - Title
  - Base and head branches
  - Assigned reviewers
  - Applied labels
  - Draft status

## Examples

1. **Basic PR creation**:
   ```
   /bkff-git:git-pr
   ```
   Creates PR with auto-generated title and description from commits.

2. **With custom title**:
   ```
   /bkff-git:git-pr --title="Add user authentication feature"
   ```

3. **Draft PR**:
   ```
   /bkff-git:git-pr --draft --title="WIP: Implementing new API"
   ```
   Creates draft PR that can't be merged until marked ready.

4. **Specify base branch**:
   ```
   /bkff-git:git-pr --base=develop
   ```
   Creates PR targeting `develop` instead of default branch.

5. **With reviewers and labels**:
   ```
   /bkff-git:git-pr --reviewer=alice,bob --label=enhancement,needs-review
   ```

6. **Open in browser after creation**:
   ```
   /bkff-git:git-pr --web
   ```
   Creates PR and opens it in default browser.

7. **Full example**:
   ```
   /bkff-git:git-pr --title="feat: add OAuth2 support" --base=main --reviewer=security-team --label=enhancement,security --draft
   ```

## Arguments

- `--title=TITLE`: (Optional) PR title. Auto-generated from commits if not provided.
- `--base=BRANCH`: (Optional) Target branch. Defaults to repository's default branch.
- `--draft`: (Optional) Create as draft PR.
- `--reviewer=USER`: (Optional) Request review from users. Comma-separated for multiple.
- `--label=LABEL`: (Optional) Add labels. Comma-separated for multiple.
- `--web`: (Optional) Open PR in browser after creation.

## PR Body Template

When no template exists, uses this default structure:

```markdown
## Summary
Brief description of changes.

## Changes
- List of commits

## Linked Issues
Closes #issue (if applicable)

## Test Plan
- [ ] Unit tests pass
- [ ] Manual testing completed

---
Generated with bkff-git
```

## Label Mapping

| Commit Type | GitHub Label |
|-------------|-------------|
| `feat` | `enhancement` |
| `fix` | `bug` |
| `docs` | `documentation` |
| `test` | `testing` |
| `perf` | `performance` |
| `refactor` | `refactor` |
| `build` | `build` |
| `ci` | `ci/cd` |
| `chore` | `chore` |

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| Not on feature branch | On main/master | Create and checkout a feature branch |
| No commits to PR | No commits ahead of base | Make commits before creating PR |
| gh not authenticated | Missing auth | Run `gh auth login` |
| Branch not pushed | Local-only branch | Branch will be auto-pushed |
| No write access | Repository permissions | Request write access or fork |
| PR already exists | Duplicate PR | Use `gh pr view` to see existing PR |

## CODEOWNERS Integration

If `.github/CODEOWNERS` exists, reviewers are suggested based on changed files:

```
# .github/CODEOWNERS example
*.ts @typescript-team
/docs/ @docs-team
/src/auth/ @security-team
```

Changed files are matched against patterns to suggest appropriate reviewers.

## Workflow Integration

Recommended workflow:
```bash
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Make changes and commit
git add .
/bkff-git:git-commit feat: implement feature

# 3. Create PR
/bkff-git:git-pr

# 4. After review and approval
gh pr merge --squash --delete-branch
```

## Related Commands

- `/bkff-git:git-status` - Check repository state before PR
- `/bkff-git:git-commit` - Create commits with conventional format
- `/bkff-git:git-branch` - Create feature branches

## Notes

- Always verify CI checks pass before requesting review
- Use draft PRs for work-in-progress
- Link beads issues in commits for automatic tracking
- CODEOWNERS suggestions are advisory; you can override with `--reviewer`
