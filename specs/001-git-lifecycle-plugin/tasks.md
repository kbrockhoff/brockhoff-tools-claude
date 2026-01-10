# Tasks: Git Lifecycle Plugin

**Input**: Design documents from `/specs/001-git-lifecycle-plugin/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in spec. Test tasks included for foundational library only.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each command.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions

Project structure from plan.md:
- Plugin root: `plugins/bkff-git/`
- Plugin config: `plugins/bkff-git/.claude-plugin/`
- Skills: `plugins/bkff-git/skills/<skill-name>/`
- Shared libraries: `plugins/bkff-git/lib/`
- Tests: `plugins/bkff-git/tests/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Plugin initialization and directory structure

- [ ] T001 Create plugin directory structure per plan.md at plugins/bkff-git/
- [ ] T002 [P] Create plugin.json with metadata in plugins/bkff-git/.claude-plugin/plugin.json
- [ ] T003 [P] Create README.md with plugin overview in plugins/bkff-git/README.md
- [ ] T004 [P] Create skills directory structure with subdirectories for git-st, git-branch, git-commit, git-sync, git-pr in plugins/bkff-git/skills/
- [ ] T005 [P] Create lib directory for shared utilities in plugins/bkff-git/lib/
- [ ] T006 [P] Create tests directory structure in plugins/bkff-git/tests/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core shared libraries that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T007 Implement worktree detection function in plugins/bkff-git/lib/common.sh
- [ ] T008 Implement error handling utilities (error_exit, warn) in plugins/bkff-git/lib/common.sh
- [ ] T009 Implement output formatting functions in plugins/bkff-git/lib/common.sh
- [ ] T010 [P] Implement branch status detection (is_pushed, ahead/behind) in plugins/bkff-git/lib/git-helpers.sh
- [ ] T011 [P] Implement branch name parsing (prefix, short_name) in plugins/bkff-git/lib/git-helpers.sh
- [ ] T012 [P] Implement git status parsing helpers in plugins/bkff-git/lib/git-helpers.sh
- [ ] T013 [P] Implement build tool validation runner in plugins/bkff-git/lib/validation.sh
- [ ] T014 [P] Implement GPG signing availability check in plugins/bkff-git/lib/validation.sh
- [ ] T015 Create test helper utilities in plugins/bkff-git/tests/test-helpers.sh
- [ ] T016 Test common.sh worktree detection in plugins/bkff-git/tests/test-common.sh

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Check Development Status (Priority: P1) 🎯 MVP

**Goal**: Developer can check current worktree status including uncommitted changes, last commit, beads tasks, and PR status

**Independent Test**: Run `/bkff:git-st` in a git worktree and verify output shows correct status information

**Contract**: specs/001-git-lifecycle-plugin/contracts/git-st.md

### Implementation for User Story 1

- [ ] T017 [US1] Create skill.md documentation for git-st command in plugins/bkff-git/skills/git-st/skill.md
- [ ] T018 [US1] Implement uncommitted changes display (FR-001) in plugins/bkff-git/skills/git-st/SKILL.md
- [ ] T019 [US1] Implement last commit information display (FR-002) in plugins/bkff-git/skills/git-st/SKILL.md
- [ ] T020 [US1] Implement beads task status retrieval (FR-003) in plugins/bkff-git/skills/git-st/SKILL.md
- [ ] T021 [US1] Implement PR status check via gh CLI (FR-004) in plugins/bkff-git/skills/git-st/SKILL.md
- [ ] T022 [US1] Implement consolidated status message formatting (FR-005) in plugins/bkff-git/skills/git-st/SKILL.md
- [ ] T023 [US1] Add worktree validation at command start (FR-033) in plugins/bkff-git/skills/git-st/SKILL.md
- [ ] T024 [US1] Add error handling for network failures (PR check) in plugins/bkff-git/skills/git-st/SKILL.md

**Checkpoint**: User Story 1 complete - `/bkff:git-st` should be fully functional and testable independently

---

## Phase 4: User Story 2 - Create Feature Branch (Priority: P2)

**Goal**: Developer can create a new branch from a beads issue with correct prefix, worktree, and beads initialization

**Independent Test**: Run `/bkff:git-branch beads-xxx` and verify new worktree created with correct branch, pushed to origin, beads initialized

**Contract**: specs/001-git-lifecycle-plugin/contracts/git-branch.md

### Implementation for User Story 2

- [ ] T025 [US2] Create skill.md documentation for git-branch command in plugins/bkff-git/skills/git-branch/skill.md
- [ ] T026 [US2] Implement beads issue ID parsing and validation (FR-006) in plugins/bkff-git/skills/git-branch/SKILL.md
- [ ] T027 [US2] Implement issue type to branch prefix mapping (FR-007) in plugins/bkff-git/skills/git-branch/SKILL.md
- [ ] T028 [US2] Implement worktree creation with git worktree add (FR-008) in plugins/bkff-git/skills/git-branch/SKILL.md
- [ ] T029 [US2] Implement branch push to origin (FR-009) in plugins/bkff-git/skills/git-branch/SKILL.md
- [ ] T030 [US2] Implement beads database initialization (FR-010) in plugins/bkff-git/skills/git-branch/SKILL.md
- [ ] T031 [US2] Implement beads sync after init (FR-011) in plugins/bkff-git/skills/git-branch/SKILL.md
- [ ] T032 [US2] Add validation for existing branch conflict in plugins/bkff-git/skills/git-branch/SKILL.md
- [ ] T033 [US2] Add error handling with valid issue list on failure in plugins/bkff-git/skills/git-branch/SKILL.md

