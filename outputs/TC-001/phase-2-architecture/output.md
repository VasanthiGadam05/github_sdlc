# Architecture

## System Overview

The feature is a small standard-library Python CLI workflow. A command-line
adapter accepts a source-root path and a docs-root path, validates both paths,
and coordinates discovery and Markdown rendering. The discovery component
recursively enumerates regular files ending in `.py`, converts each result to
a source-root-relative POSIX-style path, and sorts the paths alphabetically.

The renderer receives only already-normalized relative paths and writes the
complete report to `docs/generated/source-files.md`. The output directory is
created when needed, and an empty discovery result produces a clear
`No Python source files found` message. Path validation and output-path
construction remain in the CLI/application layer so the renderer cannot
accidentally access files outside the supplied docs root.

```text
                         source root
                              |
                              v
                     +------------------+
                     | CLI / application|
                     | validation      |
                     +--------+---------+
                              |
                              v
                     +------------------+
                     | Python source   |
                     | file discovery  |
                     +--------+---------+
                              |
                  sorted relative .py paths
                              |
                              v
                     +------------------+
                     | Markdown report  |
                     | rendering        |
                     +--------+---------+
                              |
                              v
                 docs-root/docs/generated/source-files.md
```

## Technology Choices

| Concern | Choice | Rationale |
|---|---|---|
| Language | Python 3.10+ | Matches the project baseline and supports complete type annotations. |
| File traversal | `pathlib.Path.rglob` | Standard-library recursive traversal with platform-safe path handling. |
| Path normalization | `Path.relative_to` and POSIX conversion | Prevents absolute paths in the report and gives stable Markdown output across Windows and POSIX hosts. |
| Markdown generation | Explicit string assembly | The report has a fixed, small format and needs no third-party templating package. |
| CLI parsing | `argparse` | Standard-library argument parsing with consistent usage and validation errors. |
| Logging/errors | `logging` plus controlled CLI exit codes | Keeps diagnostics separate from final report output and avoids unhandled expected exceptions. |
| Testing | `unittest` and temporary directories/mocks | Standard-library-only isolated and integration testing. |

## Component Responsibilities

### `src/docsync/source_files.py`

**Responsibility:** Discover Python source files and return normalized,
alphabetically sorted relative paths.

**Public interface:**

```python
def discover_python_files(source_root: Path) -> list[str]: ...
```

The component depends only on `pathlib`. It validates that traversal is
anchored at the supplied source root and does not read file contents.

### `src/docsync/report.py`

**Responsibility:** Render and persist the source-file Markdown report beneath
the supplied docs root.

**Public interface:**

```python
def render_source_file_report(relative_paths: Sequence[str]) -> str: ...

def write_source_file_report(
    docs_root: Path,
    relative_paths: Sequence[str],
) -> Path: ...
```

The component depends on `pathlib` and `collections.abc.Sequence`. It writes
only `docs_root / "generated" / "source-files.md"` and replaces that file as a
single complete document.

### `src/docsync/cli.py`

**Responsibility:** Parse command-line arguments, validate roots, coordinate
discovery and report writing, and map expected failures to user-facing
messages and exit codes.

**Public interface:**

```python
def main(argv: Sequence[str] | None = None) -> int: ...
```

The CLI depends on `argparse`, `pathlib`, `logging`, `source_files`, and
`report`. It passes roots explicitly to collaborators, preventing implicit
working-directory or environment access.

### `src/docsync/__main__.py`

**Responsibility:** Provide the `python -m docsync` entry point.

**Public interface:** No application API; it invokes `cli.main()` and exits
with the returned status.

### Tests

`tests/test_source_files.py` isolates recursive discovery with temporary
directories. `tests/test_report.py` verifies exact Markdown content,
alphabetical ordering, empty-result messaging, output-directory creation, and
overwrite behavior. `tests/test_cli.py` covers argument validation and the
end-to-end happy path plus expected error exits.

## Data Flow

1. The user invokes `python -m docsync --src <source-root> --docs <docs-root>`.
2. The CLI parses arguments and checks that both supplied roots exist and are
   directories.
3. The CLI passes the source root to `discover_python_files`.
4. Discovery recursively finds regular `.py` files, computes paths relative to
   the source root, converts separators to `/`, and sorts them.
5. The CLI passes the resulting list and docs root to the report writer.
6. The report writer renders a Markdown heading and either a sorted list of
   relative paths or `No Python source files found`.
7. The writer creates `docs/generated/` under the supplied docs root and
   overwrites `source-files.md`.
8. The CLI reports the generated path and returns success.

## Directory Layout

```text
src/docsync/
├── __init__.py
├── __main__.py
├── cli.py
├── report.py
└── source_files.py

tests/
├── test_cli.py
├── test_report.py
└── test_source_files.py
```

## Security Architecture

The CLI accepts explicit source and docs roots and passes them as `Path`
objects to components; no component reads environment variables, `.env` files,
or implicit paths. Discovery returns only relative path strings and never
returns file contents. The report writer constructs its sole destination from
the validated docs root and the fixed suffix `generated/source-files.md`, so
it cannot write to an arbitrary caller-provided filename. The writer also
rejects or normalizes any path value that is not relative before rendering,
ensuring absolute filesystem paths cannot enter the document.

## Requirement Traceability

| Requirement | Architectural coverage |
|---|---|
| FR-1 | `source_files.discover_python_files` uses recursive `.py` traversal. |
| FR-2 | `report.write_source_file_report` writes the fixed generated report under the docs root. |
| FR-3 | Discovery sorts normalized relative paths before returning them. |
| FR-4 | The report writer replaces the complete generated report. |
| FR-5 | The renderer emits the exact empty-result message. |
| NFR-1 | Discovery emits relative POSIX paths only; the renderer rejects absolute entries. |
| NFR-2 | All components use Python standard-library modules only. |

## Error Handling Strategy

| Scenario | Behaviour |
|---|---|
| `--src` does not exist | CLI writes a clear error to stderr and returns a non-zero exit code; no report is written. |
| `--src` exists but is not a directory | CLI writes a clear error to stderr and returns a non-zero exit code. |
| `--docs` does not exist | CLI writes a clear error to stderr and returns a non-zero exit code; it does not create an unrelated docs root. |
| `--docs` exists but is not a directory | CLI writes a clear error to stderr and returns a non-zero exit code. |
| Source root contains no `.py` files | Report is written successfully with `No Python source files found`; CLI returns zero. |
| Existing output report | The writer overwrites only the fixed generated report. |
| Output directory is absent | Writer creates `docs/generated/` beneath the validated docs root. |
| Unexpected filesystem failure | CLI reports the operation and returns a non-zero exit code without exposing file contents or environment values. |
