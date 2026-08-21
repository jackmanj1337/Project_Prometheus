#!/usr/bin/env python3
"""check_availability_reasons.py — a gated entry must carry its reason on the entry.

[EPUX-07] / [RPD-15] rule that a gated entry stays in the focus order AND carries a
reason. The focus half is implemented in ModalScreen.gd and FocusNavigator.gd; the
reason half was, until this check, implemented by hand on each surface. That does not
survive contact with a new screen: OverworldScreen (2026-08-19) was a bare Control that
used neither shared file and reproduced the defect the shell-wide fix had closed the day
before, and the shipped MainMenu gated Continue and Load Game with no reason at all for
months. Six hand-applications, and nothing ever failed.

So this is the check half of AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20. A shared
availability-list builder was considered and rejected for the same job: a builder only
helps surfaces written after it lands, while every surface written before it still needs
the hand-application that has now happened six times.

THE RULE. Wherever a script disables a BaseButton, the same script must also set that
button's `tooltip_text`. One carrier, on the entry itself, because that is the only
place a keyboard or screen-reader user standing on the gated entry can reach:

    _load_game_btn.disabled = slots.is_empty()
    _load_game_btn.tooltip_text = "" if not _load_game_btn.disabled else _menu_text(...)

A nearby validation or status label does NOT satisfy this, deliberately. PrepScreen's
`_validation.text` and MapResultsScreen's `_save_status_label.text` explain the gate to
someone who can see the whole screen; neither is announced when focus lands on the
disabled button, which is the exact case that surfaced the sixth instance.

The check is textual and file-scoped: it pairs assignments by receiver name within one
file. That is coarse on purpose — it cannot prove the reason is CORRECT, only that a
carrier exists. Pinning the rendered sentence is the job of a screen's own suite (see
test_main_menu.gd and test_overworld_screen.gd, which assert the rendered text rather
than its non-emptiness).

`disabled = false` ENABLES an entry and is skipped: it is the reset at the top of a
refresh, and a screen that only ever enables cannot gate anything.

WAIVERS, following the `# rng-allow:` precedent in check_rng_usage.sh. Put one on the
assignment line, or on the comment line directly above it when the assignment is
already near gdlint's line-length cap:

    # availability-allow: <why this is not an availability gate>
        A transient control state rather than a gate over a player's choice — a list
        reorder arrow at the end of its travel, a toolbar button that follows a mode.

    # availability-todo: <TRACKER-ROW-ID>
        A real gate that still owes a reason. Suppresses the failure, but is counted
        and printed on every run so it cannot quietly become permanent.

Scenes are checked too. A `disabled = true` on a node in a .tscn must be accompanied by
`tooltip_text` in the same node section. There are no such sites today; the check covers
them so the scene file does not become the way around the script rule.

Run from anywhere:  python3 scripts/ci/check_availability_reasons.py
Exit 0 = clean, 1 = violations. `--root DIR` scans a different tree, which is how
test_check_availability_reasons.py drives it over fixtures.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]

# `<receiver>.disabled =` but not `==`. The receiver is captured loosely and normalized
# below, because it shows up as a bare name, a member, or a parenthesized cast.
GD_ASSIGN = re.compile(r"^\s*(?P<recv>.+?)\.disabled\s*=(?!=)\s*(?P<value>.*)$")
# `disabled = false` ENABLES an entry. A screen that only ever enables cannot gate
# anything, so these are skipped outright rather than made to carry a waiver — they are
# resets at the top of a refresh, and requiring a marker on each would train authors to
# add markers reflexively, which is how a waiver vocabulary stops being read.
GD_ENABLE = re.compile(r"^false\s*(#.*)?$")
# `(control as OptionButton).disabled = false` gates `control`, not the cast expression.
GD_CAST = re.compile(r"^\((?P<inner>.+?)\s+as\s+\w+\)$")
ALLOW = re.compile(r"#\s*availability-allow:\s*(?P<reason>\S.*)$")
TODO = re.compile(r"#\s*availability-todo:\s*(?P<row>\S+)")

TSCN_SECTION = re.compile(r"^\[(?P<kind>\w+)")
TSCN_DISABLED = re.compile(r"^disabled\s*=\s*true\s*$")
TSCN_TOOLTIP = re.compile(r"^tooltip_text\s*=")


class Finding:
    def __init__(self, path: str, line: int, receiver: str, source: str) -> None:
        self.path = path
        self.line = line
        self.receiver = receiver
        self.source = source

    def __str__(self) -> str:
        return f"  {self.path}:{self.line}  {self.source}"


def normalize_receiver(raw: str) -> str:
    """Reduce an assignment target to the name the tooltip would be set on."""
    recv = raw.strip()
    cast = GD_CAST.match(recv)
    if cast:
        recv = cast.group("inner").strip()
    return recv


def has_carrier(text: str, receiver: str) -> bool:
    """True when the file sets tooltip_text on the same receiver, anywhere."""
    # The lookbehind stops `up` from matching `group.tooltip_text`; the receiver may
    # itself be dotted (`_row.button`), which is why `.` is excluded rather than \b.
    pattern = re.compile(r"(?<![\w.])" + re.escape(receiver) + r"\.tooltip_text\s*=")
    return bool(pattern.search(text))


def check_gdscript(path: pathlib.Path, rel: str) -> tuple[list[Finding], list[str]]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    violations: list[Finding] = []
    todos: list[str] = []
    for number, line in enumerate(lines, start=1):
        match = GD_ASSIGN.match(line)
        if not match:
            continue
        if GD_ENABLE.match(match.group("value").strip()):
            continue
        # A marker sits on the assignment line, or on the comment line directly above
        # it. Both are needed: gdlint caps line length, and several of these
        # assignments are already near the cap before any comment is added.
        marked = [line]
        previous = lines[number - 2].strip() if number >= 2 else ""
        if previous.startswith("#"):
            marked.append(previous)
        if any(ALLOW.search(candidate) for candidate in marked):
            continue
        todo = next(
            (found for found in (TODO.search(c) for c in marked) if found), None
        )
        if todo:
            todos.append(f"  {rel}:{number}  owed by {todo.group('row')}")
            continue
        receiver = normalize_receiver(match.group("recv"))
        if has_carrier(text, receiver):
            continue
        violations.append(Finding(rel, number, receiver, line.strip()))
    return violations, todos


def check_scene(path: pathlib.Path, rel: str) -> list[Finding]:
    """A node section that disables a button must also give it a tooltip."""
    violations: list[Finding] = []
    section_start = 0
    section_lines: list[str] = []

    def flush() -> None:
        if not section_lines:
            return
        disabled_at = next(
            (
                index
                for index, body in enumerate(section_lines)
                if TSCN_DISABLED.match(body)
            ),
            None,
        )
        if disabled_at is None:
            return
        if any(TSCN_TOOLTIP.match(body) for body in section_lines):
            return
        line = section_start + disabled_at
        violations.append(Finding(rel, line, "<scene node>", section_lines[0].strip()))

    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if TSCN_SECTION.match(line):
            flush()
            section_start = number
            section_lines = [line]
        elif section_lines:
            section_lines.append(line)
    flush()
    return violations


def iter_sources(root: pathlib.Path) -> list[tuple[pathlib.Path, str]]:
    sources: list[tuple[pathlib.Path, str]] = []
    for path in sorted((root / "scripts").rglob("*.gd")):
        rel = path.relative_to(root).as_posix()
        # Suites disable buttons to set up the very states this check is about.
        if "/tests/" in rel:
            continue
        sources.append((path, rel))
    for path in sorted((root / "scenes").rglob("*.tscn")):
        sources.append((path, path.relative_to(root).as_posix()))
    return sources


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=pathlib.Path, default=REPO_ROOT)
    args = parser.parse_args(argv)

    violations: list[Finding] = []
    todos: list[str] = []
    for path, rel in iter_sources(args.root):
        if rel.endswith(".gd"):
            found, owed = check_gdscript(path, rel)
            violations.extend(found)
            todos.extend(owed)
        else:
            violations.extend(check_scene(path, rel))

    if todos:
        print(f"check_availability_reasons: {len(todos)} gate(s) still owe a reason:")
        for entry in todos:
            print(entry)

    if violations:
        print(f"FAIL: {len(violations)} gated entrie(s) with no reason on the entry.")
        for violation in violations:
            print(str(violation))
        print(
            "      [EPUX-07]/[RPD-15]: a gated entry stays focusable AND carries a "
            "reason.\n"
            "      Set tooltip_text on the same button, taking the text from the "
            "availability\n"
            "      authority rather than phrasing it in the screen ([EPUX-04]). If this "
            "is not\n"
            "      an availability gate, mark the line '# availability-allow: <why>'."
        )
        return 1

    print(
        "check_availability_reasons: PASS — every gated entry carries a reason "
        f"({len(todos)} deferred)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
