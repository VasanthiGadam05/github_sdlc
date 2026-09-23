## [0.1.0] - 2026-09-23
### Added
- Recursive Python source-file discovery with sorted, source-root-relative paths.
- Markdown generation at `docs/generated/source-files.md`.
- Empty-source reporting with `No Python source files found`.
- Atomic report replacement, directory symlink protection, CLI validation, JSON status output, and CI-compatible `md` format.
- Unit, integration, symlink-safety, entry-point, and 500-file performance tests.
- Complete TC-001 requirements, architecture, design review, implementation plan, code review, verification, and PR artifacts.

### Known Limitations
- `--fix` stub generation and its idempotency contract remain out of scope.
- The thin `__main__.py` wrapper is not directly attributed by coverage when exercised in a subprocess.
- The architecture technology table should be aligned from `pathlib.Path.rglob` to the implemented `os.walk(..., followlinks=False)`.
- Direct fault-injection coverage for temporary-file write failures remains a future reliability-test enhancement.
