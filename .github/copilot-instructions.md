# Copilot Instructions — Automated Documentation Sync (docsync)

## Project Shape

| Aspect | Value |
|---|---|
| Project | `docsync` — CLI that detects drift between source code and `docs/` |
| Package | `src/docsync/` (invoked as `python -m docsync`) |
| Requirements | `requirements.md` (repo root — baseline FR-1..FR-8, NFR-1..NFR-6) |
| Language | Python 3.10+, **standard library only** (NFR-6 — no runtime deps) |
| Tests | `tests/` (pytest or `unittest`) |
| SDLC docs (per cycle) | `docs/TC-XXX/*.md` |
| Pipeline state | `outputs/phase-status.json` + `outputs/TC-XXX/phase-status.json` |

This repo is driven by an **8-phase agentic SDLC pipeline**, orchestrated through
GitHub Copilot **Agents**, **Prompts**, **Instructions**, **Skills**, and **Hooks**.
Every phase requires explicit human approval before the next phase starts.

## The 8 Phases

| # | Phase | Prompt | Output | Instructions |
|---|-------|--------|--------|---------------|
| 1 | Requirements | `.github/prompts/requirements.prompt.md` | `docs/TC-XXX/requirements.md` | `phase-1-requirements.instructions.md` |
| 2 | Architecture | `.github/prompts/architecture.prompt.md` | `docs/TC-XXX/architecture.md` | `phase-2-architecture.instructions.md` |
| 3 | Design Review | `.github/prompts/design-review.prompt.md` | `docs/TC-XXX/design-review.md` | `phase-3-design-review.instructions.md` |
| 4 | Impl Planning | `.github/prompts/impl-planning.prompt.md` | `docs/TC-XXX/impl-plan.md` | `phase-4-impl-planning.instructions.md` |
| 5 | Implementation | `.github/prompts/implementation.prompt.md` | `src/docsync/*.py`, `tests/*.py` | `docsync.instructions.md` (path-scoped) |
| 6 | Review | `.github/prompts/code-review.prompt.md` | `docs/TC-XXX/code-review.md` | `phase-6-code-review.instructions.md` |
| 7 | Verify | `.github/prompts/verification.prompt.md` | `docs/TC-XXX/verification.md` | `phase-7-verification.instructions.md` |
| 8 | PR | `.github/prompts/pr.prompt.md` | `docs/TC-XXX/pr-description.md`, `CHANGELOG.md` | `phase-8-pr.instructions.md` |

An end-to-end **orchestration agent** that drives all 8 phases with checkpoints
lives at `.github/prompts/orchestration-agent.prompt.md`. Custom Copilot
**agents** (personas) live in `.github/agents/`.

## How to Run a Phase

1. In Copilot Chat, switch to **Agent Mode**.
2. Initialize the pipeline once per test case:
   ```powershell
   scripts\init-pipeline.ps1 -TestCase TC-001 -UserStory "US-001: ..."
   ```
3. Invoke the phase prompt, e.g. `@requirements.prompt.md`. Copilot will ask for
   the active test case ID (`${testCase}`) if it cannot infer it.
4. Review the output the agent produces under `docs/TC-001/`.
5. Approve or reject:
   ```powershell
   scripts\approve-phase.ps1 -Phase 1 -Decision APPROVED -TestCase TC-001
   scripts\approve-phase.ps1 -Phase 1 -Decision REJECTED -Reason "..." -TestCase TC-001
   ```
6. Only after approval, invoke the next phase's prompt.

## How to Run the Full Pipeline

Invoke the orchestration agent instead of running phases one by one:
```
Use TC-001, user story "US-001: As a developer I want ...".
@orchestration-agent.prompt.md
```
It still stops for human approval at every phase — it just removes the need to
manually invoke each of the 8 prompt files yourself.

## How to Resume After an Interruption

```powershell
scripts\resume-pipeline.ps1 -TestCase TC-001 -FromPhase 4 -Force
```
This keeps phases 1–3 `APPROVED` and resets phase 4 onward to `PENDING`. Then
re-invoke that phase's prompt.

## Human-in-the-Loop Checkpoints

Every phase prompt ends by writing a `PENDING_APPROVAL` status and printing a
checkpoint summary with the exact approve/reject commands. **No prompt may
advance to the next phase on its own.** This is enforced by the "Pre-flight
Check" at the top of every phase prompt, which reads
`outputs/TC-XXX/phase-status.json` and refuses to proceed if the prior phase
is not `APPROVED`.

## Pipeline Status Tracking

```powershell
scripts\show-phase-status.ps1 -TestCase TC-001      # human-readable status table
scripts\check-agent-status.ps1 -TestCase TC-001     # machine-readable JSON
scripts\generate-tc-report.ps1 -TestCase TC-001      # roll-up report across all phases
```

## Output Directory Structure

```
docs/TC-001/                              <- SDLC artifacts (source of truth)
  requirements.md
  architecture.md
  design-review.md
  impl-plan.md
  code-review.md
  verification.md
  pr-description.md

outputs/phase-status.json                 <- master tracker (active_test_cases)
outputs/TC-001/phase-status.json          <- per-TC phase status
outputs/TC-001/phase-1-requirements/
  output.md                               <- archived copy of the phase output
  agent-log.json                          <- {phase, agent, completed_at, status}
  approval.json                           <- {decision, reason, approved_by, approved_at}
outputs/TC-001/phase-7-verification/
  test-results.json                       <- captured pytest/coverage results
```

## Security Rules

- **Never** hardcode secrets (tokens, credentials) in any file.
- Any credential (e.g. a GitHub token used by `scripts\create-github-pr.ps1`)
  comes from the environment or the local `gh` CLI auth — never from a
  committed file.
- No secrets in `.docsync` config files, logs, or commit history.
- The `docsync` tool itself must never print or write file contents, or
  environment variables, outside the given `--src`/`--docs` roots (NFR-3).

## Code Conventions

- Standard library only — no third-party runtime dependency (NFR-6).
- `from __future__ import annotations`, full type hints on public APIs.
- No unhandled exceptions for expected edge cases — see NFR-2 (missing paths,
  empty `docs/`, zero `.py` files) — always a clear message + correct exit code.
- Every implementation module ships with matching tests in `tests/`.
- Prefer clear naming over comments (NFR-5) — comment only non-obvious *why*.

## Do Not

- Do not skip a phase or invent SDLC-doc content ahead of the phase that owns it.
- Do not mark a phase `APPROVED` except via `scripts\approve-phase.ps1`.
- Do not commit, push, or open a PR without the human explicitly approving Phase 8.
- Do not add third-party runtime dependencies (violates NFR-6) without a
  design-review DD entry explicitly approving the exception.

## Quick Reference

```powershell
scripts\init-pipeline.ps1 -TestCase TC-002 -UserStory "US-002: ..."
scripts\approve-phase.ps1 -Phase 1 -Decision APPROVED -TestCase TC-002
scripts\resume-pipeline.ps1 -TestCase TC-002 -FromPhase 3 -Force
scripts\show-phase-status.ps1 -TestCase TC-002
scripts\generate-tc-report.ps1 -TestCase TC-002
scripts\create-github-pr.ps1 -TestCase TC-002
```
