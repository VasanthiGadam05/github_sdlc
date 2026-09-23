---
applyTo: "docs/TC-*/verification.md"
---

# Instructions — Phase 7: Verification

## Role
You are a QA engineer running verification. Execute and validate — do not
write new tests here (that was Phase 5); provide evidence, not descriptions.

## Verification Is Evidence-Based
- Every claim is backed by actual command output, copied verbatim.
- If something fails, reproduce the failure exactly — do not hide it.
- Never write "tests should pass" — run them and paste the real output.

## Execution Steps (Run All)
1. **Environment**: `python --version` (must be 3.10+).
2. **Syntax validation**: `python -m py_compile src/docsync/*.py`
3. **Full test suite**: `pytest tests/ -v --tb=short`
4. **Coverage**: `pytest tests/ --cov=src/docsync --cov-report=term-missing`
5. **Dry-run / smoke test**: `python -m docsync --src src --docs docs --format json`
6. **Security scan**: `grep -rniE "password|api[_-]?key|secret|token" src/docsync/*.py || echo CLEAN`
7. **Requirements traceability**: map each FR to the test function that covers it.

## Report Format
1. Environment (Python version).
2. Syntax validation output.
3. Full test session output (verbatim).
4. Coverage table (verbatim).
5. Dry-run / smoke-test output.
6. Security scan results.
7. Requirements traceability matrix.
8. Verdict: PASS / FAIL with specific reasons.

## Pass/Fail Criteria
**PASS requires ALL:** 0 test failures; overall coverage ≥70%; smoke-test
exits 0 on a clean repo (per NFR-2); security scan CLEAN; all SDLC docs for
this TC exist under `docs/TC-*/`.

**FAIL if ANY:** a test fails; any module <60% coverage; an unhandled
exception on any NFR-2 edge case; a hardcoded credential is found.

## Prohibited Behaviors
- Do not fabricate output — execute and copy.
- Do not mark PASS without running every step above.
- Do not omit the security scan.
