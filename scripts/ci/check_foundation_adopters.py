#!/usr/bin/env python3
"""check_foundation_adopters.py — a foundation must have a caller that is not a test.

The prose clause landed 2026-08-22 (FOUNDATION-ADOPTER-GATE): *a foundation closes on
an adopter, not on its own tests.* A row shipping an engine primitive, registry or
service closes `completed` only with a non-test caller, or by naming a dated successor
row that already exists. That clause governs when a TRACKER ROW may close, which lives
in the container repo and which no checker here can see. This is its code-level
symptom check, which IS mechanical: the shape it looks for is a foundation nothing
outside `scripts/tests/` reaches.

TWO RULES, because the engine has two foundation shapes and one query does not see
both. The row that cut this check assumed one query would; that was wrong, and the
correction is the reason the check is built this way:

1. `class_name` TYPES, by REACHABILITY, not by direct reference. A direct-reference
   grep is not enough: `PrepActivityRegistry` — the instance the clause was written
   for — IS referenced outside its own file, by `PrepActivityDef.gd`, which nothing
   itself reaches. A two-file orphan cluster passes a direct-reference check and is
   exactly the failure mode the clause is about. So the check walks outward from real
   entry points instead: the `[autoload]` block in `project.godot` and every script
   attached to a scene under `scenes/`. A type whose file that walk never arrives at
   has no adopter, however many unadopted neighbours mention it.

2. AUTOLOADS, by direct reference. An autoload is an entry point by construction, so
   rule 1 can never flag one — it is always its own root. Its adopter question is a
   different one: does any non-test file mention the autoload name at all? This is
   the rule that covers `extends Node` services with no `class_name`, which rule 1
   cannot see either. `RequirementSystem` is one such service, and it PASSES —
   `CampaignManager.gd` resolves it at `/root/RequirementSystem`.

WAIVERS follow the `# rng-allow:` and `# availability-allow:` precedent — inline in
the file itself rather than a central allowlist that nobody reads. Put one in the
first 20 lines of the declaring file:

    # adopter-allow: <why this needs no in-repo caller>
        The consumer cannot be in this repository by construction. `WebTestBridge`
        is read over `JavaScriptBridge` by the Playwright harness;
        `SaveBudgetMeasurement` is a measurement fixture whose consumer is the suite
        that publishes its evidence.

    # adopter-todo: <TRACKER-ROW-ID>
        A real foundation still waiting for its consumer. Suppresses the failure, but
        is counted and printed on every run so it cannot quietly become permanent.
        Every one of these must name a row that exists — that is what makes the debt
        recoverable rather than forgotten.

COMMENTS DO NOT COUNT. Prose naming a foundation is not adoption, and this is not a
theoretical worry — see `strip_comments`, which exists because the first draft of this
check went green on a real finding after a comment added in the same pass mentioned it.

WHAT THIS CHECK STILL CANNOT DO. It cannot tell a good adopter from a token one: one
identifier in dead code counts. Pinning that a foundation is genuinely USED is the job
of the consumer's own suite. This only asserts that something outside the tests reaches
it at all — the coarse half, which is the half that was going unnoticed.

Run from anywhere:  python3 scripts/ci/check_foundation_adopters.py
Exit 0 = clean, 1 = violations. `--root DIR` scans a different tree, which is how
test_check_foundation_adopters.py drives it over fixtures.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]

CLASS_NAME = re.compile(r"^class_name\s+(?P<name>\w+)", re.M)
# `Foo="*res://scripts/autoloads/Foo.gd"` in project.godot's [autoload] block.
AUTOLOAD = re.compile(r'^(?P<name>\w+)="\*?res://(?P<path>[^"]+)"', re.M)
# A scene's script reference: `[ext_resource type="Script" path="res://..." ...]`.
SCENE_SCRIPT = re.compile(r'path="res://(?P<path>[^"]+\.gd)"')
# A `preload`/`load` of a script by path, which reaches a file with no class_name.
SCRIPT_PATH = re.compile(r'res://(?P<path>scripts/[^"\']+\.gd)')

ALLOW = re.compile(r"#\s*adopter-allow:\s*(?P<reason>\S.*)$", re.M)
TODO = re.compile(r"#\s*adopter-todo:\s*(?P<row>\S+)", re.M)

# A marker belongs at the top of the file it excuses, next to the declaration it is
# about. Scanning the whole file would let a marker written for one thing silence a
# declaration hundreds of lines away.
MARKER_WINDOW = 20

TESTS_DIR = "/tests/"


class Finding:
    def __init__(self, kind: str, name: str, path: str) -> None:
        self.kind = kind
        self.name = name
        self.path = path

    def __str__(self) -> str:
        return f"  {self.kind} {self.name}  ({self.path})"


def marker(text: str) -> tuple[str | None, str | None]:
    """Return (allow_reason, todo_row) from the head of a file."""
    head = "\n".join(text.splitlines()[:MARKER_WINDOW])
    allow = ALLOW.search(head)
    todo = TODO.search(head)
    return (
        allow.group("reason").strip() if allow else None,
        todo.group("row") if todo else None,
    )


def load_tree(root: pathlib.Path) -> tuple[dict[str, str], dict[str, str], str]:
    """Return (non-test .gd texts by relpath, scene texts by relpath, project.godot)."""
    scripts: dict[str, str] = {}
    for path in sorted(root.glob("scripts/**/*.gd")):
        rel = path.relative_to(root).as_posix()
        if TESTS_DIR in f"/{rel}":
            continue
        scripts[rel] = path.read_text(encoding="utf-8", errors="replace")
    scenes = {
        path.relative_to(root).as_posix(): path.read_text(encoding="utf-8", errors="replace")
        for path in sorted(root.glob("scenes/**/*.tscn"))
    }
    project = root / "project.godot"
    return scripts, scenes, project.read_text(encoding="utf-8") if project.exists() else ""


def declared_types(scripts: dict[str, str]) -> dict[str, str]:
    """class_name -> declaring file."""
    types: dict[str, str] = {}
    for rel, text in scripts.items():
        found = CLASS_NAME.search(text)
        if found:
            types[found.group("name")] = rel
    return types


def autoloads(project: str) -> dict[str, str]:
    """Autoload name -> script path, from project.godot's [autoload] block."""
    if "[autoload]" not in project:
        return {}
    block = project.split("[autoload]", 1)[1].split("\n[", 1)[0]
    return {m.group("name"): m.group("path") for m in AUTOLOAD.finditer(block)}


