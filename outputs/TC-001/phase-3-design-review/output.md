# Design Review

## Review Scope

This review evaluates the approved requirements and architecture for the
Python source-file Markdown listing feature before implementation.

## Risk Analysis

| Risk ID | Severity | What could go wrong and condition | Mitigation | Action |
|---|---|---|---|---|
| RISK-01 | LOW | The architecture has no `--fix` stub-generation feature, so a future fix mode could lack idempotency guarantees. | Keep `--fix` and stub generation out of this story; any future fix mode requires its own design and tests. | DEFERRED — out of scope. |
| RISK-02 | MEDIUM | Traversal or report generation could exceed an acceptable duration on a larger repository. | Collect only relative path strings, sort once, and verify 500 files complete within three seconds. | Applied to architecture; verify in Phase 7. |
| RISK-03 | LOW | Directory symlinks could cause traversal outside the source root or create cycles. | Do not follow directory symlinks; normalize discovered paths with `relative_to`. | Applied to architecture and implementation tests. |
| RISK-04 | LOW | A crash during output could leave a truncated Markdown report. | Use a temporary file in the destination directory and atomically replace the report only after a complete write. | Applied to architecture and implementation tests. |
| RISK-05 | LOW | A path bug could write outside the docs root or expose an absolute source path. | Validate roots, use a fixed output suffix, and pass only relative paths to rendering. | Applied to architecture and security tests. |
| RISK-06 | LOW | Syntax errors, encoding issues, or malformed Python could interrupt scanning. | The feature lists filenames only and never reads or parses source contents. | No code change required. |

## Gap Analysis

| Gap ID | Missing or underspecified item | Resolution phase |
|---|---|---|
| GAP-01 | The approved requirements do not state a performance threshold. | Architecture update adds a 500-file/three-second constraint; Phase 7 verifies it. |
| GAP-02 | Symlink behavior was not explicit. | Architecture update defines that directory symlinks are not followed. |
| GAP-03 | Partial-write behavior was not explicit. | Architecture update requires atomic report replacement. |
| GAP-04 | The architecture names a test approach without confirming the repository's existing test command. | Phase 4 confirms the test command and preserves standard-library runtime constraints. |

## Design Decisions

| ID | Decision | Rationale |
|---|---|---|
| DD-01 | Discover filenames only; do not parse Python source with AST. | The story requires a file inventory, and avoiding content reads reduces encoding, syntax, and leakage risks. |
| DD-02 | Do not follow directory symlinks. | This prevents traversal from escaping the source root and avoids cycles. |
| DD-03 | Use the fixed output path beneath the validated docs root. | This directly enforces the requested destination and prevents arbitrary writes. |
| DD-04 | Atomically replace the report after a successful temporary write. | A failed or interrupted write must not leave a partial report. |
| DD-05 | Add a bounded 500-file performance smoke test. | The scanner remains predictable on a modest repository without adding asynchronous machinery. |

## Architecture Updates

Applied to `architecture.md`:

1. Directory symlink traversal is explicitly disabled.
2. Report generation requires temporary-file writing and atomic replacement.
3. Existing output remains unchanged when report writing fails where supported.
4. A measurable 500-file, three-second performance constraint was added.

## Review Verdict

| Dimension | Verdict | Evidence |
|---|---|---|
| Functional completeness | PASS | FR-1 through FR-5 are traced to discovery and reporting. |
| Security (NFR-3) | PASS | Explicit roots, relative paths, fixed destination, and no content reads prevent out-of-root access and leakage. |
| Performance | PASS WITH VERIFICATION | A 500-file/three-second target is defined for Phase 7. |
| Reliability (NFR-2) | PASS | Invalid-path and empty-source cases have controlled outcomes; atomic writes address partial output. |
| Idempotency | PASS | Repeated runs replace the same deterministic report; `--fix` is out of scope. |
| Testability | PASS | Discovery, rendering, and CLI coordination have separate interfaces and isolated tests. |

No HIGH risks remain unresolved. The architecture is ready for implementation
planning after human approval.
