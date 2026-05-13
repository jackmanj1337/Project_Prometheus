from pathlib import Path
from parsers.paths import resolve
from parsers.tres import parse_tres


def get_resource_fields(resource_path: str, project_root: Path) -> str:
    path = resolve(resource_path, project_root)
    if not path.exists():
        return f"Error: file not found: {path}"

    res = parse_tres(path)
    if res["error"]:
        return f"Parse error: {res['error']}"

    lines = [f"Resource: {path.name}  (type: {res['resource_type']})", ""]

    fields = res["fields"]
    if not fields:
        lines.append("  (no fields)")
    else:
        width = max(len(k) for k in fields)
        for key in sorted(fields):
            lines.append(f"  {key:<{width}}  =  {fields[key]}")

    return "\n".join(lines)
