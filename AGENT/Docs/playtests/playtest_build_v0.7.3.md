---
Type: playtest
Status: Candidate preparation
Last verified: 2026-08-10
---

# v0.7.3 Windows remediation candidate

This private candidate carries the complete v0.7.2 remediation programme plus the
first-run Campaign Library repair that landed after the v0.7.2 bundle was frozen. It
supersedes v0.7.2, which was never delivered for a native round: on a fresh install that
candidate reached the Campaign Library only through the disabled New Game route, so a
tester with no installed content had no way to import a pack.

Carried forward from v0.7.2: repaired installed-pack discovery, atomic package-backed
resume and legacy user-data migration, a game-owned filename modal in place of native
`FileDialog` filename editing, and removal of built-in `data/**` catalogues from player
exports.

New in v0.7.3: Campaign Library is an independent Main Menu action, enabled and
initially focused when no playable content is installed; the disabled first-run label
reads **New Game (No Data Packs Installed)**; and library imports refresh Main Menu
state, so New Game becomes available without leaving and re-entering the menu.

- Source branch: `agent/playtest-release-v0.7.3`
- Source commit: pending export.
- Baked product version / preset: `0.7.3` / `Project Prometheus v0.7.3`
- Godot: `4.6.3.stable.official.7d41c59c4`

Use `playtest_checklist_v0.7.3_windows.md`. The round remains unaccepted until native
Windows validates the first-run Campaign Library route, the content-free
launch/replacement-pack lifecycle, and the game-owned filename modal.