def strip_comments(text: str) -> str:
    """Drop GDScript comments, keeping `#` that sits inside a string literal.

    A foundation named only in a prose comment is NOT adopted, and treating one as
    adopted is not a theoretical worry: the first draft of this check went green on
    `ControllerWebBridge` because a marker comment added in the same pass -- to a file
    that happens to be an autoload, and so a reachability seed -- mentioned it by
    name. A guard that its own explanatory comments can silence is worse than no
    guard, because it reads as evidence.
    """
    out: list[str] = []
    for line in text.splitlines():
        quote = ""
        cut = len(line)
        index = 0
        while index < len(line):
            char = line[index]
            if quote:
                if char == "\\":
                    index += 2
                    continue
                if char == quote:
                    quote = ""
            elif char in "\"'":
                quote = char
            elif char == "#":
                cut = index
                break
            index += 1
        out.append(line[:cut])
    return "\n".join(out)


def mentions(text: str, name: str) -> bool:
    """True when `name` appears as a bare identifier.

    The lookbehind excludes `.` so `foo.Bar` does not count as reaching `Bar`, and
    excludes quote characters so a class's own name inside its error strings does not
    make a neighbour look like an adopter.
    """
    return bool(re.search(r"(?<![\w.\"'])" + re.escape(name) + r"(?![\w])", text))


