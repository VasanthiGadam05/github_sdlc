---
mode: agent
description: Break the approved architecture into a prioritized, dependency-ordered implementation task list
---

<!-- TC_ID RESOLUTION — read this first -->
> **Active test case (`${testCase}`):**
> - **GitHub Copilot** — you will be prompted to enter the test case ID (e.g. `TC-001`, `TC-002`). Copilot substitutes it everywhere `${testCase}` appears below.
> - **Claude Code** — read `outputs/phase-status.json` → `active_test_cases[0]`. Treat that value as `${testCase}` throughout this prompt.

## Pre-flight Check
Read `outputs/${testCase}/phase-status.json` and verify phase `"3"` has `"status": "APPROVED"`. If not:
> **Stop.** Phase 3 (Design Review) is not APPROVED. Run:
> ```powershell
> scripts\approve-phase.ps1 -Phase 3 -Decision APPROVED -TestCase ${testCase}
> ```
> Do not proceed until Phase 3 is APPROVED.

You are a technical lead for the `docsync` project. Break down the approved
architecture into a concrete implementation plan.

## Your Output: docs/${testCase}/impl-plan.md

### Task Breakdown
| Task | Description | Depends On | Priority | Estimate |
|------|--------------|------------|----------|----------|

Priorities: P0 (blocking), P1 (core), P2 (enhancement).
Estimates: 15min / 30min / 45min / 60min / 90min.
Name a specific file in every task description (e.g. `src/docsync/scanner.py`),
never a vague phrase like "implement scanner".

### Dependency Graph
ASCII graph showing task dependencies. Include the critical path.

### Blocked Tasks Summary
Table: Task | Blocked By | Reason (specific, not generic).

### Effort Estimate
Total per phase and overall.

## Rules
- Every implementation task must have a paired test task.
- P0 tasks must form a complete connected subgraph.
- No circular dependencies.

Context: `docs/${testCase}/architecture.md`, `docs/${testCase}/design-review.md`

## Save & Archive
After completing the implementation plan:
1. Write the full document to `docs/${testCase}/impl-plan.md`
2. Write the same content to `outputs/${testCase}/phase-4-impl-planning/output.md`
3. Write `outputs/${testCase}/phase-4-impl-planning/agent-log.json`:
   ```json
   {
     "phase": 4,
     "phase_name": "Implementation Planning",
     "agent": "impl-planning.prompt.md",
     "completed_at": "<current ISO timestamp>",
     "output_file": "docs/${testCase}/impl-plan.md",
     "output_archived_to": "outputs/${testCase}/phase-4-impl-planning/output.md",
     "status": "SUCCESS"
   }
   ```
4. Read `outputs/${testCase}/phase-status.json`, update `phases."4"` entry:
   ```json
   {
     "status": "PENDING_APPROVAL",
     "name": "Implementation Planning",
     "output_archive": "outputs/${testCase}/phase-4-impl-planning/output.md",
     "phase_folder": "phase-4-impl-planning",
     "completed_at": "<current ISO timestamp>"
   }
   ```
   Write the updated JSON file back.

## Human Checkpoint
Present this summary and wait — do not proceed to Phase 5 until the human approves:

**Phase 4 Complete — Implementation Planning**

- Output: `docs/${testCase}/impl-plan.md`
- Archive: `outputs/${testCase}/phase-4-impl-planning/output.md`
- Total tasks: [count] | P0 tasks: [count] | Critical path length: [estimate]
- Total effort estimate: [sum]

**Approval commands:**
- To APPROVE: `scripts\approve-phase.ps1 -Phase 4 -Decision APPROVED -TestCase ${testCase}`
- To REJECT: `scripts\approve-phase.ps1 -Phase 4 -Decision REJECTED -Reason "..." -TestCase ${testCase}`

Do not proceed to Phase 5 (Implementation) until the human runs the approve script.
