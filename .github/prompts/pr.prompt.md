---
mode: agent
description: Create the Pull Request description, reviewer checklist, and CHANGELOG entry to complete the agentic SDLC cycle
---

<!-- TC_ID RESOLUTION — read this first -->
> **Active test case (`${testCase}`):**
> - **GitHub Copilot** — you will be prompted to enter the test case ID (e.g. `TC-001`, `TC-002`). Copilot substitutes it everywhere `${testCase}` appears below.
> - **Claude Code** — read `outputs/phase-status.json` → `active_test_cases[0]`. Treat that value as `${testCase}` throughout this prompt.

## Pre-flight Check
Read `outputs/${testCase}/phase-status.json` and verify phase `"7"` has `"status": "APPROVED"`. If not:
> **Stop.** Phase 7 (Verification) is not APPROVED. Run:
> ```powershell
> scripts\approve-phase.ps1 -Phase 7 -Decision APPROVED -TestCase ${testCase}
> ```
> Do not proceed until Phase 7 is APPROVED.

You are completing Phase 8 of the `docsync` Agentic SDLC pipeline. Create the
PR package.

## Outputs Required

### 1. docs/${testCase}/pr-description.md (ALL 5 sections mandatory)

**Summary** (2-3 sentences): What was built, why, that it was driven by an
8-phase agentic SDLC pipeline.

**Changes Made** (4 tables):
- SDLC Artifacts: `docs/${testCase}/*.md` files
- Source Code: `src/docsync/*.py` with reason per file
- Infrastructure: workflow, instructions, prompts, config files
- Tests: `tests/*.py` with what each covers

**Test Evidence**: Copy the test session output from
`docs/${testCase}/verification.md` VERBATIM. Include platform line and
coverage table.

**Known Limitations**: Table of every PARTIAL finding from `code-review.md`
and DEFERRED item from `design-review.md`.

**Reviewer Checklist**: Tick-list with SPECIFIC verifiable items for:
- Each FR (where to find the implementation)
- NFR-3 (no leakage), NFR-6 (no runtime deps)
- Test run command, smoke-test command
- Architecture alignment
- Design decision `DD-XX` implementation
- No secrets in history

### 2. CHANGELOG.md
Create/update with an entry listing all additions, architectural decisions,
and known limitations.

## Rules
- Test output must be actual output from `docs/${testCase}/verification.md` —
  not paraphrased.
- Every file that was created must appear in Changes Made.
- Known limitations must be honest and complete.
- Reviewer checklist items must be independently verifiable.

Context: `docs/${testCase}/verification.md`, `docs/${testCase}/code-review.md`, `docs/${testCase}/design-review.md`, `docs/${testCase}/requirements.md`

## Save & Archive
After completing the PR package:
1. Write the PR description to `docs/${testCase}/pr-description.md`
2. Write the same content to `outputs/${testCase}/phase-8-pr/output.md`
3. Write `outputs/${testCase}/phase-8-pr/agent-log.json`:
   ```json
   {
     "phase": 8,
     "phase_name": "PR Creation",
     "agent": "pr.prompt.md",
     "completed_at": "<current ISO timestamp>",
     "output_file": "docs/${testCase}/pr-description.md",
     "output_archived_to": "outputs/${testCase}/phase-8-pr/output.md",
     "status": "SUCCESS"
   }
   ```
4. Read `outputs/${testCase}/phase-status.json`, update `phases."8"` entry and set `pipeline_status`:
   ```json
   {
     "phases": {
       "8": {
         "status": "PENDING_APPROVAL",
         "name": "PR Creation",
         "output_archive": "outputs/${testCase}/phase-8-pr/output.md",
         "phase_folder": "phase-8-pr",
         "completed_at": "<current ISO timestamp>"
       }
     },
     "pipeline_status": "PIPELINE_COMPLETE_PENDING_APPROVAL"
   }
   ```
   Write the updated JSON file back.

## Human Checkpoint
Present this summary — this is the final phase:

**Phase 8 Complete — PR Creation (Pipeline Complete)**

- PR description: `docs/${testCase}/pr-description.md`
- Archive: `outputs/${testCase}/phase-8-pr/output.md`
- CHANGELOG.md: [updated / created]
- All 8 SDLC phases complete for `${testCase}`

**Approval commands:**
- To APPROVE: `scripts\approve-phase.ps1 -Phase 8 -Decision APPROVED -TestCase ${testCase}`
- To REJECT: `scripts\approve-phase.ps1 -Phase 8 -Decision REJECTED -Reason "..." -TestCase ${testCase}`

After approval, run `scripts\create-github-pr.ps1 -TestCase ${testCase}` to
open the actual GitHub Pull Request using `docs/${testCase}/pr-description.md`
as the body.
