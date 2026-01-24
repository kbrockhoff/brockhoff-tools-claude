# Tasks: Brockhoff Cloud (bkff) Claude Plugin

**Input**: Design documents from `/specs/001-bkff-plugin/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: No explicit test tasks unless requested. Build system `validate` and `verify` targets handle testing.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Plugin structure follows Claude Plugin Marketplace standards:
- `plugins/bkff/.claude-plugin/` - Plugin manifest
- `plugins/bkff/skills/` - Skill definitions
- `plugins/bkff/agents/` - Agent definitions
- `plugins/bkff/lib/` - Shared bash libraries
- `plugins/bkff/tests/` - Test scripts

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create plugin directory structure per plan.md in plugins/bkff/
- [ ] T002 Create plugin manifest with metadata in plugins/bkff/.claude-plugin/plugin.json
- [ ] T003 [P] Create shared utility library in plugins/bkff/lib/common.sh
- [ ] T004 [P] Create test framework base in plugins/bkff/tests/test-helpers.sh

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Implement compliance check definitions in plugins/bkff/lib/compliance.sh
- [ ] T006 [P] Implement tasks.md parser in plugins/bkff/lib/tasks-parser.sh
- [ ] T007 [P] Implement loop state management in plugins/bkff/lib/loop-state.sh
- [ ] T008 [P] Implement verification helpers in plugins/bkff/lib/verification.sh
- [ ] T009 Create .bkff directory structure support in plugins/bkff/lib/common.sh

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Check Repository Compliance (Priority: P1) 🎯 MVP

**Goal**: Verify repository meets Brockhoff Cloud spec-driven development standards

**Independent Test**: Run `bkff:chkcompliance` on repositories in various states (compliant, partially compliant, non-compliant) and verify accurate issue identification

### Implementation for User Story 1

- [ ] T010 [US1] Create skill file in plugins/bkff/skills/chkcompliance/SKILL.md
- [ ] T011 [US1] Implement check_file_exists function in plugins/bkff/lib/compliance.sh
- [ ] T012 [US1] Implement check_directory_exists function in plugins/bkff/lib/compliance.sh
- [ ] T013 [US1] Implement check_file_content function in plugins/bkff/lib/compliance.sh
- [ ] T014 [US1] Implement check_command_success function for bd doctor in plugins/bkff/lib/compliance.sh
- [ ] T015 [US1] Implement run_all_checks function with JSON output in plugins/bkff/lib/compliance.sh
- [ ] T016 [US1] Add git repository validation in plugins/bkff/lib/common.sh

**Checkpoint**: User Story 1 (Check Compliance) should be fully functional and testable independently

---

## Phase 4: User Story 2 - Fix Repository Compliance Issues (Priority: P1)

**Goal**: Automatically fix compliance issues to bring repository into compliance

**Independent Test**: Run `bkff:fixcompliance` on non-compliant repository and verify all previously failing checks now pass

### Implementation for User Story 2

- [ ] T017 [US2] Create skill file in plugins/bkff/skills/fixcompliance/SKILL.md
- [ ] T018 [P] [US2] Implement create_github_files function in plugins/bkff/lib/compliance.sh
- [ ] T019 [P] [US2] Implement create_agents_md function in plugins/bkff/lib/compliance.sh
- [ ] T020 [P] [US2] Implement update_claude_md function in plugins/bkff/lib/compliance.sh
- [ ] T021 [P] [US2] Implement create_copilot_instructions function in plugins/bkff/lib/compliance.sh
- [ ] T022 [US2] Implement initialize_beads function in plugins/bkff/lib/compliance.sh
- [ ] T023 [US2] Implement fix_all_issues function with summary output in plugins/bkff/lib/compliance.sh

**Checkpoint**: User Stories 1 AND 2 (Compliance Check/Fix) should both work independently

---

## Phase 5: User Story 3 - Convert SpecKit Tasks to Beads Issues (Priority: P2)

**Goal**: Parse tasks.md and create beads issues with proper dependencies and hierarchy

**Independent Test**: Provide sample tasks.md and verify correct number of beads issues created with accurate titles, descriptions, priorities, and dependencies

### Implementation for User Story 3

- [ ] T024 [US3] Create skill file in plugins/bkff/skills/tasks2issues/SKILL.md
- [ ] T025 [US3] Implement parse_task_line function in plugins/bkff/lib/tasks-parser.sh
- [ ] T026 [US3] Implement extract_task_id function in plugins/bkff/lib/tasks-parser.sh
- [ ] T027 [US3] Implement extract_priority function in plugins/bkff/lib/tasks-parser.sh
- [ ] T028 [US3] Implement extract_user_story function in plugins/bkff/lib/tasks-parser.sh
- [ ] T029 [US3] Implement parse_phase function in plugins/bkff/lib/tasks-parser.sh
- [ ] T030 [US3] Implement create_beads_issue function in plugins/bkff/lib/tasks-parser.sh
- [ ] T031 [US3] Implement add_dependencies function in plugins/bkff/lib/tasks-parser.sh
- [ ] T032 [US3] Implement convert_tasks_to_issues main function in plugins/bkff/lib/tasks-parser.sh

**Checkpoint**: User Story 3 (Tasks to Issues) should be fully functional and testable independently

---

## Phase 6: User Story 4 - Start Agentic Development Loop (Priority: P2)

**Goal**: Initiate autonomous development loop that iteratively works through beads issues

**Independent Test**: Start loop with ready tasks, observe agent picking up tasks, verify proper task state transitions

### Implementation for User Story 4

- [ ] T033 [US4] Create skill file in plugins/bkff/skills/startloop/SKILL.md
- [ ] T034 [P] [US4] Create skill file in plugins/bkff/skills/cancelloop/SKILL.md
- [ ] T035 [US4] Implement init_loop_state function in plugins/bkff/lib/loop-state.sh
- [ ] T036 [US4] Implement save_loop_state function in plugins/bkff/lib/loop-state.sh
- [ ] T037 [US4] Implement load_loop_state function in plugins/bkff/lib/loop-state.sh
- [ ] T038 [US4] Implement select_ready_task function in plugins/bkff/lib/loop-state.sh
- [ ] T039 [US4] Implement retry_with_backoff function in plugins/bkff/lib/loop-state.sh
- [ ] T040 [US4] Implement pause_loop function in plugins/bkff/lib/loop-state.sh
- [ ] T041 [US4] Implement cancel_loop function in plugins/bkff/lib/loop-state.sh
- [ ] T042 [US4] Implement development_loop_cycle main function in plugins/bkff/lib/loop-state.sh

**Checkpoint**: User Story 4 (Development Loop) should be fully functional and testable independently

---

## Phase 7: User Story 5 - Verify Task Completion (Priority: P3)

**Goal**: Verify tasks, features, epics, and bugs are complete by executing build system targets

**Independent Test**: Run verification on completed and incomplete tasks, confirm correct identification of completion state with failures in expected format

### Implementation for User Story 5

- [ ] T043 [P] [US5] Create skill file in plugins/bkff/skills/verifytask/SKILL.md
- [ ] T044 [P] [US5] Create skill file in plugins/bkff/skills/verifyfeat/SKILL.md
- [ ] T045 [P] [US5] Create skill file in plugins/bkff/skills/verifyepic/SKILL.md
- [ ] T046 [P] [US5] Create skill file in plugins/bkff/skills/verifybug/SKILL.md
- [ ] T047 [US5] Implement check_acceptance_criteria function in plugins/bkff/lib/verification.sh
- [ ] T048 [US5] Implement run_build_target function in plugins/bkff/lib/verification.sh
- [ ] T049 [US5] Implement parse_build_output function in plugins/bkff/lib/verification.sh
- [ ] T050 [US5] Implement format_failure_json function in plugins/bkff/lib/verification.sh
- [ ] T051 [US5] Implement verify_task function in plugins/bkff/lib/verification.sh
- [ ] T052 [US5] Implement verify_feature function (includes child task check) in plugins/bkff/lib/verification.sh
- [ ] T053 [US5] Implement verify_epic function (includes child feature check) in plugins/bkff/lib/verification.sh
- [ ] T054 [US5] Implement verify_bug function in plugins/bkff/lib/verification.sh

**Checkpoint**: User Story 5 (Verification) should be fully functional and testable independently

---

## Phase 8: User Story 6 - Write Architectural Decision Records (Priority: P3)

**Goal**: Generate MADR-formatted ADRs using multi-agent pipeline (Writer → Validator → Formatter)

**Independent Test**: Invoke ADR command with various decision contexts, verify output conforms to MADR template, passes validation, and is properly formatted

### Implementation for User Story 6

- [ ] T055 [US6] Create skill file in plugins/bkff/skills/writeadr/SKILL.md (orchestrator)
- [ ] T056 [P] [US6] Create ADR Writer Agent in plugins/bkff/agents/adr-writer/AGENT.md
- [ ] T057 [P] [US6] Create ADR Validator Agent in plugins/bkff/agents/adr-validator/AGENT.md
- [ ] T058 [P] [US6] Create ADR Formatter Agent in plugins/bkff/agents/adr-formatter/AGENT.md

**Checkpoint**: User Story 6 (ADR Generation) should be fully functional and testable independently

---

## Phase 9: User Story 7 - Generate Unit Tests (Priority: P2)

**Goal**: Generate unit tests for newly implemented code based on structure, acceptance criteria, and testing best practices

**Independent Test**: Run test generation on sample code, verify generated tests compile, execute, and provide meaningful coverage

### Implementation for User Story 7

- [ ] T059 [US7] Create skill file in plugins/bkff/skills/gentests/SKILL.md
- [ ] T060 [US7] Document supported languages and test framework detection in SKILL.md
- [ ] T061 [US7] Document --update flag behavior for coverage gap analysis in SKILL.md
- [ ] T062 [US7] Document unsupported language handling with manual testing guidance in SKILL.md

**Checkpoint**: User Story 7 (Test Generation) should be fully functional and testable independently

---

## Phase 10: User Story 8 - Generate Project README (Priority: P3)

**Goal**: Generate or update comprehensive project README based on codebase, specs, and ADRs

**Independent Test**: Run README generation on project, verify output includes all required sections and accurately reflects the codebase

### Implementation for User Story 8

- [ ] T063 [US8] Create skill file in plugins/bkff/skills/genreadme/SKILL.md
- [ ] T064 [US8] Document section generation logic (Overview, Installation, Usage, Config, Contributing, License) in SKILL.md
- [ ] T065 [US8] Document --update flag with preserve marker support in SKILL.md
- [ ] T066 [US8] Document ADR section linking in SKILL.md

**Checkpoint**: User Story 8 (README Generation) should be fully functional and testable independently

---

## Phase 11: User Story 9 - Handle PR Review Feedback (Priority: P3)

**Goal**: Parse PR review comments, categorize them, and create beads tasks for required changes

**Independent Test**: Provide sample PR review comments, verify correct parsing, categorization, and task generation

### Implementation for User Story 9

- [ ] T067 [US9] Create skill file in plugins/bkff/skills/prfeedback/SKILL.md
- [ ] T068 [US9] Document comment categorization logic (required, suggestions, questions, nitpicks) in SKILL.md
- [ ] T069 [US9] Document beads task creation for required changes in SKILL.md
- [ ] T070 [US9] Document --ready flag for marking PR ready for re-review in SKILL.md
- [ ] T071 [US9] Document stale comment handling for deleted/changed files in SKILL.md

**Checkpoint**: User Story 9 (PR Feedback) should be fully functional and testable independently

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T072 [P] Create comprehensive plugin README in plugins/bkff/README.md
- [ ] T073 [P] Add compliance test script in plugins/bkff/tests/test-compliance.sh
- [ ] T074 [P] Add tasks parser test script in plugins/bkff/tests/test-tasks-parser.sh
- [ ] T075 [P] Add verification test script in plugins/bkff/tests/test-verification.sh
- [ ] T076 Run quickstart.md validation scenarios
- [ ] T077 Validate all skills pass `make lint` (claudelint)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-11)**: All depend on Foundational phase completion
  - User stories can then proceed in priority order (P1 → P2 → P3)
  - Some user stories within same priority can run in parallel
- **Polish (Phase 12)**: Depends on all desired user stories being complete

### User Story Dependencies

| User Story | Priority | Can Start After | Dependencies |
|------------|----------|-----------------|--------------|
| US1 (Check Compliance) | P1 | Phase 2 | None |
| US2 (Fix Compliance) | P1 | Phase 2 | None (but logically follows US1) |
| US3 (Tasks to Issues) | P2 | Phase 2 | None |
| US4 (Development Loop) | P2 | Phase 2 | None (but uses US3, US5, US7 internally) |
| US5 (Verification) | P3 | Phase 2 | None |
| US6 (ADR Generation) | P3 | Phase 2 | None |
| US7 (Test Generation) | P2 | Phase 2 | None |
| US8 (README Generation) | P3 | Phase 2 | None |
| US9 (PR Feedback) | P3 | Phase 2 | None |

### Within Each User Story

- Create SKILL.md/AGENT.md file first
- Library functions before skill implementation
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

**Phase 1 (Setup):**
```bash
# Can run in parallel:
Task: "Create shared utility library in plugins/bkff/lib/common.sh" (T003)
Task: "Create test framework base in plugins/bkff/tests/test-helpers.sh" (T004)
```

**Phase 2 (Foundational):**
```bash
# Can run in parallel:
Task: "Implement tasks.md parser in plugins/bkff/lib/tasks-parser.sh" (T006)
Task: "Implement loop state management in plugins/bkff/lib/loop-state.sh" (T007)
Task: "Implement verification helpers in plugins/bkff/lib/verification.sh" (T008)
```

**Phase 4 (US2 Fix Compliance):**
```bash
# Can run in parallel:
Task: "Implement create_github_files function" (T018)
Task: "Implement create_agents_md function" (T019)
Task: "Implement update_claude_md function" (T020)
Task: "Implement create_copilot_instructions function" (T021)
```

**Phase 7 (US5 Verification) - Skill files:**
```bash
# Can run in parallel:
Task: "Create skill file verifytask/SKILL.md" (T043)
Task: "Create skill file verifyfeat/SKILL.md" (T044)
Task: "Create skill file verifyepic/SKILL.md" (T045)
Task: "Create skill file verifybug/SKILL.md" (T046)
```

**Phase 8 (US6 ADR) - Agent files:**
```bash
# Can run in parallel:
Task: "Create ADR Writer Agent" (T056)
Task: "Create ADR Validator Agent" (T057)
Task: "Create ADR Formatter Agent" (T058)
```

**Phase 12 (Polish):**
```bash
# Can run in parallel:
Task: "Create comprehensive plugin README" (T072)
Task: "Add compliance test script" (T073)
Task: "Add tasks parser test script" (T074)
Task: "Add verification test script" (T075)
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only)

