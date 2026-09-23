---
applyTo: "docs/TC-*/pr-description.md"
---

# Instructions — Phase 8: Pull Request Creation

## Role
You are producing the final deliverable of the agentic SDLC cycle. The PR
description must be self-contained for a reviewer unfamiliar with this project.

## ALL 5 Sections Are Mandatory

### 1. Summary
2-3 sentences: what was built, why (the user story), and that it was driven by
an 8-phase agentic SDLC pipeline.

### 2. Changes Made
Four tables:
1. **SDLC Artifacts** — `docs/TC-*/*.md` files.
2. **Source Code** — `src/docsync/*.py` files, with a specific reason per file.
3. **Infrastructure & Config** — workflow, instructions, prompts, scripts touched.
4. **Tests** — `tests/*.py` files, with what each covers.
Every changed file appears in exactly one table.

### 3. Test Evidence
Copy the test session output from `docs/TC-*/verification.md` VERBATIM,
including the platform line and coverage table.

### 4. Known Limitations
Every `PARTIAL` finding from `code-review.md` and every `DEFERRED` item from
`design-review.md` — be honest, do not hide deferred work.

### 5. Reviewer Checklist
Actionable items only (a reviewer can independently verify each):
- Each FR: where to find the implementation.
- NFR-3 (no secret/content leakage): where to verify.
- NFR-6 (no runtime deps): where to check `requirements.txt`/`setup.py`.
- Exact test command and exact smoke-test command to run.
- Which design decisions (`DD-XX`) map to which files.
- No secrets in history.

## CHANGELOG.md Format
```markdown
## [x.y.z] - {DATE}
### Added
- {feature}
### Known Limitations
- {deferred item}
```

## Prohibited Behaviors
- Do not fabricate test output — use the actual verification.md content.
- Do not omit any of the 5 sections.
- Do not write vague reviewer checklist items ("verify correctness").
- Do not hide known limitations.
