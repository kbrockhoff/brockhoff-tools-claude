# Feature Specification: Brockhoff Cloud (bkff) Claude Plugin

**Feature Branch**: `001-bkff-plugin`
**Created**: 2026-01-19
**Status**: Draft
**Input**: User description: "Brockhoff Cloud (bkff) Claude plugin with commands for compliance checking, task-to-issue conversion, and agentic development loops"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Check Repository Compliance (Priority: P1)

A developer wants to verify that their git repository meets Brockhoff Cloud spec-driven development standards before starting work. They run the compliance check command to identify any missing or misconfigured components, receiving a clear report of what passes and what needs attention.

**Why this priority**: This is the foundational capability that ensures all projects follow consistent standards. Without compliance checking, developers cannot know if their repository is properly configured for spec-driven development.

**Independent Test**: Can be fully tested by running the compliance check on repositories in various states (fully compliant, partially compliant, non-compliant) and verifying the report accurately identifies all issues.

**Acceptance Scenarios**:

1. **Given** a repository with all required components (`.github` directory with CODEOWNERS, CONTRIBUTING.md, dependabot.yml, pull_request_template.md, ISSUE_TEMPLATE directory; AGENTS.md; CLAUDE.md pointing to AGENTS.md; `.github/copilot-instructions.md` pointing to AGENTS.md; `.beads` initialized; `bd doctor` reports no issues), **When** the developer runs `bkff:chkcompliance`, **Then** the system reports all checks passed with a summary showing each component as compliant.

2. **Given** a repository missing the `.github` directory, **When** the developer runs `bkff:chkcompliance`, **Then** the system reports which specific files are missing (CODEOWNERS, CONTRIBUTING.md, dependabot.yml, pull_request_template.md, ISSUE_TEMPLATE) with clear descriptions of what each file should contain.

3. **Given** a repository where CLAUDE.md exists but does not reference AGENTS.md, **When** the developer runs `bkff:chkcompliance`, **Then** the system identifies the misconfiguration and explains the required content.

4. **Given** a repository where `.beads` is not initialized, **When** the developer runs `bkff:chkcompliance`, **Then** the system reports beads is not initialized and indicates the command to initialize it.

---

### User Story 2 - Fix Repository Compliance Issues (Priority: P1)

A developer has received a compliance report showing issues and wants to automatically fix them rather than manually creating each file. They run the fix compliance command, which creates or updates the necessary files to bring the repository into compliance.

**Why this priority**: Paired with compliance checking, this automates the remediation process, dramatically reducing the time to set up compliant repositories. Manual setup is error-prone and time-consuming.

**Independent Test**: Can be fully tested by running the fix command on a non-compliant repository and then verifying all previously failing checks now pass.

**Acceptance Scenarios**:

1. **Given** a repository missing the `.github` directory and its contents, **When** the developer runs `bkff:fixcompliance`, **Then** the system creates the `.github` directory with CODEOWNERS, CONTRIBUTING.md, dependabot.yml, pull_request_template.md, and ISSUE_TEMPLATE directory with bug and feature templates using sensible defaults.

2. **Given** a repository without AGENTS.md, **When** the developer runs `bkff:fixcompliance`, **Then** the system creates AGENTS.md with sections for project overview, instructions for using bkff-git skills, and instructions for using beads.

3. **Given** a repository where CLAUDE.md exists but does not reference AGENTS.md, **When** the developer runs `bkff:fixcompliance`, **Then** the system updates CLAUDE.md to include the reference to AGENTS.md while preserving existing content.

4. **Given** a repository where `.github/copilot-instructions.md` is missing or does not reference AGENTS.md, **When** the developer runs `bkff:fixcompliance`, **Then** the system creates or updates `.github/copilot-instructions.md` with the single instruction "Follow all instructions in AGENTS.md".

5. **Given** a repository without `.beads` initialized, **When** the developer runs `bkff:fixcompliance`, **Then** the system initializes the beads database and creates the `.beads` directory with proper configuration.

