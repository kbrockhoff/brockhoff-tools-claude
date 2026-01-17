# Feature Specification: Git Lifecycle Plugin for Claude Code

**Feature Branch**: `001-git-lifecycle-plugin`
**Created**: 2026-01-10
**Status**: Draft
**Input**: User description: "Create a Claude plugin for Git / GitHub lifecycle operations with five commands for branch management, committing, syncing, PR management, and status reporting in git worktree environments."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Check Development Status (Priority: P1)

A developer wants to quickly understand the current state of their work before deciding what action to take next. They invoke the status command to see uncommitted changes, the last commit, any in-progress beads tasks, and whether a PR exists for the current branch.

**Why this priority**: This is the most fundamental operation - developers need situational awareness before taking any other action. It informs all subsequent workflow decisions and has no side effects.

**Independent Test**: Can be fully tested by running the status command in a git worktree with various states (clean, dirty, with/without PR) and verifying the output accurately reflects the current state.

**Acceptance Scenarios**:

1. **Given** a git worktree with uncommitted changes, **When** user invokes `/bkff:git-st`, **Then** the system displays a summary of staged and unstaged changes
2. **Given** a git worktree with a clean working directory, **When** user invokes `/bkff:git-st`, **Then** the system indicates no uncommitted changes and shows the last commit
3. **Given** a branch with an existing pull request, **When** user invokes `/bkff:git-st`, **Then** the system displays the PR number, title, and status
4. **Given** a branch with in-progress beads tasks, **When** user invokes `/bkff:git-st`, **Then** the system displays the current task information

---

### User Story 2 - Create Feature Branch (Priority: P2)

A developer wants to start work on a new beads issue. They invoke the branch command with the issue ID, and the system automatically determines the branch type (feature, bugfix, or hotfix), creates a new worktree with the branch, pushes it to origin, and initializes the beads database for tracking.

**Why this priority**: Creating a properly configured branch is the starting point for any new work item. Without this, no other workflow commands can function correctly.

**Independent Test**: Can be fully tested by providing a beads issue ID and verifying that a new worktree is created with the correct branch prefix, pushed to origin, and has beads initialized.

**Acceptance Scenarios**:

1. **Given** a beads issue of type "feature", **When** user invokes `/bkff:git-branch <issue-id>`, **Then** the system creates a branch with prefix `feature/` in a new worktree directory
2. **Given** a beads issue of type "bug", **When** user invokes `/bkff:git-branch <issue-id>`, **Then** the system creates a branch with prefix `bugfix/`
3. **Given** a beads issue marked as urgent/critical, **When** user invokes `/bkff:git-branch <issue-id>`, **Then** the system creates a branch with prefix `hotfix/`
4. **Given** a successful branch creation, **When** the branch is created, **Then** the system pushes the branch to origin and initializes beads database
5. **Given** a branch name that already exists, **When** user invokes `/bkff:git-branch <issue-id>`, **Then** the system reports the conflict and does not create a duplicate
6. **Given** an invalid or non-existent beads issue ID, **When** user invokes `/bkff:git-branch <issue-id>`, **Then** the system fails with an error listing valid issue IDs

---

### User Story 3 - Commit Changes (Priority: P2)

A developer has completed work and wants to commit all changes with a properly formatted conventional commit message. They invoke the commit command, which validates the changes, stages all new and modified files, generates a detailed commit message based on the changes, creates a signed commit, and pushes to origin.

**Why this priority**: Committing is a core daily operation that ensures work is saved and shared. Proper commit messages and signing improve traceability and security.

**Independent Test**: Can be fully tested by making changes in a worktree, invoking the commit command, and verifying the commit is created with proper format, signed, and pushed.

**Acceptance Scenarios**:

1. **Given** a worktree with uncommitted changes that pass validation, **When** user invokes `/bkff:git-commit`, **Then** the system stages all changes and creates a signed commit with a conventional commit message
2. **Given** changes that fail validation (lint, tests, etc.), **When** user invokes `/bkff:git-commit`, **Then** the system reports the validation failures and does not create a commit
3. **Given** a successful commit, **When** the commit is created, **Then** the system automatically pushes to origin
4. **Given** a worktree with no changes, **When** user invokes `/bkff:git-commit`, **Then** the system indicates there is nothing to commit
5. **Given** changes across multiple files, **When** user invokes `/bkff:git-commit`, **Then** the generated commit message accurately summarizes all changes
6. **Given** GPG signing is unavailable or not configured, **When** user invokes `/bkff:git-commit`, **Then** the system fails with an error and does not create an unsigned commit

