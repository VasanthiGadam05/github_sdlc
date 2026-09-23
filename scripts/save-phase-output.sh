#!/usr/bin/env bash
# Archives a completed phase's output and updates the pipeline tracker to PENDING_APPROVAL.
#
# Usage:
#   scripts/save-phase-output.sh --test-case TC-001 --phase 1 --source-file docs/TC-001/requirements.md --agent-name requirements.prompt.md
set -euo pipefail

usage() {
  echo "Usage: scripts/save-phase-output.sh --test-case TC-001 --phase N --source-file <path> --agent-name <name>" >&2
  exit 1
}

TEST_CASE=""
PHASE=""
SOURCE_FILE=""
AGENT_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --test-case) TEST_CASE="$2"; shift 2 ;;
    --phase) PHASE="$2"; shift 2 ;;
    --source-file) SOURCE_FILE="$2"; shift 2 ;;
    --agent-name) AGENT_NAME="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -z "$TEST_CASE" || -z "$PHASE" || -z "$SOURCE_FILE" || -z "$AGENT_NAME" ]] && usage
[[ "$TEST_CASE" =~ ^TC-[0-9]+$ ]] || { echo "Error: --test-case must match TC-<number>" >&2; exit 1; }
[[ "$PHASE" =~ ^[1-8]$ ]] || { echo "Error: --phase must be 1-8" >&2; exit 1; }

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SOURCE_FULL_PATH="$REPO_ROOT/$SOURCE_FILE"

if [[ ! -f "$SOURCE_FULL_PATH" ]]; then
  echo "Error: source file not found: $SOURCE_FULL_PATH" >&2
  exit 1
fi

TC_OUTPUTS_DIR="$REPO_ROOT/outputs/$TEST_CASE"
TC_STATUS_PATH="$TC_OUTPUTS_DIR/phase-status.json"

if [[ ! -f "$TC_STATUS_PATH" ]]; then
  echo "Error: no pipeline found for $TEST_CASE. Run scripts/init-pipeline.sh first." >&2
  exit 1
fi

declare -A PHASE_FOLDERS=(
  [1]="phase-1-requirements" [2]="phase-2-architecture" [3]="phase-3-design-review"
  [4]="phase-4-impl-planning" [5]="phase-5-implementation" [6]="phase-6-code-review"
  [7]="phase-7-verification" [8]="phase-8-pr"
)

FOLDER_NAME="${PHASE_FOLDERS[$PHASE]}"
PHASE_FOLDER="$TC_OUTPUTS_DIR/$FOLDER_NAME"
mkdir -p "$PHASE_FOLDER"

ARCHIVE_PATH="$PHASE_FOLDER/output.md"
cp "$SOURCE_FULL_PATH" "$ARCHIVE_PATH"

NOW_ISO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
REL_ARCHIVE="outputs/$TEST_CASE/$FOLDER_NAME/output.md"

TEST_CASE="$TEST_CASE" PHASE="$PHASE" SOURCE_FILE="$SOURCE_FILE" AGENT_NAME="$AGENT_NAME" \
NOW_ISO="$NOW_ISO" REL_ARCHIVE="$REL_ARCHIVE" FOLDER_NAME="$FOLDER_NAME" \
TC_STATUS_PATH="$TC_STATUS_PATH" PHASE_FOLDER="$PHASE_FOLDER" python3 <<'PY'
import json, os

test_case = os.environ["TEST_CASE"]
phase = os.environ["PHASE"]
source_file = os.environ["SOURCE_FILE"].replace("\\", "/")
agent_name = os.environ["AGENT_NAME"]
now_iso = os.environ["NOW_ISO"]
rel_archive = os.environ["REL_ARCHIVE"]
folder_name = os.environ["FOLDER_NAME"]
status_path = os.environ["TC_STATUS_PATH"]
phase_folder = os.environ["PHASE_FOLDER"]

phase_names = {
    "1": "Requirements", "2": "Architecture", "3": "Design Review",
    "4": "Implementation Planning", "5": "Implementation", "6": "Code Review",
    "7": "Verification", "8": "PR Creation",
}
phase_name = phase_names[phase]

agent_log = {
    "phase": int(phase),
    "phase_name": phase_name,
    "agent": agent_name,
    "completed_at": now_iso,
    "output_file": source_file,
    "output_archived_to": rel_archive,
    "status": "SUCCESS",
}
with open(os.path.join(phase_folder, "agent-log.json"), "w", encoding="utf-8") as f:
    json.dump(agent_log, f, indent=2)
    f.write("\n")

with open(status_path, encoding="utf-8") as f:
    status = json.load(f)

p = status["phases"][phase]
p["status"] = "PENDING_APPROVAL"
p["output_archive"] = rel_archive
p["phase_folder"] = folder_name
p["completed_at"] = now_iso

with open(status_path, "w", encoding="utf-8") as f:
    json.dump(status, f, indent=2)
    f.write("\n")

print(f"Archived Phase {phase} ({phase_name}) output for {test_case}.")
print(f"  {source_file} -> {rel_archive}")
print("Status set to PENDING_APPROVAL. Awaiting human review.")
print(f"  scripts/approve-phase.sh --phase {phase} --decision APPROVED --test-case {test_case}")
PY