**Checkpoint**: User Story 2 complete - `/bkff:git-branch` should be fully functional and testable independently

---

## Phase 5: User Story 3 - Commit Changes (Priority: P2)

**Goal**: Developer can commit all changes with validation, conventional commit message, GPG signing, and push to origin

**Independent Test**: Make changes in worktree, run `/bkff:git-commit`, verify commit created with proper format, signed, and pushed

**Contract**: specs/001-git-lifecycle-plugin/contracts/git-commit.md

### Implementation for User Story 3

- [ ] T034 [US3] Create skill.md documentation for git-commit command in plugins/bkff-git/skills/git-commit/skill.md
- [ ] T035 [US3] Implement build tool validate target execution (FR-012) in plugins/bkff-git/skills/git-commit/SKILL.md
- [ ] T036 [US3] Implement validation failure handling and reporting (FR-013) in plugins/bkff-git/skills/git-commit/SKILL.md
- [ ] T037 [US3] Implement git add -A for all changes (FR-014) in plugins/bkff-git/skills/git-commit/SKILL.md
- [ ] T038 [US3] Implement conventional commit type detection from diff in plugins/bkff-git/skills/git-commit/SKILL.md
- [ ] T039 [US3] Implement scope extraction from changed files in plugins/bkff-git/skills/git-commit/SKILL.md
- [ ] T040 [US3] Implement commit message generation (FR-015) in plugins/bkff-git/skills/git-commit/SKILL.md
- [ ] T041 [US3] Implement GPG signed commit creation (FR-016) in plugins/bkff-git/skills/git-commit/SKILL.md
- [ ] T042 [US3] Implement push to origin after commit (FR-017) in plugins/bkff-git/skills/git-commit/SKILL.md
- [ ] T043 [US3] Add GPG unavailable error handling in plugins/bkff-git/skills/git-commit/SKILL.md
- [ ] T044 [US3] Add network failure handling (preserve local commit) in plugins/bkff-git/skills/git-commit/SKILL.md
- [ ] T045 [US3] Add --message override option support in plugins/bkff-git/skills/git-commit/SKILL.md
- [ ] T046 [US3] Add --co-author option support in plugins/bkff-git/skills/git-commit/SKILL.md

**Checkpoint**: User Story 3 complete - `/bkff:git-commit` should be fully functional and testable independently

---

## Phase 6: User Story 4 - Sync with Remote (Priority: P3)

**Goal**: Developer can sync their branch with main (or specified branch) using smart rebase/merge selection

**Independent Test**: Run `/bkff:git-sync` on branches with/without pushed commits and verify correct strategy used

**Contract**: specs/001-git-lifecycle-plugin/contracts/git-sync.md

### Implementation for User Story 4

- [ ] T047 [US4] Create skill.md documentation for git-sync command in plugins/bkff-git/skills/git-sync/skill.md
- [ ] T048 [US4] Implement fetch from origin for worktree (FR-018) in plugins/bkff-git/skills/git-sync/SKILL.md
- [ ] T049 [US4] Implement pushed status detection (FR-019) in plugins/bkff-git/skills/git-sync/SKILL.md
- [ ] T050 [US4] Implement rebase strategy for unpushed branches (FR-020) in plugins/bkff-git/skills/git-sync/SKILL.md
- [ ] T051 [US4] Implement merge strategy for pushed branches (FR-021) in plugins/bkff-git/skills/git-sync/SKILL.md
- [ ] T052 [US4] Implement optional source branch parameter with main default (FR-022) in plugins/bkff-git/skills/git-sync/SKILL.md
- [ ] T053 [US4] Enable git rerere for automatic conflict resolution in plugins/bkff-git/skills/git-sync/SKILL.md
- [ ] T054 [US4] Implement automatic conflict resolution attempt (FR-023) in plugins/bkff-git/skills/git-sync/SKILL.md
- [ ] T055 [US4] Implement conflict reporting for manual resolution in plugins/bkff-git/skills/git-sync/SKILL.md
- [ ] T056 [US4] Add uncommitted changes check before sync in plugins/bkff-git/skills/git-sync/SKILL.md

**Checkpoint**: User Story 4 complete - `/bkff:git-sync` should be fully functional and testable independently

---

## Phase 7: User Story 5 - Manage Pull Request (Priority: P3)

**Goal**: Developer can create or update a PR for current branch using repository template

**Independent Test**: Run `/bkff:git-pr` on branches with/without existing PRs and verify correct create/update behavior

**Contract**: specs/001-git-lifecycle-plugin/contracts/git-pr.md

### Implementation for User Story 5

