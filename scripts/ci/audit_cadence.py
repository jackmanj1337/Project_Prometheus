#!/usr/bin/env python3
"""Report audit freshness from immutable report metadata (never gates)."""

from __future__ import annotations

import re
import subprocess
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_SHA_RE = re.compile(r"^[0-9a-fA-F]{40}$")
_NAME_RE = re.compile(r"^full_review_rollup_(\d{4}-\d{2}-\d{2})(?:-(.*))?\.md$")


def git(*args: str, repo: Path = ROOT) -> str:
    return subprocess.check_output(
        ["git", "-C", str(repo), *args], text=True, stderr=subprocess.PIPE,
    ).strip()


def _unknown(rel: str, source: str | None = None, reason: str | None = None) -> dict[str, object]:
    result: dict[str, object] = {
        "present": True, "status": "unknown", "file": rel,
        "commits_since_rollup": None, "days_since_rollup": None,
    }
    if source:
        result["baseline_source"] = source
    if reason:
        result["reason"] = reason
    return result


def _candidate_key(path: Path) -> tuple[date, str]:
    match = _NAME_RE.match(path.name)
    if not match:
        return date.min, ""
    try:
        parsed = date.fromisoformat(match.group(1))
    except ValueError:
        parsed = date.min
    return parsed, match.group(2) or ""


def audit_cadence(repo: Path = ROOT) -> dict[str, object]:
    reports = sorted(
        (repo / "AGENT" / "Code Reviews").glob("full_review_rollup_*.md"),
        key=_candidate_key,
    )
    if not reports:
        return {
            "present": False, "status": "absent",
            "commits_since_rollup": None, "days_since_rollup": None,
        }
    report = reports[-1]
    rel = str(report.relative_to(repo))
    has_metadata = False
    try:
        text = report.read_text(encoding="utf-8", errors="replace")
        date_lines = re.findall(r"^\*\*Audit date:\*\*\s*(.*?)\s*$", text, re.MULTILINE)
        sha_lines = re.findall(r"^\*\*Audited commit:\*\*\s*(.*?)\s*$", text, re.MULTILINE)
        has_metadata = bool(date_lines or sha_lines)
        if has_metadata:
            if len(date_lines) != 1 or len(sha_lines) != 1:
                return _unknown(rel, "metadata", "missing or duplicate metadata header")
            audit_date = date_lines[0].strip()
            sha = sha_lines[0].strip().strip("`")
            if not _DATE_RE.fullmatch(audit_date) or not _SHA_RE.fullmatch(sha):
                return _unknown(rel, "metadata", "malformed metadata header")
            parsed_date = date.fromisoformat(audit_date)
            if parsed_date > date.today():
                return _unknown(rel, "metadata", "audit date is in the future")
            added = git("log", "--diff-filter=A", "--format=%H", "--", rel, repo=repo).splitlines()
            if not added:
                return _unknown(rel, "metadata", "report is not tracked")
            git("cat-file", "-e", f"{sha}^{{commit}}", repo=repo)
            ancestor_result = subprocess.run(
                ["git", "-C", str(repo), "merge-base", "--is-ancestor", sha, "HEAD"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
            if ancestor_result.returncode > 1:
                return {"present": True, "status": "unavailable", "file": rel,
                        "baseline_source": "metadata", "reason": "git ancestry check unavailable",
                        "commits_since_rollup": None, "days_since_rollup": None}
            if ancestor_result.returncode == 1:
                return _unknown(rel, "metadata", "audited commit is not an ancestor of HEAD")
            count = int(git("rev-list", "--count", f"{sha}..HEAD", repo=repo))
            return {
                "present": True, "status": "ok", "file": rel,
                "baseline_source": "metadata", "audited_commit": sha, "commit": sha,
                "audit_date": audit_date, "commits_since_rollup": count,
                "days_since_rollup": (date.today() - parsed_date).days,
            }
        match = _NAME_RE.match(report.name)
        if not match:
            return _unknown(rel, "legacy", "filename has no audit date")
        audit_date = match.group(1)
        added = git("log", "--diff-filter=A", "--format=%H", "--", rel, repo=repo).splitlines()
        if not added:
            return _unknown(rel, "legacy", "report is not tracked")
        sha = added[-1]
        parsed_date = date.fromisoformat(audit_date)
        if parsed_date > date.today():
            return _unknown(rel, "legacy", "audit date is in the future")
        count = int(git("rev-list", "--count", f"{sha}..HEAD", repo=repo))
        return {
            "present": True, "status": "ok", "file": rel, "baseline_source": "legacy",
            "audited_commit": sha, "commit": sha, "audit_date": audit_date,
            "commits_since_rollup": count, "days_since_rollup": (date.today() - parsed_date).days,
        }
    except subprocess.CalledProcessError:
        return _unknown(rel, "metadata" if has_metadata else "legacy", "git data unavailable")
    except (OSError, ValueError) as exc:
        return _unknown(rel, "metadata" if has_metadata else "legacy", str(exc))


def main() -> int:
    result = audit_cadence()
    if result["status"] == "absent":
        print("audit-cadence: no full review rollup found")
    elif result["status"] != "ok":
        print(f"audit-cadence: {result['status']} ({result.get('file', '')}; {result.get('reason', '')})")
    else:
        print(
            f"audit-cadence: {result['days_since_rollup']} day(s) and "
            f"{result['commits_since_rollup']} commit(s) since {result['file']} "
            f"[{result['baseline_source']}; {str(result['audited_commit'])[:12]}]"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
