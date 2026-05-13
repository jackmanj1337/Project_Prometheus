#!/usr/bin/env python3
"""
Godot Analyzer MCP Server

Provides static analysis tools for Godot 4 projects over the MCP stdio transport.
Uses only the Python standard library — no external packages required.

Usage: python3 server.py <project_root>
"""

import json
import sys
import logging
from pathlib import Path

# Ensure sibling packages (parsers/, tools/) are importable regardless of cwd
sys.path.insert(0, str(Path(__file__).parent))

from tools.scene    import get_scene_nodes, find_scenes_with_script
from tools.resource import get_resource_fields
from tools.script   import validate_onready_paths
from tools.project  import get_autoloads

log = logging.getLogger(__name__)

# ── Tool manifest ─────────────────────────────────────────────────────────────

TOOLS = [
    {
        "name": "get_scene_nodes",
        "description": (
            "Returns all nodes in a Godot .tscn scene file with their types, "
            "GDScript $-paths (relative to scene root), and attached scripts. "
            "Use this to verify that node paths referenced in code actually exist."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "scene_path": {
                    "type": "string",
                    "description": "Path to the .tscn file — absolute or res:// form.",
                }
            },
            "required": ["scene_path"],
        },
    },
    {
        "name": "validate_onready_paths",
        "description": (
            "Parses every @onready var declaration that uses a $node/path from a "
            ".gd script, finds the scene that attaches that script, and reports "
            "which paths exist and which are missing. "
            "Essential for catching $Panel/VBox/Missing references before runtime."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "script_path": {
                    "type": "string",
                    "description": "Path to the .gd script — absolute or res:// form.",
                }
            },
            "required": ["script_path"],
        },
    },
    {
        "name": "get_resource_fields",
        "description": (
            "Returns all exported field values from a Godot .tres resource file "
            "with their raw string values. More reliable than reading the file as "
            "plain text — handles the Godot resource format correctly."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "resource_path": {
                    "type": "string",
                    "description": "Path to the .tres file — absolute or res:// form.",
                }
            },
            "required": ["resource_path"],
        },
    },
    {
        "name": "find_scenes_with_script",
        "description": (
            "Scans all .tscn files in the project and returns those that attach "
            "the given script to any node. Useful for reverse-lookup when you "
            "need to know which scenes a script is responsible for."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "script_path": {
                    "type": "string",
                    "description": "Path to the .gd script — absolute or res:// form.",
                }
            },
            "required": ["script_path"],
        },
    },
    {
        "name": "get_autoloads",
        "description": (
            "Returns the list of autoload singletons registered in project.godot, "
            "with their script paths and enabled status. Use this to verify that "
            "a new autoload was registered correctly."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {},
        },
    },
]

# ── Dispatch ──────────────────────────────────────────────────────────────────

def dispatch(name: str, args: dict, project_root: Path) -> str:
    if name == "get_scene_nodes":
        return get_scene_nodes(args["scene_path"], project_root)
    if name == "validate_onready_paths":
        return validate_onready_paths(args["script_path"], project_root)
    if name == "get_resource_fields":
        return get_resource_fields(args["resource_path"], project_root)
    if name == "find_scenes_with_script":
        return find_scenes_with_script(args["script_path"], project_root)
    if name == "get_autoloads":
        return get_autoloads(project_root)
    raise ValueError(f"Unknown tool: {name}")

# ── JSON-RPC helpers ──────────────────────────────────────────────────────────

def send(data: dict) -> None:
    print(json.dumps(data), flush=True)


def ok(msg_id, result: dict) -> None:
    send({"jsonrpc": "2.0", "id": msg_id, "result": result})


def err(msg_id, code: int, message: str) -> None:
    send({"jsonrpc": "2.0", "id": msg_id, "error": {"code": code, "message": message}})

# ── Main loop ─────────────────────────────────────────────────────────────────

def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: server.py <project_root>", file=sys.stderr)
        sys.exit(1)

    project_root = Path(sys.argv[1]).resolve()
    logging.basicConfig(stream=sys.stderr, level=logging.WARNING)

    for raw_line in sys.stdin:
        raw_line = raw_line.strip()
        if not raw_line:
            continue

        try:
            msg = json.loads(raw_line)
        except json.JSONDecodeError as e:
            log.error("JSON decode error: %s", e)
            continue

        msg_id = msg.get("id")
        method = msg.get("method", "")

        # Notifications have no id — no response required
        if msg_id is None:
            continue

        if method == "initialize":
            ok(msg_id, {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "godot-analyzer", "version": "1.0.0"},
            })

        elif method == "tools/list":
            ok(msg_id, {"tools": TOOLS})

        elif method == "tools/call":
            params    = msg.get("params", {})
            tool_name = params.get("name", "")
            tool_args = params.get("arguments", {})
            try:
                text = dispatch(tool_name, tool_args, project_root)
                ok(msg_id, {"content": [{"type": "text", "text": text}]})
            except Exception as e:
                ok(msg_id, {
                    "content": [{"type": "text", "text": f"Error: {e}"}],
                    "isError": True,
                })

        else:
            err(msg_id, -32601, f"Method not found: {method}")


if __name__ == "__main__":
    main()
