---
mode: agent
description: Conduct a structured code review of the docsync implementation covering all 7 checklist areas
---

<!-- TC_ID RESOLUTION — read this first -->
> **Active test case (`${testCase}`):**
> - **GitHub Copilot** — you will be prompted to enter the test case ID (e.g. `TC-001`, `TC-002`). Copilot substitutes it everywhere `${testCase}` appears below.
> - **Claude Code** — read `outputs/phase-status.json` → `active_test_cases[0]`. Treat that value as `${testCase}` throughout this prompt.

## Pre-flight Check
Read `outputs/${testCase}/phase-status.json` and verify phase `"5"` has `"status": "APPROVED"`. If not:
> **Stop.** Phase 5 (Implementation) is not APPROVED. Run:
> ```powershell
> scripts\approve-phase.ps1 -Phase 5 -Decision APPROVED -TestCase ${testCase}
> ```
> Do not proceed until Phase 5 is APPROVED.

You are a senior peer reviewer for the `docsync` project. Conduct a thorough
code review of `src/docsync/` and `tests/`.

## Review Areas (All Required)

### 1. Correctness
For every FR in `requirements.md` and `docs/${testCase}/requirements.md`: find
the implementing code, verify it matches. Status: PASS / FAIL / PARTIAL.

### 2. Security
- No hardcoded credentials (grep the source).
- No file reads/writes outside the given `--src`/`--docs` roots (NFR-3).
- No environment variables read, printed, or logged.

### 3. Error Handling
Verify every failure mode from the architecture's error handling table is
implemented and tested.

### 4. Test Coverage
Run `pytest --cov=src/docsync --cov-report=term-missing`. Flag any module
< 80%. Check tests assert correct behavior, not just "no exception raised."

### 5. Code Clarity
Read as a new team member. Flag anything confusing. Verify single
responsibility per module.

### 6. DRY Principle
Find duplicated patterns (e.g. repeated path validation, repeated exit-code
handling) — is it refactored?

### 7. Dependency Safety
Check `requirements.txt`/`setup.py` — confirm no runtime dependency was
introduced (NFR-6); anything present must be dev/test-only.

## Output: docs/${testCase}/code-review.md
Format each finding:
```
**Finding CR-XX (SEVERITY):** File path, line. What is wrong.
**Recommendation:** Specific fix.
```

Final verdict: PASS / PASS WITH MINOR ISSUES / FAIL

Context: `src/docsync/*.py`, `tests/*.py`, `docs/${testCase}/requirements.md`

## Save & Archive
After completing the code review:
1. Write the full review document to `docs/${testCase}/code-review.md`
2. Write the same content to `outputs/${testCase}/phase-6-code-review/output.md`
3. Write `outputs/${testCase}/phase-6-code-review/agent-log.json`:
   ```json
   {
     "phase": 6,
     "phase_name": "Code Review",
     "agent": "code-review.prompt.md",
     "completed_at": "<current ISO timestamp>",
     "output_file": "docs/${testCase}/code-review.md",
     "output_archived_to": "outputs/${testCase}/phase-6-code-review/output.md",
     "status": "SUCCESS"
   }
   ```
4. Read `outputs/${testCase}/phase-status.json`, update `phases."6"` entry:
   ```json
   {
     "status": "PENDING_APPROVAL",
     "name": "Code Review",
     "output_archive": "outputs/${testCase}/phase-6-code-review/output.md",
     "phase_folder": "phase-6-code-review",
     "completed_at": "<current ISO timestamp>"
   }
   ```
   Write the updated JSON file back.

## Human Checkpoint
Present this summary and wait — do not proceed to Phase 7 until the human approves:

**Phase 6 Complete — Code Review**

- Output: `docs/${testCase}/code-review.md`
- Archive: `outputs/${testCase}/phase-6-code-review/output.md`
- Findings: [count CRITICAL/HIGH/MEDIUM/LOW]
- Coverage: [overall %] (modules below 80%: [list or NONE])
- Final verdict: [PASS / PASS WITH MINOR ISSUES / FAIL]

**Approval commands:**
- To APPROVE: `scripts\approve-phase.ps1 -Phase 6 -Decision APPROVED -TestCase ${testCase}`
- To REJECT: `scripts\approve-phase.ps1 -Phase 6 -Decision REJECTED -Reason "..." -TestCase ${testCase}`

Do not proceed to Phase 7 (Verification) until the human runs the approve script.