6. **Given** a repository with beads health issues (missing hooks, sync problems), **When** the developer runs `bkff:fixcompliance`, **Then** the system runs `bd doctor --fix` to resolve beads-related issues.

---

### User Story 3 - Convert SpecKit Tasks to Beads Issues (Priority: P2)

A developer has generated a tasks.md file using SpecKit and wants to convert these tasks into trackable beads issues with proper dependencies and hierarchy. They run the tasks-to-issues command, which parses the markdown and creates corresponding beads issues.

**Why this priority**: This bridges the gap between specification/planning (SpecKit output) and execution tracking (beads). It enables the spec-driven development workflow to flow seamlessly into task management.

**Independent Test**: Can be fully tested by providing a sample tasks.md file and verifying the correct number of beads issues are created with accurate titles, descriptions, priorities, and dependencies.

**Acceptance Scenarios**:

1. **Given** a valid tasks.md file with hierarchical tasks, **When** the developer runs `bkff:tasks2issues`, **Then** the system creates beads issues for each task preserving the parent-child hierarchy as dependencies.

2. **Given** a tasks.md file with tasks containing priority markers (P0-P4), **When** the developer runs `bkff:tasks2issues`, **Then** the beads issues are created with corresponding priority values (0-4).

3. **Given** a tasks.md file where some tasks depend on others, **When** the developer runs `bkff:tasks2issues`, **Then** the beads issues are created with proper `blocks`/`blocked-by` dependency relationships.

4. **Given** a tasks.md file with task descriptions and acceptance criteria, **When** the developer runs `bkff:tasks2issues`, **Then** the beads issue descriptions include the full task details.

---

### User Story 4 - Start Agentic Development Loop (Priority: P2)

A developer wants to initiate an autonomous development loop where the AI agent iteratively works through beads issues, implementing features, running tests, and committing changes. They start the loop and the agent begins processing ready tasks.

**Why this priority**: This is the core automation capability that enables hands-off development. While compliance and task conversion are prerequisites, the development loop delivers the primary productivity value.

**Independent Test**: Can be fully tested by starting the loop with ready tasks available, observing the agent pick up and work on tasks, and verifying proper task state transitions.

**Acceptance Scenarios**:

1. **Given** a repository with ready beads tasks (no blockers), **When** the developer runs `bkff:startloop`, **Then** the agent begins working on the highest priority ready task.

2. **Given** a running development loop, **When** a task is completed, **Then** the agent automatically checks for newly unblocked tasks and proceeds to the next highest priority ready task.

3. **Given** a running development loop, **When** any issue prevents the loop from proceeding (e.g., errors, ambiguous requirements, missing dependencies, failed tests), **Then** the loop pauses, reports the issue to the user with context, and waits for user input before continuing.

4. **Given** a running development loop, **When** the user runs `bkff:cancelloop`, **Then** the agent stops after completing its current atomic operation and reports final status.

5. **Given** a repository with no ready beads tasks (all tasks are blocked or completed), **When** the developer runs `bkff:startloop`, **Then** the system reports "no ready tasks" and exits without starting the loop.

6. **Given** no development loop is currently running, **When** the user runs `bkff:cancelloop`, **Then** the system reports "no loop running" and exits gracefully without error.

---

### User Story 5 - Verify Task Completion (Priority: P3)

A developer or the agentic loop needs to verify that a beads task (task, feature, epic, or bug) is truly complete according to its acceptance criteria before closing it. The verification skills execute build system targets that run tests and check code quality, documentation, security, and standards adherence. Failures are output in a structured format consumable by the coding agent.

**Why this priority**: Verification ensures quality gates are enforced. While the development loop can function without explicit verification, having dedicated verification skills with automated checks improves reliability and enables the agentic loop to self-correct.

**Independent Test**: Can be fully tested by running verification on completed and incomplete tasks, confirming the skill correctly identifies the completion state and outputs failures in the expected format.

