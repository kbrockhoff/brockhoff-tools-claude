Convert the speckit task list to bd issues using the speckit2beads skill.

Follow these steps:

1. If no path is provided as an argument, ask the user for the path to the tasks.md file
2. Read the tasks.md file
3. Parse the markdown structure:
   - Extract epic title from `# Tasks: <Title>` heading
   - Identify phase headers (`## Phase N: Title`) → features
   - Find task items (`- [ ] T###`) → tasks under their phase's feature
   - Extract metadata:
     - `**Purpose**` or `**Goal**` → feature description
     - `**Checkpoint**` → feature acceptance_criteria
     - `**Contract**` reference → feature acceptance_criteria
     - `[P]` marker → parallel label
     - `[US#]` marker → user-story label
     - `(Priority: P#)` → feature priority (P1=1, P2=2, P3=3)
     - File paths in task descriptions → design field
4. Parse "Dependencies & Execution Order" section for cross-phase dependencies
5. Generate JSONL preview of all issues to be created
6. Show the JSONL to the user for review
7. Ask if they want to proceed with creating the issues
8. If yes, create the issues using bd create commands
9. Add dependencies:
   - Tasks block their parent feature
   - Features block the epic
   - Cross-phase dependencies (e.g., Phase 2 blocks Phases 3-7)

Important:
- Preserve task IDs (T001, T002, etc.) in issue titles
- Use intelligent field distribution (description for "what", design for file paths and "how", acceptance_criteria for checkpoints and contracts)
- Set correct blocking dependencies so work flows in the right order
- Generate proper issue IDs following bd's prefix pattern
