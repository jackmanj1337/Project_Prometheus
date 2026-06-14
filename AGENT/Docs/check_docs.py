#!/usr/bin/env python3
"""
check_docs.py — Structural documentation consistency checks (DOC-011).

Run from the repo root: python3 AGENT/Docs/check_docs.py
Exit 0 = all checks pass. Exit 1 = one or more checks failed.

Checks:
  1. Banned paths  — active docs must not link to deleted/renamed files
  2. Repo paths    — backtick-quoted AGENT/ scripts/ data/ scenes/ paths must exist
  3. Headers       — active GDD chapters need Status + Last verified; guides need Last verified
  4. Feature index — .gd files listed as implemented in GDD_Feature_Index must exist
  5. Roadmap IDs   — no duplicate ## headings in GDD_10_Roadmap.md
  6. Stale dates   — Last verified must not be older than the file's last git commit date
  7. Status words  — status-bearing lines must not use 'current'/'complete'/'canonical'
  8. Status labels — every status-bearing line must carry an approved governance label
  9. .uid tracking — every Godot .uid sidecar on disk must be tracked in git
 10. Version tag  — the current product_version must have a matching git tag
"""

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent  # workspace root

_failures: list[str] = []


def _fail(check: str, path: Path, line_no: int, msg: str) -> None:
    rel = path.relative_to(ROOT) if path.is_relative_to(ROOT) else path
    _failures.append(f"[{check}] {rel}:{line_no}: {msg}")


def _is_historical(path: Path) -> bool:
    """True if the file carries a Historical or ARCHIVED marker in its first 10 lines."""
    try:
        with open(path, encoding="utf-8") as fh:
            for i, line in enumerate(fh):
                if i >= 10:
                    break
                if re.search(r">\s*\*\*(Historical|ARCHIVED|Archived)\*\*", line):
                    return True
    except OSError:
        pass
    return False


# ── file lists ──────────────────────────────────────────────────────────────

_ACTIVE_GDD_FILES = sorted((ROOT / "AGENT/GDD").glob("GDD_*.md"))

# DOC-003 status vocabulary binds the numbered design chapters (GDD_00–08) only —
# NOT the GDD_10 roadmap (its own tracker vocab: "COMPLETE", "Stub created") nor the
# indices (GDD_Feature_Index "Seed", GDD_Adoption_Matrix). Scope checks 7/8 to these.
_NUMBERED_CHAPTERS = [
    p for p in _ACTIVE_GDD_FILES if re.match(r"GDD_0\d", p.name)
]

_ACTIVE_GUIDE_FILES = [
    ROOT / "AGENT/Docs/testing_guide.md",
    ROOT / "AGENT/Docs/map_authoring_guide.md",
    ROOT / "AGENT/Docs/environment_setup.md",
    ROOT / "AGENT/Docs/campaign_rules.md",
    ROOT / "AGENT/Docs/manual_test_playbook.md",
    ROOT / "AGENT/Docs/Docker Instructions.md",
    ROOT / "AGENT/Docs/new_machine_transfer_checklist.md",
]

# These are scanned for banned/broken paths but are not operational guides
# and do not require a Last verified header.
_SCAN_ONLY_FILES = [
    ROOT / "README.md",
    ROOT / "AGENTS.md",
]

_ALL_SCAN_FILES = _ACTIVE_GDD_FILES + _ACTIVE_GUIDE_FILES + _SCAN_ONLY_FILES


# ── check 1: banned paths ───────────────────────────────────────────────────

_BANNED_PATHS = [
    "GDD_10a_Overview.md",
    "GDD_09_Checklist.md",
    "GDD_Assumptions.md",
    "GDD_Manual_Tasks.md",
]

# Lines that explicitly document the deletion/move are exempt.
_EXEMPT_RE = re.compile(
    r"\b(Deleted|deleted|Moved|moved|retrieve via [Gg]it|Stage [0-9])\b"
)