**Build System Targets**:
- `validate` target: Used for tasks and bugs. Runs tests, code quality checks, documentation validation, security scanning, and standards adherence checks.
- `verify` target: Used for features and epics. Runs comprehensive validation including integration tests, feature-level documentation, and cross-component verification.

**Acceptance Scenarios**:

1. **Given** a beads task with defined acceptance criteria, **When** `bkff:verifytask` is run, **Then** the skill executes the build system `validate` target and reports pass/fail status with any failures in agent-consumable format.

2. **Given** a beads task where the `validate` target fails, **When** `bkff:verifytask` is run, **Then** the skill outputs all failures in a structured format containing: file path, line number (if applicable), failure type (test/quality/docs/security/standards), severity, and remediation hint.

3. **Given** a beads feature with multiple child tasks all closed, **When** `bkff:verifyfeat` is run, **Then** the skill executes the build system `verify` target and checks that all child tasks are closed and the feature's own criteria are met.

4. **Given** a beads epic with multiple features, **When** `bkff:verifyepic` is run, **Then** the skill executes the build system `verify` target for the epic scope and checks that all child features are verified complete.

5. **Given** a beads bug with reproduction steps and fix verification steps, **When** `bkff:verifybug` is run, **Then** the skill executes the build system `validate` target and confirms the bug no longer reproduces and the fix verification passes.

6. **Given** a beads task without defined acceptance criteria, **When** any verification skill is run, **Then** the skill fails verification and reports that acceptance criteria must be defined before verification can proceed.

7. **Given** a verification skill encounters multiple failures, **When** outputting results, **Then** all failures are listed in a structured JSON format with fields: `file`, `line`, `type`, `severity`, `message`, `hint`.

---

### User Story 6 - Write Architectural Decision Records (Priority: P3)

A developer or architect needs to document an architectural decision using the team's standard ADR format. They invoke the ADR writer command with context about the decision, and a multi-agent pipeline produces a well-structured, validated, and properly formatted ADR document.

**Why this priority**: ADRs are critical for maintaining architectural knowledge across team changes and time. Automating their creation ensures consistency and completeness while reducing the friction that often leads to undocumented decisions.

**Independent Test**: Can be fully tested by invoking the ADR command with various decision contexts and verifying the output conforms to the MADR template, passes validation against grounding sources, and is properly formatted.

**Agent Pipeline**:
- **Writer Agent**: Generates initial ADR content based on user input and context, following the Markdown Architectural Decision Records (MADR) template structure.
- **Validator Agent**: Validates the ADR against grounding sources (codebase context, existing ADRs, referenced documentation) to ensure technical accuracy, consistency with prior decisions, and completeness of required sections.
- **Formatter Agent**: Applies consistent formatting, generates the ADR filename with sequential numbering, and ensures markdown compliance.

**MADR Template Sections**:
- Title (with ADR number)
- Status (proposed, accepted, deprecated, superseded)
- Context (problem statement and driving forces)
- Decision (the change being proposed/made)
- Consequences (resulting context, positive and negative)
- Optional: Considered Alternatives, Pros/Cons of each

**Acceptance Scenarios**:

1. **Given** a user describes an architectural decision context, **When** `bkff:writeadr` is run, **Then** the Writer Agent generates an ADR following the MADR template with all required sections populated.

2. **Given** the Writer Agent has produced an initial ADR, **When** the Validator Agent runs, **Then** it checks the ADR against: existing ADRs for conflicts or supersession relationships, codebase components referenced in the decision, and any linked documentation or RFCs.

3. **Given** the Validator Agent finds inconsistencies with grounding sources, **When** validation completes, **Then** it returns specific findings with references to the grounding source (file path, ADR number, or URL) and suggested corrections.

4. **Given** the Validator Agent approves the ADR, **When** the Formatter Agent runs, **Then** it assigns the next sequential ADR number, generates the filename (e.g., `0042-use-event-sourcing.md`), and ensures consistent markdown formatting.

