from __future__ import annotations

import os
import tempfile
from collections.abc import Sequence
from pathlib import Path


OUTPUT_RELATIVE_PATH = Path("generated") / "source-files.md"
EMPTY_MESSAGE = "No Python source files found"


def render_source_file_report(relative_paths: Sequence[str]) -> str:
    """Render a Markdown inventory from source-root-relative paths."""
    normalized = list(relative_paths)
    if any(Path(path).is_absolute() for path in normalized):
        raise ValueError("Report paths must be relative to the source root")
    lines = ["# Python Source Files", ""]
    if normalized:
        lines.extend(f"- `{path}`" for path in normalized)
    else:
        lines.append(EMPTY_MESSAGE)
    return "\n".join(lines) + "\n"


def write_source_file_report(
    docs_root: Path,
    relative_paths: Sequence[str],
) -> Path:
    """Atomically write the inventory beneath the supplied docs root."""
    if not docs_root.is_dir():
        raise NotADirectoryError(f"Docs path is not a directory: {docs_root}")

    output_directory = docs_root / OUTPUT_RELATIVE_PATH.parent
    output_directory.mkdir(parents=True, exist_ok=True)
    output_path = docs_root / OUTPUT_RELATIVE_PATH
    report_content = render_source_file_report(relative_paths)
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=output_directory,
            prefix=".source-files-",
            suffix=".tmp",
            delete=False,
        ) as temporary_file:
            temporary_path = Path(temporary_file.name)
            temporary_file.write(report_content)
            temporary_file.flush()
            os.fsync(temporary_file.fileno())
        os.replace(temporary_path, output_path)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
    return output_path
