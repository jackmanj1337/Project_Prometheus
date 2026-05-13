"""Extracts @onready declarations from GDScript source files."""

import re
from pathlib import Path


def parse_onready_paths(path: Path) -> list:
    """
    Return a list of @onready variable declarations that use a $node/path.

    Each entry: {var_name: str, node_path: str, line: int}
    node_path is the raw path string after $, e.g. "Panel/VBox/LabelName".
    """
    try:
        source = path.read_text(encoding="utf-8")
    except OSError:
        return []

    results = []
    # Matches both typed and untyped forms:
    #   @onready var _foo: Label = $Panel/VBox/Label
    #   @onready var _foo = $Panel/VBox/Label
    pattern = re.compile(
        r'^\s*@onready\s+var\s+(\w+)(?:\s*:\s*[\w.]+)?\s*=\s*\$([^\s#\n]+)',
        re.MULTILINE,
    )
    for m in pattern.finditer(source):
        line_number = source[:m.start()].count("\n") + 1
        results.append({
            "var_name":  m.group(1),
            "node_path": m.group(2).rstrip(","),
            "line":      line_number,
        })

    return results