5. **Given** existing ADRs in the repository, **When** a new ADR references or supersedes a prior decision, **Then** the pipeline automatically links the ADRs and suggests updating the status of superseded ADRs.

6. **Given** the user provides minimal context, **When** the Writer Agent generates the ADR, **Then** it prompts for missing critical information (decision drivers, alternatives considered) before proceeding.

7. **Given** the complete pipeline executes successfully, **When** the ADR is written to disk, **Then** it is placed in the configured ADR directory (default: `docs/adr/`) with proper naming convention.

---

### User Story 7 - Generate Unit Tests (Priority: P2)

A developer or the agentic loop needs to generate unit tests for newly implemented code to ensure adequate test coverage before verification. The test generation skill analyzes the code and produces appropriate test cases based on the code structure, acceptance criteria, and testing best practices.

**Why this priority**: Test generation is essential for the inner validation loop shown in the development lifecycle. Without tests, the verification skills cannot validate code quality, and the agentic loop cannot self-correct.

**Independent Test**: Can be fully tested by running test generation on sample code and verifying the generated tests compile, execute, and provide meaningful coverage.

**Acceptance Scenarios**:

1. **Given** newly implemented code for a beads task, **When** `bkff:gentests` is run, **Then** the skill generates unit tests that cover the primary code paths and edge cases defined in the task's acceptance criteria.

2. **Given** code with existing tests that need updating, **When** `bkff:gentests` is run with the `--update` flag, **Then** the skill analyzes gaps in existing test coverage and generates additional tests to fill those gaps.

3. **Given** code in a supported language (determined by file extension and project structure), **When** `bkff:gentests` is run, **Then** the skill generates tests using the project's established testing framework and conventions.

4. **Given** code that requires mocking external dependencies, **When** `bkff:gentests` is run, **Then** the generated tests include appropriate mocks/stubs following the project's mocking patterns.

5. **Given** the agentic development loop is running, **When** new code is generated, **Then** the loop automatically invokes test generation before running verification.

6. **Given** test generation fails (e.g., unsupported language, parse errors), **When** `bkff:gentests` encounters the error, **Then** it reports the failure with actionable context and does not block the development loop from continuing with manual test writing.

---

### User Story 8 - Generate Project README (Priority: P3)

A developer completing a feature or initializing a new project needs to generate or update the project README to document the implementation. The README generation skill produces comprehensive documentation based on the codebase structure, specifications, and ADRs.

**Why this priority**: The sequence diagram shows "generate detailed README & ADRs from chosen solution" as part of the design phase completion. While ADRs are covered by User Story 6, README generation ensures documentation completeness.

**Independent Test**: Can be fully tested by running README generation on a project and verifying the output includes all required sections and accurately reflects the codebase.

**Acceptance Scenarios**:

1. **Given** a project with spec.md and plan.md, **When** `bkff:genreadme` is run, **Then** the skill generates a README.md with sections for: project overview, installation, usage, configuration, contributing guidelines, and license.

2. **Given** a project with existing README.md, **When** `bkff:genreadme` is run with the `--update` flag, **Then** the skill updates sections that are out of date while preserving custom content marked with preserve markers.

3. **Given** a project with multiple plugins or components, **When** `bkff:genreadme` is run, **Then** the generated README includes a component index with links to component-specific documentation.

4. **Given** ADRs exist in the project, **When** `bkff:genreadme` is run, **Then** the README includes an "Architecture Decisions" section linking to relevant ADRs.

5. **Given** the project has a build system with defined targets, **When** `bkff:genreadme` is run, **Then** the README includes documentation of available build commands and their purposes.

---

### User Story 9 - Handle PR Review Feedback (Priority: P3)

A developer has received review comments on a pull request and needs to address the feedback efficiently. The PR feedback skill parses review comments, categorizes them, and assists in implementing the required changes.

**Why this priority**: The sequence diagram shows a feedback loop with "PR review comments", "suggested changes", and "update PR to ready". This closes the loop between code review and implementation.

