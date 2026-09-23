#!/usr/bin/env bash
# Opens the GitHub Pull Request for a test case whose Phase 8 has been approved.
#
# Wraps the GitHub CLI (`gh`). Pushes the current branch if needed, then runs
# `gh pr create` using docs/<TestCase>/pr-description.md as the PR body.
# Never handles a token directly — relies entirely on `gh auth`.
#
# Usage:
#   scripts/create-github-pr.sh --test-case TC-001 [--base main]
set -euo pipefail

usage() {
  echo "Usage: scripts/create-github-pr.sh --test-case TC-001 [--base main]" >&2
  exit 1
}

TEST_CASE=""
BASE="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --test-case) TEST_CASE="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -z "$TEST_CASE" ]] && usage
[[ "$TEST_CASE" =~ ^TC-[0-9]+$ ]] || { echo "Error: --test-case must match TC-<number>" >&2; exit 1; }

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TC_STATUS_PATH="$REPO_ROOT/outputs/$TEST_CASE/phase-status.json"

if [[ ! -f "$TC_STATUS_PATH" ]]; then
  echo "Error: no pipeline found for $TEST_CASE." >&2
  exit 1
fi

PHASE8_STATUS="$(TC_STATUS_PATH="$TC_STATUS_PATH" python3 <<'PY'
import json, os
with open(os.environ["TC_STATUS_PATH"], encoding="utf-8") as f:
    status = json.load(f)
print(status["phases"]["8"]["status"])
PY
)"

if [[ "$PHASE8_STATUS" != "APPROVED" ]]; then
  echo "Error: Phase 8 (PR Creation) for $TEST_CASE is '$PHASE8_STATUS', not APPROVED. Run scripts/approve-phase.sh --phase 8 --decision APPROVED --test-case $TEST_CASE first." >&2
  exit 1
fi

PR_DESC_PATH="$REPO_ROOT/docs/$TEST_CASE/pr-description.md"
if [[ ! -f "$PR_DESC_PATH" ]]; then
  echo "Error: PR description not found: $PR_DESC_PATH" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: GitHub CLI (gh) is not installed or not on PATH." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Error: gh CLI is not authenticated. Run 'gh auth login' first (interactively) — this script never handles tokens directly." >&2
  exit 1
fi

cd "$REPO_ROOT"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" == "$BASE" ]]; then
  echo "Error: currently on '$BASE'. Create/checkout a feature branch for $TEST_CASE before opening a PR." >&2
  exit 1
fi

git push -u origin "$CURRENT_BRANCH"

USER_STORY="$(TC_STATUS_PATH="$TC_STATUS_PATH" python3 <<'PY'
import json, os
with open(os.environ["TC_STATUS_PATH"], encoding="utf-8") as f:
    status = json.load(f)
print(status.get("user_story", ""))
PY
)"

TITLE="[$TEST_CASE] $USER_STORY"
if [[ ${#TITLE} -gt 100 ]]; then
  TITLE="${TITLE:0:97}..."
fi

PR_URL="$(gh pr create --title "$TITLE" --base "$BASE" --body-file "$PR_DESC_PATH")"

echo "Pull Request created: $PR_URL"

PR_URL="$PR_URL" TC_STATUS_PATH="$TC_STATUS_PATH" python3 <<'PY'
import json, os
path = os.environ["TC_STATUS_PATH"]
with open(path, encoding="utf-8") as f:
    status = json.load(f)
status["pr_url"] = os.environ["PR_URL"].strip().splitlines()[-1]
with open(path, "w", encoding="utf-8") as f:
    json.dump(status, f, indent=2)
    f.write("\n")
PY
