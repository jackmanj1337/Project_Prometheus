#!/usr/bin/env python3
"""
gen_docs_index.py — generate AGENT/Docs/INDEX.md (doc map) and REGISTERS.md
(open-question/decisions registers catalog) from each document's header.

Ratified by `documentation_system_design_2026-06-23.md` (DSR-3): the manifests are
GENERATED, never hand-edited — a hand-maintained catalog rots (roadmap §H did). The
source of truth is each doc's header. A fenced metadata block at the top of a file is
preferred:

    ---
    Type: register
    Status: RESOLVED 2026-06-23
    Last verified: 2026-06-23
    Register: ICO-1..6
    Resolved-in: 2026-06-23e
    ---

Files without that block are classified by a filename/body heuristic so the generator
works during the transition (the headers pass fills blocks in incrementally).

Usage:
  python3 AGENT/Docs/gen_docs_index.py          # rewrite INDEX.md + REGISTERS.md
  python3 AGENT/Docs/gen_docs_index.py --check   # exit 1 if they would change

`check_docs.py` imports `build()` for its no-diff guard.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

DOCS = Path(__file__).resolve().parent          # AGENT/Docs/
GENERATED = {"INDEX.md", "REGISTERS.md"}

# TYPE taxonomy (DSR-1). Order = the section order in INDEX.md.
TYPE_ORDER = [
    "guide", "governance", "decision-record", "register",
    "design", "plan", "playtest", "handoff", "reference",
]
TYPE_TITLE = {
    "guide": "Guides & runbooks (active)",
    "governance": "Governance & doc-system",
    "decision-record": "Decision records & index",
    "register": "Open-question / decisions registers",
    "design": "Design & vision docs",
    "plan": "Implementation plans",
    "playtest": "Playtest builds / checklists / triage",
    "handoff": "Session handoffs",
    "reference": "Reference / feasibility / Q&A",
}

# Known active guides (DSR-2 guides/) — used by the heuristic fallback.
GUIDE_NAMES = {
    "testing_guide.md", "map_authoring_guide.md", "environment_setup.md",
    "campaign_rules.md", "manual_test_playbook.md", "Docker Instructions.md",
    "new_machine_transfer_checklist.md", "fe_map_sprite_importer_guide.md",
}

_ID_RE = re.compile(r"\[([A-Z]{2,4})-(\d+)(?:\.\.(\d+))?\]")
_FENCE_RE = re.compile(r"\A---\n(.*?)\n---\n", re.S)
_PROSE_STATUS_RE = re.compile(r"^\s*(?:\*\*)?Status:?\*?\*?\s*(.+)$", re.I | re.M)
_HIST_RE = re.compile(r">\s*\*\*(Historical|ARCHIVED|Archived|Superseded)\*\*")


@dataclass
class Doc:
    path: Path
    rel: str
    type: str = "reference"
    status: str = ""
    lifecycle: str = ""          # OPEN / RESOLVED / SUPERSEDED / Historical / ""
    last_verified: str = ""
    register: str = ""           # e.g. "ICO-1..6"
    resolved_in: str = ""
    archived: bool = False
    title: str = ""
    fields: dict = field(default_factory=dict)


def _parse_fence(text: str) -> dict:
    m = _FENCE_RE.match(text)
    if not m:
        return {}
    out = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            out[k.strip().lower()] = v.strip()
    return out


def _first_heading(text: str) -> str:
    for line in text.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return ""


def _lifecycle(status: str) -> str:
    s = status.upper()
    if "SUPERSEDED" in s:
        return "SUPERSEDED"
    # OPEN wins over RESOLVED: a register with any open item is OPEN even if it
    # also records partial resolutions (e.g. "CST-1..12 RESOLVED, CST-13 OPEN").
    if "OPEN" in s:
        return "OPEN"
    if "RESOLVED" in s:
        return "RESOLVED"
    if "HISTORICAL" in s or "ARCHIVED" in s:
        return "Historical"
    return ""


def _dominant_register(text: str) -> str:
    """Return 'PREFIX-min..max' for the most common [XXX-n] prefix, else ''."""
    counts: dict[str, list[int]] = {}
    for m in _ID_RE.finditer(text):
        prefix, lo, hi = m.group(1), int(m.group(2)), int(m.group(3) or m.group(2))
        counts.setdefault(prefix, []).extend([lo, hi])
    if not counts:
        return ""
    prefix = max(counts, key=lambda p: len(counts[p]))
    nums = counts[prefix]
    lo, hi = min(nums), max(nums)
    return f"{prefix}-{lo}..{hi}" if lo != hi else f"{prefix}-{lo}"


def _heuristic_type(rel: str, name: str, text: str, register: str) -> str:
    low = name.lower()
    if name in GUIDE_NAMES:
        return "guide"
    if any(k in low for k in (
        "documentation_governance", "documentation_lifecycle",
        "documentation_consolidation", "documentation_review",
        "documentation_system", "check_docs",
    )):
        return "governance"
    if low.startswith("decision_") or "design_decisions_log" in low or \
            low == "online_play_design_decisions.md":
        return "decision-record"
    if "open_questions" in low or "open_decisions" in low or \
            (register and text.count("[" + register.split("-")[0]) >= 3):
        return "register"
    if low.startswith("playtest"):
        return "playtest"
    if low.startswith("handoff"):
        return "handoff"
    if "implementation_plan" in low or low.endswith("_plan.md") or "_plan_" in low:
        return "plan"
    if "design" in low or "vision" in low:
        return "design"
    return "reference"


def _scan() -> list[Doc]:
    docs: list[Doc] = []
    for path in sorted(DOCS.rglob("*.md")):
        name = path.name
        if name in GENERATED:
            continue
        rel = path.relative_to(DOCS).as_posix()
        text = path.read_text(encoding="utf-8")
        head = "\n".join(text.splitlines()[:12])
        fence = _parse_fence(text)

        register = fence.get("register", "") or _dominant_register(text)
        if fence.get("type"):
            dtype = fence["type"].strip().lower()
        else:
            dtype = _heuristic_type(rel, name, text, register)

        status = fence.get("status", "")
        if not status:
            m = _PROSE_STATUS_RE.search(text)
            status = (m.group(1).strip() if m else "")[:90]

        archived = rel.startswith("archive/") or bool(_HIST_RE.search(head))
        lifecycle = _lifecycle(status)
        if archived and lifecycle not in ("SUPERSEDED", "Historical"):
            lifecycle = lifecycle or "Historical"

        docs.append(Doc(
            path=path, rel=rel, type=dtype, status=status, lifecycle=lifecycle,
            last_verified=fence.get("last verified", ""),
            register=register if dtype == "register" else "",
            resolved_in=fence.get("resolved-in", ""),
            archived=archived, title=_first_heading(text) or name,
        ))
    return docs


def _registers_md(docs: list[Doc]) -> str:
    regs = [d for d in docs if d.type == "register" or d.register]
    regs.sort(key=lambda d: (d.lifecycle != "OPEN", d.register or d.rel))
    lines = [
        "# Registers Catalog",
        "",
        "> **GENERATED** by `gen_docs_index.py` — do not hand-edit. Source of truth is each",
        "> register's header. Run `python3 AGENT/Docs/gen_docs_index.py` after changing a",
        "> register. Governance-ID decisions (DOC/RULE/SET/OPEN/RNG/AWR) live in",
        "> `decisions/decision_index.md`; this catalog covers the feature `[XXX-n]` namespace.",
        "",
        "| Register | Title | Status | Resolved in | File |",
        "|---|---|---|---|---|",
    ]
    for d in regs:
        reg = d.register or "—"
        status = d.lifecycle or (d.status[:24] if d.status else "—")
        resolved = d.resolved_in or "—"
        lines.append(f"| `{reg}` | {d.title} | {status} | {resolved} | `{d.rel}` |")
    lines.append("")
    return "\n".join(lines)


def _index_md(docs: list[Doc]) -> str:
    lines = [
        "# AGENT/Docs Index",
        "",
        "> **GENERATED** by `gen_docs_index.py` — do not hand-edit. Run",
        "> `python3 AGENT/Docs/gen_docs_index.py` after adding/moving a doc.",
        "> Retrieval: *what's active* → here; *where was a `[XXX-n]` decided* →",
        "> `REGISTERS.md`; *governance IDs* → `decisions/decision_index.md`.",
        "",
    ]
    live = [d for d in docs if not d.archived]
    archived = [d for d in docs if d.archived]

    for dtype in TYPE_ORDER:
        group = sorted((d for d in live if d.type == dtype), key=lambda d: d.rel)
        if not group:
            continue
        lines.append(f"## {TYPE_TITLE[dtype]}")
        lines.append("")
        for d in group:
            status = f" — *{d.lifecycle or d.status[:40]}*" if (d.lifecycle or d.status) else ""
            lines.append(f"- [`{d.rel}`]({d.rel.replace(' ', '%20')}) — {d.title}{status}")
        lines.append("")

    if archived:
        lines.append("## Archive (historical / superseded — kept, never deleted)")
        lines.append("")
        for d in sorted(archived, key=lambda d: d.rel):
            tag = d.lifecycle or "Historical"
            lines.append(f"- [`{d.rel}`]({d.rel.replace(' ', '%20')}) — {d.title} — *{tag}*")
        lines.append("")
    return "\n".join(lines)


def build() -> dict[str, str]:
    """Return {filename: content} for the generated manifests."""
    docs = _scan()
    return {"INDEX.md": _index_md(docs), "REGISTERS.md": _registers_md(docs)}


def main() -> int:
    check = "--check" in sys.argv
    drift = False
    for name, content in build().items():
        target = DOCS / name
        existing = target.read_text(encoding="utf-8") if target.exists() else None
        if existing != content:
            drift = True
            if check:
                print(f"DRIFT: {name} is out of date — run gen_docs_index.py")
            else:
                target.write_text(content, encoding="utf-8")
                print(f"wrote {name}")
    if check and drift:
        return 1
    if not check:
        print("INDEX.md / REGISTERS.md regenerated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
