#!/usr/bin/env bash
# Prints the phase-by-phase status table for a docsync pipeline test case.
#
# Usage:
#   scripts/show-phase-status.sh --test-case TC-001
#   scripts/show-phase-status.sh   # uses the first active test case in outputs/phase-status.json
set -euo pipefail

TEST_CASE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --test-case) TEST_CASE="$2"; shift 2 ;;
    *) echo "Usage: scripts/show-phase-status.sh [--test-case TC-001]" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [[ -z "$TEST_CASE" ]]; then
  MASTER_STATUS_PATH="$REPO_ROOT/outputs/phase-status.json"
  if [[ ! -f "$MASTER_STATUS_PATH" ]]; then
    echo "Error: no pipeline has been initialized yet. Run scripts/init-pipeline.sh first." >&2
    exit 1
  fi
  TEST_CASE="$(MASTER_STATUS_PATH="$MASTER_STATUS_PATH" python3 <<'PY'
import json, os, sys
path = os.environ["MASTER_STATUS_PATH"]
with open(path, encoding="utf-8") as f:
    master = json.load(f)
tcs = master.get("active_test_cases", [])
if not tcs:
    print(f"Error: no active test cases found in {path}", file=sys.stderr)
    sys.exit(1)
print(tcs[0])
PY
)"
fi

TC_STATUS_PATH="$REPO_ROOT/outputs/$TEST_CASE/phase-status.json"
if [[ ! -f "$TC_STATUS_PATH" ]]; then
  echo "Error: no pipeline found for $TEST_CASE." >&2
  exit 1
fi

TEST_CASE="$TEST_CASE" TC_STATUS_PATH="$TC_STATUS_PATH" python3 <<'PY'
import json, os

test_case = os.environ["TEST_CASE"]
path = os.environ["TC_STATUS_PATH"]

with open(path, encoding="utf-8") as f:
    status = json.load(f)

print()
print(f"Test Case  : {test_case}")
print(f"User Story : {status.get('user_story', '')}")
print(f"Pipeline   : {status.get('pipeline_status', '')}")
print()
print(f"{'Phase':<6} {'Name':<24} {'Status':<18} {'Decided/Completed At'}")
print("-" * 80)

pending = []
for n in range(1, 9):
    p = status["phases"][str(n)]
    when = p.get("decided_at") or p.get("completed_at") or "-"
    print(f"{n:<6} {p['name']:<24} {p['status']:<18} {when}")
    if p["status"] == "REJECTED" and p.get("rejection_reason"):
        print(f"       Reason: {p['rejection_reason']}")
    if p["status"] == "PENDING_APPROVAL":
        pending.append(n)
print()

for n in pending:
    print(f"Awaiting approval for Phase {n}. Run:")
    print(f"  scripts/approve-phase.sh --phase {n} --decision APPROVED --test-case {test_case}")
PY