**Independent Test**: Can be fully tested by providing sample PR review comments and verifying the skill correctly parses, categorizes, and generates actionable tasks from the feedback.

**Acceptance Scenarios**:

1. **Given** a PR with review comments, **When** `bkff:prfeedback` is run, **Then** the skill fetches all review comments and categorizes them as: required changes, suggestions, questions, or nitpicks.

2. **Given** categorized review feedback, **When** processing required changes, **Then** the skill creates beads tasks for each required change with appropriate priority (P1 for blocking, P2 for non-blocking).

3. **Given** review comments that suggest code changes, **When** processing suggestions, **Then** the skill presents the suggested changes with context and allows the developer to accept, modify, or reject each suggestion.

4. **Given** review comments that are questions, **When** processing questions, **Then** the skill drafts response comments based on the codebase context for developer review before posting.

5. **Given** all required changes have been addressed, **When** `bkff:prfeedback --ready` is run, **Then** the skill marks the PR as ready for re-review and notifies reviewers.

6. **Given** a PR with no pending review comments, **When** `bkff:prfeedback` is run, **Then** the skill reports "No pending feedback" and suggests requesting review if the PR is still in draft.

---

### Edge Cases

- What happens when `bkff:tasks2issues` is run but no tasks.md file exists in the expected location?
- How does the system handle `bkff:fixcompliance` when the user lacks write permissions to the repository?
- When `bkff:startloop` is called but no ready tasks exist, the system reports "no ready tasks" and exits without starting the loop.
- When the development loop encounters rate limits or API failures, it retries with exponential backoff (up to 3 attempts), then pauses and reports to the user if retries are exhausted.
- When `bkff:cancelloop` is called but no loop is running, the system reports "no loop running" and exits gracefully without error.
- When any command is run in a directory that is not a git repository, it fails immediately with clear error: "Not a git repository".
- Verification skills fail and require acceptance criteria to be defined before verification can proceed.
- When verification skills are run but the build system `validate` or `verify` target does not exist, verification fails with an error requiring the build system targets to be implemented.
- When `bkff:writeadr` is run but no ADR directory exists, the system creates `docs/adr/` automatically and proceeds.
- When the ADR pipeline detects conflicting information between user input and grounding sources, it flags the conflicts and presents them to the user for resolution before finalizing the ADR.
- When the Validator Agent cannot access referenced grounding sources (e.g., URLs are unreachable), it warns the user about inaccessible sources and continues validation with available sources.
- When `bkff:gentests` is run on code in an unsupported language, it warns the user, skips test generation, and suggests manual test writing with guidance on testing patterns.
- When test generation encounters code with complex external dependencies, it generates test stubs with TODO markers for complex mocks and includes guidance on the mocking approach.
- When `bkff:genreadme` is run on a project without spec.md or plan.md, it generates README from available sources (codebase, existing docs, ADRs) with a warning about limited context.
- How does README generation handle conflicting information between different source files?
- When `bkff:prfeedback` is run but no PR exists for the current branch, it reports "No PR exists for this branch" and suggests running `bkff:git-pr` to create one.
- When PR feedback encounters comments on files that have been deleted or significantly changed, it flags them as potentially stale, shows diff context, and lets the developer decide relevance.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Plugin MUST provide a `bkff:chkcompliance` command that validates repository compliance with Brockhoff Cloud standards
- **FR-002**: Plugin MUST check for `.github` directory containing CODEOWNERS, CONTRIBUTING.md, dependabot.yml, pull_request_template.md, and ISSUE_TEMPLATE directory with bug and feature templates
- **FR-003**: Plugin MUST check for AGENTS.md with required sections (project overview, bkff-git instructions, beads instructions)
- **FR-004**: Plugin MUST check that CLAUDE.md and `.github/copilot-instructions.md` reference AGENTS.md
- **FR-005**: Plugin MUST check that `.beads` directory is initialized
- **FR-006**: Plugin MUST check beads health by running `bd doctor` and report any issues
- **FR-007**: Plugin MUST provide a `bkff:fixcompliance` command that creates or updates files to achieve compliance
- **FR-008**: Plugin MUST provide a `bkff:tasks2issues` command that parses tasks.md files in the format generated by SpecKit `/speckit.tasks` command
- **FR-009**: Plugin MUST convert tasks.md hierarchical structure into beads issues with proper dependencies
- **FR-010**: Plugin MUST map tasks.md priority markers to beads priority values (P0→0, P1→1, P2→2, P3→3, P4→4)
- **FR-011**: Plugin MUST provide a `bkff:startloop` command that initiates an agentic development loop
- **FR-012**: Plugin MUST provide a `bkff:cancelloop` command that gracefully stops the development loop
- **FR-014**: Plugin MUST provide `bkff:verifytask`, `bkff:verifyfeat`, `bkff:verifyepic`, and `bkff:verifybug` skills
- **FR-015**: Verification skills MUST check acceptance criteria defined in the beads issue; verification MUST fail if no acceptance criteria are defined
- **FR-021**: `bkff:verifytask` and `bkff:verifybug` MUST execute the build system `validate` target
- **FR-022**: `bkff:verifyfeat` and `bkff:verifyepic` MUST execute the build system `verify` target
- **FR-023**: Build system targets MUST run tests, code quality checks, documentation validation, security scanning, and standards adherence checks
- **FR-024**: Verification skills MUST output failures in structured JSON format with fields: `file`, `line`, `type`, `severity`, `message`, `hint`
- **FR-016**: Development loop MUST automatically select the highest priority ready task (no blockers)
- **FR-017**: Development loop MUST pause, report, and wait for user input when any issue prevents the loop from proceeding
- **FR-018**: All commands MUST provide clear error messages when preconditions are not met
- **FR-019**: All commands MUST operate within a git repository context
- **FR-020**: Development loop MUST implement exponential backoff retry (up to 3 attempts) for transient failures before pausing
- **FR-025**: Plugin MUST provide a `bkff:writeadr` command that generates Architectural Decision Records
- **FR-026**: ADR generation MUST use a multi-agent pipeline: Writer Agent → Validator Agent → Formatter Agent
- **FR-027**: Writer Agent MUST generate ADR content following the Markdown Architectural Decision Records (MADR) template
- **FR-028**: Validator Agent MUST validate ADR content against grounding sources: existing ADRs, codebase context, and referenced documentation
- **FR-029**: Validator Agent MUST return specific findings with references to grounding sources when inconsistencies are found
- **FR-030**: Formatter Agent MUST assign sequential ADR numbers and generate filenames following the pattern `NNNN-kebab-case-title.md`
- **FR-031**: ADR pipeline MUST detect and link supersession relationships between ADRs
- **FR-032**: ADR pipeline MUST place generated ADRs in the configured directory (default: `docs/adr/`)
- **FR-033**: ADR pipeline MUST create the ADR directory automatically if it does not exist
- **FR-034**: Validator Agent MUST flag conflicts between user input and grounding sources and present them to the user for resolution before finalizing
- **FR-035**: Validator Agent MUST warn user about inaccessible grounding sources and continue validation with available sources
- **FR-036**: Verification skills MUST fail with error if required build system target (`validate` or `verify`) does not exist
- **FR-037**: Plugin MUST provide a `bkff:gentests` command that generates unit tests for implemented code
- **FR-038**: Test generation MUST analyze code structure, acceptance criteria, and project testing conventions
- **FR-039**: Test generation MUST support updating existing tests with `--update` flag to fill coverage gaps
- **FR-040**: Development loop MUST automatically invoke test generation after code generation and before verification
- **FR-041**: Plugin MUST provide a `bkff:genreadme` command that generates or updates project README documentation
- **FR-042**: README generation MUST include sections for: overview, installation, usage, configuration, contributing, and license
- **FR-043**: README generation MUST preserve custom content marked with preserve markers when using `--update` flag
- **FR-044**: Plugin MUST provide a `bkff:prfeedback` command that processes PR review comments
- **FR-045**: PR feedback processing MUST categorize comments as: required changes, suggestions, questions, or nitpicks
- **FR-046**: PR feedback MUST create beads tasks for required changes with appropriate priority
- **FR-047**: PR feedback MUST support `--ready` flag to mark PR ready for re-review after addressing feedback
- **FR-048**: Test generation MUST gracefully skip unsupported languages with warning and manual testing guidance
- **FR-049**: README generation MUST work with available sources when spec.md or plan.md are missing, with warning about limited context
- **FR-050**: Test generation MUST create test stubs with TODO markers for complex dependencies that cannot be easily mocked
- **FR-051**: PR feedback MUST flag comments on deleted or significantly changed files as potentially stale with diff context for developer review

