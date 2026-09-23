---
name: tc-report-generator
description: Generates a single consolidated Markdown report for a test case, summarizing all 8 phase outputs, approval history, and final verdicts.
---

# TC Report Generator

Use this skill when the user asks for a "summary of TC-XXX" or "full report
for TC-XXX" spanning all phases.

## Steps

1. Read `outputs/<TC>/phase-status.json` for phase statuses and timestamps.
2. For each phase 1-8 that has completed, read its archived output:
   `outputs/<TC>/phase-N-<name>/output.md`.
3. Produce `outputs/<TC>/tc-report.md` with:
   - Header: test case ID, user story, overall pipeline status.
   - One section per phase: name, status, approved-at timestamp, a 2-4
     sentence summary of that phase's output (not a full copy).
   - A consolidated "Key Decisions" list pulled from `DD-XX` entries in
     `design-review.md`.
   - A consolidated "Known Limitations" list pulled from `PARTIAL`/`DEFERRED`
     findings in `code-review.md` and `design-review.md`.
   - Final verification verdict (from `verification.md`) and PR link (from
     `phase-status.json` `pr_url`, if present).

## Equivalent script
`scripts\generate-tc-report.ps1 -TestCase <TC>` performs the same read and
file-write directly from PowerShell.

## Hard Rules
- Summarize, don't fabricate — every claim in the report must trace back to
  an actual phase output file.
- If a phase has not completed, list it as "Not yet reached" rather than
  guessing its content.
