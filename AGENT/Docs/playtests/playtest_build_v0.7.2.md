---
Type: playtest
Status: Candidate preparation
Last verified: 2026-08-09
---

# v0.7.2 Windows remediation candidate

This private candidate recuts the rejected v0.7.1 round after the complete automated
remediation programme. It repairs installed-pack discovery, makes package-backed resume
and legacy user-data migration atomic, replaces native FileDialog filename editing with
a game-owned modal, and removes built-in `data/**` catalogues from player exports.

- Source branch: `agent/playtest-release-v0.7.2`
- Source commit: recorded per artifact in `artifact-manifest-*.json` and
  `BUILD_INFO.json`; it is read from the artifact rather than transcribed here.
- Baked product version / preset: `0.7.2` / `Project Prometheus v0.7.2`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: the full suite must be green on the exact exported commit.

Use `playtest_checklist_v0.7.2_windows.md`. The round remains unaccepted until native
Windows validates the content-free launch/replacement-pack lifecycle and the game-owned
filename modal.