def check_banned_paths() -> None:
    """Active docs must not reference deleted or renamed file paths."""
    for path in _ALL_SCAN_FILES:
        if not path.exists() or _is_historical(path):
            continue
        with open(path, encoding="utf-8") as fh:
            for i, line in enumerate(fh, 1):
                if _EXEMPT_RE.search(line):
                    continue
                for banned in _BANNED_PATHS:
                    if banned in line:
                        _fail("banned-path", path, i,
                              f"reference to deleted/renamed path: {banned!r}")


# ── check 2: repo-relative path existence ───────────────────────────────────

_BACKTICK_PATH_RE = re.compile(
    r"`((?:AGENT|scripts|data|scenes)/[^`\s\)]+)`"
)
_TARGET_SKIP_RE = re.compile(r"\b(target|Target|Deleted|deleted|Moved|moved)\b")


# Template/example paths used in procedural how-to text — not real file paths.
_TEMPLATE_PATH_PREFIXES = (
    "data/skills/skill_name",  # GDD_05 how-to guide
    "data/maps/<",             # map_authoring_guide placeholder
    "data/classes/<",          # GDD_03 how-to guide
)


def check_repo_paths() -> None:
    """Backtick-quoted paths starting with AGENT/, scripts/, data/, scenes/ must exist."""
    for path in _ALL_SCAN_FILES:
        if not path.exists() or _is_historical(path):
            continue
        with open(path, encoding="utf-8") as fh:
            for i, line in enumerate(fh, 1):
                if _TARGET_SKIP_RE.search(line):
                    continue
                for m in _BACKTICK_PATH_RE.finditer(line):
                    raw = m.group(1).split("#")[0].rstrip(")")
                    if "*" in raw or "..." in raw:
                        continue
                    # Template placeholder paths (angle brackets or known example names)
                    if "<" in raw or ">" in raw:
                        continue
                    if any(raw.startswith(t) for t in _TEMPLATE_PATH_PREFIXES):
                        continue
                    if not (ROOT / raw).exists():
                        _fail("broken-path", path, i,
                              f"path does not exist in repo: {raw!r}")


# ── check 3: required headers ───────────────────────────────────────────────

def check_required_headers() -> None:
    """Active GDD numbered files need **Status:** + Last verified:; guides need Last verified:."""
    # GDD_10 (roadmap) is also checked — it has its own Status/Last verified added in Stage 6
    numbered = [
        p for p in _ACTIVE_GDD_FILES
        if re.match(r"GDD_\d", p.name) and not _is_historical(p)
    ]
    for path in numbered:
        try:
            content = path.read_text(encoding="utf-8")
        except OSError:
            continue
        first_15 = "\n".join(content.splitlines()[:15])
        if "**Status:**" not in first_15:
            _fail("required-header", path, 1,
                  "missing **Status:** in first 15 lines")
        if "Last verified:" not in content:
            _fail("required-header", path, 1,
                  "missing 'Last verified:' anywhere in file")

    for path in _ACTIVE_GUIDE_FILES:
        if not path.exists() or _is_historical(path):
            continue
        try:
            content = path.read_text(encoding="utf-8")
        except OSError:
            continue
        if "Last verified:" not in content:
            _fail("required-header", path, 1,
                  "active guide missing 'Last verified:'")


# ── check 4: feature index .gd targets exist ────────────────────────────────

_GD_FILE_RE = re.compile(r"`([A-Za-z_][A-Za-z0-9_]*\.gd)`")


def _before_match_has_target(line: str, match_start: int) -> bool:
    """True if 'target' appears before this match in the same cell/paren context."""
    before = line[:match_start]
    if re.search(r"\btarget\b", before, re.IGNORECASE):
        return True
    # Check innermost open paren before the match
    paren = before.rfind("(")
    if paren != -1:
        between = before[paren + 1 :]
        if re.search(r"\btarget\b", between, re.IGNORECASE):
            return True
    return False


