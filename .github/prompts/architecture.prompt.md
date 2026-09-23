---
mode: agent
description: Design system architecture for docsync based on approved requirements
---

<!-- TC_ID RESOLUTION — read this first -->
> **Active test case (`${testCase}`):**
> - **GitHub Copilot** — you will be prompted to enter the test case ID (e.g. `TC-001`, `TC-002`). Copilot substitutes it everywhere `${testCase}` appears below.
> - **Claude Code** — read `outputs/phase-status.json` → `active_test_cases[0]`. Treat that value as `${testCase}` throughout this prompt.

## Pre-flight Check
Read `outputs/${testCase}/phase-status.json` and verify phase `"1"` has `"status": "APPROVED"`. If not:
> **Stop.** Phase 1 (Requirements) is not APPROVED. Run:
> ```powershell
> scripts\approve-phase.ps1 -Phase 1 -Decision APPROVED -TestCase ${testCase}
> ```
> Do not proceed until Phase 1 is APPROVED.

You are a senior software architect for the `docsync` project. Design a
complete system architecture based on the requirements in
`docs/${testCase}/requirements.md`.

## Your Output: docs/${testCase}/architecture.md

1. **System Overview** — narrative (2-3 paragraphs) + ASCII component diagram.
2. **Technology Choices** — table: Concern | Choice | Rationale. Every choice
   must respect NFR-6 (standard library only) unless requirements explicitly
   approved an exception.
3. **Component Responsibilities** — file path, purpose, public method
   signatures, dependencies, for each component.
4. **Data Flow** — numbered steps from CLI invocation to report output.
5. **Directory Layout** — complete file tree for `src/docsync/` and `tests/`.
6. **Security Architecture** — how NFR-3 is enforced structurally.
7. **Error Handling Strategy** — table: Scenario | Behaviour, for every NFR-2
   edge case.

## Constraints
- Must satisfy all FR and NFR from `docs/${testCase}/requirements.md`.
- Components must be independently testable (mockable interfaces).
- No component has more than one responsibility.
- No component depends on a third-party package (NFR-6).

Context: `docs/${testCase}/requirements.md`

## Save & Archive
After completing the architecture document:
1. Write the full document to `docs/${testCase}/architecture.md`
2. Write the same content to `outputs/${testCase}/phase-2-architecture/output.md`
3. Write `outputs/${testCase}/phase-2-architecture/agent-log.json`:
   ```json
   {
     "phase": 2,
     "phase_name": "Architecture",
     "agent": "architecture.prompt.md",
     "completed_at": "<current ISO timestamp>",
     "output_file": "docs/${testCase}/architecture.md",
     "output_archived_to": "outputs/${testCase}/phase-2-architecture/output.md",
     "status": "SUCCESS"
   }
   ```
4. Read `outputs/${testCase}/phase-status.json`, update `phases."2"` entry:
   ```json
   {
     "status": "PENDING_APPROVAL",
     "name": "Architecture",
     "output_archive": "outputs/${testCase}/phase-2-architecture/output.md",
     "phase_folder": "phase-2-architecture",
     "completed_at": "<current ISO timestamp>"
   }
   ```
   Write the updated JSON file back.

## Human Checkpoint
Present this summary and wait — do not proceed to Phase 3 until the human approves:

**Phase 2 Complete — Architecture**

- Output: `docs/${testCase}/architecture.md`
- Archive: `outputs/${testCase}/phase-2-architecture/output.md`
- Components defined: [count] | Tech choices: [count] | Error scenarios covered: [count]

**Approval commands:**
- To APPROVE: `scripts\approve-phase.ps1 -Phase 2 -Decision APPROVED -TestCase ${testCase}`
- To REJECT: `scripts\approve-phase.ps1 -Phase 2 -Decision REJECTED -Reason "..." -TestCase ${testCase}`

Do not proceed to Phase 3 (Design Review) until the human runs the approve script.
