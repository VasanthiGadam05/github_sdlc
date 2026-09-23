#!/usr/bin/env bash
# Verifies each completed phase's agent-log.json is consistent with phase-status.json.
#
# Usage:
#   scripts/check-agent-status.sh --test-case TC-001
set -euo pipefail

usage() {
  echo "Usage: scripts/check-agent-status.sh --test-case TC-001" >&2
  exit 1
}

TEST_CASE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --test-case) TEST_CASE="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -z "$TEST_CASE" ]] && usage
[[ "$TEST_CASE" =~ ^TC-[0-9]+$ ]] || { echo "Error: --test-case must match TC-<number>" >&2; exit 1; }

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TC_OUTPUTS_DIR="$REPO_ROOT/outputs/$TEST_CASE"
TC_STATUS_PATH="$TC_OUTPUTS_DIR/phase-status.json"

if [[ ! -f "$TC_STATUS_PATH" ]]; then
  echo "Error: no pipeline found for $TEST_CASE." >&2
  exit 1
fi

TEST_CASE="$TEST_CASE" TC_OUTPUTS_DIR="$TC_OUTPUTS_DIR" TC_STATUS_PATH="$TC_STATUS_PATH" python3 <<'PY'
import json, os, sys

test_case = os.environ["TEST_CASE"]
tc_outputs_dir = os.environ["TC_OUTPUTS_DIR"]
path = os.environ["TC_STATUS_PATH"]

phase_folders = {
    1: "phase-1-requirements", 2: "phase-2-architecture", 3: "phase-3-design-review",
    4: "phase-4-impl-planning", 5: "phase-5-implementation", 6: "phase-6-code-review",
    7: "phase-7-verification", 8: "phase-8-pr",
}

with open(path, encoding="utf-8") as f:
    status = json.load(f)

problems = 0

for n in range(1, 9):
    p = status["phases"][str(n)]
    folder = os.path.join(tc_outputs_dir, phase_folders[n])
    log_path = os.path.join(folder, "agent-log.json")
    has_log = os.path.exists(log_path)
    tracked_as_started = p["status"] != "NOT_STARTED"

    if tracked_as_started and not has_log:
        print(f"MISMATCH: Phase {n} is '{p['status']}' in phase-status.json but no agent-log.json exists at {log_path}")
        problems += 1
        continue

    if not has_log:
        print(f"Phase {n} ({p['name']}): NOT_STARTED")
        continue

    with open(log_path, encoding="utf-8") as f:
        log = json.load(f)

    if log.get("status") != "SUCCESS":
        print(f"Phase {n} ({p['name']}): agent-log reports status '{log.get('status')}' (expected SUCCESS)")
        problems += 1
    else:
        print(f"Phase {n} ({p['name']}): agent-log OK, completed {log.get('completed_at')}, tracker status {p['status']}")

print()
if problems == 0:
    print(f"No inconsistencies found for {test_case}.")
else:
    print(f"{problems} inconsistency(ies) found for {test_case}. Investigate before approving further phases.")
    sys.exit(1)
PY
