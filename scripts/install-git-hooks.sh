#!/usr/bin/env bash
# Installs .github/hooks/pre-commit into .git/hooks/pre-commit.
#
# Usage:
#   scripts/install-git-hooks.sh
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SRC_HOOK="$REPO_ROOT/.github/hooks/pre-commit"
DEST_HOOK="$REPO_ROOT/.git/hooks/pre-commit"

if [[ ! -f "$SRC_HOOK" ]]; then
  echo "Error: $SRC_HOOK not found." >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST_HOOK")"
cp "$SRC_HOOK" "$DEST_HOOK"
chmod +x "$DEST_HOOK"

echo "Installed pre-commit hook: $DEST_HOOK"
