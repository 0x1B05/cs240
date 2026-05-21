from __future__ import annotations

from pathlib import Path


def has_symlink_parent(path: Path) -> bool:
    for parent in path.parents:
        if parent == parent.parent:
            break
        if parent.is_symlink():
            return True
    return False
