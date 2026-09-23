---
mode: agent
description: Implement the docsync Python source code following the approved implementation plan
---

<!-- TC_ID RESOLUTION — read this first -->
> **Active test case (`${testCase}`):**
> - **GitHub Copilot** — you will be prompted to enter the test case ID (e.g. `TC-001`, `TC-002`). Copilot substitutes it everywhere `${testCase}` appears below.
> - **Claude Code** — read `outputs/phase-status.json` → `active_test_cases[0]`. Treat that value as `${testCase}` throughout this prompt.

## Pre-flight Check
Read `outputs/${testCase}/phase-status.json` and verify phase `"4"` has `"status": "APPROVED"`. If not:
> **Stop.** Phase 4 (Implementation Planning) is not APPROVED. Run:
> ```powershell
> scripts\approve-phase.ps1 -Phase 4 -Decision APPROVED -TestCase ${testCase}
> ```
> Do not proceed until Phase 4 is APPROVED.

You are implementing the `docsync` tool. Follow the task order in
`docs/${testCase}/impl-plan.md` exactly.

## Mandatory Coding Conventions
- `from __future__ import annotations` in every module.
- Full type annotations on all public APIs.
- Standard library only (NFR-6) — no new runtime dependency.
- `logging`, not `print()`, for anything beyond final CLI output.
- Clear, specific exceptions for every NFR-2 edge case, caught at the CLI
  boundary and converted to a message + correct exit code.

## Enforce All Design Decisions
Apply every `DD-XX` decision recorded in `docs/${testCase}/design-review.md`.
If a design decision cannot be implemented as written, stop and flag it —
do not silently deviate.

## After Each Module
Run: `pytest tests/test_{module}.py -v`
Fix any failing tests before proceeding to the next module.

## Quality Gate
Before reporting complete:
- `pytest tests/ -v` → 0 failures
- `python -m docsync --src src --docs docs --format json` → exits 0 on this repo

Context: `docs/${testCase}/impl-plan.md`, `docs/${testCase}/architecture.md`, `docs/${testCase}/design-review.md`, `.github/instructions/docsync.instructions.md`

## Save & Archive
After all modules are implemented and the quality gate passes:
1. Write an implementation summary to `outputs/${testCase}/phase-5-implementation/output.md`:
   - List every file created/modified under `src/docsync/` and `tests/`.
   - Include final `pytest` pass/fail counts.
   - Note any deviations from `docs/${testCase}/impl-plan.md`.
2. Write `outputs/${testCase}/phase-5-implementation/agent-log.json`:
   ```json
   {
     "phase": 5,
     "phase_name": "Implementation",
     "agent": "implementation.prompt.md",
     "completed_at": "<current ISO timestamp>",
     "output_file": "src/docsync/ (multiple files)",
     "output_archived_to": "outputs/${testCase}/phase-5-implementation/output.md",
     "status": "SUCCESS"
   }
   ```
3. Read `outputs/${testCase}/phase-status.json`, update `phases."5"` entry:
   ```json
   {
     "status": "PENDING_APPROVAL",
     "name": "Implementation",
     "output_archive": "outputs/${testCase}/phase-5-implementation/output.md",
     "phase_folder": "phase-5-implementation",
     "completed_at": "<current ISO timestamp>"
   }
   ```
   Write the updated JSON file back.

## Human Checkpoint
Present this summary and wait — do not proceed to Phase 6 until the human approves:

**Phase 5 Complete — Implementation**

- Summary: `outputs/${testCase}/phase-5-implementation/output.md`
- Modules written: [list src/docsync/*.py]
- Tests written: [list tests/*.py]
- pytest result: [X passed, 0 failed]
- Smoke-test result: [PASS / FAIL]

**Approval commands:**
- To APPROVE: `scripts\approve-phase.ps1 -Phase 5 -Decision APPROVED -TestCase ${testCase}`
- To REJECT: `scripts\approve-phase.ps1 -Phase 5 -Decision REJECTED -Reason "..." -TestCase ${testCase}`

Do not proceed to Phase 6 (Code Review) until the human runs the approve script.
