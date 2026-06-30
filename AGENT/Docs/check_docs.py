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
 11. Tree cover   — every top-level dir is named in the review procedure §2 map
 12. Rollup score — each full_review_rollup_* carries an anchored overall score
 13. Class moves  — every class .tres declares ≥1 VALID_MOVEMENT_TYPES tag (V021-11)
 14. Mouse modes  — SettingsManager/GDD agree on mouse_cursor values (V021-17)
 15. Render cfg   — project.godot pins gl_compatibility + stretch aspect keep (V021-18/19)
 16. Resolutions  — RESOLUTION_CHOICES offers native 1440p + 4K (V021-19)
 17. Duration vox — GDD_07 documents every VALID_DURATION_TYPES value (V021-09)
 18. Gen manifest — INDEX.md/REGISTERS.md match gen_docs_index.build() (DSR-3)
 19. Archive marks — archive/ docs carry a marker; Superseded targets resolve (DSR-4)
 20. Control plane — tracker rows use the ratified schema, prefixes, and valid Track IDs
 21. Autoload order — project.godot satisfies the Band 1/2 cross-plan autoload contracts
"""

import re
import subprocess
import sys
from pathlib import Path

# check 18 imports the sibling gen_docs_index module; without this the hook/CI runs
# (which don't set PYTHONDONTWRITEBYTECODE) would drop an AGENT/Docs/__pycache__ on every
# invocation. No-artifacts policy: never write bytecode from this tool.
sys.dont_write_bytecode = True

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
                if re.search(r">\s*\*\*(Historical|ARCHIVED|Archived|Superseded)\*\*", line):
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
    ROOT / "AGENT/Docs/guides/testing_guide.md",
    ROOT / "AGENT/Docs/guides/map_authoring_guide.md",
    ROOT / "AGENT/Docs/guides/environment_setup.md",
    ROOT / "AGENT/Docs/guides/campaign_rules.md",
    ROOT / "AGENT/Docs/guides/manual_test_playbook.md",
    ROOT / "AGENT/Docs/guides/Docker Instructions.md",
    ROOT / "AGENT/Docs/guides/new_machine_transfer_checklist.md",
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


# ── check 20: project control-plane schema ─────────────────────────────────

_CONTROL_PLANE = ROOT / "AGENT/Docs/plans/project_control_plane_2026-06-29.md"
_CONTROL_PLANE_COLUMNS = [
    "Track ID", "Band", "Status", "Work item", "Scope", "Blocks / depends on",
    "GDD owner", "Decision source", "Build source", "Save / registry impact",
    "Test / validation", "Next action",
]
_CONTROL_PLANE_STATUSES = {
    "Planned", "Target design", "Pending validation", "Deferred",
    "Open decision", "Known issue", "Historical", "Superseded", "Implemented",
}
_CONTROL_PLANE_BANDS = {str(i) for i in range(9)} | {
    "Validation", "Release gate", "Cleanup", "Content", "Polish", "UI",
}
_CONTROL_PLANE_TRACK_ID_PREFIXES = (
    "B0-", "B1-", "B2-", "B3-", "B4-", "B5-", "B6-", "B7-", "B8-",
    "VAL-", "REL-", "CLEAN-", "CONTENT-", "POLISH-", "UI-",
)
_TRACK_ID_RE = re.compile(r"`([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)+)`")
_TRACK_ID_CELL_RE = re.compile(r"^`([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)+)`$")
_MARKDOWN_LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")


def _split_markdown_table_row(line: str) -> list[str]:
    """Split a simple markdown table row while allowing escaped pipe characters."""
    stripped = line.strip()
    if not stripped.startswith("|"):
        return []
    if stripped.endswith("|"):
        stripped = stripped[:-1]
    stripped = stripped[1:]

    cells: list[str] = []
    current: list[str] = []
    escaped = False
    for char in stripped:
        if char == "|" and not escaped:
            cells.append("".join(current).strip())
            current = []
            escaped = False
            continue
        current.append(char)
        escaped = char == "\\" and not escaped
    cells.append("".join(current).strip())
    return cells


def _iter_local_markdown_links(line: str) -> list[str]:
    links: list[str] = []
    for match in _MARKDOWN_LINK_RE.finditer(line):
        target = match.group(1).split("#", 1)[0].strip()
        if not target or "://" in target or target.startswith("mailto:"):
            continue
        links.append(target)
    return links


def _iter_track_id_refs(path: Path) -> list[tuple[int, str]]:
    refs: list[tuple[int, str]] = []
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return refs
    for line_no, line in enumerate(lines, 1):
        for match in _TRACK_ID_RE.finditer(line):
            refs.append((line_no, match.group(1)))
    return refs


def check_control_plane_schema() -> None:
    """Validate the ratified project tracker row schema and Track ID references."""
    if not _CONTROL_PLANE.exists():
        _fail("control-plane", _CONTROL_PLANE, 1, "project control plane not found")
        return

    lines = _CONTROL_PLANE.read_text(encoding="utf-8").splitlines()
    in_tracker_table = False
    table_count = 0
    row_count = 0
    track_ids: dict[str, int] = {}
    local_refs: list[tuple[int, str]] = []

    for line_no, line in enumerate(lines, 1):
        for target in _iter_local_markdown_links(line):
            if not (_CONTROL_PLANE.parent / target).resolve().exists():
                _fail("control-plane", _CONTROL_PLANE, line_no,
                      f"local markdown link does not resolve: {target!r}")

        if line.startswith("| Track ID | Band | Status |"):
            table_count += 1
            in_tracker_table = True
            columns = _split_markdown_table_row(line)
            if columns != _CONTROL_PLANE_COLUMNS:
                _fail("control-plane", _CONTROL_PLANE, line_no,
                      "tracker table header does not match the ratified schema")
            continue

        if not in_tracker_table:
            continue
        if line.startswith("|---"):
            continue
        if not line.startswith("|"):
            in_tracker_table = False
            continue

        cells = _split_markdown_table_row(line)
        if len(cells) != len(_CONTROL_PLANE_COLUMNS):
            _fail("control-plane", _CONTROL_PLANE, line_no,
                  f"tracker row has {len(cells)} columns; expected "
                  f"{len(_CONTROL_PLANE_COLUMNS)}")
            continue

        row_count += 1
        for column, cell in zip(_CONTROL_PLANE_COLUMNS, cells):
            if not cell:
                _fail("control-plane", _CONTROL_PLANE, line_no,
                      f"empty required field: {column}")

        match = _TRACK_ID_CELL_RE.match(cells[0])
        if not match:
            _fail("control-plane", _CONTROL_PLANE, line_no,
                  "Track ID cell must be one backticked uppercase hyphenated id")
        else:
            track_id = match.group(1)
            if track_id in track_ids:
                _fail("control-plane", _CONTROL_PLANE, line_no,
                      f"duplicate Track ID {track_id!r} "
                      f"(first at line {track_ids[track_id]})")
            else:
                track_ids[track_id] = line_no
            if not track_id.startswith(_CONTROL_PLANE_TRACK_ID_PREFIXES):
                _fail("control-plane", _CONTROL_PLANE, line_no,
                      f"Track ID {track_id!r} does not use an allowed prefix")

        if cells[1] not in _CONTROL_PLANE_BANDS:
            _fail("control-plane", _CONTROL_PLANE, line_no,
                  f"invalid Band {cells[1]!r}")
        if cells[2] not in _CONTROL_PLANE_STATUSES:
            _fail("control-plane", _CONTROL_PLANE, line_no,
                  f"invalid Status {cells[2]!r}")

        for match in _TRACK_ID_RE.finditer(line):
            local_refs.append((line_no, match.group(1)))

    if table_count == 0:
        _fail("control-plane", _CONTROL_PLANE, 1, "no tracker tables found")
    if row_count == 0:
        _fail("control-plane", _CONTROL_PLANE, 1, "no tracker rows found")

    for line_no, track_id in local_refs:
        if track_id not in track_ids:
            _fail("control-plane", _CONTROL_PLANE, line_no,
                  f"unknown Track ID reference {track_id!r}")

    for ref_doc in (
        ROOT / "AGENT/GDD/GDD_10_Roadmap.md",
        ROOT / "AGENT/GDD/GDD_Feature_Index.md",
    ):
        for line_no, track_id in _iter_track_id_refs(ref_doc):
            if track_id not in track_ids:
                _fail("control-plane", ref_doc, line_no,
                      f"unknown Track ID reference {track_id!r}")


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


# ── check 11: review-procedure tree completeness ─────────────────────────────

_MASTER_REVIEW_DOC = ROOT / "AGENT/Review Procedures/00_Master_Review_Procedure.md"


def check_tree_completeness() -> None:
    """Every top-level dir must be named in the master review procedure's §2 map.

    Guards the audit's "nothing is unowned" guarantee: a new top-level directory
    added without assigning it to a pillar is a coverage hole. Audit 2026-06-14 MR-1.
    """
    if not _MASTER_REVIEW_DOC.exists():
        return
    content = _MASTER_REVIEW_DOC.read_text(encoding="utf-8")
    for d in sorted(ROOT.iterdir()):
        if not d.is_dir() or d.name.startswith("."):
            continue
        if f"{d.name}/" not in content:
            _fail("tree-coverage", _MASTER_REVIEW_DOC, 1,
                  f"top-level dir {d.name!r} is not named in the §2 coverage map "
                  f"(assign it to a review pillar or remove it)")


# ── check 12: rollup carries an anchored overall-health score ────────────────

_OVERALL_SCORE_RE = re.compile(r"Overall health.{0,30}?\b\d{1,2}\s*/\s*10")


def check_rollup_score_header() -> None:
    """Each full-audit rollup must carry a parseable overall-health score line.

    A naive `N/10` grep mis-hit a `150 / 10` code snippet during the 2026-06-14
    audit; an anchored `Overall health … N/10` line makes trend extraction reliable.
    Audit 2026-06-14 MR-6.
    """
    for rollup in sorted((ROOT / "AGENT/Code Reviews").glob("full_review_rollup_*.md")):
        content = rollup.read_text(encoding="utf-8")
        if not _OVERALL_SCORE_RE.search(content):
            _fail("rollup-score", rollup, 1,
                  "no anchored overall-health score (expected a line like "
                  "'**Overall health:** N/10')")


# ── main ─────────────────────────────────────────────────────────────────────

# V021-11: every class resource must declare at least one movement type in its
# special_qualities (the resolver defaults to infantry, but the tag must be authored
# so movement cost is explicit, not inferred from absence). Mirrors
# GameConstants.VALID_MOVEMENT_TYPES — keep the two in sync.
_VALID_MOVEMENT_TYPES = {"flying", "mounted", "armoured", "light_footed", "infantry"}


def check_class_movement_types() -> None:
    classes_dir = ROOT / "data/classes"
    if not classes_dir.is_dir():
        return
    sq_re = re.compile(r"special_qualities\s*=\s*\[([^\]]*)\]")
    for tres in sorted(classes_dir.glob("*.tres")):
        try:
            text = tres.read_text(encoding="utf-8")
        except OSError:
            continue
        m = sq_re.search(text)
        tags = set()
        if m:
            tags = {t.strip().strip('"') for t in m.group(1).split(",") if t.strip()}
        if not (tags & _VALID_MOVEMENT_TYPES):
            line_no = text[: m.start()].count("\n") + 1 if m else 1
            _fail("class-movement-type", tres, line_no,
                  f"class declares no movement type; add one of {sorted(_VALID_MOVEMENT_TYPES)}")


def _parse_gd_string_array(path: Path, const_name: str) -> list[str] | None:
    try:
        content = path.read_text(encoding="utf-8")
    except OSError:
        return None
    pattern = re.compile(
        rf"const\s+{re.escape(const_name)}\s*:\s*Array\[String\]\s*=\s*\[(.*?)\]",
        re.S,
    )
    match = pattern.search(content)
    if not match:
        return None
    return re.findall(r'"([^"]+)"', match.group(1))


def check_render_display_config() -> None:
    """project.godot must pin the web-load-bearing renderer + stretch keys (V021-18/19).

    The debug Web build and the v0.2.3 scaling rework both stand on two mechanical
    settings: the Compatibility renderer (Web has no Forward+/Mobile) and an explicit
    `keep` stretch aspect (so a contributor can't silently switch to `expand` and break
    both desktop letterboxing and the 16:9 web canvas). Guard them so neither reverts.
    """
    project_godot = ROOT / "project.godot"
    try:
        content = project_godot.read_text(encoding="utf-8")
    except OSError:
        _fail("render-config", project_godot, 1, "project.godot not found")
        return
    required = {
        'renderer/rendering_method="gl_compatibility"':
            "renderer must be Compatibility for the Web export (D1)",
        'window/stretch/aspect="keep"':
            "stretch aspect must be explicit `keep` to hold the 16:9 contract (E5)",
    }
    for needle, why in required.items():
        if needle not in content:
            _fail("render-config", project_godot, 1,
                  f"project.godot missing `{needle}` — {why}")


def check_resolution_choices() -> None:
    """V021-19: SettingsManager.RESOLUTION_CHOICES must offer native 1440p + 4K."""
    settings = ROOT / "scripts/autoloads/SettingsManager.gd"
    choices = _parse_gd_string_array(settings, "RESOLUTION_CHOICES")
    if choices is None:
        _fail("resolution-choices", settings, 1,
              "could not parse RESOLUTION_CHOICES")
        return
    for needed in ("2560x1440", "3840x2160"):
        if needed not in choices:
            _fail("resolution-choices", settings, 1,
                  f"RESOLUTION_CHOICES must include native {needed!r} (V021-19)")


def check_mouse_cursor_modes() -> None:
    """V021-17 fixes mouse_cursor to follow|click|disabled and GDD_07 must name them."""
    expected = ["follow", "click", "disabled"]
    settings = ROOT / "scripts/autoloads/SettingsManager.gd"
    modes = _parse_gd_string_array(settings, "VALID_MOUSE_CURSOR_MODES")
    if modes != expected:
        _fail("mouse-cursor-modes", settings, 1,
              f"VALID_MOUSE_CURSOR_MODES must be {expected}, got {modes}")

    gdd = ROOT / "AGENT/GDD/GDD_07_UI_UX.md"
    try:
        content = gdd.read_text(encoding="utf-8")
    except OSError:
        return
    for mode in expected:
        if f"`{mode}`" not in content:
            _fail("mouse-cursor-modes", gdd, 1,
                  f"GDD_07 must document mouse_cursor mode `{mode}`")


def check_duration_type_vocabulary() -> None:
    """V021-09: GDD_07 must document every GameConstants.VALID_DURATION_TYPES value.

    The vocabulary is enforced code-side by a test invariant (test_stat_breakdown asserts
    each value renders a non-empty label), but nothing kept the GDD_07 §Character Sheet
    list in sync with the const — a new duration type could land in code yet go undocumented.
    This guard closes that gap (the doc-sync half of the V021-09 check-back). Mirrors the
    mouse_cursor value-set check [14].
    """
    settings = ROOT / "scripts/shared/GameConstants.gd"
    values = _parse_gd_string_array(settings, "VALID_DURATION_TYPES")
    if values is None:
        _fail("duration-vocab", settings, 1,
              "could not parse VALID_DURATION_TYPES")
        return

    gdd = ROOT / "AGENT/GDD/GDD_07_UI_UX.md"
    try:
        content = gdd.read_text(encoding="utf-8")
    except OSError:
        _fail("duration-vocab", gdd, 1, "GDD_07_UI_UX.md not found")
        return
    for value in values:
        if f"`{value}`" not in content:
            _fail("duration-vocab", gdd, 1,
                  f"GDD_07 must document duration type `{value}` "
                  "(VALID_DURATION_TYPES — keep the list in sync)")


# ── check 18: generated manifests are up to date ─────────────────────────────

def check_generated_manifests() -> None:
    """INDEX.md / REGISTERS.md must match `gen_docs_index.build()` (DSR-3).

    The catalog is generated, not hand-maintained (roadmap §H rotted as prose). This
    guard fails if a doc header changed without regenerating — run
    `python3 AGENT/Docs/gen_docs_index.py`. Same self-consistency pattern as check 11.
    """
    docs_dir = ROOT / "AGENT/Docs"
    sys.path.insert(0, str(docs_dir))
    try:
        import gen_docs_index  # noqa: E402  (lives beside this script)
    except Exception as exc:  # pragma: no cover - import guard
        _fail("gen-manifest", docs_dir / "gen_docs_index.py", 1,
              f"could not import gen_docs_index: {exc}")
        return
    for name, content in gen_docs_index.build().items():
        target = docs_dir / name
        on_disk = target.read_text(encoding="utf-8") if target.exists() else None
        if on_disk != content:
            _fail("gen-manifest", target, 1,
                  "out of date — run `python3 AGENT/Docs/gen_docs_index.py` and commit")


# ── check 19: archive markers + supersession targets ─────────────────────────

_SUPERSEDED_BY_RE = re.compile(r"Superseded\*\*\s*by\s*\[[^\]]*\]\(([^)]+)\)")


def check_archive_markers() -> None:
    """Archived docs must declare it; a `Superseded by [..](path)` target must exist (DSR-4).

    Makes "which decision is live" unambiguous from inside any dead doc: every file under
    AGENT/Docs/archive/ carries a Historical/ARCHIVED/Superseded marker in its first 10
    lines, and any supersession link resolves to a real file.
    """
    docs_dir = ROOT / "AGENT/Docs"
    archive_dir = docs_dir / "archive"
    if archive_dir.is_dir():
        for path in sorted(archive_dir.rglob("*.md")):
            if not _is_historical(path):
                _fail("archive-marker", path, 1,
                      "file under archive/ lacks a Historical/ARCHIVED/Superseded marker "
                      "in its first 10 lines")
    # Supersession targets must resolve (scan all Docs markdown).
    for path in sorted(docs_dir.rglob("*.md")):
        try:
            head = "\n".join(path.read_text(encoding="utf-8").splitlines()[:10])
        except OSError:
            continue
        for m in _SUPERSEDED_BY_RE.finditer(head):
            target = (path.parent / m.group(1)).resolve()
            if not target.exists():
                _fail("archive-marker", path, 1,
                      f"'Superseded by' target does not exist: {m.group(1)!r}")


# ── check 21: cross-plan autoload ordering ───────────────────────────────────

# Ordering contracts the Band 1/2 implementation plans depend on but that live
# only in plan prose today. Each pair is (earlier, later): if BOTH autoloads are
# registered, `earlier` must load before `later`. Pairs naming an autoload that
# does not exist yet (RngService, RegistryManager) are skipped, so this guard is
# inert until that autoload lands — then it locks the order the moment it does.
# Sources: band1_determinism_save_implementation_plan_2026-06-30 (RngService
# after EventBus, before SettingsManager/GameState) and
# band2_shared_runtime_contracts_implementation_plan_2026-06-30 (RegistryManager
# before DataManager).
_AUTOLOAD_ORDER_CONSTRAINTS = [
    ("EventBus", "RngService",
     "RngService must mix on EventBus-era state (Band 1 plan)"),
    ("RngService", "GameState",
     "GameState/gameplay services draw deterministic RNG (Band 1 plan)"),
    ("RngService", "SettingsManager",
     "RngService loads ahead of the settings/state block (Band 1 plan)"),
    ("RegistryManager", "DataManager",
     "DataManager validation asks RegistryManager for known ids (Band 2 plan)"),
]


def _parse_autoload_order(path: Path) -> list[str] | None:
    """Return the autoload names in project.godot order, or None if unparseable."""
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return None
    names: list[str] = []
    in_section = False
    for line in lines:
        stripped = line.strip()
        if stripped == "[autoload]":
            in_section = True
            continue
        if in_section:
            # A new `[section]` header ends the autoload block.
            if stripped.startswith("[") and stripped.endswith("]"):
                break
            m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=", stripped)
            if m:
                names.append(m.group(1))
    return names


def check_autoload_order() -> None:
    """project.godot autoload order must satisfy the Band 1/2 plan contracts.

    The RngService and RegistryManager dependencies are real cross-plan couplings
    that otherwise only exist in plan prose — if Band 1 lands and someone places a
    new autoload wrong, Band 2 boot breaks. This guard makes the contract durable
    (DoD#2) while staying inert for autoloads that have not been added yet.
    """
    project_godot = ROOT / "project.godot"
    order = _parse_autoload_order(project_godot)
    if order is None:
        _fail("autoload-order", project_godot, 22, "could not parse [autoload] section")
        return
    index = {name: i for i, name in enumerate(order)}
    for earlier, later, why in _AUTOLOAD_ORDER_CONSTRAINTS:
        if earlier in index and later in index and index[earlier] > index[later]:
            _fail("autoload-order", project_godot, 22,
                  f"`{earlier}` must load before `{later}` — {why}")


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
        ("[11] Review tree completeness",  check_tree_completeness),
        ("[12] Rollup score header",       check_rollup_score_header),
        ("[13] Class movement types",      check_class_movement_types),
        ("[14] Mouse cursor modes",        check_mouse_cursor_modes),
        ("[15] Render/display config",     check_render_display_config),
        ("[16] Resolution choices",        check_resolution_choices),
        ("[17] Duration-type vocabulary",  check_duration_type_vocabulary),
        ("[18] Generated manifests",       check_generated_manifests),
        ("[19] Archive markers",           check_archive_markers),
        ("[20] Project control plane",     check_control_plane_schema),
        ("[21] Autoload order",            check_autoload_order),
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