---

### User Story 4 - Sync with Remote (Priority: P3)

A developer wants to synchronize their branch with changes from another branch (typically main). They invoke the sync command, which fetches from origin and intelligently chooses between rebase (if no commits pushed) or merge (if commits already pushed) to integrate changes.

**Why this priority**: Keeping branches up-to-date prevents merge conflicts and ensures integration with team changes. The smart rebase/merge selection simplifies the decision for developers.

**Independent Test**: Can be fully tested by creating scenarios with unpushed and pushed commits, then verifying the correct integration strategy is used.

**Acceptance Scenarios**:

1. **Given** a branch with no commits pushed to origin, **When** user invokes `/bkff:git-sync`, **Then** the system rebases the branch onto main
2. **Given** a branch with commits already pushed to origin, **When** user invokes `/bkff:git-sync`, **Then** the system merges main into the branch
3. **Given** user specifies a different source branch, **When** user invokes `/bkff:git-sync develop`, **Then** the system syncs from `develop` instead of `main`
4. **Given** conflicts occur during sync, **When** the system encounters conflicts, **Then** the system attempts to resolve the conflicts automatically and only requests user input for conflicts it cannot resolve
5. **Given** the entire worktree needs updating, **When** user invokes `/bkff:git-sync`, **Then** the system fetches updates for all branches in the worktree

---

### User Story 5 - Manage Pull Request (Priority: P3)

A developer wants to create or update a pull request for their branch. They invoke the PR command, which checks for an existing PR and either updates it or creates a new one, using the repository's PR template if available. The developer can optionally create the PR as a draft when the work is not yet ready for full review, later mark it as ready when development is complete, and retrieve reviewer feedback to address comments.

**Why this priority**: PR management is the final step in the development workflow before code review. Automating this reduces manual effort and ensures consistency. Draft PR support enables early feedback while signaling work-in-progress status, and review comment retrieval streamlines the feedback loop.

**Independent Test**: Can be fully tested by running the PR command on branches with and without existing PRs, verifying the correct create/update behavior, testing draft creation and ready marking, and verifying review comments are retrieved accurately.

**Acceptance Scenarios**:

1. **Given** a branch with no existing PR, **When** user invokes `/bkff:git-pr`, **Then** the system creates a new PR using the repository's template
2. **Given** a branch with an existing PR, **When** user invokes `/bkff:git-pr`, **Then** the system updates the existing PR rather than creating a duplicate
3. **Given** a repository with `.github/pull_request_template.md`, **When** creating a new PR, **Then** the system uses the template content as the PR body
4. **Given** a repository without a PR template, **When** creating a new PR, **Then** the system generates a reasonable default description based on commits
5. **Given** the branch has not been pushed to origin, **When** user invokes `/bkff:git-pr`, **Then** the system pushes the branch first before creating the PR
6. **Given** a branch with no existing PR, **When** user invokes `/bkff:git-pr --draft`, **Then** the system creates a new draft PR that is marked as not ready for review
7. **Given** a branch with an existing draft PR, **When** user invokes `/bkff:git-pr --ready`, **Then** the system marks the PR as ready for review
8. **Given** a branch with a non-draft PR, **When** user invokes `/bkff:git-pr --ready`, **Then** the system indicates the PR is already ready for review
9. **Given** a branch with an existing PR that has review comments, **When** user invokes `/bkff:git-pr --comments`, **Then** the system retrieves and displays all review comments with reviewer attribution
10. **Given** a branch with an existing PR that has no review comments, **When** user invokes `/bkff:git-pr --comments`, **Then** the system indicates no comments exist
11. **Given** a branch with an existing PR that has review comments, **When** user invokes `/bkff:git-pr --comments --analyze`, **Then** the system retrieves comments and for each comment displays a compliance probability score (0-100%) indicating how likely implementing the suggestion would improve requirements compliance or security
12. **Given** a review comment suggesting a code change, **When** analysis is performed, **Then** the system provides a brief rationale explaining which requirement(s) or security principle(s) the suggestion addresses
13. **Given** a review comment that is purely stylistic or preference-based, **When** analysis is performed, **Then** the system assigns a low probability score and indicates the suggestion is outside requirements/security scope
14. **Given** a branch with a spec file in the specs directory, **When** analysis is performed, **Then** the system uses the spec's functional requirements as the primary reference for compliance evaluation
15. **Given** a branch without a spec file, **When** analysis is performed, **Then** the system evaluates comments against general security principles and coding best practices only

