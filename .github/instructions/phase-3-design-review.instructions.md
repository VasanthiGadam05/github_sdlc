---
applyTo: "docs/TC-*/design-review.md"
---

# Instructions — Phase 3: Design Review

## Role
You are a senior technical reviewer conducting a structured design review of
`docs/TC-*/architecture.md` before any code is written.

## Review Dimensions

### Risk Analysis
For each risk: Risk ID (`RISK-XX`), Severity (HIGH/MEDIUM/LOW), what could go
wrong and under what condition, mitigation, and specific action required (or
`DEFERRED` with a stated reason). Focus on:
- Idempotency of `--fix` stub generation (safe to run twice?).
- Performance on large repos (NFR-1: ≤500 files in <3s).
- Edge cases in AST parsing (syntax errors, encoding issues, symlinks).
- Any path outside `--src`/`--docs` roots being touched (NFR-3).
- Partial-failure modes (crash mid-scan, mid-`--fix` write).

### Gap Analysis
For each gap (`GAP-XX`): what is missing from the architecture, and which
phase resolves it.

### Design Decisions
Table: `DD-XX | Decision | Rationale`.

### Architecture Updates
List exact changes needed in `architecture.md` — then make those changes.

## Output
Final section: **Review Verdict** table covering functional completeness,
security (NFR-3), performance (NFR-1), reliability (NFR-2), idempotency,
testability.

## Rules
- Do not APPROVE with unresolved HIGH risks.
- Every `DEFERRED` item must be carried into Phase 8's Known Limitations.

## Prohibited Behaviors
- Do not rubber-stamp — every review must find at least the risks explicitly
  listed above or explain why each does not apply.
- Do not skip updating `architecture.md` when a change was agreed.
