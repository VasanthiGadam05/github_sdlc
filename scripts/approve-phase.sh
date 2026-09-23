#!/usr/bin/env bash
# Records the human approval or rejection decision for a docsync pipeline phase.
#
# This is the ONLY script that may set a phase's status to APPROVED. No
# agent or prompt may call this on the human's behalf — it exists precisely
# so the human-in-the-loop checkpoint is a real gate, not a formality.
#
# On APPROVED, this script also stages and commits that phase's artifact(s)
# to git. The commit only ever happens as a direct result of a human running
# this script — no agent or prompt commits on its own.
#
# Usage:
#   scripts/approve-phase.sh --phase 1 --decision APPROVED --test-case TC-001
#   scripts/approve-phase.sh --phase 2 --decision REJECTED --test-case TC-001 --reason "Architecture missed NFR-1 performance budget"
set -euo pipefail

usage() {
  echo "Usage: scripts/approve-phase.sh --phase N --decision APPROVED|REJECTED --test-case TC-001 [--reason \"...\"]" >&2
  exit 1
}

PHASE=""
DECISION=""
TEST_CASE=""
REASON=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="$2"; shift 2 ;;
    --decision) DECISION="$2"; shift 2 ;;
    --test-case) TEST_CASE="$2"; shift 2 ;;
    --reason) REASON="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -z "$PHASE" || -z "$DECISION" || -z "$TEST_CASE" ]] && usage
[[ "$PHASE" =~ ^[1-8]$ ]] || { echo "Error: --phase must be 1-8" >&2; exit 1; }
[[ "$DECISION" == "APPROVED" || "$DECISION" == "REJECTED" ]] || { echo "Error: --decision must be APPROVED or REJECTED" >&2; exit 1; }
[[ "$TEST_CASE" =~ ^TC-[0-9]+$ ]] || { echo "Error: --test-case must match TC-<number>" >&2; exit 1; }
if [[ "$DECISION" == "REJECTED" && -z "$REASON" ]]; then
  echo "Error: --reason is required when --decision is REJECTED" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TC_STATUS_PATH="$REPO_ROOT/outputs/$TEST_CASE/phase-status.json"

if [[ ! -f "$TC_STATUS_PATH" ]]; then
  echo "Error: no pipeline found for $TEST_CASE. Run scripts/init-pipeline.sh first." >&2
  exit 1
fi

NOW_ISO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

PHASE="$PHASE" DECISION="$DECISION" REASON="$REASON" NOW_ISO="$NOW_ISO" \
TC_STATUS_PATH="$TC_STATUS_PATH" TEST_CASE="$TEST_CASE" python3 <<'PY'
import json, os, sys

phase = os.environ["PHASE"]
decision = os.environ["DECISION"]
reason = os.environ.get("REASON", "")
now_iso = os.environ["NOW_ISO"]
path = os.environ["TC_STATUS_PATH"]
test_case = os.environ["TEST_CASE"]

with open(path, encoding="utf-8") as f:
    status = json.load(f)

p = status["phases"].get(phase)
if p is None:
    print(f"Error: phase {phase} not found in {path}", file=sys.stderr)
    sys.exit(1)

current = p["status"]
if current not in ("PENDING_APPROVAL", "REJECTED"):
    print(f"Error: phase {phase} is currently '{current}', not PENDING_APPROVAL. The agent must produce the phase output before it can be approved or rejected.", file=sys.stderr)
    sys.exit(1)

p["status"] = decision
p["decided_at"] = now_iso
if decision == "REJECTED":
    p["rejection_reason"] = reason
else:
    p.pop("rejection_reason", None)

if decision == "APPROVED" and phase == "8":
    status["pipeline_status"] = "PIPELINE_COMPLETE"

with open(path, "w", encoding="utf-8") as f:
    json.dump(status, f, indent=2)
    f.write("\n")

print(f"Phase {phase} ({p['name']}) for {test_case} recorded as {decision}.")
PY

declare -A PHASE_NAMES=(
  [1]="Requirements" [2]="Architecture" [3]="Design Review" [4]="Implementation Planning"
  [5]="Implementation" [6]="Code Review" [7]="Verification" [8]="PR Creation"
)

if [[ "$DECISION" == "APPROVED" ]]; then
  declare -a COMMIT_PATHS=("outputs/$TEST_CASE" "outputs/phase-status.json")
  case "$PHASE" in
    1) COMMIT_PATHS+=("docs/$TEST_CASE/requirements.md") ;;
    2) COMMIT_PATHS+=("docs/$TEST_CASE/architecture.md") ;;
    3) COMMIT_PATHS+=("docs/$TEST_CASE/design-review.md" "docs/$TEST_CASE/architecture.md") ;;
    4) COMMIT_PATHS+=("docs/$TEST_CASE/impl-plan.md") ;;
    5) COMMIT_PATHS+=("src" "tests") ;;
    6) COMMIT_PATHS+=("docs/$TEST_CASE/code-review.md") ;;
    7) COMMIT_PATHS+=("docs/$TEST_CASE/verification.md") ;;
    8) COMMIT_PATHS+=("docs/$TEST_CASE/pr-description.md" "CHANGELOG.md") ;;
  esac

  declare -a EXISTING_PATHS=()
  for p in "${COMMIT_PATHS[@]}"; do
    [[ -e "$REPO_ROOT/$p" ]] && EXISTING_PATHS+=("$p")
  done

  if [[ ${#EXISTING_PATHS[@]} -gt 0 ]]; then
    git -C "$REPO_ROOT" add -- "${EXISTING_PATHS[@]}"
    if git -C "$REPO_ROOT" diff --cached --quiet; then
      echo "Nothing new to commit for Phase $PHASE (already committed)."
    else
      git -C "$REPO_ROOT" commit -m "$TEST_CASE: approve Phase $PHASE - ${PHASE_NAMES[$PHASE]}"
      echo "Committed approved Phase $PHASE (${PHASE_NAMES[$PHASE]}) artifact(s) for $TEST_CASE."
    fi
  fi

  if [[ "$PHASE" -lt 8 ]]; then
    NEXT=$((PHASE + 1))
    echo "You may now invoke the Phase $NEXT prompt to continue the pipeline."
  else
    echo "All 8 phases are approved. Run scripts/create-github-pr.sh --test-case $TEST_CASE to open the Pull Request."
  fi
else
  echo "Re-invoke the Phase $PHASE prompt with the rejection reason as feedback before approving again."
fi
