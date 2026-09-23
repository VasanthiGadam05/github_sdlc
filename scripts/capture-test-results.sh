#!/usr/bin/env bash
# Runs the docsync test suite and coverage, and writes a structured
# test-results.json for Phase 7. Convenience wrapper around the same
# commands listed in .github/prompts/verification.prompt.md and
# .github/instructions/phase-7-verification.instructions.md — it does not
# replace reading and archiving the full verification.md report.
#
# Usage:
#   scripts/capture-test-results.sh --test-case TC-001
#
# Note: deliberately no `set -e` — pytest/docsync are expected to be able
# to fail; their exit codes are captured, not treated as script errors.
set -uo pipefail

usage() {
  echo "Usage: scripts/capture-test-results.sh --test-case TC-001" >&2
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
PHASE_FOLDER="$REPO_ROOT/outputs/$TEST_CASE/phase-7-verification"
mkdir -p "$PHASE_FOLDER"

cd "$REPO_ROOT"

TEST_OUTPUT="$(python3 -m pytest tests/ -v --tb=short 2>&1)"
TEST_EXIT=$?

COV_OUTPUT="$(python3 -m pytest tests/ --cov=src/docsync --cov-report=term-missing 2>&1)"

SMOKE_OUTPUT="$(python3 -m docsync --src src --docs docs --format json 2>&1)"
SMOKE_EXIT=$?

SECRET_HITS="$(grep -inE 'password|api[_-]?key|secret|token' src/docsync/*.py 2>/dev/null || true)"

NOW_ISO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

TEST_CASE="$TEST_CASE" TEST_OUTPUT="$TEST_OUTPUT" TEST_EXIT="$TEST_EXIT" COV_OUTPUT="$COV_OUTPUT" \
SMOKE_EXIT="$SMOKE_EXIT" SECRET_HITS="$SECRET_HITS" NOW_ISO="$NOW_ISO" \
RESULTS_PATH="$PHASE_FOLDER/test-results.json" python3 <<'PY'
import json, os, re, sys

test_output = os.environ["TEST_OUTPUT"]
cov_output = os.environ["COV_OUTPUT"]
secret_hits = os.environ["SECRET_HITS"]

passed_match = re.search(r"(\d+)\s+passed", test_output)
failed_match = re.search(r"(\d+)\s+failed", test_output)
cov_match = re.search(r"TOTAL\s+\d+\s+\d+\s+(\d+)%", cov_output)

passed = int(passed_match.group(1)) if passed_match else 0
failed = int(failed_match.group(1)) if failed_match else 0
coverage_percent = int(cov_match.group(1)) if cov_match else 0

smoke_exit = int(os.environ["SMOKE_EXIT"])
smoke_result = "PASS" if smoke_exit == 0 else "FAIL"
security_scan = "ISSUES_FOUND" if secret_hits.strip() else "CLEAN"

results = {
    "passed": passed,
    "failed": failed,
    "test_exit_code": int(os.environ["TEST_EXIT"]),
    "coverage_percent": coverage_percent,
    "smoke_test": smoke_result,
    "smoke_exit_code": smoke_exit,
    "security_scan": security_scan,
    "captured_at": os.environ["NOW_ISO"],
}

with open(os.environ["RESULTS_PATH"], "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2)
    f.write("\n")

print(f"Test results captured for {os.environ['TEST_CASE']} :")
print(f"  Passed: {passed}  Failed: {failed}  Coverage: {coverage_percent}%  Smoke: {smoke_result}  Security: {security_scan}")
print(f"  Written to outputs/{os.environ['TEST_CASE']}/phase-7-verification/test-results.json")

if failed > 0 or smoke_exit != 0 or security_scan != "CLEAN":
    print("WARNING: one or more verification checks did not pass. Do not report Phase 7 as PASS.", file=sys.stderr)
PY