def check_feature_index_targets() -> None:
    """Each .gd file in GDD_Feature_Index.md (not marked as target) must exist in the repo."""
    feature_index = ROOT / "AGENT/GDD/GDD_Feature_Index.md"
    if not feature_index.exists():
        _fail("feature-index", feature_index, 1, "file not found")
        return

    with open(feature_index, encoding="utf-8") as fh:
        for i, line in enumerate(fh, 1):
            if not line.startswith("|"):
                continue
            for m in _GD_FILE_RE.finditer(line):
                if _before_match_has_target(line, m.start()):
                    continue
                name = m.group(1)
                result = subprocess.run(
                    ["find", str(ROOT), "-name", name, "-not", "-path", "*/.*"],
                    capture_output=True, text=True,
                )
                if not result.stdout.strip():
                    _fail("feature-index", feature_index, i,
                          f"listed file not found in repo: {name!r}")


# ── check 5: duplicate roadmap milestone headings ───────────────────────────

def check_duplicate_roadmap_headings() -> None:
    """No ## heading should appear more than once in GDD_10_Roadmap.md."""
    roadmap = ROOT / "AGENT/GDD/GDD_10_Roadmap.md"
    if not roadmap.exists():
        _fail("roadmap-ids", roadmap, 1, "GDD_10_Roadmap.md not found")
        return

    seen: dict[str, int] = {}
    with open(roadmap, encoding="utf-8") as fh:
        for i, line in enumerate(fh, 1):
            m = re.match(r"^## (.+)", line.rstrip())
            if not m:
                continue
            heading = m.group(1).strip()
            if heading in seen:
                _fail("roadmap-ids", roadmap, i,
                      f"duplicate heading {heading!r} (first at line {seen[heading]})")
            else:
                seen[heading] = i


# ── check 6: stale Last verified ────────────────────────────────────────────

def _git_last_commit_date(path: Path) -> str | None:
    """Return YYYY-MM-DD of the last git commit that touched this file, or None."""
    result = subprocess.run(
        ["git", "-C", str(ROOT), "log", "-1", "--format=%as", "--", str(path)],
        capture_output=True, text=True,
    )
    date_str = result.stdout.strip()
    return date_str or None


def check_stale_last_verified() -> None:
    """GDD files changed after their Last verified date should be flagged."""
    numbered = [
        p for p in _ACTIVE_GDD_FILES
        if re.match(r"GDD_\d", p.name) and not _is_historical(p)
    ]
    for path in numbered:
        try:
            content = path.read_text(encoding="utf-8")
        except OSError:
            continue
        m = re.search(r"\*\*Last verified:\*\*\s*(\d{4}-\d{2}-\d{2})", content)
        if not m:
            continue
        verified = m.group(1)
        git_date = _git_last_commit_date(path)
        if git_date and git_date > verified:
            _fail("stale-verified", path, 1,
                  f"file last committed {git_date} but Last verified is {verified}")


# ── check 7: prohibited status words ────────────────────────────────────────

# A status-bearing line is one that declares a Status (chapter header `**Status:**`
# or a per-section `Status:` line). Only these are scanned — domain uses of "current"
# in prose (e.g. "the unit's current rank") are intentionally allowed (DOC-003).
_STATUS_LINE_RE = re.compile(r"^\s*(?:\*\*)?Status:")
_PROHIBITED_WORD_RE = re.compile(r"\b(current|complete|canonical)\b", re.IGNORECASE)


def check_prohibited_status_words() -> None:
    """Status-bearing lines must not use the words current/complete/canonical (DOC-003)."""
    for path in _NUMBERED_CHAPTERS:
        with open(path, encoding="utf-8") as fh:
            for i, line in enumerate(fh, 1):
                if not _STATUS_LINE_RE.match(line):
                    continue
                m = _PROHIBITED_WORD_RE.search(line)
                if m:
                    _fail("status-word", path, i,
                          f"prohibited word {m.group(1)!r} in a status-bearing line "
                          f"(use an approved label, e.g. 'project' vs 'corpus')")


# ── check 8: approved status labels ──────────────────────────────────────────