- [ ] T057 [US5] Create skill.md documentation for git-pr command in plugins/bkff-git/skills/git-pr/skill.md
- [ ] T058 [US5] Implement existing PR check via gh pr list (FR-024) in plugins/bkff-git/skills/git-pr/SKILL.md
- [ ] T059 [US5] Implement PR update for existing PRs (FR-025) in plugins/bkff-git/skills/git-pr/SKILL.md
- [ ] T060 [US5] Implement PR creation for new PRs (FR-026) in plugins/bkff-git/skills/git-pr/SKILL.md
- [ ] T061 [US5] Implement PR template detection and usage (FR-027) in plugins/bkff-git/skills/git-pr/SKILL.md
- [ ] T062 [US5] Implement default description generation from commits in plugins/bkff-git/skills/git-pr/SKILL.md
- [ ] T063 [US5] Implement push before PR creation (FR-028) in plugins/bkff-git/skills/git-pr/SKILL.md
- [ ] T064 [US5] Add --title override option support in plugins/bkff-git/skills/git-pr/SKILL.md
- [ ] T065 [US5] Add --draft option support in plugins/bkff-git/skills/git-pr/SKILL.md
- [ ] T066 [US5] Add main/master branch protection check in plugins/bkff-git/skills/git-pr/SKILL.md

**Checkpoint**: User Story 5 complete - `/bkff:git-pr` should be fully functional and testable independently

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, validation, and improvements across all commands

- [ ] T067 [P] Update README.md with complete command reference in plugins/bkff-git/README.md
- [ ] T068 [P] Add installation instructions to README.md in plugins/bkff-git/README.md
- [ ] T069 [P] Add troubleshooting section to README.md in plugins/bkff-git/README.md
- [ ] T070 Run make lint to validate plugin structure
- [ ] T071 Verify all commands work in sample git worktree
- [ ] T072 Run quickstart.md validation scenarios from specs/001-git-lifecycle-plugin/quickstart.md
- [ ] T073 Update marketplace.json if needed in .claude-plugin/marketplace.json

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P2 → P3 → P3)
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

| Story | Priority | Depends On | Can Parallelize With |
|-------|----------|------------|----------------------|
| US1 (git-st) | P1 | Foundational only | - |
| US2 (git-branch) | P2 | Foundational only | US1, US3, US4, US5 |
| US3 (git-commit) | P2 | Foundational only | US1, US2, US4, US5 |
| US4 (git-sync) | P3 | Foundational only | US1, US2, US3, US5 |
| US5 (git-pr) | P3 | Foundational only | US1, US2, US3, US4 |

**Note**: All user stories are independently testable. No cross-story dependencies.

### Within Each User Story

1. Create skill.md documentation first
2. Implement core functionality (FR requirements)
3. Add error handling
4. Add optional features (--flags)

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel
- Once Foundational completes, all 5 user stories can start in parallel
- Within Foundational: git-helpers.sh and validation.sh can be developed in parallel

---

## Parallel Example: Foundational Phase

```bash
# After T007-T009 (common.sh base), launch these in parallel:
Task: "Implement branch status detection in plugins/bkff-git/lib/git-helpers.sh"
Task: "Implement branch name parsing in plugins/bkff-git/lib/git-helpers.sh"
Task: "Implement git status parsing in plugins/bkff-git/lib/git-helpers.sh"
Task: "Implement build tool validation runner in plugins/bkff-git/lib/validation.sh"
Task: "Implement GPG signing check in plugins/bkff-git/lib/validation.sh"
```

## Parallel Example: User Stories After Foundational

```bash
# After Foundational complete, launch user stories in parallel:
Task: "Implement git-st command (US1) in plugins/bkff-git/skills/git-st/"
Task: "Implement git-branch command (US2) in plugins/bkff-git/skills/git-branch/"
Task: "Implement git-commit command (US3) in plugins/bkff-git/skills/git-commit/"
Task: "Implement git-sync command (US4) in plugins/bkff-git/skills/git-sync/"
Task: "Implement git-pr command (US5) in plugins/bkff-git/skills/git-pr/"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (git-st)
4. **STOP and VALIDATE**: Test `/bkff:git-st` independently
5. Deploy/demo if ready - developers can check status

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add US1 (git-st) → Test independently → MVP complete
3. Add US2 (git-branch) + US3 (git-commit) → Test → Core workflow complete
4. Add US4 (git-sync) + US5 (git-pr) → Test → Full feature set
5. Each story adds value without breaking previous stories

### Recommended Order (Single Developer)

1. **Phase 1-2**: Setup + Foundational (~T001-T016)
2. **Phase 3**: US1 git-st (P1) - MVP
3. **Phase 4**: US2 git-branch (P2) - Start new work
4. **Phase 5**: US3 git-commit (P2) - Save work
5. **Phase 6**: US4 git-sync (P3) - Stay current
6. **Phase 7**: US5 git-pr (P3) - Submit for review
7. **Phase 8**: Polish

This order follows the natural developer workflow: check status → create branch → make changes → commit → sync → create PR.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story (US1-US5)
- Each user story independently completable and testable
- All commands share common.sh and git-helpers.sh (Foundational phase)
- SKILL.md files contain both documentation AND implementation (bash code blocks)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies
