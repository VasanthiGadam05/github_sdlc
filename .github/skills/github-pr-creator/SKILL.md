---
name: github-pr-creator
description: Opens the GitHub Pull Request for a completed docsync test case using the gh CLI, once Phase 8 has been approved.
---

# GitHub PR Creator

Use this skill after Phase 8 (PR Creation) has been APPROVED for a test case,
to actually open the Pull Request on GitHub.

## Pre-conditions
1. Read `outputs/<TC>/phase-status.json` — phase `"8"` must have
   `"status": "APPROVED"`. If not, stop and tell the user to run:
   ```powershell
   scripts\approve-phase.ps1 -Phase 8 -Decision APPROVED -TestCase <TC>
   ```
2. `docs/<TC>/pr-description.md` must exist.
3. The `gh` CLI must be authenticated (`gh auth status`). This skill never
   asks for or handles a personal access token directly — auth is delegated
   entirely to the `gh` CLI's own login state.

## Steps
1. Confirm the current branch contains the committed implementation for
   `<TC>` (`git status`, `git log`). Do not create a PR from an empty diff.
2. Push the current branch if it is not already pushed:
   `git push -u origin <branch>`
3. Create the PR:
   ```powershell
   gh pr create --title "[<TC>] <short title>" --base main --body-file docs/<TC>/pr-description.md
   ```
4. Report the returned PR URL to the user.
5. Update `outputs/<TC>/phase-status.json` with the PR URL under a
   `pr_url` key.

## Equivalent script
`scripts\create-github-pr.ps1 -TestCase <TC>` wraps steps 1-4.

## Hard Rules
- Never fabricate a PR URL — only report what `gh pr create` actually returns.
- Never force-push or push to `main` directly.
- Never create the PR before Phase 8 is APPROVED.
- Never embed a token or credential in the command — rely solely on the
  ambient `gh` CLI authentication.
