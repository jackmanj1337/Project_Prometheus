"""Parser for project.godot — extracts autoloads and basic project settings."""

import re
from pathlib import Path


def parse_autoloads(project_root: Path) -> dict:
    """
    Return autoload registrations from project.godot.

    Returns:
        autoloads: {name: {path: str, enabled: bool}}
        error    : str | None
    """
    proj = project_root / "project.godot"
    try:
        content = proj.read_text(encoding="utf-8")
    except OSError as e:
        return {"autoloads": {}, "error": str(e)}

    # Find the [autoload] section
    section_m = re.search(r'\[autoload\](.*?)(?=\n\[|\Z)', content, re.DOTALL)
    if not section_m:
        return {"autoloads": {}, "error": None}

    autoloads = {}
    for line in section_m.group(1).splitlines():
        line = line.strip()
        if not line or line.startswith(";"):
            continue
        # Format: Name="*res://path/Script.gd"  (* prefix = enabled)
        m = re.match(r'^(\w+)\s*=\s*"(\*?)([^"]+)"', line)
        if m:
            autoloads[m.group(1)] = {
                "path":    m.group(3),
                "enabled": m.group(2) == "*",
            }

    return {"autoloads": autoloads, "error": None}
