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
 22. Danger vox   — GDD_07 documents every MapCursor.VALID_DANGER_MODES value ([TUR])
 23. F1 manifest  — save-schema manifest rows keep the locked B1-F1 shape
 24. Gamepad binds — B6-INPUT gameplay actions stay pad-bound; debug actions do not
 25. Input modes  — SettingsManager/GDD agree on input_mode values
 26. Touch controls — SettingsManager/GDD agree on touch_controls values
 27. Stat guard   — no NEW hardcoded growth-stat list / stat-label map outside StatRegistry (B3-STAT-REGISTRY DoD#2)
 28. Gold writes  — gameplay party-gold mutation stays behind ResourceLedger
 29. Spawn guard  — normal GameMap spawn flow stays behind OccupancyService
 30. Doc ownership — active plan/design sources have a tracker/index owner or manifest exception
 31. Retired vocab — active docs do not reuse vocabulary retired by the Band 0 manifest
 32. Raw assets    — campaign media loading stays behind AssetResolver and pack media uses approved formats
 33. Save policy   — durable mid-map policies require infinite rewind and carry the builder warning
 36. Decision index — rows use independent decision-state and delivery vocabularies
 37. GDD section shape — split companions pair status/date; DOC-002 sections keep their shape
 38. Feature ownership — Feature Index identities and ownership/status rows are unique
 39. Open registries — authored objective/item ids cannot regress to closed dispatch
 40. Process evidence — closeout, audit, claim, export, and matrix enforcement exists
 42. Free-text fields — TEXT-06 permits only explicitly allow-listed naming fields
 43. Session-note names — new notes use an exact UTC second and descriptive slug
"""

import json
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
    """Feature-index code targets and exact GDD-owner anchors must resolve."""
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

    heading_cache: dict[Path, set[str]] = {}
    with open(feature_index, encoding="utf-8") as fh:
        for i, line in enumerate(fh, 1):
            if not line.startswith("|"):
                continue
            cells = _split_markdown_table_row(line)
            if len(cells) != 6 or cells[0] in {"Feature", "---"}:
                continue
            owner_links = list(_MARKDOWN_LINK_RE.finditer(cells[2]))
            if not owner_links:
                _fail("feature-index-anchor", feature_index, i,
                      "GDD owner cell must contain an exact Markdown section link")
                continue
            for match in owner_links:
                target = match.group(1)
                if "#" not in target:
                    _fail("feature-index-anchor", feature_index, i,
                          f"GDD owner link lacks a section fragment: {target!r}")
                    continue
                file_part, fragment = target.split("#", 1)
                owner_path = (feature_index.parent / file_part).resolve()
                if not owner_path.exists():
                    _fail("feature-index-anchor", feature_index, i,
                          f"GDD owner file does not resolve: {file_part!r}")
                    continue
                if owner_path not in heading_cache:
                    headings: set[str] = set()
                    for owner_line in owner_path.read_text(encoding="utf-8").splitlines():
                        heading = re.match(r"^#{1,6}\s+(.+?)\s*$", owner_line)
                        if heading:
                            text = heading.group(1).replace("`", "").lower()
                            text = re.sub(r"[^\w\- ]", "", text)
                            headings.add(re.sub(r"\s+", "-", text).strip("-"))
                    heading_cache[owner_path] = headings
                if fragment not in heading_cache[owner_path]:
                    _fail("feature-index-anchor", feature_index, i,
                          f"GDD owner fragment does not resolve: {target!r}")


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

_F1_MANIFEST = ROOT / "AGENT/Docs/plans/f1_save_schema_manifest_2026-07-06.md"
_F1_MANIFEST_COLUMNS = [
    "Field path", "Owner", "Scope", "Lifecycle", "Default / migration",
    "Serializer owner", "Retry behavior", "Suspend behavior", "Fixtures",
    "Row status", "Source",
]
_F1_MANIFEST_SCOPES = {
    "campaign", "campaign_rules", "roster_unit", "party_inventory",
    "map_runtime", "object_runtime", "unit_runtime", "transient_suspend",
    "settings", "authoring_data", "derived",
}
_F1_MANIFEST_ROW_STATUSES = {
    "v1", "dormant_reserve", "post_v1_deferred", "explicit_no_save",
}
_F1_MANIFEST_FIXTURES = {
    "codec_roundtrip", "old_save_default", "migration_default",
    "campaign_carry", "map_reset", "retry_restore", "suspend_restore",
    "reference_validation", "no_save_guard",
}


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


def _strip_md_code(value: str) -> str:
    stripped = value.strip()
    if stripped.startswith("`") and stripped.endswith("`"):
        return stripped[1:-1].strip()
    return stripped


def _extract_md_code_values(value: str) -> list[str]:
    found = re.findall(r"`([^`]+)`", value)
    if found:
        return [v.strip() for v in found if v.strip()]
    stripped = value.strip()
    return [stripped] if stripped else []


def check_f1_manifest_shape() -> None:
    """Validate the B1-F1 save-schema manifest row shape.

    This is intentionally a shape check, not serializer coverage. It keeps the
    locked Markdown manifest reviewable until `B1-SAVECODEC` gives the checks a
    real codec surface to compare against.
    """
    if not _F1_MANIFEST.exists():
        _fail("f1-manifest", _F1_MANIFEST, 1, "F1 save-schema manifest not found")
        return

    lines = _F1_MANIFEST.read_text(encoding="utf-8").splitlines()
    in_manifest_table = False
    table_count = 0
    row_count = 0

    for line_no, line in enumerate(lines, 1):
        if line.startswith("| Field path | Owner | Scope |"):
            table_count += 1
            in_manifest_table = True
            columns = _split_markdown_table_row(line)
            if columns != _F1_MANIFEST_COLUMNS:
                _fail("f1-manifest", _F1_MANIFEST, line_no,
                      "manifest table header does not match the locked B1-F1 schema")
            continue

        if not in_manifest_table:
            continue
        if line.startswith("|---"):
            continue
        if not line.startswith("|"):
            in_manifest_table = False
            continue

        cells = _split_markdown_table_row(line)
        if len(cells) != len(_F1_MANIFEST_COLUMNS):
            _fail("f1-manifest", _F1_MANIFEST, line_no,
                  f"manifest row has {len(cells)} columns; expected "
                  f"{len(_F1_MANIFEST_COLUMNS)}")
            continue

        row_count += 1
        for column, cell in zip(_F1_MANIFEST_COLUMNS, cells):
            if not cell:
                _fail("f1-manifest", _F1_MANIFEST, line_no,
                      f"empty required field: {column}")
            if re.search(r"\b(TBD|TODO|placeholder)\b", cell, re.IGNORECASE):
                _fail("f1-manifest", _F1_MANIFEST, line_no,
                      f"{column} still contains unfinished marker text")

        field_path = cells[0].strip()
        if not (field_path.startswith("`") and field_path.endswith("`")):
            _fail("f1-manifest", _F1_MANIFEST, line_no,
                  "Field path must be one backticked path or field-family id")

        for scope in _extract_md_code_values(cells[2]):
            if scope not in _F1_MANIFEST_SCOPES:
                _fail("f1-manifest", _F1_MANIFEST, line_no,
                      f"unknown F1 scope {scope!r}")

        for fixture in _extract_md_code_values(cells[8]):
            if fixture not in _F1_MANIFEST_FIXTURES:
                _fail("f1-manifest", _F1_MANIFEST, line_no,
                      f"unknown F1 fixture key {fixture!r}")

        row_status = _strip_md_code(cells[9])
        if row_status not in _F1_MANIFEST_ROW_STATUSES:
            _fail("f1-manifest", _F1_MANIFEST, line_no,
                  f"invalid Row status {row_status!r}")

    if table_count != 1:
        _fail("f1-manifest", _F1_MANIFEST, 1,
              f"expected exactly one manifest table, found {table_count}")
    if row_count == 0:
        _fail("f1-manifest", _F1_MANIFEST, 1, "manifest has no rows")


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

    gdd = ROOT / "AGENT/GDD/GDD_07_Input_Cursor.md"
    try:
        content = gdd.read_text(encoding="utf-8")
    except OSError:
        return
    for mode in expected:
        if f"`{mode}`" not in content:
            _fail("mouse-cursor-modes", gdd, 1,
                  f"GDD_07 must document mouse_cursor mode `{mode}`")


def check_input_modes() -> None:
    """B6-INPUT fixes input_mode to auto|gamepad|touch|mouse_keyboard."""
    expected = ["auto", "gamepad", "touch", "mouse_keyboard"]
    settings = ROOT / "scripts/autoloads/SettingsManager.gd"
    modes = _parse_gd_string_array(settings, "VALID_INPUT_MODES")
    if modes != expected:
        _fail("input-modes", settings, 1,
              f"VALID_INPUT_MODES must be {expected}, got {modes}")

    gdd = ROOT / "AGENT/GDD/GDD_07_Input_Cursor.md"
    try:
        content = gdd.read_text(encoding="utf-8")
    except OSError:
        return
    for mode in expected:
        if f"`{mode}`" not in content:
            _fail("input-modes", gdd, 1,
                  f"GDD_07 must document input_mode `{mode}`")


def check_touch_controls() -> None:
    """B6-INPUT fixes touch_controls to dedicated|virtual_gamepad."""
    expected = ["dedicated", "virtual_gamepad"]
    settings = ROOT / "scripts/autoloads/SettingsManager.gd"
    modes = _parse_gd_string_array(settings, "VALID_TOUCH_CONTROLS")
    if modes != expected:
        _fail("touch-controls", settings, 1,
              f"VALID_TOUCH_CONTROLS must be {expected}, got {modes}")

    gdd = ROOT / "AGENT/GDD/GDD_07_Input_Cursor.md"
    try:
        content = gdd.read_text(encoding="utf-8")
    except OSError:
        return
    for mode in expected:
        if f"`{mode}`" not in content:
            _fail("touch-controls", gdd, 1,
                  f"GDD_07 must document touch_controls `{mode}`")


def check_danger_mode_vocabulary() -> None:
    """[TUR] _danger_mode is a fixed value-set — GDD_07 must document every value.

    The threat overlay's danger mode (B6-MRD slice 2) is one of a small fixed set
    (none|full|selected|combined). Mirrors the mouse_cursor value-set check [14]:
    parse the literal source-of-truth const and assert GDD_07 names each value, so
    a new mode can't land in code yet go undocumented.
    """
    cursor = ROOT / "scripts/core/MapCursor.gd"
    values = _parse_gd_string_array(cursor, "VALID_DANGER_MODES")
    if values is None:
        _fail("danger-mode-vocab", cursor, 1, "could not parse VALID_DANGER_MODES")
        return
    expected = ["none", "full", "selected", "combined"]
    if sorted(values) != sorted(expected):
        _fail("danger-mode-vocab", cursor, 1,
              f"VALID_DANGER_MODES must be {expected}, got {values}")

    gdd = ROOT / "AGENT/GDD/GDD_07_Input_Cursor.md"
    try:
        content = gdd.read_text(encoding="utf-8")
    except OSError:
        _fail("danger-mode-vocab", gdd, 1, "GDD_07_UI_UX.md not found")
        return
    for value in values:
        if f"`{value}`" not in content:
            _fail("danger-mode-vocab", gdd, 1,
                  f"GDD_07 must document danger mode `{value}`")


def _project_input_action_block(project_godot: Path, action: str) -> str | None:
    try:
        content = project_godot.read_text(encoding="utf-8")
    except OSError:
        return None
    match = re.search(rf"^{re.escape(action)}=\{{(.*?)^\}}", content, re.S | re.M)
    return match.group(1) if match else None


def _block_has_joy_button(block: str, button_index: int) -> bool:
    pattern = rf"Object\(InputEventJoypadButton,[^\n]*\"button_index\":{button_index}\b"
    return re.search(pattern, block) is not None


def _block_has_joy_axis(block: str, axis: int, axis_value: float) -> bool:
    pattern = (
        rf"Object\(InputEventJoypadMotion,[^\n]*\"axis\":{axis}\b"
        rf"[^\n]*\"axis_value\":{axis_value:.1f}\b"
    )
    return re.search(pattern, block) is not None


def check_gamepad_bindings() -> None:
    """B6-INPUT slice 1: normal gameplay actions are pad-bound; debug actions are not."""
    project_godot = ROOT / "project.godot"
    button_cases = {
        "confirm": 0,
        "cancel": 1,
        "more_info": 2,
        "inspect_unit": 3,
        "peek_range": 4,
        "open_menu": 6,
        "zoom_reset": 7,
        "show_danger_zone": 8,
        "prev_unit": 9,
        "next_unit": 10,
        "cursor_up": 11,
        "cursor_down": 12,
        "cursor_left": 13,
        "cursor_right": 14,
    }
    for action, button_index in button_cases.items():
        block = _project_input_action_block(project_godot, action)
        if block is None:
            _fail("gamepad-bindings", project_godot, 1,
                  f"missing input action `{action}`")
            continue
        if not _block_has_joy_button(block, button_index):
            _fail("gamepad-bindings", project_godot, 1,
                  f"`{action}` must include joypad button {button_index}")

    axis_cases = [
        ("cursor_up", 1, -1.0),
        ("cursor_down", 1, 1.0),
        ("cursor_left", 0, -1.0),
        ("cursor_right", 0, 1.0),
        ("zoom_out", 4, 1.0),
        ("zoom_in", 5, 1.0),
    ]
    for action, axis, axis_value in axis_cases:
        block = _project_input_action_block(project_godot, action)
        if block is None:
            _fail("gamepad-bindings", project_godot, 1,
                  f"missing input action `{action}`")
            continue
        if not _block_has_joy_axis(block, axis, axis_value):
            _fail("gamepad-bindings", project_godot, 1,
                  f"`{action}` must include joypad axis {axis}/{axis_value:.1f}")

    for action in (
        "open_settings",
        "debug_toggle_force_levelup",
        "debug_toggle_growth_boost",
        "debug_toggle_hotseat_override",
    ):
        block = _project_input_action_block(project_godot, action)
        if block is not None and "InputEventJoypad" in block:
            _fail("gamepad-bindings", project_godot, 1,
                  f"`{action}` must stay without direct joypad bindings")

    gdd = ROOT / "AGENT/GDD/GDD_07_Input_Cursor.md"
    try:
        gdd_content = gdd.read_text(encoding="utf-8")
    except OSError:
        _fail("gamepad-bindings", gdd, 1, "GDD_07_UI_UX.md not found")
        return
    for label in (
        "Pad A", "Pad B", "Pad X", "Pad Y", "View", "Start", "L3", "R3",
        "LB", "RB", "D-pad Up", "D-pad Down", "D-pad Left", "D-pad Right",
        "Left Stick Up", "Left Stick Down", "Left Stick Left", "Left Stick Right",
        "LT", "RT",
    ):
        if label not in gdd_content:
            _fail("gamepad-bindings", gdd, 1,
                  f"GDD_07 must document gamepad binding label `{label}`")


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

    gdd = ROOT / "AGENT/GDD/GDD_07_Screens_Panels.md"
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


# ── check 30: active plan/design ownership (B0-DOC-ROLE-MANIFEST) ───────────

_ROLE_MANIFEST = ROOT / "AGENT/Docs/plans/doc_role_manifest_2026-06-29.md"
_FEATURE_INDEX = ROOT / "AGENT/GDD/GDD_Feature_Index.md"
_OWNERSHIP_MAP_HEADING = "## Active Source Ownership Map"


def _role_manifest_owner_paths() -> set[Path]:
    """Return plan/design source paths explicitly mapped by the role manifest."""
    try:
        lines = _ROLE_MANIFEST.read_text(encoding="utf-8").splitlines()
    except OSError:
        _fail("active-doc-ownership", _ROLE_MANIFEST, 1, "role manifest is missing")
        return set()

    mapped: set[Path] = set()
    in_map = False
    for line_no, line in enumerate(lines, 1):
        if line.strip() == _OWNERSHIP_MAP_HEADING:
            in_map = True
            continue
        if in_map and line.startswith("## "):
            break
        if not in_map:
            continue
        for target in _iter_local_markdown_links(line):
            path = (_ROLE_MANIFEST.parent / target).resolve()
            if path.suffix != ".md" or path.parent.name not in {"plans", "design"}:
                continue
            if not path.exists():
                _fail("active-doc-ownership", _ROLE_MANIFEST, line_no,
                      f"ownership-map source does not exist: {target!r}")
                continue
            if _is_historical(path):
                _fail("active-doc-ownership", _ROLE_MANIFEST, line_no,
                      f"ownership-map source is Historical/Superseded: {target!r}")
                continue
            mapped.add(path)

    if not in_map:
        _fail("active-doc-ownership", _ROLE_MANIFEST, 1,
              f"missing {_OWNERSHIP_MAP_HEADING!r} section")
    return mapped


def check_active_doc_ownership() -> None:
    """Active plan/design docs need a direct owner or explicit manifest mapping.

    A filename in the Project Control Plane or Feature Index is a direct owner
    link. Cross-cutting sources that would make those navigation tables noisy
    must instead be named in the role manifest's ownership map. Historical and
    Superseded docs are lifecycle evidence and are outside this active check.
    """
    direct_sources = ""
    for path in (_CONTROL_PLANE, _FEATURE_INDEX):
        try:
            direct_sources += path.read_text(encoding="utf-8")
        except OSError:
            _fail("active-doc-ownership", path, 1, "ownership source is missing")

    mapped = _role_manifest_owner_paths()
    source_dirs = (
        ROOT / "AGENT/Docs/plans",
        ROOT / "AGENT/Docs/design",
    )
    for source_dir in source_dirs:
        for path in sorted(source_dir.glob("*.md")):
            if path == _CONTROL_PLANE or _is_historical(path):
                continue
            if path.name in direct_sources or path.resolve() in mapped:
                continue
            _fail("active-doc-ownership", path, 1,
                  "active plan/design source has no Project Control Plane or "
                  "Feature Index link and no role-manifest ownership-map entry")


# ── check 31: retired active vocabulary (B0-VOCAB-NAMING) ──────────────────

_VOCABULARY_MANIFEST = ROOT / "AGENT/Docs/plans/project_vocabulary_manifest_2026-06-29.md"
_RETIRED_VOCAB_HEADING = "## Retired Or Limited Terms"
_RETIRED_VOCAB_EXEMPTION = "<!-- retired-vocabulary: historical-quotation -->"


def _retired_vocabulary_terms() -> list[str]:
    """Read the retired-term column from the vocabulary manifest."""
    try:
        lines = _VOCABULARY_MANIFEST.read_text(encoding="utf-8").splitlines()
    except OSError:
        _fail("retired-vocabulary", _VOCABULARY_MANIFEST, 1,
              "vocabulary manifest is missing")
        return []

    terms: list[str] = []
    in_table = False
    for line_no, line in enumerate(lines, 1):
        if line.strip() == _RETIRED_VOCAB_HEADING:
            in_table = True
            continue
        if in_table and line.startswith("## "):
            break
        if not in_table or not line.startswith("|") or line.startswith("|---"):
            continue
        cells = _split_markdown_table_row(line)
        if not cells or cells[0] == "Term":
            continue
        term = cells[0].strip().strip("`\"'")
        if not term:
            _fail("retired-vocabulary", _VOCABULARY_MANIFEST, line_no,
                  "retired-vocabulary row has an empty Term cell")
            continue
        terms.append(term)

    if not in_table:
        _fail("retired-vocabulary", _VOCABULARY_MANIFEST, 1,
              f"missing {_RETIRED_VOCAB_HEADING!r} section")
    if not terms:
        _fail("retired-vocabulary", _VOCABULARY_MANIFEST, 1,
              "retired-vocabulary table has no terms")
    return terms


def check_retired_vocabulary() -> None:
    """Reject retired terms in active GDD/Docs prose.

    Archives, session notes, and whole-file Historical/Superseded sources are
    lifecycle evidence rather than active prose. The vocabulary manifest must
    name the terms it bans, fenced command/examples are inert, and a preserved
    quotation must carry the explicit one-line exemption marker.
    """
    terms = _retired_vocabulary_terms()
    if not terms:
        return
    term_patterns = [
        (term, re.compile(re.escape(term), re.IGNORECASE)) for term in terms
    ]
    scan_paths = sorted((ROOT / "AGENT/GDD").glob("*.md"))
    scan_paths += sorted((ROOT / "AGENT/Docs").rglob("*.md"))

    archive_dir = (ROOT / "AGENT/Docs/archive").resolve()
    for path in scan_paths:
        resolved = path.resolve()
        if path == _VOCABULARY_MANIFEST or resolved.is_relative_to(archive_dir):
            continue
        if _is_historical(path):
            continue
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except OSError:
            continue

        in_fence = False
        for line_no, line in enumerate(lines, 1):
            if line.lstrip().startswith("```"):
                in_fence = not in_fence
                continue
            if in_fence or _RETIRED_VOCAB_EXEMPTION in line:
                continue
            for term, pattern in term_patterns:
                if pattern.search(line):
                    _fail("retired-vocabulary", path, line_no,
                          f"retired term {term!r}; use the manifest replacement or "
                          f"mark a genuine quotation with {_RETIRED_VOCAB_EXEMPTION}")


# ── check 21: cross-plan autoload ordering ───────────────────────────────────

# Ordering contracts the Band 1/2 implementation plans depend on but that live
# only in plan prose today. Each pair is (earlier, later): if BOTH autoloads are
# registered, `earlier` must load before `later`. Pairs naming an autoload that
# does not exist yet (RngService, RegistryManager) are skipped, so this guard is
# inert until that autoload lands — then it locks the order the moment it does.
# Sources: band1_determinism_save_implementation_plan_2026-06-30 (RngService
# after EventBus, before SettingsManager/GameState),
# input_controls_open_decisions_2026-06-21 (InputModeManager after SettingsManager),
# and band2_shared_runtime_contracts_implementation_plan_2026-06-30
# (RegistryManager before DataManager).
_AUTOLOAD_ORDER_CONSTRAINTS = [
    ("EventBus", "RngService",
     "RngService must mix on EventBus-era state (Band 1 plan)"),
    ("RngService", "GameState",
     "GameState/gameplay services draw deterministic RNG (Band 1 plan)"),
    ("RngService", "SettingsManager",
     "RngService loads ahead of the settings/state block (Band 1 plan)"),
    ("SettingsManager", "InputModeManager",
     "InputModeManager reads persisted controls settings (ICD-1)"),
    ("InputModeManager", "GameState",
     "Input-mode runtime state belongs in the settings/input block before gameplay state"),
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


# ── check 27: stat-vocabulary registry guard (B3-STAT-REGISTRY DoD#2) ──────────

# The narrow-v1 guard for the stat-vocabulary unification (session 2026-07-09e):
# StatRegistry.gd is now the ONE source of the growth-stat set and the short
# stat-label map. This guard stops that debt from silently regrowing — a fresh
# `["hp","strength",...]` growth list or `{"strength":"Str",...}` label map in some
# other file — WITHOUT false-positiving on the many legitimate individual stat-id
# reads (SaveCodec's field allow-list, CombatResolver reading strength/magic,
# WeaponData scaling codes, MoreInfoContent's long-form stat descriptions,
# PairUpBonusTable.scaling_stats' deliberately-different subset). It therefore
# triggers on two EXACT shapes only, not on stat-id count. Owner-scoped narrow v1
# (2026-07-09f): direct base-stat field reads (data.strength) are intentionally
# NOT guarded yet — legacy fields stay allowed until the F1 storage slice makes
# those reads wrong. Register: extensible_stat_model_open_questions_2026-06-25 §STM-3.
_STAT_GUARD_ARRAY_RE = re.compile(r"\[([^\[\]]*?)\]", re.S)
_STAT_GUARD_STR_RE = re.compile(r'"([^"]+)"')


def check_stat_registry_guard() -> None:
    registry = ROOT / "scripts/core/StatRegistry.gd"
    growth = _parse_gd_string_array(registry, "GROWTH_STAT_IDS")
    display = _parse_gd_string_array(registry, "DISPLAY_ONLY_STAT_IDS")
    if growth is None or display is None:
        _fail("stat-registry-guard", registry, 1,
              "could not parse GROWTH_STAT_IDS / DISPLAY_ONLY_STAT_IDS")
        return
    growth_set = set(growth)
    all_ids = growth_set | set(display)
    # A stat-id key mapped to a SHORT no-space abbreviation value (i.e. a label
    # like "Str"), distinct from MoreInfoContent's sentence-length descriptions.
    label_re = re.compile(
        r'"(' + "|".join(re.escape(s) for s in sorted(all_ids)) + r')"\s*:\s*"([^"\s]{1,5})"'
    )

    scripts_dir = ROOT / "scripts"
    for path in sorted(scripts_dir.rglob("*.gd")):
        if path.name == "StatRegistry.gd":
            continue
        if "tests" in path.relative_to(scripts_dir).parts:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue

        # Shape A — a re-introduced growth-stat LIST: an array literal whose exact
        # string-element set equals GROWTH_STAT_IDS. Equality (not superset) spares
        # SaveCodec's allow-list (extra fields) and PairUpBonusTable (7-id subset).
        for m in _STAT_GUARD_ARRAY_RE.finditer(text):
            if set(_STAT_GUARD_STR_RE.findall(m.group(1))) == growth_set:
                line_no = text[: m.start()].count("\n") + 1
                _fail("stat-registry-guard", path, line_no,
                      "hardcoded growth-stat list duplicates StatRegistry.GROWTH_STAT_IDS "
                      "— read the registry instead (B3-STAT-REGISTRY DoD#2)")

        # Shape B — a re-introduced stat-LABEL map: ≥3 `"stat_id": "<abbrev>"`
        # short-value entries. MoreInfoContent's sentence values are spared by the
        # ≤5-char no-space value bound.
        label_hits = label_re.findall(text)
        if len(label_hits) >= 3:
            first = label_re.search(text)
            line_no = text[: first.start()].count("\n") + 1 if first else 1
            _fail("stat-registry-guard", path, line_no,
                  "hardcoded stat-label map duplicates StatRegistry.STAT_LABELS "
                  "— use StatRegistry.label_for() instead (B3-STAT-REGISTRY DoD#2)")


# ── check 28: party-gold transaction guard (B2-RESOURCE-LEDGER DoD#2) ─────────

_PARTY_GOLD_WRITE_RE = re.compile(r"\bparty_gold\s*(?:\+=|-=|=)")
_PARTY_GOLD_WRITE_ALLOW = {
    Path("scripts/autoloads/GameState.gd"),
    Path("scripts/autoloads/ResourceLedger.gd"),
}


def check_party_gold_transaction_guard() -> None:
    """Gameplay consumers must mutate party gold through ResourceLedger."""
    scripts_dir = ROOT / "scripts"
    for path in sorted(scripts_dir.rglob("*.gd")):
        relative = path.relative_to(ROOT)
        if relative in _PARTY_GOLD_WRITE_ALLOW or "tests" in relative.parts:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        for match in _PARTY_GOLD_WRITE_RE.finditer(text):
            line_no = text[:match.start()].count("\n") + 1
            _fail("party-gold-transaction-guard", path, line_no,
                  "direct party_gold write bypasses ResourceLedger atomicity "
                  "(B2-RESOURCE-LEDGER DoD#2)")


# ── check 29: public spawn occupancy guard (B2-OCCUPANCY DoD#2) ──────────────

def check_spawn_occupancy_guard() -> None:
    """GameMap's normal spawn flow must resolve OccupancyService first."""
    path = ROOT / "scripts/core/GameMap.gd"
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        _fail("spawn-occupancy-guard", path, 1, "GameMap.gd is missing")
        return
    helper = re.search(
        r"func _place_and_spawn\b(?P<body>.*?)(?=\nfunc |\Z)", text, re.DOTALL)
    if helper is None or '"/root/OccupancyService"' not in helper.group("body") \
            or 'occupancy.call("place"' not in helper.group("body"):
        _fail("spawn-occupancy-guard", path, 1,
              "_place_and_spawn must resolve OccupancyService.place before instancing "
              "(B2-OCCUPANCY DoD#2)")
    spawn_flow = re.search(r"func _spawn_units\(\).*?(?=\nfunc |\Z)", text, re.DOTALL)
    if spawn_flow is None or "_spawn_unit(" in spawn_flow.group(0):
        _fail("spawn-occupancy-guard", path, 1,
              "_spawn_units bypasses _place_and_spawn occupancy policy "
              "(B2-OCCUPANCY DoD#2)")


# ── check 32: campaign raw-asset boundary (B6-CAMPAIGN-SHARING DoD#2) ────────

_RAW_ASSET_CALLS = (
    re.compile(r"\bImage\.load_from_file\s*\("),
    re.compile(r"\.load_dynamic_font\s*\("),
    re.compile(r"\bAudioStream(?:OggVorbis|WAV)\.load_from_file\s*\("),
)
_PACK_MEDIA_EXTENSIONS = {".png", ".jpg", ".jpeg", ".ttf", ".otf", ".ogg", ".wav"}


def check_campaign_asset_boundary() -> None:
    """Raw user media has one loader boundary and a narrow portable format set."""
    scripts_dir = ROOT / "scripts"
    resolver = scripts_dir / "assets/AssetResolver.gd"
    for path in sorted(scripts_dir.rglob("*.gd")):
        if path == resolver or "tests" in path.relative_to(scripts_dir).parts:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        for pattern in _RAW_ASSET_CALLS:
            for match in pattern.finditer(text):
                _fail("campaign-asset-boundary", path,
                      text[:match.start()].count("\n") + 1,
                      "raw campaign media must load through AssetResolver")

    # This tree is introduced by the package seed/build slice. Keeping the check
    # active before it exists makes the rule automatically cover its first file.
    pack_seed = ROOT / "data/campaign_packs"
    if pack_seed.exists():
        for path in sorted(pack_seed.rglob("*")):
            if not path.is_file() or "data" in path.relative_to(pack_seed).parts:
                continue
            if path.name in {"manifest.json"} or path.suffix.lower() == ".json":
                continue
            if path.suffix.lower() not in _PACK_MEDIA_EXTENSIONS:
                _fail("campaign-asset-boundary", path, 1,
                      "Tier-1 pack media must be PNG/JPG, TTF/OTF, OGG, or WAV")


# ── check 33: durable mid-map policy warning (B1-LEDGER Phase 5 DoD#2) ───────

def check_durable_mid_map_policy() -> None:
    """Authored durable battle reloads may not silently bypass finite Rewind."""
    guide = ROOT / "AGENT/Docs/guides/campaign_rules.md"
    required = "durable mid_map saves require infinite rewind"
    if required not in guide.read_text(encoding="utf-8"):
        _fail("save-policy-warning", guide, 1,
              f"campaign rules guide must carry the exact warning: {required!r}")

    for path in sorted((ROOT / "data/campaigns").glob("*.json")):
        try:
            document = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue  # the catalogue validator owns malformed JSON reporting
        if not isinstance(document, dict):
            continue
        rules = document.get("rules", {})
        if not isinstance(rules, dict):
            continue
        classes = rules.get("save_slot_classes", [])
        rewind = rules.get("rewind_charges_per_map", 4)
        if rewind == -1 or not isinstance(classes, list):
            continue
        for entry in classes:
            if not isinstance(entry, dict):
                continue
            durable_mid = (entry.get("accepts") in {"mid_map", "any"}
                           and not entry.get("consumed_on_load", False)
                           and entry.get("count", 0) > 0)
            if durable_mid:
                _fail("save-policy-warning", path, 1,
                      "durable mid_map slot class requires "
                      "rules.rewind_charges_per_map = -1")
                break


# ── check 34: mutable campaign rule contract (Q13 DoD#2) ────────────────────

def check_mutable_campaign_rule_contract() -> None:
    """Keep the fixed revert vocabulary and required F1 region synchronized."""
    runtime = ROOT / "AGENT/GDD/GDD_01_Runtime_Contracts.md"
    runtime_text = runtime.read_text(encoding="utf-8")
    if "`revert_scope` vocabulary `end_of_map|permanent`" not in runtime_text:
        _fail("mutable-rule-contract", runtime, 1,
              "document revert_scope exactly as end_of_map|permanent")

    game_state = ROOT / "scripts/autoloads/GameState.gd"
    code_text = game_state.read_text(encoding="utf-8")
    if 'revert_scope not in ["end_of_map", "permanent"]' not in code_text:
        _fail("mutable-rule-contract", game_state, 1,
              "runtime revert_scope vocabulary drifted from the GDD")

    manifest_text = _F1_MANIFEST.read_text(encoding="utf-8")
    for field in ("campaign.mutable_state.rule_patches[]",
                  "campaign.mutable_state.carry_forward_facts",
                  "campaign.mutable_state.imported_record_ref",
                  "campaign.per_map_overrides",
                  "campaign.active_mid_map_overrides"):
        if field not in manifest_text:
            _fail("mutable-rule-contract", _F1_MANIFEST, 1,
                  f"F1 manifest is missing required field {field}")


# ── check 35: CampaignStatusRecord envelope/open facts (Q8 DoD#2) ───────────

def check_campaign_status_record_contract() -> None:
    """Keep the portable envelope fixed while story facts remain data-shaped."""
    record_path = ROOT / "scripts/resources/CampaignStatusRecord.gd"
    text = record_path.read_text(encoding="utf-8")
    required = ("format_version", "record_id", "author_id", "campaign_id",
                "campaign_version", "created_at_utc", "completion", "facts",
                "counters", "checksum")
    for field in required:
        if f'"{field}"' not in text:
            _fail("campaign-status-contract", record_path, 1,
                  f"CampaignStatusRecord envelope is missing {field}")
    forbidden_named_facts = ("villages_saved", "units_recruited",
                             "story_flags", "losses")
    for field in forbidden_named_facts:
        if f"var {field}" in text or f"@export var {field}" in text:
            _fail("campaign-status-contract", record_path, 1,
                  f"status fact {field} must remain a facts-dictionary key")


# ── check 36: decision-index lifecycle vocabulary (DOC-009) ────────────────

_DECISION_INDEX = ROOT / "AGENT/Docs/decisions/decision_index.md"
_DECISION_HEADER = ["ID", "Title", "Decision state", "Delivery status", "Home", "Notes"]
_DECISION_STATES = {"Open", "Ratified", "Superseded", "Historical"}
_DELIVERY_STATUSES = {
    "Not scheduled", "Target design", "Planned", "In implementation",
    "Implemented", "Pending validation", "Deferred", "Not applicable",
}


def check_decision_index_vocabulary() -> None:
    """Decision rows keep owner acceptance separate from delivery progress."""
    if not _DECISION_INDEX.exists():
        _fail("decision-index", _DECISION_INDEX, 1, "decision index not found")
        return

    header_count = 0
    row_count = 0
    seen_ids: dict[str, int] = {}
    in_table = False
    for line_no, line in enumerate(_DECISION_INDEX.read_text(encoding="utf-8").splitlines(), 1):
        if line.startswith("| ID |"):
            header_count += 1
            in_table = True
            cells = _split_markdown_table_row(line)
            if cells != _DECISION_HEADER:
                _fail("decision-index", _DECISION_INDEX, line_no,
                      f"table header must be {_DECISION_HEADER!r}")
            continue
        if not in_table:
            continue
        if re.match(r"^\|\s*:?-+", line):
            continue
        if not line.startswith("|"):
            in_table = False
            continue

        cells = _split_markdown_table_row(line)
        if len(cells) != len(_DECISION_HEADER):
            _fail("decision-index", _DECISION_INDEX, line_no,
                  f"row has {len(cells)} columns; expected {len(_DECISION_HEADER)}")
            continue
        row_count += 1
        decision_id, _title, state, delivery, _home, _notes = cells
        if decision_id in seen_ids:
            _fail("decision-index", _DECISION_INDEX, line_no,
                  f"duplicate decision ID {decision_id!r}; first at line {seen_ids[decision_id]}")
        else:
            seen_ids[decision_id] = line_no
        if state not in _DECISION_STATES:
            _fail("decision-index", _DECISION_INDEX, line_no,
                  f"invalid Decision state {state!r}; expected one of {sorted(_DECISION_STATES)}")
        if delivery not in _DELIVERY_STATUSES:
            _fail("decision-index", _DECISION_INDEX, line_no,
                  f"invalid Delivery status {delivery!r}; expected one of {sorted(_DELIVERY_STATUSES)}")

    if header_count == 0:
        _fail("decision-index", _DECISION_INDEX, 1, "no decision tables found")
    if row_count == 0:
        _fail("decision-index", _DECISION_INDEX, 1, "decision index has no rows")


# ── checks 37-38: section-local GDD governance and feature ownership ─────────

_SPLIT_GDD_COMPANIONS = sorted(
    list((ROOT / "AGENT/GDD").glob("GDD_01_*.md"))
    + list((ROOT / "AGENT/GDD").glob("GDD_07_*.md"))
)
_DOC_002_CATALOG_PREFIXES = ("GDD_06_", "GDD_07_", "GDD_08_")
_DOC_002_STRICT_FILES = {
    "GDD_01_Data_Contracts.md",
    "GDD_01_Runtime_Contracts.md",
}


def _heading_scopes(lines: list[str]) -> list[tuple[int, int, int]]:
    """Return (heading line index, level, exclusive scope end) for Markdown headings."""
    headings: list[tuple[int, int]] = []
    in_fence = False
    for index, line in enumerate(lines):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        match = re.match(r"^(#{1,6})\s+", line)
        if match:
            headings.append((index, len(match.group(1))))
    scopes: list[tuple[int, int, int]] = []
    for position, (start, level) in enumerate(headings):
        end = len(lines)
        for candidate, candidate_level in headings[position + 1:]:
            if candidate_level <= level:
                end = candidate
                break
        scopes.append((start, level, end))
    return scopes


def check_gdd_section_governance() -> None:
    """Enforce section-local verification and DOC-002 on status-bearing features."""
    for path in _SPLIT_GDD_COMPANIONS:
        lines = path.read_text(encoding="utf-8").splitlines()
        scopes = _heading_scopes(lines)
        for line_index, line in enumerate(lines):
            if not _STATUS_LINE_RE.match(line):
                continue
            containing = [scope for scope in scopes if scope[0] <= line_index < scope[2]]
            scope = max(containing, key=lambda item: (item[1], item[0])) if containing else None
            end = scope[2] if scope else len(lines)
            if not any(re.match(r"^\s*(?:\*\*)?Last verified:", candidate)
                       for candidate in lines[line_index + 1:end]):
                _fail("section-verified", path, line_index + 1,
                      "status-bearing section lacks a local Last verified marker")

    for path in _NUMBERED_CHAPTERS:
        if path.name.startswith(_DOC_002_CATALOG_PREFIXES):
            # DOC-002a explicitly treats 06/07/08 as catalogues; their table or
            # repeated-entry bodies are not forced into per-feature Summary/Specs.
            continue
        # DOC-002 enforcement starts at the campaign/save companion contracts
        # closed by this follow-up. Other legacy chapters remain a migration
        # backlog rather than turning this checker change into a silent rewrite.
        if path.name not in _DOC_002_STRICT_FILES:
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        for start, level, end in _heading_scopes(lines):
            if level != 2:
                continue
            body = lines[start + 1:end]
            if not any(_STATUS_LINE_RE.match(line) for line in body):
                continue
            headings = {
                re.sub(r"\s*\(.*\)$", "", match.group(1)).strip().lower()
                for line in body
                if (match := re.match(r"^###\s+(.+?)\s*$", line))
            }
            for required in ("summary", "specs", "known gaps", "anchors"):
                if required not in headings:
                    _fail("doc-002-shape", path, start + 1,
                          f"status-bearing feature section is missing '### {required.title()}'")


def check_feature_index_ownership_duplicates() -> None:
    """Feature names and exact status/owner/track ownership rows must be unique."""
    path = ROOT / "AGENT/GDD/GDD_Feature_Index.md"
    seen_features: dict[str, int] = {}
    seen_ownership: dict[tuple[str, str, str], int] = {}
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.startswith("|"):
            continue
        cells = _split_markdown_table_row(line)
        if len(cells) != 6 or cells[0] in {"Feature", "---"}:
            continue
        feature_key = re.sub(r"[^a-z0-9]+", "-", cells[0].lower()).strip("-")
        if feature_key in seen_features:
            _fail("feature-ownership", path, line_no,
                  f"duplicate Feature identity {feature_key!r}; first at line {seen_features[feature_key]}")
        else:
            seen_features[feature_key] = line_no
        owner_targets = "|".join(sorted(match.group(1) for match in _MARKDOWN_LINK_RE.finditer(cells[2])))
        track_ids = "|".join(sorted(set(re.findall(r"`([A-Z][A-Z0-9-]+)`", cells[3]))))
        signature = (cells[1].strip().lower(), owner_targets, track_ids)
        if signature in seen_ownership:
            _fail("feature-ownership", path, line_no,
                  "duplicate status/GDD-owner/Track-ID ownership row; "
                  f"first at line {seen_ownership[signature]}")
        else:
            seen_ownership[signature] = line_no


# ── check 39: open objective/item registry architecture (B2-REGISTRY) ─────────

_OPEN_REGISTRY_COMPATIBILITY_IDS = {
    "objective_conditions": {
        "rout", "defeat_boss", "seize", "escape", "survive", "protect", "turn_limit",
    },
    "item_effects": {"heal_flat", "heal_full", "promote", "reclass", "stat_buff"},
}


def check_open_authored_registries() -> None:
    """Keep authored objective/item vocabularies data-backed and dispatch-switch free."""
    forbidden = {
        ROOT / "scripts/autoloads/DataManager.gd": (
            "_VALID_OBJECTIVE_TYPES", "IMPLEMENTED_EFFECT_IDS", "match cond.type",
        ),
        ROOT / "scripts/core/TurnManager.gd": ("match cond.type",),
        ROOT / "scripts/items/ItemHandler.gd": (
            "IMPLEMENTED_EFFECT_IDS", "match item.effect_id", "match effect_id",
        ),
    }
    for path, needles in forbidden.items():
        text = path.read_text(encoding="utf-8")
        for needle in needles:
            line_no = text[:text.find(needle)].count("\n") + 1 if needle in text else 1
            if needle in text:
                _fail("open-registries", path, line_no,
                      f"closed authored-id dispatch token is forbidden: {needle!r}")

    for family, expected_ids in _OPEN_REGISTRY_COMPATIBILITY_IDS.items():
        manifest_path = ROOT / "data/registries" / family / "resource_manifest.json"
        try:
            filenames = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            _fail("open-registries", manifest_path, 1, f"cannot read registry manifest: {exc}")
            continue
        actual_ids = {Path(filename).stem for filename in filenames if isinstance(filename, str)}
        if actual_ids != expected_ids:
            _fail("open-registries", manifest_path, 1,
                  f"compatibility ids are {sorted(actual_ids)}; expected {sorted(expected_ids)}")
        for filename in filenames:
            if isinstance(filename, str) and not (manifest_path.parent / filename).is_file():
                _fail("open-registries", manifest_path, 1,
                      f"manifest entry does not exist: {filename!r}")


def check_process_evidence_tooling() -> None:
    required = {
        "scripts/ci/audit_cadence.py": "audit-cadence:",
        "scripts/ci/check_session_commit_claims.py": "CLAIM_RE",
        "scripts/ci/check_evidence_matrices.py": "implemented_track_evidence.json",
        "scripts/session_closeout.sh": "audit_cadence.py",
        "scripts/hooks/pre-push": "audit_cadence.py",
        "scripts/tools/export_smoke.sh": "sha256=",
        "scripts/ci/check_gdscript_style.sh": "gdformat --check",
        "scripts/hooks/pre-commit": "check_gdscript_style.sh",
        ".github/workflows/tests-pr.yml": "check_gdscript_style.sh",
        ".github/workflows/tests-push.yml": "check_gdscript_style.sh",
        "AGENT/Session Notes/TEMPLATE.md": "## Commits claimed",
        "AGENT/Docs/templates/requirement_evidence_matrix.md": "Automated evidence",
        "AGENT/Docs/governance/implemented_track_evidence.json": "bootstrap_rule",
        "requirements-dev.txt": "gdtoolkit==",
        "gdformatrc": "line_length: 100",
        "gdlintrc": "trailing-whitespace",
    }
    for relative, marker in required.items():
        path = ROOT / relative
        if not path.is_file():
            _fail("process-evidence", path, 1, "required process artifact is missing")
        elif marker not in path.read_text(encoding="utf-8"):
            _fail("process-evidence", path, 1, f"required marker is missing: {marker!r}")


# ── check 42: collision-proof session-note names ─────────────────────────────

# All top-level session notes already present at the consolidation baseline are
# historical and keep their published paths. Every later note must carry its
# exact UTC creation second plus a descriptive slug. Using the immutable Git
# tree as the grandfather set avoids a mutable allowlist that could silently
# bless new date-only collisions.
_SESSION_NOTE_FILENAME_BASE = "b9e777013e38e0774742f9537612585189fc46a9"
_SESSION_NOTE_TIMESTAMP_RE = re.compile(
    r"^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}Z-[a-z0-9]+(?:-[a-z0-9]+)*\.md$"
)
_SESSION_NOTE_SPECIAL_FILES = {"INDEX.md", "TEMPLATE.md"}


def check_session_note_filenames() -> None:
    notes_dir = ROOT / "AGENT/Session Notes"
    for path in sorted(notes_dir.glob("*.md")):
        if path.name in _SESSION_NOTE_SPECIAL_FILES or _SESSION_NOTE_TIMESTAMP_RE.fullmatch(path.name):
            continue
        relative = path.relative_to(ROOT).as_posix()
        baseline = subprocess.run(
            ["git", "cat-file", "-e", f"{_SESSION_NOTE_FILENAME_BASE}:{relative}"],
            cwd=ROOT,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if baseline.returncode != 0:
            _fail(
                "session-note-filenames",
                path,
                1,
                "new session note must use YYYY-MM-DD-HH-MM-SSZ-<slug>.md",
            )


# ── check 41: dangling deferral targets ─────────────────────────────────────

# A register may defer an open question to another workstream, written as a
# bracketed tag: "deferred to [PER]". If that tag names nothing that exists, the
# item is deferred indefinitely and no trigger can ever fire — which is exactly
# how MRD-8 sat pointing at a [PER] workstream that had never been created
# (found 2026-07-20). This check makes that failure loud instead of silent.
#
# A tag resolves if it appears anywhere outside the deferral sentence itself:
# another register, a GDD section, or the workspace task tracker. The bar is
# deliberately low — the point is to catch tags that exist nowhere at all.

# Matches across line wraps -- the real MRD-8 case had "deferred" and "[PER]" on
# different lines, so a per-line regex silently missed it. Bounded by a blank
# line so the window cannot run past the end of the deferral paragraph.
_DEFERRAL_RE = re.compile(
    r"defer(?:red|s|ral)?\b(?:(?!\n\s*\n).){0,200}?\[([A-Z][A-Z0-9-]{1,15})\]",
    re.IGNORECASE | re.DOTALL,
)

# Bracketed tags that are register question-ids, not workstream references.
# A register's own ids ([MRD-8], [LEG-2]) are resolved by the register itself.
_DEFERRAL_TAG_IGNORE = re.compile(r"^[A-Z]{2,4}-\d+$")


def check_dangling_deferral_targets() -> None:
    """A register deferring to a workstream tag must name one that exists."""
    registers = sorted((ROOT / "AGENT/Docs/registers").glob("*.md"))
    if not registers:
        return

    # Corpus of everywhere a workstream tag could legitimately be defined.
    corpus_paths = list(registers)
    corpus_paths += sorted((ROOT / "AGENT/Docs/decisions").glob("*.md"))
    corpus_paths += _ACTIVE_GDD_FILES
    tracker = ROOT.parent.parent / "coordination" / "tasks.json"
    if tracker.is_file():
        corpus_paths.append(tracker)

    for path in registers:
        try:
            content = path.read_text(encoding="utf-8")
        except OSError:
            continue
        if _is_historical(path):
            continue
        for m in _DEFERRAL_RE.finditer(content):
            tag = m.group(1)
            if _DEFERRAL_TAG_IGNORE.match(tag):
                continue
            i = content.count("\n", 0, m.start(1)) + 1
            # Resolve against every other source, and against this file with
            # every mention inside a deferral phrase stripped -- otherwise the
            # deferral sentence resolves itself.
            found = False
            for other in corpus_paths:
                try:
                    text = other.read_text(encoding="utf-8")
                except OSError:
                    continue
                if other == path:
                    text = _DEFERRAL_RE.sub("", text)
                if tag in text:
                    found = True
                    break
            if not found:
                _fail("dangling-deferral", path, i,
                      f"deferred to [{tag}], which exists nowhere — no register, "
                      f"GDD section, or tracker row defines it, so nothing can "
                      f"ever un-defer this item")


# TEXT-06: every free-text field that may exist, and why it is allowed.
# Adding a row here is the deliberate act the rule exists to force -- it should be
# a decision, not a side effect of building a screen.
_FREE_TEXT_FIELD_ALLOWLIST: dict[tuple[str, str], str] = {}

_FREE_TEXT_NODE_RE = re.compile(
    r'^\[node name="([^"]+)" type="(LineEdit|TextEdit)"', re.MULTILINE
)


def check_free_text_fields() -> None:
    """TEXT-06: no v1 feature may REQUIRE free text; naming is the only exception.

    Godot's virtual keyboard is Android/iOS/Web only, so on our shipping targets a
    LineEdit has no on-screen affordance at all -- a new free-text field silently
    strands every controller-only player. The rule is ratified in
    GDD_07_Input_Cursor.md; this is its DoD#2 enforcement.
    """
    rule_doc = ROOT / "AGENT/GDD/GDD_07_Input_Cursor.md"
    if rule_doc.is_file() and "TEXT-06" not in rule_doc.read_text(encoding="utf-8"):
        _fail("free-text-fields", rule_doc, 1,
              "the TEXT-06 free-text rule is missing from the input contract that "
              "owns it -- the allow-list below enforces a rule nothing states")

    scenes = sorted((ROOT / "scenes").rglob("*.tscn"))
    for path in scenes:
        try:
            content = path.read_text(encoding="utf-8")
        except OSError:
            continue
        rel = str(path.relative_to(ROOT))
        for m in _FREE_TEXT_NODE_RE.finditer(content):
            node_name = m.group(1)
            line_no = content.count("\n", 0, m.start()) + 1
            if (rel, node_name) in _FREE_TEXT_FIELD_ALLOWLIST:
                continue
            _fail("free-text-fields", path, line_no,
                  f'{m.group(2)} "{node_name}" is not in the TEXT-06 allow-list. '
                  f"No v1 feature may REQUIRE free text except naming -- use "
                  f"selection, filters, or a generated identifier. If this really "
                  f"is the naming exception, add it to _FREE_TEXT_FIELD_ALLOWLIST "
                  f"in check_docs.py with the reason.")

    # A stale allow-list is its own failure: it would silently re-permit a field
    # that was removed, and it is the only record of why each one is allowed.
    for (rel, node_name) in sorted(_FREE_TEXT_FIELD_ALLOWLIST):
        path = ROOT / rel
        if not path.is_file():
            _fail("free-text-fields", path, 1,
                  f"allow-listed scene is gone; drop the {node_name} entry")
            continue
        names = {m.group(1) for m in _FREE_TEXT_NODE_RE.finditer(
            path.read_text(encoding="utf-8"))}
        if node_name not in names:
            _fail("free-text-fields", path, 1,
                  f'allow-listed field "{node_name}" no longer exists; remove its '
                  f"entry so the list keeps meaning something")


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
        ("[22] Danger-mode vocabulary",    check_danger_mode_vocabulary),
        ("[23] F1 save-schema manifest",   check_f1_manifest_shape),
        ("[24] Gamepad bindings",          check_gamepad_bindings),
        ("[25] Input modes",               check_input_modes),
        ("[26] Touch controls",            check_touch_controls),
        ("[27] Stat registry guard",       check_stat_registry_guard),
        ("[28] Party-gold ledger guard",   check_party_gold_transaction_guard),
        ("[29] Spawn occupancy guard",     check_spawn_occupancy_guard),
        ("[30] Active doc ownership",      check_active_doc_ownership),
        ("[31] Retired vocabulary",       check_retired_vocabulary),
        ("[32] Campaign asset boundary",  check_campaign_asset_boundary),
        ("[33] Durable mid-map policy",   check_durable_mid_map_policy),
        ("[34] Mutable campaign rules",   check_mutable_campaign_rule_contract),
        ("[35] Campaign status record",   check_campaign_status_record_contract),
        ("[36] Decision-index vocabulary",check_decision_index_vocabulary),
        ("[37] GDD section governance",   check_gdd_section_governance),
        ("[38] Feature ownership rows",   check_feature_index_ownership_duplicates),
        ("[39] Open authored registries", check_open_authored_registries),
        ("[40] Process evidence tooling",  check_process_evidence_tooling),
        ("[41] Dangling deferral targets", check_dangling_deferral_targets),
        ("[42] Free-text fields (TEXT-06)", check_free_text_fields),
        ("[43] Session-note filenames",   check_session_note_filenames),
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
