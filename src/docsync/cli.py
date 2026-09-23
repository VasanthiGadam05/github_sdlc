from __future__ import annotations

import argparse
import json
import logging
from collections.abc import Sequence
from pathlib import Path

from .report import write_source_file_report
from .source_files import discover_python_files

LOGGER = logging.getLogger(__name__)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Generate a Markdown inventory of Python source files."
    )
    parser.add_argument("--src", required=True, help="Python source root")
    parser.add_argument("--docs", required=True, help="Documentation root")
    parser.add_argument(
        "--format",
        choices=("markdown", "md", "json"),
        default="markdown",
        help="Output status format; the generated report is always Markdown",
    )
    return parser


def _existing_directory(value: str, label: str) -> Path:
    path = Path(value)
    if not path.exists():
        raise ValueError(f"{label} path does not exist: {path}")
    if not path.is_dir():
        raise ValueError(f"{label} path is not a directory: {path}")
    return path


def main(argv: Sequence[str] | None = None) -> int:
    """Run the source-file report CLI and return its process exit code."""
    parser = _build_parser()
    args = parser.parse_args(argv)
    try:
        source_root = _existing_directory(args.src, "Source")
        docs_root = _existing_directory(args.docs, "Docs")
        relative_paths = discover_python_files(source_root)
        output_path = write_source_file_report(docs_root, relative_paths)
    except (OSError, ValueError) as error:
        LOGGER.error("%s", error)
        return 1

    if args.format == "json":
        print(
            json.dumps(
                {
                    "output": output_path.as_posix(),
                    "python_files": len(relative_paths),
                }
            )
        )
    else:
        print(f"Generated source-file report: {output_path}")
    return 0
