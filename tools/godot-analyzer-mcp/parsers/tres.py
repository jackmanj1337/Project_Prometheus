"""Parser for Godot 4 text resource files (.tres)."""

import re
from pathlib import Path


def parse_tres(path: Path) -> dict:
    """
    Parse a .tres file and return its exported field values as raw strings.
    Multi-line values (rare in practice) are not supported and will be truncated
    to the first line — all primitive fields and single-line arrays parse correctly.

    Returns:
        resource_type: str | None
        fields       : {key: raw_value_string}
        error        : str | None
    """
    try:
        content = path.read_text(encoding="utf-8")
    except OSError as e:
        return {"resource_type": None, "fields": {}, "error": str(e)}

    header_m = re.search(r'\[gd_resource\s+type="([^"]+)"', content)
    resource_type = header_m.group(1) if header_m else None

    # The [resource] section holds the exported fields; sub_resource sections are skipped.
    section_m = re.search(r'\[resource\](.*?)(?=\n\[|\Z)', content, re.DOTALL)
    if not section_m:
        return {"resource_type": resource_type, "fields": {}, "error": None}

    fields = {}
    for line in section_m.group(1).splitlines():
        line = line.strip()
        if not line or line.startswith(";") or line.startswith("#"):
            continue
        m = re.match(r'^([^=]+?)\s*=\s*(.+)$', line)
        if m:
            fields[m.group(1).strip()] = m.group(2).strip()

    return {"resource_type": resource_type, "fields": fields, "error": None}
