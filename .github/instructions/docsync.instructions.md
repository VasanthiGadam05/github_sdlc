---
applyTo: "src/docsync/**"
---

# Instructions — docsync source code

## Role
You are implementing/maintaining the `docsync` CLI: a tool that parses Python
source with `ast`, extracts documented symbols from `docs/`, and reports drift.

## Conventions
- `from __future__ import annotations` in every module.
- Full type annotations on all public functions/classes.
- **Standard library only** (NFR-6). Do not add `requirements.txt` runtime
  entries. If a third-party package seems necessary, stop and raise it as a
  design-review gap (`GAP-XX`) instead of importing it.
- Use `logging` (stdlib), not `print()`, for anything beyond final CLI output.
- Public API surface (functions/classes not prefixed with `_`) is what the
  scanner itself must extract from — so keep it minimal and intentional.

## Error Handling (NFR-2)
Every one of these must produce a clear message and the correct exit code —
never an unhandled traceback:
- `--src` or `--docs` path does not exist.
- `docs/` directory exists but is empty.
- `--src` directory has zero `*.py` files.
- No drift found → exit code `0`.
- Drift found → non-zero exit code (see FR-8 / CI usage).

## Security (NFR-3)
- Never read, print, or write environment variables or `.env` contents.
- Never read or write file contents outside the given `--src`/`--docs` roots.
- Stub files written by `--fix` (FR-6) go only under `docs/generated/` and
  must never overwrite an existing file under `docs/`.

## Testing (NFR-4)
- Unit tests for the scanner, docs reader, and differ, each in isolation
  (mock the filesystem or use `tmp_path` fixtures — do not require real repo
  state to pass).
- Integration tests cover the CLI happy path plus every NFR-2 edge case and
  the `Not Found in docs` case (FR-3).
- Every module you touch must have its tests run and passing before you move
  to the next module (`pytest tests/test_<module>.py -v`).

## Prohibited Behaviors
- Do not add a runtime dependency to sidestep a stdlib limitation.
- Do not swallow exceptions silently — convert to a specific, user-facing
  error message and the correct exit code.
- Do not write to any path outside `docs/generated/` when `--fix` is used.
- Do not implement functionality not present in `docs/TC-*/impl-plan.md` —
  raise it as a follow-up task instead of scope-creeping.
