"""Parser for Godot 4 text scene files (.tscn)."""

import re
from pathlib import Path


def parse_tscn(path: Path) -> dict:
    """
    Parse a .tscn file into a structured dict.

    Each node's 'path' field is the GDScript $-path relative to the scene root,
    e.g. "Panel/VBox/LabelName" for @onready var x = $Panel/VBox/LabelName.

    Returns:
        root_name    : str | None
        nodes        : list of {name, type, path, parent, script}
        ext_resources: {id: {type, path}}
        error        : str | None
    """
    try:
        content = path.read_text(encoding="utf-8")
    except OSError as e:
        return {"root_name": None, "nodes": [], "ext_resources": {}, "error": str(e)}

    ext_resources = {}
    nodes = []

    # Collect ext_resource declarations (script and scene references)
    for m in re.finditer(
        r'\[ext_resource\s+type="([^"]+)"\s+path="([^"]+)"\s+id="([^"]+)"\]',
        content,
    ):
        ext_resources[m.group(3)] = {"type": m.group(1), "path": m.group(2)}

    # Each [node ...] section runs until the next bracketed section or EOF
    node_re = re.compile(
        r'\[node\s+name="([^"]+)"([^\]]*)\](.*?)(?=\n\[|\Z)', re.DOTALL
    )

    root_name = None

    for m in node_re.finditer(content):
        name = m.group(1)
        attrs = m.group(2)
        body = m.group(3)

        type_m   = re.search(r'type="([^"]+)"', attrs)
        parent_m = re.search(r'parent="([^"]*)"', attrs)

        node_type = type_m.group(1) if type_m else "PackedScene"
        parent    = parent_m.group(1) if parent_m else None  # None → root node

        # GDScript $-path relative to scene root:
        #   root node  → ""   (you never $-reference the root itself)
        #   parent="." → "Name"
        #   parent="X" → "X/Name"
        if parent is None:
            gdpath = ""
            root_name = name
        elif parent == ".":
            gdpath = name
        else:
            gdpath = parent + "/" + name

        # Resolve attached script
        script = None
        sm = re.search(r'^script\s*=\s*ExtResource\("([^"]+)"\)', body, re.MULTILINE)
        if sm and sm.group(1) in ext_resources:
            script = ext_resources[sm.group(1)]["path"]

        nodes.append({
            "name":   name,
            "type":   node_type,
            "path":   gdpath,
            "parent": parent,
            "script": script,
        })

    return {
        "root_name":     root_name,
        "nodes":         nodes,
        "ext_resources": ext_resources,
        "error":         None,
    }


def resolve_node_path(scene: dict, gdpath: str) -> bool:
    """Return True if gdpath (e.g. 'Panel/VBox/Label') exists in the parsed scene."""
    gdpath = gdpath.lstrip("$").strip()
    return any(n["path"] == gdpath for n in scene["nodes"])