1. Complete Phase 1: Setup (4 tasks)
2. Complete Phase 2: Foundational (5 tasks)
3. Complete Phase 3: User Story 1 - Check Compliance (7 tasks)
4. Complete Phase 4: User Story 2 - Fix Compliance (7 tasks)
5. **STOP and VALIDATE**: Test compliance workflow independently
6. Deploy/demo if ready

### Incremental Delivery

1. **Foundation**: Setup + Foundational → Core libraries ready
2. **MVP (P1)**: US1 + US2 → Compliance check/fix works → Demo!
3. **Task Management (P2)**: US3 + US4 + US7 → Development loop works → Demo!
4. **Quality Gates (P3)**: US5 + US6 + US8 + US9 → Full workflow → Demo!
5. Each story adds value without breaking previous stories

### Task Count Summary

| Phase | User Story | Task Count |
|-------|------------|------------|
| 1 | Setup | 4 |
| 2 | Foundational | 5 |
| 3 | US1 (Check Compliance) | 7 |
| 4 | US2 (Fix Compliance) | 7 |
| 5 | US3 (Tasks to Issues) | 9 |
| 6 | US4 (Development Loop) | 10 |
| 7 | US5 (Verification) | 12 |
| 8 | US6 (ADR Generation) | 4 |
| 9 | US7 (Test Generation) | 4 |
| 10 | US8 (README Generation) | 4 |
| 11 | US9 (PR Feedback) | 5 |
| 12 | Polish | 6 |
| **Total** | | **77** |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Skills are markdown files with instructions for Claude to execute (not bash scripts)
- Agents are markdown files with system prompts and tool definitions
- Library files are bash scripts with shared functions
