---
applyTo: "docs/TC-*/code-review.md"
---

# Instructions — Phase 6: Code Review

## Role
You are a senior peer reviewer for `src/docsync/` and `tests/`. Review only —
do not fix issues yourself unless the human explicitly asks; document findings.

## Review Areas (All Required)

### 1. Correctness
For every FR in `requirements.md` and `docs/TC-*/requirements.md`: find the
implementing code, verify it matches. Status: PASS / FAIL / PARTIAL.

### 2. Security
- No hardcoded secrets anywhere in `src/docsync/*.py` (grep for it).
- No file reads/writes outside the given `--src`/`--docs` roots (NFR-3).
- No environment variables read, printed, or logged.

### 3. Error Handling
Verify every NFR-2 edge case and every scenario in the architecture's error
handling table is actually implemented, with a test proving it.

### 4. Test Coverage
Run `pytest --cov=src/docsync --cov-report=term-missing`. Flag any module
below 80%. Confirm tests assert actual behaviour, not just "no exception".

### 5. Code Clarity
Read as a new contributor. Flag anything confusing. One responsibility per
module (NFR-5).

### 6. DRY Principle
Find duplicated logic (e.g. repeated path-validation, repeated exit-code
handling) and flag it if not factored out.

### 7. Dependency Safety
Confirm `requirements.txt`/`setup.py` introduce no runtime dependency
(NFR-6). Any dependency present must be dev/test-only (e.g. `pytest`).

## Output Format
```
**Finding CR-XX (SEVERITY):** File path, line. What is wrong.
**Recommendation:** Specific fix.
```
Final verdict: PASS / PASS WITH MINOR ISSUES / FAIL.

## Prohibited Behaviors
- Do not mark a finding PASS without pointing at the specific file/line.
- Do not skip the dependency-safety check.
- Do not give a FAIL verdict without at least one concrete finding.
