#!/usr/bin/env bash
# Initializes the docsync Agentic SDLC pipeline for a new test case.
#
# Usage:
#   scripts/init-pipeline.sh --test-case TC-001 --user-story "US-001: As a developer I want docsync to detect renamed functions"
set -euo pipefail

usage() {
  echo "Usage: scripts/init-pipeline.sh --test-case TC-001 --user-story \"...\"" >&2
  exit 1
}

TEST_CASE=""
USER_STORY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --test-case) TEST_CASE="$2"; shift 2 ;;
    --user-story) USER_STORY="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -z "$TEST_CASE" || -z "$USER_STORY" ]] && usage
[[ "$TEST_CASE" =~ ^TC-[0-9]+$ ]] || { echo "Error: --test-case must match TC-<number>, e.g. TC-001" >&2; exit 1; }

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TC_OUTPUTS_DIR="$REPO_ROOT/outputs/$TEST_CASE"
TC_DOCS_DIR="$REPO_ROOT/docs/$TEST_CASE"
MASTER_STATUS_PATH="$REPO_ROOT/outputs/phase-status.json"
TC_STATUS_PATH="$TC_OUTPUTS_DIR/phase-status.json"

if [[ -f "$TC_STATUS_PATH" ]]; then
  echo "Error: pipeline already initialized for $TEST_CASE ($TC_STATUS_PATH exists). Use scripts/resume-pipeline.sh to continue it, or pick a new test case ID." >&2
  exit 1
fi

mkdir -p "$TC_OUTPUTS_DIR" "$TC_DOCS_DIR"

NOW_ISO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

TEST_CASE="$TEST_CASE" USER_STORY="$USER_STORY" NOW_ISO="$NOW_ISO" TC_STATUS_PATH="$TC_STATUS_PATH" python3 <<'PY'
import json, os

test_case = os.environ["TEST_CASE"]
user_story = os.environ["USER_STORY"]
now_iso = os.environ["NOW_ISO"]
tc_status_path = os.environ["TC_STATUS_PATH"]

phase_names = {
    "1": "Requirements", "2": "Architecture", "3": "Design Review",
    "4": "Implementation Planning", "5": "Implementation", "6": "Code Review",
    "7": "Verification", "8": "PR Creation",
}

status = {
    "test_case": test_case,
    "user_story": user_story,
    "created_at": now_iso,
    "pipeline_status": "IN_PROGRESS",
    "phases": {k: {"status": "NOT_STARTED", "name": v} for k, v in phase_names.items()},
}

with open(tc_status_path, "w", encoding="utf-8") as f:
    json.dump(status, f, indent=2)
    f.write("\n")
PY

TEST_CASE="$TEST_CASE" USER_STORY="$USER_STORY" NOW_ISO="$NOW_ISO" MASTER_STATUS_PATH="$MASTER_STATUS_PATH" python3 <<'PY'
import json, os

test_case = os.environ["TEST_CASE"]
user_story = os.environ["USER_STORY"]
now_iso = os.environ["NOW_ISO"]
master_path = os.environ["MASTER_STATUS_PATH"]

if os.path.exists(master_path):
    with open(master_path, encoding="utf-8") as f:
        master = json.load(f)
else:
    os.makedirs(os.path.dirname(master_path), exist_ok=True)
    master = {"active_test_cases": [], "test_cases": {}}

if test_case not in master["active_test_cases"]:
    master["active_test_cases"].append(test_case)

master["test_cases"][test_case] = {
    "user_story": user_story,
    "created_at": now_iso,
    "status_file": f"outputs/{test_case}/phase-status.json",
}

with open(master_path, "w", encoding="utf-8") as f:
    json.dump(master, f, indent=2)
    f.write("\n")
PY

echo "Initialized pipeline for $TEST_CASE"
echo "  Status file : $TC_STATUS_PATH"
echo "  Docs folder : $TC_DOCS_DIR"
echo ""
echo "Next: invoke the Phase 1 (Requirements) prompt via GitHub Copilot CLI agent mode or Claude Code:"
echo "  @requirements.prompt.md"
