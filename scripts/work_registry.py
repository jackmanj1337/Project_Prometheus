#!/usr/bin/env python3
"""Validate, mutate, and render the Project Prometheus work registry."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "branches.yaml"
ACTIVE = ROOT / "ACTIVE_WORK.md"
RELEASES = ROOT / "RELEASE_TRAINS.md"
REQUIRED = {
    "work_id", "title", "branch", "owner", "status", "target", "base_branch",
    "base_sha", "dependencies", "blockers", "reference", "last_update",
    "playtest_ref", "scope",
}


def load() -> dict[str, Any]:
    with REGISTRY.open(encoding="utf-8") as handle:
        return json.load(handle)


def save(data: dict[str, Any]) -> None:
    REGISTRY.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def git_lines(*args: str) -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(ROOT), *args], text=True, capture_output=True, check=False
    )
    if result.returncode != 0:
        return []
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def ref_exists(ref: str) -> bool:
    return subprocess.run(
        ["git", "-C", str(ROOT), "show-ref", "--verify", "--quiet", ref],
        check=False,
    ).returncode == 0


def validate(data: dict[str, Any], check_git: bool = True, today: dt.date | None = None) -> list[str]:
    errors: list[str] = []
    settings = data.get("settings", {})
    allowed = set(settings.get("allowed_statuses", []))
    lifecycle_branches = set(settings.get("lifecycle_branches", []))
    records = data.get("work", [])
    seen_ids: set[str] = set()
    seen_branches: set[str] = set()
    today = today or dt.date.today()
    stale_days = int(settings.get("stale_after_days", 14))

    for index, record in enumerate(records):
        label = record.get("work_id", f"record[{index}]")
        missing = REQUIRED - set(record)
        if missing:
            errors.append(f"{label}: missing fields: {', '.join(sorted(missing))}")
        work_id = str(record.get("work_id", ""))
        branch = str(record.get("branch", ""))
        if work_id in seen_ids:
            errors.append(f"{work_id}: duplicate Work ID")
        seen_ids.add(work_id)
        if branch in seen_branches:
            errors.append(f"{work_id}: duplicate branch claim: {branch}")
        seen_branches.add(branch)
        if record.get("status") not in allowed:
            errors.append(f"{work_id}: invalid status: {record.get('status')}")
        if record.get("status") == "blocked" and not record.get("trigger"):
            errors.append(f"{work_id}: blocked work requires a resume trigger")
        if (branch.startswith("agent/") and branch not in lifecycle_branches
                and len(branch.split("/")) < 3
                and record.get("owner") != "legacy-agent"):
            errors.append(f"{work_id}: malformed agent branch: {branch}")
        if branch.startswith("agent/") and record.get("base_branch") not in {
            "main", "integration", "agent/stable-release", "agent/integration",
            "agent/playtest-release",
            "agent/coordination", "agent/b4-encounter-model-slice2",
            "agent/codex/2026-07-14/v0.4.0-windows-build",
        }:
            errors.append(f"{work_id}: unexpected feature base: {record.get('base_branch')}")
        try:
            updated = dt.date.fromisoformat(str(record.get("last_update", "")))
            if record.get("status") not in {"completed", "blocked"} and (today - updated).days > stale_days:
                errors.append(f"{work_id}: stale active item ({updated.isoformat()})")
        except ValueError:
            errors.append(f"{work_id}: invalid last_update date")
        if check_git and branch and record.get("status") != "completed":
            local = ref_exists(f"refs/heads/{branch}")
            remote = ref_exists(f"refs/remotes/origin/{branch}")
            expected = remote if record.get("scope") == "remote" else local or remote
            if not expected:
                errors.append(f"{work_id}: registered branch does not exist in expected scope: {branch}")
        if record.get("status") == "completed" and check_git:
            local_exists = ref_exists(f"refs/heads/{branch}")
            remote_exists = ref_exists(f"refs/remotes/origin/{branch}")
            still_exists = remote_exists if record.get("scope") == "remote" else local_exists or remote_exists
            if still_exists:
                errors.append(f"{work_id}: completed work still has a branch: {branch}")

    if check_git:
        prefixes = tuple(settings.get("tracked_remote_prefixes", ["agent/", "release/"]))
        remote_branches = {
            line.removeprefix("origin/")
            for line in git_lines("for-each-ref", "--format=%(refname:short)", "refs/remotes/origin")
            if line.removeprefix("origin/").startswith(prefixes)
        }
        ignored: set[str] = set()
        for branch in sorted(remote_branches - seen_branches - ignored):
            errors.append(f"active remote branch absent from registry: {branch}")

    for train in data.get("release_trains", []):
        version = str(train.get("version", "unnamed release"))
        if not train.get("source_sha"):
            errors.append(f"{version}: release missing source SHA")
        if train.get("acceptance") == "accepted" and not train.get("stable_tag"):
            errors.append(f"{version}: accepted release missing stable tag")
        if train.get("acceptance") == "playtesting" and not train.get("playtest_tags"):
            errors.append(f"{version}: playtesting release missing playtest tag")
        if check_git:
            for tag in train.get("playtest_tags", []):
                if not ref_exists(f"refs/tags/{tag}"):
                    errors.append(f"{version}: playtest tag does not exist: {tag}")
            stable = train.get("stable_tag")
            if stable and not ref_exists(f"refs/tags/{stable}"):
                errors.append(f"{version}: stable tag does not exist: {stable}")
    return errors


def md(value: Any) -> str:
    if value is None or value == "":
        return "—"
    if isinstance(value, list):
        return ", ".join(map(str, value)) if value else "—"
    return str(value).replace("|", "\\|")


def render(data: dict[str, Any]) -> None:
    active_lines = [
        "# Active Work", "", "Generated from `branches.yaml`; do not edit directly.", "",
        "| Work ID | Title | Status | Branch | Owner | Target | Base | Dependencies | Blockers | Trigger | Reference | Updated | Playtest |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|---|",
    ]
    for item in data.get("work", []):
        if item.get("status") == "completed":
            continue
        active_lines.append("| " + " | ".join(md(item.get(key)) for key in (
            "work_id", "title", "status", "branch", "owner", "target",
            "base_branch", "dependencies", "blockers", "trigger", "reference", "last_update",
            "playtest_ref",
        )) + " |")
    ACTIVE.write_text("\n".join(active_lines) + "\n", encoding="utf-8")

    release_lines = [
        "# Release Trains", "", "Generated from `branches.yaml`; do not edit directly.", "",
        "| Version | Branch | Source branch | Source SHA | Playtest tags | Stable tag | Acceptance | Updated |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for train in data.get("release_trains", []):
        release_lines.append("| " + " | ".join(md(train.get(key)) for key in (
            "version", "branch", "source_branch", "source_sha", "playtest_tags",
            "stable_tag", "acceptance", "last_update",
        )) + " |")
    RELEASES.write_text("\n".join(release_lines) + "\n", encoding="utf-8")


def find_work(data: dict[str, Any], work_id: str) -> dict[str, Any]:
    matches = [item for item in data.get("work", []) if item.get("work_id") == work_id]
    if len(matches) != 1:
        raise SystemExit(f"Work ID must resolve exactly once: {work_id}")
    return matches[0]


def mutate(args: argparse.Namespace, data: dict[str, Any]) -> None:
    today = dt.date.today().isoformat()
    if args.command == "start":
        if any(item.get("work_id") == args.work_id for item in data["work"]):
            raise SystemExit(f"Duplicate Work ID: {args.work_id}")
        if any(item.get("branch") == args.branch for item in data["work"]):
            raise SystemExit(f"Branch already claimed: {args.branch}")
        data["work"].append({
            "work_id": args.work_id, "title": args.title, "branch": args.branch,
            "owner": args.owner, "status": "in_progress", "target": args.target,
            "base_branch": args.base_branch, "base_sha": args.base_sha,
            "dependencies": [], "blockers": [], "reference": "",
            "last_update": today, "playtest_ref": None, "scope": args.scope,
        })
    elif args.command == "pause":
        item = find_work(data, args.work_id)
        item["status"] = "blocked"
        item["blockers"] = [args.reason]
        item["last_update"] = today
    elif args.command == "finish":
        item = find_work(data, args.work_id)
        item["status"] = "completed"
        item["reference"] = args.reference
        item["blockers"] = []
        item["last_update"] = today
    elif args.command == "start-release":
        if any(train.get("version") == args.version for train in data["release_trains"]):
            raise SystemExit(f"Release already exists: {args.version}")
        data["release_trains"].append({
            "version": args.version, "branch": args.branch,
            "source_branch": args.source_branch, "source_sha": args.source_sha,
            "playtest_tags": [], "stable_tag": None, "acceptance": "pending",
            "last_update": today,
        })
    else:
        raise SystemExit(f"Unsupported mutation: {args.command}")
    save(data)


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser()
    sub = root.add_subparsers(dest="command", required=True)
    sub.add_parser("render")
    check = sub.add_parser("check")
    check.add_argument("--no-git", action="store_true")
    sub.add_parser("status")
    start = sub.add_parser("start")
    start.add_argument("work_id"); start.add_argument("title"); start.add_argument("branch")
    start.add_argument("owner"); start.add_argument("target"); start.add_argument("base_branch")
    start.add_argument("base_sha"); start.add_argument("--scope", choices=("local", "remote"), default="remote")
    pause = sub.add_parser("pause")
    pause.add_argument("work_id"); pause.add_argument("reason")
    finish = sub.add_parser("finish")
    finish.add_argument("work_id"); finish.add_argument("reference")
    release = sub.add_parser("start-release")
    release.add_argument("version"); release.add_argument("branch")
    release.add_argument("source_branch"); release.add_argument("source_sha")
    return root


def main() -> int:
    args = parser().parse_args()
    data = load()
    if args.command == "render":
        render(data)
        return 0
    if args.command == "status":
        render(data)
        print(ACTIVE.read_text(encoding="utf-8"), end="")
        return 0
    if args.command == "check":
        errors = validate(data, check_git=not args.no_git)
        if errors:
            print("work registry: FAIL", file=sys.stderr)
            for error in errors:
                print(f"  - {error}", file=sys.stderr)
            return 1
        render(data)
        print(f"work registry: PASS ({len(data.get('work', []))} work records, {len(data.get('release_trains', []))} release trains)")
        return 0
    mutate(args, data)
    errors = validate(data)
    if errors:
        print("mutation produced an invalid registry:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    render(data)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
