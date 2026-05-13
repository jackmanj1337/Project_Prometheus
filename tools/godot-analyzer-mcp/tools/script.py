from pathlib import Path
from parsers.gdscript import parse_onready_paths
from parsers.tscn import parse_tscn, resolve_node_path


def _resolve(path_str: str, project_root: Path) -> Path:
    if path_str.startswith("res://"):
        return project_root / path_str[6:]
    return Path(path_str)


def _to_res(path: Path, project_root: Path) -> str:
    try:
        return "res://" + path.relative_to(project_root).as_posix()
    except ValueError:
        return str(path)


def validate_onready_paths(script_path: str, project_root: Path) -> str:
    path = _resolve(script_path, project_root)
    if not path.exists():
        return f"Error: file not found: {path}"

    declarations = parse_onready_paths(path)
    if not declarations:
        return f"No @onready $-path declarations found in {path.name}"

    script_res = _to_res(path, project_root)

    # Find all scenes that attach this script to a node
    scene_hits = []
    for tscn in sorted(project_root.rglob("*.tscn")):
        scene = parse_tscn(tscn)
        for node in scene["nodes"]:
            if node["script"] == script_res:
                scene_hits.append((tscn, node["name"], scene))
                break

    lines = []

    if not scene_hits:
        lines.append(f"Script: {path.name}")
        lines.append("  No scene found using this script — cannot validate paths.")
        lines.append("")
        lines.append(f"  @onready declarations ({len(declarations)}):")
        for d in declarations:
            lines.append(f"    line {d['line']:3d}  {d['var_name']:<30} = ${d['node_path']}")
        return "\n".join(lines)

    for tscn_path, attached_to, scene in scene_hits:
        rel = _to_res(tscn_path, project_root)
        lines.append(f"Script: {path.name}")
        lines.append(f"Scene:  {rel}  (script attached to: {attached_to})")
        lines.append("")

        ok = miss = 0
        for d in declarations:
            exists = resolve_node_path(scene, d["node_path"])
            tag = "OK  " if exists else "MISS"
            if exists:
                ok += 1
            else:
                miss += 1
            lines.append(
                f"  {tag}  line {d['line']:3d}  {d['var_name']:<30} = ${d['node_path']}"
            )

        lines.append("")
        summary = f"  {ok} OK"
        if miss:
            summary += f", {miss} MISSING"
        lines.append(summary)

    return "\n".join(lines)
