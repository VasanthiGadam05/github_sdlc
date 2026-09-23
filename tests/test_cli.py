from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

from docsync.cli import main


def test_cli_generates_report(tmp_path: Path, capsys) -> None:
    source_root = tmp_path / "src"
    docs_root = tmp_path / "docs"
    source_root.mkdir()
    docs_root.mkdir()
    (source_root / "app.py").write_text("", encoding="utf-8")

    assert main(["--src", str(source_root), "--docs", str(docs_root)]) == 0
    output = docs_root / "generated" / "source-files.md"
    assert "`app.py`" in output.read_text(encoding="utf-8")
    assert str(source_root) not in output.read_text(encoding="utf-8")
    assert "Generated source-file report" in capsys.readouterr().out


def test_cli_returns_error_for_missing_root(tmp_path: Path) -> None:
    docs_root = tmp_path / "docs"
    docs_root.mkdir()
    assert main(["--src", str(tmp_path / "missing"), "--docs", str(docs_root)]) == 1


def test_cli_supports_json_status_format(tmp_path: Path, capsys) -> None:
    source_root = tmp_path / "src"
    docs_root = tmp_path / "docs"
    source_root.mkdir()
    docs_root.mkdir()
    assert main([
        "--src",
        str(source_root),
        "--docs",
        str(docs_root),
        "--format",
        "json",
    ]) == 0
    assert '"python_files": 0' in capsys.readouterr().out


def test_cli_accepts_ci_markdown_format_alias(tmp_path: Path, capsys) -> None:
    source_root = tmp_path / "src"
    docs_root = tmp_path / "docs"
    source_root.mkdir()
    docs_root.mkdir()
    assert main([
        "--src",
        str(source_root),
        "--docs",
        str(docs_root),
        "--format",
        "md",
    ]) == 0
    assert "Generated source-file report" in capsys.readouterr().out


def test_cli_handles_500_files_under_three_seconds(tmp_path: Path) -> None:
    source_root = tmp_path / "src"
    docs_root = tmp_path / "docs"
    source_root.mkdir()
    docs_root.mkdir()
    for index in range(500):
        (source_root / f"file_{index:03d}.py").write_text("", encoding="utf-8")

    started = time.perf_counter()
    assert main(["--src", str(source_root), "--docs", str(docs_root)]) == 0
    assert time.perf_counter() - started < 3


def test_module_entry_point_generates_report(tmp_path: Path) -> None:
    source_root = tmp_path / "src"
    docs_root = tmp_path / "docs"
    source_root.mkdir()
    docs_root.mkdir()
    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "docsync",
            "--src",
            str(source_root),
            "--docs",
            str(docs_root),
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    assert (docs_root / "generated" / "source-files.md").exists()
