#!/usr/bin/env bash
# Generates a single consolidated Markdown report for a test case across all 8 phases.
#
# Usage:
#   scripts/generate-tc-report.sh --test-case TC-001
set -euo pipefail

usage() {
  echo "Usage: scripts/generate-tc-report.sh --test-case TC-001" >&2
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
import json, os

test_case = os.environ["TEST_CASE"]
tc_outputs_dir = os.environ["TC_OUTPUTS_DIR"]
status_path = os.environ["TC_STATUS_PATH"]

phase_folders = {
    1: "phase-1-requirements", 2: "phase-2-architecture", 3: "phase-3-design-review",
    4: "phase-4-impl-planning", 5: "phase-5-implementation", 6: "phase-6-code-review",
    7: "phase-7-verification", 8: "phase-8-pr",
}

with open(status_path, encoding="utf-8") as f:
    status = json.load(f)

lines = []
lines.append(f"# Test Case Report: {test_case}")
lines.append("")
lines.append(f"**User Story:** {status.get('user_story', '')}")
lines.append(f"**Pipeline Status:** {status.get('pipeline_status', '')}")
if status.get("pr_url"):
    lines.append(f"**Pull Request:** {status['pr_url']}")
lines.append("")
lines.append("## Phase Summary")
lines.append("")
lines.append("| Phase | Name | Status | Completed/Decided At |")
lines.append("|-------|------|--------|----------------------|")

for n in range(1, 9):
    p = status["phases"][str(n)]
    when = p.get("decided_at") or p.get("completed_at") or "-"
    lines.append(f"| {n} | {p['name']} | {p['status']} | {when} |")

lines.append("")
lines.append("## Phase Details")

for n in range(1, 9):
    p = status["phases"][str(n)]
    folder = os.path.join(tc_outputs_dir, phase_folders[n])
    output_path = os.path.join(folder, "output.md")

    lines.append("")
    lines.append(f"### Phase {n}: {p['name']} — {p['status']}")

    if p["status"] == "NOT_STARTED":
        lines.append("_Not yet reached._")
        continue

    if os.path.exists(output_path):
        with open(output_path, encoding="utf-8") as f:
            content = f.read()
        preview = content[:500] + "..." if len(content) > 500 else content
        lines.append("")
        lines.append("```")
        lines.append(preview)
        lines.append("```")
        lines.append("")
        lines.append(f"Full output: `outputs/{test_case}/{phase_folders[n]}/output.md`")
    else:
        lines.append(f"_No archived output found at {output_path}._")

    if p["status"] == "REJECTED" and p.get("rejection_reason"):
        lines.append("")
        lines.append(f"**Rejection reason:** {p['rejection_reason']}")

report_path = os.path.join(tc_outputs_dir, "tc-report.md")
with open(report_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

print(f"Report written to outputs/{test_case}/tc-report.md")
PY