def reachable_files(
    scripts: dict[str, str], scenes: dict[str, str], project: str, types: dict[str, str]
) -> set[str]:
    """Every script file the engine can arrive at, walked out from real entry points."""
    seeds: set[str] = set()
    for path in autoloads(project).values():
        if path in scripts:
            seeds.add(path)
    for text in scenes.values():
        for found in SCENE_SCRIPT.finditer(text):
            if found.group("path") in scripts:
                seeds.add(found.group("path"))

    code = {rel: strip_comments(text) for rel, text in scripts.items()}
    reached = set(seeds)
    frontier = list(seeds)
    while frontier:
        current = frontier.pop()
        text = code[current]
        outgoing = {
            declaring
            for name, declaring in types.items()
            if declaring != current and mentions(text, name)
        }
        outgoing |= {
            found.group("path")
            for found in SCRIPT_PATH.finditer(text)
            if found.group("path") in scripts
        }
        for target in outgoing:
            if target not in reached:
                reached.add(target)
                frontier.append(target)
    return reached


def check(root: pathlib.Path) -> tuple[list[Finding], list[str], list[str]]:
    scripts, scenes, project = load_tree(root)
    types = declared_types(scripts)
    reached = reachable_files(scripts, scenes, project, types)

    violations: list[Finding] = []
    todos: list[str] = []
    waived: list[str] = []

    for name, rel in sorted(types.items()):
        if rel in reached:
            continue
        allow, todo = marker(scripts[rel])
        if allow:
            waived.append(f"{name} ({rel}): {allow}")
        elif todo:
            todos.append(f"  type     {name} ({rel})  owed by {todo}")
        else:
            violations.append(Finding("type    ", name, rel))

    # Rule 2. An autoload is its own entry point, so reachability can never flag one.
    non_test_text = {rel: strip_comments(text) for rel, text in scripts.items()}
    non_test_text.update(scenes)
    for name, rel in sorted(autoloads(project).items()):
        callers = [
            other
            for other, text in non_test_text.items()
            if other != rel and mentions(text, name)
        ]
        if callers:
            continue
        text = scripts.get(rel, "")
        allow, todo = marker(text)
        if allow:
            waived.append(f"{name} ({rel}): {allow}")
        elif todo:
            todos.append(f"  autoload {name} ({rel})  owed by {todo}")
        else:
            violations.append(Finding("autoload", name, rel))

    return violations, todos, waived


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=pathlib.Path, default=REPO_ROOT)
    parser.add_argument(
        "--list-waivers", action="store_true",
        help="also print the permanently waived foundations and their reasons",
    )
    args = parser.parse_args(argv)

    violations, todos, waived = check(args.root)

    if todos:
        print(f"check_foundation_adopters: {len(todos)} foundation(s) still owe an adopter:")
        for entry in todos:
            print(entry)
    if args.list_waivers and waived:
        print(f"check_foundation_adopters: {len(waived)} waived:")
        for entry in waived:
            print(f"  {entry}")

    if violations:
        noun = "foundation" if len(violations) == 1 else "foundations"
        print(f"FAIL: {len(violations)} {noun} with no caller outside scripts/tests/.")
        for violation in violations:
            print(str(violation))
        print(
            "      A foundation closes on an adopter, not on its own tests.\n"
            "      Either land the consumer, or mark the declaring file's head:\n"
            "        '# adopter-todo: <TRACKER-ROW-ID>'  a real foundation still\n"
            "          waiting for its consumer -- counted and printed every run.\n"
            "        '# adopter-allow: <why>'            no in-repo caller is\n"
            "          possible, e.g. a surface read by an out-of-repo harness."
        )
        return 1

    print(
        "check_foundation_adopters: PASS — no unadopted foundations "
        f"({len(todos)} deferred, {len(waived)} waived)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