### Key Entities

- **Compliance Check**: Represents a single validation rule with name, check logic, pass/fail status, and remediation instructions
- **Compliance Report**: Collection of compliance checks with overall pass/fail status and summary statistics
- **Task Mapping**: Represents the relationship between a tasks.md entry and a beads issue, including hierarchy and dependencies
- **Development Loop State**: Tracks the current loop status (running, paused, stopped), current task, and history of completed tasks
- **Verification Failure**: Represents a single failure from build system validation with file path, line number, failure type (test/quality/docs/security/standards), severity level, message, and remediation hint
- **Architectural Decision Record (ADR)**: Document capturing an architectural decision with: number, title, status, context, decision, consequences, and optionally considered alternatives
- **ADR Validation Finding**: Result from Validator Agent containing: finding type (conflict, incomplete, inconsistent), severity, grounding source reference, affected ADR section, and suggested correction
- **Grounding Source**: Reference material used for validation including: existing ADRs, codebase files, external documentation URLs
- **Generated Test**: Unit test created by the test generation skill with: target code reference, test type (unit/integration), coverage metrics, and test framework compatibility
- **Test Coverage Gap**: Identified area of code lacking test coverage with: file path, function/method name, coverage percentage, and suggested test scenarios
- **PR Review Comment**: Parsed review feedback with: comment ID, author, category (required/suggestion/question/nitpick), file reference, and resolution status
- **README Section**: Component of generated documentation with: section name, content, preserve flag, and source references

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can verify repository compliance in under 30 seconds
- **SC-002**: Developers can bring a non-compliant repository to full compliance in under 2 minutes using the fix command
- **SC-003**: 100% of tasks.md entries are successfully converted to beads issues with correct hierarchy
- **SC-004**: Development loop can autonomously complete at least 3 consecutive tasks without human intervention when no blockers exist
- **SC-005**: 95% of compliance issues detected by `bkff:chkcompliance` can be automatically fixed by `bkff:fixcompliance`
- **SC-006**: Verification skills accurately identify task completion state with 100% accuracy for tasks with defined acceptance criteria
- **SC-007**: ADR pipeline generates MADR-compliant documents with all required sections populated
- **SC-008**: Validator Agent detects 90% of conflicts with existing ADRs and codebase inconsistencies
- **SC-009**: Generated ADRs require minimal manual editing (less than 20% content changes on average)
- **SC-010**: Generated unit tests achieve at least 70% code coverage for targeted code
- **SC-011**: Generated tests compile and execute successfully on first generation 90% of the time
- **SC-012**: Generated README accurately reflects project structure and capabilities
- **SC-013**: PR feedback processing correctly categorizes 95% of review comments
- **SC-014**: Required changes from PR feedback are converted to actionable beads tasks within 30 seconds

