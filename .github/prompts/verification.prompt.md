---
mode: agent
description: Run comprehensive verification suite and produce docs/${testCase}/verification.md with test evidence
---

<!-- TC_ID RESOLUTION — read this first -->
> **Active test case (`${testCase}`):**
> - **GitHub Copilot** — you will be prompted to enter the test case ID (e.g. `TC-001`, `TC-002`). Copilot substitutes it everywhere `${testCase}` appears below.
> - **Claude Code** — read `outputs/phase-status.json` → `active_test_cases[0]`. Treat that value as `${testCase}` throughout this prompt.

## Pre-flight Check
Read `outputs/${testCase}/phase-status.json` and verify phase `"6"` has `"status": "APPROVED"`. If not:
> **Stop.** Phase 6 (Code Review) is not APPROVED. Run:
> ```powershell
> scripts\approve-phase.ps1 -Phase 6 -Decision APPROVED -TestCase ${testCase}
> ```
> Do not proceed until Phase 6 is APPROVED.

You are a QA engineer for the `docsync` project. Execute the full verification
suite and produce a verification report.

## Execute and Capture Output (All Steps Required)
1. **Environment**: `python --version`
2. **Syntax validation**: `python -m py_compile src/docsync/*.py`
3. **Full test suite**: `pytest tests/ -v --tb=short`
4. **Coverage**: `pytest tests/ --cov=src/docsync --cov-report=term-missing`
5. **Smoke test**: `python -m docsync --src src --docs docs --format json`
6. **Security scan**: `grep -rniE "password|api[_-]?key|secret|token" src/docsync/*.py || echo CLEAN`
7. **SDLC docs check**: verify `docs/${testCase}/requirements.md`, `architecture.md`, `design-review.md`, `impl-plan.md`, `code-review.md` all exist.

## Output: docs/${testCase}/verification.md
Sections:
1. Environment (Python version)
2. Syntax validation (verbatim output)
3. Test session output (verbatim — paste the COMPLETE output)
4. Coverage table (verbatim)
5. Smoke-test output
6. Security scan results
7. Requirements traceability (FR-* → test function)
8. Verdict: PASS or FAIL (with specific reason if FAIL)

## Pass Criteria
- All tests pass (0 failures)
- Coverage ≥ 70% overall
- Smoke-test exits 0
- Security scan CLEAN

Do NOT fabricate output. Run the commands. Copy actual results.

Context: `tests/`, `src/docsync/`, `docs/${testCase}/code-review.md`

## Save & Archive
After completing the verification report:
1. Write the full document to `docs/${testCase}/verification.md`
2. Write the same content to `outputs/${testCase}/phase-7-verification/output.md`
3. Write `outputs/${testCase}/phase-7-verification/agent-log.json`:
   ```json
   {
     "phase": 7,
     "phase_name": "Verification",
     "agent": "verification.prompt.md",
     "completed_at": "<current ISO timestamp>",
     "output_file": "docs/${testCase}/verification.md",
     "output_archived_to": "outputs/${testCase}/phase-7-verification/output.md",
     "status": "SUCCESS"
   }
   ```
4. Write `outputs/${testCase}/phase-7-verification/test-results.json`:
   ```json
   {
     "passed": 0,
     "failed": 0,
     "coverage_percent": 0,
     "smoke_test": "PASS",
     "security_scan": "CLEAN"
   }
   ```
5. Read `outputs/${testCase}/phase-status.json`, update `phases."7"` entry:
   ```json
   {
     "status": "PENDING_APPROVAL",
     "name": "Verification",
     "output_archive": "outputs/${testCase}/phase-7-verification/output.md",
     "phase_folder": "phase-7-verification",
     "completed_at": "<current ISO timestamp>"
   }
   ```
   Write the updated JSON file back.

## Human Checkpoint
Present this summary and wait — do not proceed to Phase 8 until the human approves:

**Phase 7 Complete — Verification**

- Output: `docs/${testCase}/verification.md`
- Archive: `outputs/${testCase}/phase-7-verification/output.md`
- Test result: [X passed, Y failed]
- Coverage: [overall %]
- Smoke-test: [PASS / FAIL]
- Security scan: [CLEAN / issues found]
- Verdict: [PASS / FAIL]

**Approval commands:**
- To APPROVE: `scripts\approve-phase.ps1 -Phase 7 -Decision APPROVED -TestCase ${testCase}`
- To REJECT: `scripts\approve-phase.ps1 -Phase 7 -Decision REJECTED -Reason "..." -TestCase ${testCase}`

Do not proceed to Phase 8 (PR Creation) until the human runs the approve script.