# The governance status vocabulary (DOC-003) plus the structural framings used in
# chapter/section headers (Split = a two-label split status; Active/Reference = chapter
# framing). Any Status line must contain at least one of these.
_APPROVED_LABELS = [
    "Implemented", "Pending validation", "Known issue", "Target design",
    "Planned", "Deferred", "Open decision", "Historical", "Superseded",
    "Split", "Reference", "Active",
]
_APPROVED_LABEL_RE = re.compile(
    "(" + "|".join(re.escape(lbl) for lbl in _APPROVED_LABELS) + ")"
)


def check_status_labels() -> None:
    """Every status-bearing line must contain an approved governance label (DOC-003)."""
    for path in _NUMBERED_CHAPTERS:
        with open(path, encoding="utf-8") as fh:
            for i, line in enumerate(fh, 1):
                if not _STATUS_LINE_RE.match(line):
                    continue
                if not _APPROVED_LABEL_RE.search(line):
                    _fail("status-label", path, i,
                          "status line has no approved label "
                          f"(expected one of: {', '.join(_APPROVED_LABELS)})")


# ── check 9: .uid sidecar tracking ───────────────────────────────────────────

def check_uid_tracking() -> None:
    """Every Godot .uid sidecar on disk must be tracked in git.

    Godot 4 writes a `<script>.gd.uid` next to each script; if it is left untracked
    the `uid://` reference fails to resolve on a fresh clone or in CI. Policy is
    track-all-.uid (95/97 at audit time, no `*.uid` in .gitignore), so any untracked
    .uid is accidental drift. Audit 2026-06-14 CR-1.
    """
    result = subprocess.run(
        ["git", "-C", str(ROOT), "ls-files", "--others", "--exclude-standard", "*.uid"],
        capture_output=True, text=True,
    )
    for rel in result.stdout.splitlines():
        rel = rel.strip()
        if rel:
            _fail("uid-untracked", ROOT / rel, 1,
                  "Godot .uid sidecar is untracked — `git add` it (breaks uid:// "
                  "resolution on a fresh clone/CI)")


# ── check 10: release version has a git tag ──────────────────────────────────

def check_version_tag() -> None:
    """The current product_version in project.godot must have a matching git tag.

    Without a tag, a shipped build cannot be checked out / reproduced from source.
    Convention: tag `v<product_version>` (e.g. product_version 0.1.5.0 -> tag
    v0.1.5.0). Audit 2026-06-14 rollup #5.
    """
    project_godot = ROOT / "project.godot"
    try:
        content = project_godot.read_text(encoding="utf-8")
    except OSError:
        return
    m = re.search(r'application/product_version="([^"]+)"', content)
    if not m or not m.group(1):
        return  # no version declared — nothing to enforce
    version = m.group(1)
    tag = f"v{version}"
    result = subprocess.run(
        ["git", "-C", str(ROOT), "tag", "-l", tag],
        capture_output=True, text=True,
    )
    if not result.stdout.strip():
        _fail("version-untagged", project_godot, 1,
              f"product_version is {version!r} but git tag {tag!r} does not exist "
              f"— tag the release so the build is reproducible from source")


# ── main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    print("check_docs: documentation structural checks (DOC-011)\n")

    steps = [
        ("[1] Banned paths",              check_banned_paths),
        ("[2] Repo-relative paths",       check_repo_paths),
        ("[3] Required headers",          check_required_headers),
        ("[4] Feature index targets",     check_feature_index_targets),
        ("[5] Duplicate roadmap headings",check_duplicate_roadmap_headings),
        ("[6] Stale Last verified",       check_stale_last_verified),
        ("[7] Prohibited status words",   check_prohibited_status_words),
        ("[8] Approved status labels",    check_status_labels),
        ("[9] .uid sidecar tracking",     check_uid_tracking),
        ("[10] Release version tagged",    check_version_tag),
    ]
    for label, fn in steps:
        print(f"  {label}...")
        fn()

    print()
    if _failures:
        print(f"FAIL: {len(_failures)} issue(s) found:")
        for msg in _failures:
            print(f"  {msg}")
        sys.exit(1)
    else:
        print("PASS: all documentation checks green")
        sys.exit(0)


if __name__ == "__main__":
    main()
