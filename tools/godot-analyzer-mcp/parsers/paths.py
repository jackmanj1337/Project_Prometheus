"""Shared path-resolution helpers for godot-analyzer tools.

Centralised here so the three tool modules (script.py, scene.py, resource.py)
can't drift apart. The bug that prompted extraction: a relative input like
"scripts/ui/HUD.gd" was returned as a bare relative Path, which then made
_to_res() raise ValueError on relative_to(project_root) and fall through to
the unprefixed string, breaking comparisons against parse_tscn's res:// values.
"""

from pathlib import Path


def resolve(path_str: str, project_root: Path) -> Path:
    """Resolve a user-supplied path to an absolute filesystem path.

    Accepts "res://...", absolute paths, or relative paths (anchored to project_root).
    """
    if path_str.startswith("res://"):
        return project_root / path_str[6:]
    p = Path(path_str)
    return p if p.is_absolute() else (project_root / p)


def to_res(path: Path, project_root: Path) -> str:
    """Convert an absolute filesystem path back into a "res://..." string.

    Falls back to the raw string when path is outside project_root.
    """
    try:
        return "res://" + path.relative_to(project_root).as_posix()
    except ValueError:
        return str(path)
