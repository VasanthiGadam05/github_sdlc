# Implementation Plan

## Task Breakdown

| Task | Description | Depends On | Priority | Estimate |
|---|---|---|---|---|
| T01 | Create the package entry points in `src/docsync/__init__.py` and `src/docsync/__main__.py`, preserving `python -m docsync` invocation and standard-library-only imports. | None | P0 | 15min |
| T02 | Implement recursive regular `.py` file discovery in `src/docsync/source_files.py`, returning sorted source-root-relative POSIX paths without following directory symlinks or reading file contents. | T01 | P0 | 45min |
| T03 | Add isolated discovery tests in `tests/test_source_files.py` covering nested files, alphabetical ordering, non-Python files, empty roots, and directory symlinks. | T02 | P0 | 45min |
| T04 | Implement Markdown rendering and atomic persistence in `src/docsync/report.py`, including the fixed `generated/source-files.md` destination, empty-result text, relative-path validation, temporary-file replacement, and cleanup on write failure. | T01 | P0 | 60min |
| T05 | Add report tests in `tests/test_report.py` covering exact list output, empty-source output, output-directory creation, overwrite behavior, absolute-path rejection, and preservation of an existing report after a simulated write failure. | T04 | P0 | 60min |
| T06 | Implement argument parsing, root validation, orchestration, logging, and controlled exit codes in `src/docsync/cli.py`. | T02, T04 | P0 | 60min |
| T07 | Add CLI integration tests in `tests/test_cli.py` covering the happy path, missing/non-directory roots, empty source roots, generated output location, and no absolute source paths in output. | T06 | P0 | 60min |
| T08 | Add the bounded 500-file performance smoke test to `tests/test_cli.py` or `tests/test_source_files.py`, asserting discovery and report generation complete in under three seconds in the supported environment. | T03, T05, T07 | P1 | 30min |
| T09 | Run the focused test suite and type/syntax checks for `src/docsync/` and `tests/`, then record the implementation verification command in `docs/TC-001/verification.md` during Phase 7. | T07, T08 | P1 | 30min |

## Dependency Graph

```text
T01
├──> T02 ───> T03 ───────────────┐
└──> T04 ───> T05 ───────────────┼──> T06 ───> T07 ───> T08 ───> T09
                                 │
                                 └───────────────(T06 also depends on T02 and T04)

Critical path:
T01 -> T02 -> T04 -> T06 -> T07 -> T08 -> T09
```

T03 and T05 are paired component tests and can be developed after their
respective implementation tasks. T06 integrates the tested discovery and
report interfaces; T07 then validates the complete CLI behavior.

## Blocked Tasks Summary

| Task | Blocked By | Reason |
|---|---|---|
| T02 | T01 | `source_files.py` must be importable through the package structure. |
| T03 | T02 | Discovery behavior must exist before isolated discovery assertions can run. |
| T04 | T01 | `report.py` belongs to the initialized package and uses its public conventions. |
| T05 | T04 | Report tests require the renderer and writer interfaces. |
| T06 | T02, T04 | CLI orchestration requires both collaborator APIs and their error contracts. |
| T07 | T06 | Integration tests invoke the completed CLI entry point. |
| T08 | T03, T05, T07 | Performance coverage should measure the integrated, tested discovery and report path. |
| T09 | T07, T08 | Final focused validation depends on functional and performance tests being present. |

No task is blocked by an unresolved external dependency. All P0 tasks form one
connected dependency graph from package entry points through implementation,
component tests, CLI integration, and the core happy path.

## Effort Estimate

| Phase | Tasks | Estimate |
|---|---|---|
| Package setup | T01 | 15min |
| Discovery | T02-T03 | 90min |
| Reporting | T04-T05 | 120min |
| CLI integration | T06-T07 | 120min |
| Performance and validation | T08-T09 | 60min |
| **Overall** | **T01-T09** | **405min (6h 45min)** |

The critical path is T01 → T02 → T04 → T06 → T07 → T08 → T09, estimated at
300 minutes (5h), because T03 and T05 provide parallel component-test
coverage but do not add serial work to the primary integration route.
