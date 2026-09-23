---
name: pipeline-status-reporter
description: Reports the current status of the docsync SDLC pipeline for a test case — which phases are approved, pending, or rejected — by reading outputs/phase-status.json and outputs/<TC>/phase-status.json.
---

# Pipeline Status Reporter

Use this skill when the user asks "what's the status of TC-XXX", "what phase
are we on", or "is the pipeline blocked".

## Steps

1. Read `outputs/phase-status.json` (master tracker) to find
   `active_test_cases`. If the user did not specify a test case, use the
   first entry.
2. Read `outputs/<TC>/phase-status.json` for that test case.
3. Render a table:

   | Phase | Name | Status |
   |-------|------|--------|
   | 1 | Requirements | APPROVED |
   | 2 | Architecture | PENDING_APPROVAL |
   | ... | ... | NOT_STARTED |

4. If any phase is `PENDING_APPROVAL`, print the exact approval command:
   ```powershell
   scripts\approve-phase.ps1 -Phase <N> -Decision APPROVED -TestCase <TC>
   ```
5. If any phase is `REJECTED`, show the recorded rejection reason and note
   that the phase must be re-run before the pipeline can advance.
6. If all 8 phases are `APPROVED`, report the pipeline as
   `PIPELINE_COMPLETE_PENDING_APPROVAL` or fully complete, and mention the PR
   URL if `create-github-pr.ps1` has already been run.

## Equivalent script
`scripts\show-phase-status.ps1 -TestCase <TC>` performs the same read and
prints the table directly — prefer invoking that script when running in a
terminal-capable context; use this skill's manual read/render steps when only
file-read tools are available (e.g. inside GitHub Copilot Chat without
terminal access).

## Hard Rules
- Never mark a phase as APPROVED yourself — only report what is on disk.
- Never fabricate a phase's status if the JSON file is missing; report
  "not initialized" and point to `scripts\init-pipeline.ps1`.