## Clarifications

### Session 2026-01-22

- Q: What happens when `bkff:startloop` is called but no ready tasks exist? → A: Report "no ready tasks" and exit without starting loop
- Q: What constitutes a "blocking issue" that pauses the development loop? → A: Any issue that prevents the loop from proceeding; report and wait for user input
- Q: How should the development loop handle API/rate limit failures? → A: Retry with exponential backoff (3 attempts), then pause after max retries
- Q: What happens when verification skills encounter tasks without defined acceptance criteria? → A: Fail verification - require acceptance criteria to verify
- Q: What happens when `bkff:cancelloop` is called but no loop is running? → A: Report "no loop running" and exit gracefully (no error)

### Session 2026-01-23

- Q: How should verification skills validate task/bug completion? → A: Execute build system `validate` target (tests, quality, docs, security, standards)
- Q: How should verification skills validate feature/epic completion? → A: Execute build system `verify` target (comprehensive validation including integration tests)
- Q: What format should verification failures use? → A: Structured JSON with fields: `file`, `line`, `type`, `severity`, `message`, `hint` - consumable by coding agent
- Q: What ADR template format should be used? → A: Markdown Architectural Decision Records (MADR) template
- Q: How should ADR generation be structured? → A: Multi-agent pipeline: Writer Agent → Validator Agent → Formatter Agent
- Q: How should the Validator Agent ensure accuracy? → A: Grounding with existing ADRs, codebase context, and referenced documentation
- Q: What happens when `bkff:writeadr` is run but no ADR directory exists? → A: Create `docs/adr/` directory automatically and proceed
- Q: How does the ADR pipeline handle conflicting information between user input and grounding sources? → A: Flag conflicts and present to user for resolution before finalizing
- Q: What happens when the Validator Agent cannot access referenced grounding sources? → A: Warn user about inaccessible sources and continue validation with available sources
- Q: What happens when verification skills are run but the build system target does not exist? → A: Fail verification with error requiring build system targets
- Q: How does `bkff:chkcompliance` handle repositories that are not git repositories? → A: Fail immediately with clear error: "Not a git repository"
- Q: What happens when `bkff:gentests` is run on code in an unsupported language? → A: Warn user, skip test generation, and suggest manual test writing with guidance
- Q: What happens when `bkff:prfeedback` is run but no PR exists for the current branch? → A: Report "No PR exists for this branch" and suggest running `bkff:git-pr` to create one
- Q: What happens when `bkff:genreadme` is run on a project without spec.md or plan.md? → A: Generate README from available sources (codebase, existing docs, ADRs) with warning about limited context
- Q: How does test generation handle code with complex external dependencies? → A: Generate test stubs with TODO markers for complex mocks, include guidance on mocking approach
- Q: How does PR feedback handle comments on files that have been deleted or significantly changed? → A: Flag comments as potentially stale, show diff context, and let developer decide relevance