---

### Edge Cases

- Commands invoked outside a git worktree: fail immediately with error explaining the worktree requirement
- Network failures when pushing to origin: fail immediately with clear error message, preserve local state (commit remains local) for manual retry
- When GPG key is not configured or unavailable, the commit command fails with an error (unsigned commits not permitted)
- How does the system handle a detached HEAD state?
- Invalid beads issue ID: fail with error listing valid issue IDs available for branch creation
- Partial failures (e.g., commit succeeds but push fails): report the failure state clearly, preserve successful operations (local commit intact), user can retry push manually
- What happens when origin remote is not configured?
- How does the system handle branches that have been force-pushed by others?

## Requirements *(mandatory)*

### Functional Requirements

#### Status Command (`/bkff:git-st`)

- **FR-001**: System MUST display uncommitted changes (both staged and unstaged) in the current worktree
- **FR-002**: System MUST display information about the last commit (hash, message, author, date)
- **FR-003**: System MUST display any in-progress beads tasks associated with the current branch
- **FR-004**: System MUST check and display existing pull request information for the current branch
- **FR-005**: System MUST generate a consolidated status message summarizing all information

#### Branch Command (`/bkff:git-branch`)

- **FR-006**: System MUST accept a beads issue ID as input
- **FR-007**: System MUST analyze the beads issue to determine the appropriate branch prefix (`feature/`, `bugfix/`, `hotfix/`)
- **FR-008**: System MUST create a new local branch in a git worktree directory named after the branch (without prefix)
- **FR-009**: System MUST push the new branch to the origin remote
- **FR-010**: System MUST initialize the beads database for the new branch
- **FR-011**: System MUST sync the beads database after initialization

#### Commit Command (`/bkff:git-commit`)

- **FR-012**: System MUST run the project's build tool `validate` target before committing
- **FR-013**: System MUST halt the commit process if any validation fails and report the failures
- **FR-014**: System MUST stage all new and changed files (not limited to current session)
- **FR-015**: System MUST analyze the staged changes to generate a conventional commit message
- **FR-016**: System MUST create a signed commit using the active GPG key
- **FR-017**: System MUST push the commit to origin after successful commit creation

#### Sync Command (`/bkff:git-sync`)

- **FR-018**: System MUST fetch from origin for the entire worktree
- **FR-019**: System MUST determine whether the current branch has commits pushed to origin
- **FR-020**: System MUST use rebase when no commits have been pushed to origin
- **FR-021**: System MUST use merge when commits have already been pushed to origin
- **FR-022**: System MUST accept an optional branch name parameter, defaulting to `main`
- **FR-023**: System MUST attempt to resolve merge conflicts automatically and only request user input for conflicts it cannot resolve

#### Pull Request Command (`/bkff:git-pr`)

