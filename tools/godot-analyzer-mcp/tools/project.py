from pathlib import Path
from parsers.project_godot import parse_autoloads


def get_autoloads(project_root: Path) -> str:
    result = parse_autoloads(project_root)
    if result["error"]:
        return f"Error reading project.godot: {result['error']}"

    autoloads = result["autoloads"]
    if not autoloads:
        return "No autoloads registered in project.godot"

    lines = [f"Autoloads ({len(autoloads)}):"]
    for name, info in autoloads.items():
        status = "enabled" if info["enabled"] else "disabled"
        lines.append(f"  {name:<22}  {info['path']}  [{status}]")

    return "\n".join(lines)