## Assumptions

- Git (2.25+), GitHub CLI (2.0+), bd (beads CLI), and jq are available in the environment
- The repository uses GitHub as the remote repository host
- AGENTS.md follows a predictable structure that can be validated programmatically
- tasks.md is in the format generated by SpecKit `/speckit.tasks` command, with hierarchical headers, checkboxes, priority markers, and dependency annotations
- The development environment supports the bash scripting required for commands
- Users have appropriate permissions to create and modify files in the repository
- Beads daemon is configured for auto-sync when beads is initialized
- The repository has a build system with `validate` and `verify` targets that run tests, code quality, documentation, security, and standards checks
- Build system targets output results in a parseable format (exit codes and structured output)
- ADR directory exists or can be created at `docs/adr/` (configurable)
- Existing ADRs follow MADR naming convention (`NNNN-kebab-case-title.md`)
- Grounding sources (existing ADRs, codebase files) are accessible to the Validator Agent
- Project uses a recognized testing framework compatible with the primary programming language
- Test generation supports common languages: JavaScript/TypeScript, Python, Go, Rust, Java, and shell scripts
- README.md follows standard markdown conventions and project documentation patterns
- PR review comments are accessible via GitHub CLI (`gh`) API
- Reviewers use standard GitHub review comment conventions (approve, request changes, comment)
