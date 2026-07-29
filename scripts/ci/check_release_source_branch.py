#!/usr/bin/env python3
"""Require the release build record to name the branch being exported."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
VERSION_RE = re.compile(r'^application/product_version="([^"]+)"$', re.MULTILINE)
SOURCE_RE = re.compile(r"^- Source branch: `([^`]+)`$", re.MULTILINE)


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


def main() -> None:
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
    print(f"release-source: PASS ({version} from {actual})")


if __name__ == "__main__":
    main()
