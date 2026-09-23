from __future__ import annotations

import os
from pathlib import Path


def discover_python_files(source_root: Path) -> list[str]:
    """Return sorted relative paths for regular Python files under a root."""
    if not source_root.is_dir():
        raise NotADirectoryError(f"Source path is not a directory: {source_root}")

    discovered: list[str] = []
    for current_root, directory_names, file_names in os.walk(
        source_root,
        followlinks=False,
    ):
        current_path = Path(current_root)
        directory_names[:] = [
            name
            for name in directory_names
            if not (current_path / name).is_symlink()
        ]
        for file_name in file_names:
            file_path = current_path / file_name
            if file_path.suffix == ".py" and file_path.is_file():
                discovered.append(file_path.relative_to(source_root).as_posix())
    return sorted(discovered)