- **FR-024**: System MUST check if a pull request already exists for the current branch
- **FR-025**: System MUST update the existing PR if one exists
- **FR-026**: System MUST create a new PR if none exists
- **FR-027**: System MUST use `.github/pull_request_template.md` content if the file exists
- **FR-028**: System MUST ensure the branch is pushed to origin before creating a PR
- **FR-034**: System MUST support creating a PR as a draft when `--draft` flag is provided
- **FR-035**: System MUST support marking a draft PR as ready for review when `--ready` flag is provided
- **FR-036**: System MUST indicate when `--ready` is used on a PR that is already ready for review
- **FR-037**: System MUST retrieve and display all review comments for an existing PR when `--comments` flag is provided
- **FR-038**: System MUST display reviewer attribution (name/username) with each review comment
- **FR-039**: System MUST indicate when no review comments exist for a PR
- **FR-040**: System MUST analyze each review comment against requirements and security principles when `--comments --analyze` flags are provided
- **FR-041**: System MUST assign a compliance probability score (0-100%) to each analyzed comment indicating likelihood the suggestion improves requirements compliance or security
- **FR-042**: System MUST provide a brief rationale for each analyzed comment explaining which requirement(s) or security principle(s) the suggestion addresses
- **FR-043**: System MUST identify and flag comments that are purely stylistic or preference-based as outside requirements/security scope
- **FR-044**: System MUST use the spec's functional requirements from the specs directory as the primary reference when a spec file exists for the branch
- **FR-045**: System MUST evaluate comments against general security principles and coding best practices when no spec file exists

#### General Requirements

- **FR-029**: All commands MUST execute using bash to run `git`, `gh`, or custom bash scripts
- **FR-030**: All commands MUST operate correctly within the specified git worktree directory layout
- **FR-031**: All commands MUST provide clear error messages when operations fail
- **FR-032**: All commands MUST be invokable as Claude Code skills using the `/bkff:` prefix
- **FR-033**: All commands MUST verify execution is within a valid git worktree and fail with a clear error if not

### Key Entities

- **Git Worktree**: A working directory linked to a bare repository, with multiple worktrees per repository for parallel branch work
- **Beads Issue**: A tracked work item from the beads issue tracking system, containing type (feature/bug), priority, and status
- **Branch**: A git branch with a standardized naming convention including prefix (`feature/`, `bugfix/`, `hotfix/`) and descriptive name
- **Conventional Commit**: A commit message following the conventional commits specification (type, scope, description)
- **Pull Request**: A GitHub pull request linking a feature branch to the base branch for code review

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can check the complete status of their work environment in under 5 seconds
- **SC-002**: Developers can create a new properly-configured branch with beads tracking in under 30 seconds
- **SC-003**: 100% of commits created by the plugin follow conventional commit format
- **SC-004**: 100% of commits are properly signed when GPG is configured
- **SC-005**: Developers can complete the commit-and-push workflow in a single command invocation
- **SC-006**: The sync command correctly chooses rebase vs merge strategy in 100% of cases
- **SC-007**: Pull requests use the repository template when available 100% of the time
- **SC-008**: All five commands are discoverable and executable through Claude Code's skill system
- **SC-009**: Error messages provide sufficient information for developers to resolve issues without additional investigation in 90% of failure cases
- **SC-010**: Developers can create a draft PR and mark it ready in separate operations, enabling work-in-progress feedback workflows
- **SC-011**: Developers can retrieve all review comments for a PR in under 5 seconds
- **SC-012**: Review comments display clearly identifies the reviewer and comment content for 100% of comments
- **SC-013**: Developers can analyze review comments for requirements compliance in under 30 seconds for PRs with up to 50 comments
- **SC-014**: 100% of analyzed comments receive a compliance probability score and rationale
- **SC-015**: Developers report that analysis helps them prioritize which review comments to address first in 80% of cases
- **SC-016**: Analysis correctly identifies requirements-related comments vs stylistic comments in 90% of cases

## Clarifications

### Session 2026-01-10

- Q: What constitutes "configured validations" for the commit command? → A: Run the project's build tool with a `validate` target
- Q: What happens when GPG signing is unavailable? → A: Fail the commit (do not allow unsigned commits)
- Q: How should network failures be handled? → A: Fail immediately, report error, preserve local state for manual retry
- Q: What happens when invoked outside a git worktree? → A: Fail with error explaining worktree requirement
- Q: What happens when beads issue ID does not exist? → A: Fail with error listing valid issue IDs

## Assumptions

- The user has `git` and `gh` (GitHub CLI) installed and configured
- The user has a GPG key configured for commit signing
- The repository uses a git worktree layout with a `.bare` directory and `.git` symlink
- The beads issue tracking system is initialized and accessible via `bd` commands
- The origin remote is configured and accessible
- The user has appropriate permissions to push to origin and create PRs
- The project's build tool has a `validate` target configured for pre-commit validation
- The `main` branch exists as the default integration target
