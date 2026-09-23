# docsync Agentic SDLC Pipeline — Run Order Guide

This repo's `.github/` scaffolding drives an 8-phase Agentic SDLC pipeline for
the **docsync** tool (a stdlib-only Python CLI that detects drift between
public API symbols and their Markdown documentation). Every phase requires an
explicit human approval before the next one may start — no prompt or agent is
ever allowed to self-approve.

This guide only describes *how to run* the pipeline that is already scaffolded
here. It does not contain (and must not be used to author) any actual
requirements, architecture, or implementation content — that is produced by
you, interactively, by invoking the prompts below.

## One-time setup

```powershell
scripts\install-git-hooks.ps1
```

Installs `.github/hooks/pre-commit` into `.git/hooks/pre-commit`. It blocks
commits containing hardcoded secrets, direct edits to the root
`requirements.md`, or `src/docsync/` changes that skip Phase 5 approval.

## Starting a new test case

```powershell
scripts\init-pipeline.ps1 -TestCase TC-001 -UserStory "US-001: As a developer I want docsync to detect renamed functions"
```

Creates `outputs\TC-001\phase-status.json` (all 8 phases `NOT_STARTED`),
`docs\TC-001\`, and registers `TC-001` in the master
`outputs\phase-status.json` tracker.

## Running the 8 phases

Invoke each phase's prompt in GitHub Copilot Chat (agent mode) 
Every prompt resolves `${testCase}` from the master tracker, checks the prior
phase is `APPROVED`, does the phase's work, then archives its output and stops
at a **Human Checkpoint** — it will never advance itself.

| # | Phase | Prompt | Produces |
|---|-------|--------|----------|
| 1 | Requirements | `@requirements.prompt.md` | `docs/<TC>/requirements.md` |
| 2 | Architecture | `@architecture.prompt.md` | `docs/<TC>/architecture.md` |
| 3 | Design Review | `@design-review.prompt.md` | `docs/<TC>/design-review.md` |
| 4 | Implementation Planning | `@impl-planning.prompt.md` | `docs/<TC>/impl-plan.md` |
| 5 | Implementation | `@implementation.prompt.md` | code under `src/docsync/`, `docs/<TC>/impl-notes.md` |
| 6 | Code Review | `@code-review.prompt.md` | `docs/<TC>/code-review.md` |
| 7 | Verification | `@verification.prompt.md` | `docs/<TC>/verification.md` + `test-results.json` |
| 8 | PR Creation | `@pr.prompt.md` | `docs/<TC>/pr-description.md` |

After each phase finishes, review its archived output at
`outputs\<TC>\phase-N-<name>\output.md`, then either:

```powershell
scripts\approve-phase.ps1 -Phase N -Decision APPROVED -TestCase TC-001
```

or, if it needs rework:

```powershell
scripts\approve-phase.ps1 -Phase N -Decision REJECTED -TestCase TC-001 -Reason "explain what must change"
```

A `REJECTED` phase must be re-invoked (its prompt, with the reason as
feedback) before it can be approved again.

Alternatively, drive the whole sequence with `@orchestration-agent.prompt.md`,
which loops through phases 1-8 automatically but still stops at every Human
Checkpoint waiting for the `approve-phase.ps1` decision above.

## Checking status

```powershell
scripts\show-phase-status.ps1 -TestCase TC-001
scripts\check-agent-status.ps1 -TestCase TC-001
```

`show-phase-status.ps1` prints a table of all 8 phases with status and
timestamps, plus the exact approval command for anything
`PENDING_APPROVAL`. `check-agent-status.ps1` cross-checks each phase's
`agent-log.json` against the tracker and flags inconsistencies.

## Resuming after an interruption

```powershell
scripts\resume-pipeline.ps1 -TestCase TC-001 -FromPhase 4 -Force
```

Resets phases 4-8 back to `NOT_STARTED` (phases 1-3 are left untouched) so the
pipeline can be re-entered at Phase 4. Omit `-Force` to require phases 1-3 to
already be `APPROVED`.

## Verification helpers

```powershell
scripts\capture-test-results.ps1 -TestCase TC-001
```

Runs `pytest`, coverage, the docsync smoke test, and a secret scan, writing
`outputs\TC-001\phase-7-verification\test-results.json`. This supplements —
does not replace — the full `verification.prompt.md` report.

## Opening the Pull Request

Once Phase 8 is `APPROVED`:

```powershell
scripts\create-github-pr.ps1 -TestCase TC-001
```

Pushes the current branch and runs `gh pr create` using
`docs\TC-001\pr-description.md` as the PR body. Requires `gh auth login` to
already be set up — this script never handles a token directly.

## Final report

```powershell
scripts\generate-tc-report.ps1 -TestCase TC-001
```

Consolidates all 8 phases (status, timestamps, output previews, rejection
reasons) into `outputs\TC-001\tc-report.md`.

## CI

`.github/workflows/docsync-ci.yml` runs on every push/PR: installs Python
3.10+, verifies no runtime dependency was added to `requirements.txt`
(docsync is stdlib-only per NFR-6), runs the test suite, and runs docsync
against this repo's own `src/` and `docs/` — failing the build on any "Not
Found in docs" symbol and warning (never failing) on orphaned doc sections.

## Reference

- `.github/copilot-instructions.md` — repo-wide Copilot context.
- `.github/instructions/*.instructions.md` — path-scoped conventions.
- `.github/agents/*.agent.md` — persona definitions for orchestrator,
  requirements-analyst, architect-reviewer, qa-verifier.
- `.github/skills/*/SKILL.md` — status reporting, PR creation, TC report
  generation as Copilot Skills (mirrors the `scripts/*.ps1` equivalents).
- `.github/hooks/pre-commit` — enforces this workflow at commit time.
