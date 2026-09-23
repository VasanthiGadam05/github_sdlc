from __future__ import annotations

from pathlib import Path

import pytest

from docsync.report import EMPTY_MESSAGE, render_source_file_report, write_source_file_report


def test_renders_sorted_relative_paths() -> None:
    assert render_source_file_report(["a.py", "nested/b.py"]) == (
        "# Python Source Files\n\n- `a.py`\n- `nested/b.py`\n"
    )


def test_renders_empty_message() -> None:
    assert EMPTY_MESSAGE in render_source_file_report([])


def test_writes_and_overwrites_report(tmp_path: Path) -> None:
    output = write_source_file_report(tmp_path, ["one.py"])
    assert output == tmp_path / "generated" / "source-files.md"
    assert output.read_text(encoding="utf-8") == (
        "# Python Source Files\n\n- `one.py`\n"
    )

    write_source_file_report(tmp_path, [])
    assert EMPTY_MESSAGE in output.read_text(encoding="utf-8")


def test_rejects_absolute_report_path(tmp_path: Path) -> None:
    with pytest.raises(ValueError, match="relative"):
        render_source_file_report([str(tmp_path / "absolute.py")])


def test_rejects_non_directory_docs_root(tmp_path: Path) -> None:
    file_path = tmp_path / "docs.txt"
    file_path.write_text("", encoding="utf-8")
    with pytest.raises(NotADirectoryError):
        write_source_file_report(file_path, [])
