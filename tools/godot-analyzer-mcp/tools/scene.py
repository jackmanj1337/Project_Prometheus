from pathlib import Path
from parsers.tscn import parse_tscn


def _resolve(path_str: str, project_root: Path) -> Path:
    if path_str.startswith("res://"):
        return project_root / path_str[6:]
    return Path(path_str)


def _to_res(path: Path, project_root: Path) -> str:
    try:
        return "res://" + path.relative_to(project_root).as_posix()
    except ValueError:
        return str(path)


def get_scene_nodes(scene_path: str, project_root: Path) -> str:
    path = _resolve(scene_path, project_root)
    if not path.exists():
        return f"Error: file not found: {path}"

    scene = parse_tscn(path)
    if scene["error"]:
        return f"Parse error: {scene['error']}"

    lines = [f"Scene: {path.name}  (root: {scene['root_name']})", ""]
    lines.append(f"  {'$path from root':<42} {'Type':<26} Script")
    lines.append("  " + "-" * 90)

    for node in scene["nodes"]:
        display = "(root)" if not node["path"] else node["path"]
        script = node["script"] or ""
        if script.startswith("res://"):
            script = script[6:]
        lines.append(f"  {display:<42} {node['type']:<26} {script}")

    return "\n".join(lines)


def find_scenes_with_script(script_path: str, project_root: Path) -> str:
    # Normalise to res:// for comparison
    if not script_path.startswith("res://"):
        p = Path(script_path)
        if p.is_absolute():
            script_path = _to_res(p, project_root)
        else:
            script_path = "res://" + script_path.replace("\\", "/")

    matches = []
    for tscn in sorted(project_root.rglob("*.tscn")):
        scene = parse_tscn(tscn)
        for node in scene["nodes"]:
            if node["script"] == script_path:
                matches.append(
                    f"  {_to_res(tscn, project_root):<60}  node: {node['name']}"
                )
                break

    if not matches:
        return f"No scenes found using script: {script_path}"
    return f"Scenes using {script_path}:\n" + "\n".join(matches)
