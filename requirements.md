# Requirements — Automated Documentation Sync

## User Story

**As** a developer maintaining this repository,
**I want** an automated tool that scans the source code (functions, classes,
public API surface) and compares it against the existing docs,
**so that** I am notified — and can auto-generate stubs — whenever code and
docs drift out of sync, without manually re-reading every file after each
change.

Ticket: `DOCSYNC-1` (synthetic — no JIRA/Confluence instance was available for
this exercise; the story above is treated as the source of truth for this
capstone).

## Clarifying questions considered and resolved

These are the questions a reviewer would reasonably raise before implementation;
each is answered below so the requirement is unambiguous rather than left open.

| # | Question | Resolution |
|---|----------|------------|
| 1 | Which language(s) must be supported first? | Python only for v1, using the standard `ast` module. Architecture must not preclude adding JS/TS later (see architecture.md). |
| 2 | What counts as "documented"? | A doc entry matches a source symbol when a markdown heading of the exact form `## <symbol_name>` exists in any file under `docs/`. This is a deliberately simple, explicit convention — no fuzzy matching. |
| 3 | What is "public"? | Any top-level function or class in a scanned `.py` file whose name does not start with `_`. Nested/private helpers are out of scope. |
| 4 | What should happen with no `docs/` folder or no source files? | Tool must exit cleanly with a clear message and correct exit code — never a stack trace (see NFR-2). |
| 5 | Should the tool modify files by default? | No. Default run is report-only. Stub generation only happens with an explicit `--fix` flag, and never overwrites an existing doc file. |
| 6 | How is this consumed in CI? | As a GitHub Actions step that runs the CLI and fails the build (non-zero exit) when drift is detected on a pull request. |

## Functional Requirements

- **FR-1 — Scan source.** Given a source directory, the tool parses every
  `*.py` file and extracts each public function and class, its qualified
  name, file path, line number, and docstring (if any).
- **FR-2 — Scan docs.** Given a docs directory, the tool extracts the set of
  symbol names documented via `## <symbol_name>` headings across all `*.md`
  files.
- **FR-3 — Detect missing docs.** Any public symbol from FR-1 with no
  matching heading from FR-2 is reported as `Not Found in docs` — it must be
  listed explicitly, never silently dropped.
- **FR-4 — Detect orphaned docs.** Any documented symbol from FR-2 that no
  longer exists in source (per FR-1) is reported as `stale` / orphaned.
- **FR-5 — Structured report.** The tool produces a report in Markdown (for
  humans/PR comments) and JSON (for machine consumption) containing: total
  symbols scanned, missing list, orphaned list, and a pass/fail verdict.
- **FR-6 — Stub generation (opt-in).** With `--fix`, the tool writes a stub
  Markdown file per missing symbol (heading + signature + docstring if
  present) under `docs/generated/`, without touching existing docs files.
- **FR-7 — CLI.** The tool is runnable as
  `python -m docsync --src <path> --docs <path> [--fix] [--format md|json]`.
- **FR-8 — CI integration.** A GitHub Actions workflow runs the CLI on every
  PR and fails the check when the verdict is `fail` (i.e. one or more
  `Not Found in docs` symbols exist). Orphaned docs are reported as warnings
  and do not fail the build.

## Non-Functional Requirements

- **NFR-1 — Performance.** Full scan + diff completes in under 3 seconds on
  a repository with ≤ 500 source files (single pass, no network calls).
- **NFR-2 — Graceful degradation.** Missing `--src`/`--docs` paths, an empty
  `docs/` folder, a `docs/` folder that doesn't exist yet, and a source tree
  with zero `.py` files must each produce a clear, specific message and the
  correct exit code (`0` when there's nothing to check, non-zero only when
  drift or a genuine error is found) — never an unhandled exception.
- **NFR-3 — No secret leakage.** The tool must never read, print, or write
  environment variables, `.env` contents, or file contents outside the given
  `--src`/`--docs` roots into its report, logs, or generated stubs.
- **NFR-4 — Test coverage.** Unit tests cover the scanner, docs reader, and
  differ in isolation; integration tests cover the CLI happy path plus the
  edge cases in NFR-2 and the `Not Found` case in FR-3.
- **NFR-5 — Clarity.** Public functions have descriptive names and no
  explanatory comments are needed to follow the control flow.
- **NFR-6 — Dependencies.** Standard library only for v1 (no third-party
  runtime dependency), eliminating supply-chain/vulnerable-package risk by
  construction.

## Out of Scope (v1)

- Non-Python source languages (JS/TS docstring conventions) — noted as a
  follow-on in architecture.md but not implemented.
- Fuzzy/semantic matching between doc prose and code behavior (only presence
  of a heading is checked, not correctness of the doc content).
- Automatically opening a PR to fix drift (the CI step only reports/fails;
  a human applies `--fix` and commits).

## Acceptance Criteria (Given/When/Then)

1. **Given** a source file with a public function with no corresponding
   `## <name>` heading anywhere in `docs/`, **when** the tool runs, **then**
   the report lists that function under `Not Found in docs`.
2. **Given** a `docs/` heading `## old_function` where `old_function` no
   longer exists in source, **when** the tool runs, **then** the report
   lists it under `Stale / orphaned docs`.
3. **Given** an empty repository (no `src/`, no `docs/`), **when** the tool
   runs, **then** it exits with a clear message and exit code `0`, not a
   crash.
4. **Given** a fully-documented source tree, **when** the tool runs,
   **then** the verdict is `pass` and exit code is `0`.
5. **Given** `--fix` is passed and symbols are missing, **when** the tool
   runs, **then** stub files are written under `docs/generated/` and no
   existing file under `docs/` is modified or deleted.
