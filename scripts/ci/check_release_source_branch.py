#!/usr/bin/env python3
"""Validate the source branch and distribution safety of a release export."""

from __future__ import annotations

import fnmatch
import hashlib
import json
import os
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
VERSION_RE = re.compile(r'^application/product_version="([^"]+)"$', re.MULTILINE)
SOURCE_RE = re.compile(r"^- Source branch: `([^`]+)`$", re.MULTILINE)
EXCLUDE_RE = re.compile(r'^exclude_filter="([^"]*)"$', re.MULTILINE)
PUBLIC_SCOPE = "public"
INTERNAL_SCOPE = "internal"
PRIVATE_POLICY = "private_only"
FE_REPO_NAME = "Project_Prometheus_Campaign_Pack_FE"
PACK0_REPO_NAME = "Project_Prometheus_Campaign_Pack_0"
FINGERPRINT_IGNORES = {"CREDITS.md", "NOTICE.md", "README.md"}
AUTOMATIC_EXPORT_IGNORES = {".git", ".godot", "builds"}
SOURCE_COPY_EXCLUDES = (
    "AGENT/**",
    "scripts/tests/**",
    "scripts/tools/**",
    "test_fixtures/**",
    "tools/**",
)


def read_version() -> str:
    preset = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    match = VERSION_RE.search(preset)
    if not match:
        raise SystemExit("release-source: export preset has no product version")
    return match.group(1)


def current_branch() -> str:
    result = subprocess.run(
        ["git", "branch", "--show-current"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    branch = result.stdout.strip()
    if not branch:
        raise SystemExit("release-source: detached HEAD cannot be exported")
    return branch


def branch_at(root: Path) -> str:
    result = subprocess.run(
        ["git", "branch", "--show-current"],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def is_public_line_checkout(root: Path) -> bool:
    return branch_at(root) in {"main", "agent/staging-area"}


def distribution_scope() -> str:
    """Return the explicitly requested distribution scope, failing safe to public."""
    scope = os.environ.get("PROMETHEUS_DISTRIBUTION_SCOPE", PUBLIC_SCOPE).strip().lower()
    if scope not in {PUBLIC_SCOPE, INTERNAL_SCOPE}:
        raise SystemExit(
            "release-source: PROMETHEUS_DISTRIBUTION_SCOPE must be public or internal"
        )
    return scope


def export_excludes() -> tuple[str, ...]:
    preset = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    matches = EXCLUDE_RE.findall(preset)
    if not matches:
        raise SystemExit("release-source: export presets have no exclude_filter")
    filters: set[str] = set()
    for value in matches:
        filters.update(part.strip() for part in value.split(",") if part.strip())
    return tuple(sorted(filters))


def is_export_excluded(relative_path: Path, excludes: tuple[str, ...]) -> bool:
    if relative_path.parts and relative_path.parts[0] in AUTOMATIC_EXPORT_IGNORES:
        return True
    path = relative_path.as_posix()
    return any(fnmatch.fnmatch(path, pattern) for pattern in excludes)


def private_export_manifests(root: Path, excludes: tuple[str, ...]) -> list[Path]:
    private: list[Path] = []
    for manifest in root.rglob("manifest.json"):
        relative = manifest.relative_to(root)
        if is_export_excluded(relative, excludes):
            continue
        try:
            raw = json.loads(manifest.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
            raise SystemExit(f"release-source: cannot inspect {relative}: {error}") from error
        if isinstance(raw, dict) and raw.get("distribution_policy") == PRIVATE_POLICY:
            private.append(relative)
    return sorted(private)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def fe_fingerprints(fe_root: Path) -> dict[str, list[Path]]:
    """Index private pack payloads; names are irrelevant, bytes are authoritative."""
    fingerprints: dict[str, list[Path]] = {}
    packs = fe_root / "packs"
    if not packs.is_dir():
        return fingerprints
    for path in sorted(item for item in packs.rglob("*") if item.is_file()):
        if path.name in FINGERPRINT_IGNORES or path.name == "manifest.json":
            continue
        fingerprints.setdefault(_sha256(path), []).append(path.relative_to(fe_root))
    return fingerprints


def copied_fe_payloads(
    public_root: Path, fe_root: Path, excludes: tuple[str, ...]
) -> list[tuple[Path, Path]]:
    fingerprints = fe_fingerprints(fe_root)
    if not fingerprints:
        return []
    copies: list[tuple[Path, Path]] = []
    for path in sorted(item for item in public_root.rglob("*") if item.is_file()):
        relative = path.relative_to(public_root)
        if ".git" in relative.parts or is_export_excluded(relative, excludes):
            continue
        matches = fingerprints.get(_sha256(path), [])
        copies.extend((relative, source) for source in matches)
    return copies


def check_public_distribution() -> None:
    excludes = export_excludes()
    private = private_export_manifests(ROOT, excludes)
    if private:
        paths = ", ".join(str(path) for path in private)
        raise SystemExit(
            f"release-source: public export contains {PRIVATE_POLICY} pack manifest(s): {paths}"
        )

    fe_root = ROOT.parent / FE_REPO_NAME
    if fe_root.is_dir():
        public_roots = (ROOT, ROOT.parent / PACK0_REPO_NAME)
        found: list[str] = []
        for public_root in public_roots:
            if not public_root.is_dir():
                continue
            if public_root != ROOT and not is_public_line_checkout(public_root):
                continue
            # Public repositories must not contain FE payloads even in paths such as
            # data/** that Godot excludes from the executable. Only known internal test,
            # authoring-tool, and documentation surfaces are exempt from this source scan.
            copies = copied_fe_payloads(public_root, fe_root, SOURCE_COPY_EXCLUDES)
            found.extend(
                f"{public_root.name}/{target} <- {source}" for target, source in copies
            )
        if found:
            preview = found[:10]
            if len(found) > len(preview):
                preview.append(f"... and {len(found) - len(preview)} more")
            raise SystemExit(
                "release-source: public source contains FE-pack payload: "
                + "; ".join(preview)
            )


def main() -> None:
    scope = distribution_scope()
    if scope == PUBLIC_SCOPE:
        check_public_distribution()
    else:
        print("release-source: INTERNAL distribution (private-only content permitted)")
    version = read_version()
    record = ROOT / "AGENT" / "Docs" / "playtests" / f"playtest_build_v{version}.md"
    if not record.is_file():
        raise SystemExit(f"release-source: missing build record {record.relative_to(ROOT)}")
    match = SOURCE_RE.search(record.read_text(encoding="utf-8"))
    if not match:
        raise SystemExit(f"release-source: {record.relative_to(ROOT)} has no Source branch")
    documented = match.group(1)
    actual = current_branch()
    if documented != actual:
        raise SystemExit(
            f"release-source: build record names {documented}, but export branch is {actual}"
        )
    print(f"release-source: PASS ({version} from {actual}, distribution={scope})")


if __name__ == "__main__":
    main()
