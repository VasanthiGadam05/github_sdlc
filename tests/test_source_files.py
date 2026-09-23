from __future__ import annotations

import os
from pathlib import Path

from docsync.source_files import discover_python_files


def test_discovers_nested_python_files_in_sorted_order(tmp_path: Path) -> None:
    (tmp_path / "z.py").write_text("", encoding="utf-8")
    nested = tmp_path / "nested"
    nested.mkdir()
    (nested / "a.py").write_text("", encoding="utf-8")
    (nested / "ignore.txt").write_text("", encoding="utf-8")

    assert discover_python_files(tmp_path) == ["nested/a.py", "z.py"]


def test_empty_source_root_returns_empty_list(tmp_path: Path) -> None:
    assert discover_python_files(tmp_path) == []


def test_does_not_follow_directory_symlinks(tmp_path: Path) -> None:
    outside = tmp_path / "outside"
    outside.mkdir()
    (outside / "external.py").write_text("", encoding="utf-8")
    link = tmp_path / "linked"
    try:
        link.symlink_to(outside, target_is_directory=True)
    except (OSError, NotImplementedError):
        return

    assert discover_python_files(tmp_path) == []


def test_rejects_non_directory_source() -> None:
    path = Path(os.path.abspath("not-a-source-file.py"))
    try:
        discover_python_files(path)
    except NotADirectoryError:
        pass
    else:
        raise AssertionError("Expected NotADirectoryError")
