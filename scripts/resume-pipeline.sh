#!/usr/bin/env bash
# Resumes an interrupted docsync pipeline from a specific phase.
#
# Resets phase FROM_PHASE through 8 to NOT_STARTED so they can be re-run,
# while leaving earlier phases untouched. Refuses to run unless those
# earlier phases are already APPROVED, unless --force is supplied.
#
# Usage:
#   scripts/resume-pipeline.sh --test-case TC-001 --from-phase 4 --force
set -euo pipefail

usage() {
  echo "Usage: scripts/resume-pipeline.sh --test-case TC-001 --from-phase N [--force]" >&2
  exit 1
}

TEST_CASE=""
FROM_PHASE=""
FORCE="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --test-case) TEST_CASE="$2"; shift 2 ;;
    --from-phase) FROM_PHASE="$2"; shift 2 ;;
    --force) FORCE="true"; shift ;;
    *) usage ;;
  esac
done

[[ -z "$TEST_CASE" || -z "$FROM_PHASE" ]] && usage
[[ "$TEST_CASE" =~ ^TC-[0-9]+$ ]] || { echo "Error: --test-case must match TC-<number>" >&2; exit 1; }
[[ "$FROM_PHASE" =~ ^[1-8]$ ]] || { echo "Error: --from-phase must be 1-8" >&2; exit 1; }

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TC_STATUS_PATH="$REPO_ROOT/outputs/$TEST_CASE/phase-status.json"

if [[ ! -f "$TC_STATUS_PATH" ]]; then
  echo "Error: no pipeline found for $TEST_CASE." >&2
  exit 1
fi

TEST_CASE="$TEST_CASE" FROM_PHASE="$FROM_PHASE" FORCE="$FORCE" TC_STATUS_PATH="$TC_STATUS_PATH" python3 <<'PY'
import json, os, sys

from_phase = int(os.environ["FROM_PHASE"])
force = os.environ["FORCE"] == "true"
path = os.environ["TC_STATUS_PATH"]
test_case = os.environ["TEST_CASE"]

with open(path, encoding="utf-8") as f:
    status = json.load(f)

for p in range(1, from_phase):
    prior_status = status["phases"][str(p)]["status"]
    if prior_status != "APPROVED" and not force:
        print(f"Error: phase {p} is '{prior_status}', not APPROVED. Use --force to resume anyway, or approve phase {p} first.", file=sys.stderr)
        sys.exit(1)

for p in range(from_phase, 9):
    phase = status["phases"][str(p)]
    phase["status"] = "NOT_STARTED"
    for field in ("decided_at", "rejection_reason", "completed_at", "output_archive", "phase_folder"):
        phase.pop(field, None)

status["pipeline_status"] = "IN_PROGRESS"

with open(path, "w", encoding="utf-8") as f:
    json.dump(status, f, indent=2)
    f.write("\n")

print(f"Resumed {test_case} from Phase {from_phase}.")
print(f"Phases 1-{from_phase - 1} left untouched. Phases {from_phase}-8 reset to NOT_STARTED.")
print(f"Invoke the Phase {from_phase} prompt to continue.")
PY
