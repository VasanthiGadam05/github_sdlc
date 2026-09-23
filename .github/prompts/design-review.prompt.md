---
mode: agent
description: Conduct a structured design review of docs/${testCase}/architecture.md as a senior reviewer
---

<!-- TC_ID RESOLUTION — read this first -->
> **Active test case (`${testCase}`):**
> - **GitHub Copilot** — you will be prompted to enter the test case ID (e.g. `TC-001`, `TC-002`). Copilot substitutes it everywhere `${testCase}` appears below.
> - **Claude Code** — read `outputs/phase-status.json` → `active_test_cases[0]`. Treat that value as `${testCase}` throughout this prompt.

## Pre-flight Check
Read `outputs/${testCase}/phase-status.json` and verify phase `"2"` has `"status": "APPROVED"`. If not:
> **Stop.** Phase 2 (Architecture) is not APPROVED. Run:
> ```powershell
> scripts\approve-phase.ps1 -Phase 2 -Decision APPROVED -TestCase ${testCase}
> ```
> Do not proceed until Phase 2 is APPROVED.

You are a senior technical reviewer for the `docsync` project. Conduct a
thorough design review of `docs/${testCase}/architecture.md` before any code
is written.

## Review Dimensions

### Risk Analysis
For each risk: Risk ID (`RISK-XX`), Severity (HIGH/MEDIUM/LOW), what could go
wrong and under what condition, mitigation, and specific action required
(or `DEFERRED` with reason). Focus on:
- Idempotency of `--fix` stub generation.
- Performance on large repos (NFR-1).
- AST parsing edge cases (syntax errors, encoding, symlinks).
- Any path escaping the given `--src`/`--docs` roots (NFR-3).
- Partial-failure modes (crash mid-scan or mid-write).

### Gap Analysis
For each gap (`GAP-XX`): what is missing, and which phase resolves it.

### Design Decisions
Table: `DD-XX | Decision | Rationale`.

### Architecture Updates
List exact changes needed in `architecture.md` — then make those changes.

## Output: docs/${testCase}/design-review.md
Final section: **Review Verdict** table covering functional completeness,
security, performance, reliability, idempotency, testability.

Do not APPROVE with unresolved HIGH risks.

Context: `docs/${testCase}/architecture.md`, `docs/${testCase}/requirements.md`

## Save & Archive
After completing the design review (and any architecture updates):
1. Write the full review document to `docs/${testCase}/design-review.md`
2. Write the same content to `outputs/${testCase}/phase-3-design-review/output.md`
3. Write `outputs/${testCase}/phase-3-design-review/agent-log.json`:
   ```json
   {
     "phase": 3,
     "phase_name": "Design Review",
     "agent": "design-review.prompt.md",
     "completed_at": "<current ISO timestamp>",
     "output_file": "docs/${testCase}/design-review.md",
     "output_archived_to": "outputs/${testCase}/phase-3-design-review/output.md",
     "status": "SUCCESS"
   }
   ```
4. Read `outputs/${testCase}/phase-status.json`, update `phases."3"` entry:
   ```json
   {
     "status": "PENDING_APPROVAL",
     "name": "Design Review",
     "output_archive": "outputs/${testCase}/phase-3-design-review/output.md",
     "phase_folder": "phase-3-design-review",
     "completed_at": "<current ISO timestamp>"
   }
   ```
   Write the updated JSON file back.

## Human Checkpoint
Present this summary and wait — do not proceed to Phase 4 until the human approves:

**Phase 3 Complete — Design Review**

- Output: `docs/${testCase}/design-review.md`
- Archive: `outputs/${testCase}/phase-3-design-review/output.md`
- Risks found: [count HIGH/MEDIUM/LOW] | Gaps found: [count] | Design decisions: [count DD-XX]
- Architecture updates applied: [YES/NO — list if yes]
- Review verdict: [PASS / FAIL — state unresolved HIGH risks if any]

**Approval commands:**
- To APPROVE: `scripts\approve-phase.ps1 -Phase 3 -Decision APPROVED -TestCase ${testCase}`
- To REJECT: `scripts\approve-phase.ps1 -Phase 3 -Decision REJECTED -Reason "..." -TestCase ${testCase}`

Do not proceed to Phase 4 (Implementation Planning) until the human runs the approve script.
