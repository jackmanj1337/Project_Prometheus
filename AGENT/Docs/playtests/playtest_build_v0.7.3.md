---
Type: playtest
Status: Awaiting Windows return
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
- Source commit: `3f72688f7d48e5ceb4ea93bcda4aa1615ef31749`.
- Baked product version / preset: `0.7.3` / `Project Prometheus v0.7.3`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: all 136 suites passed on the exact exported commit; the full-check
  receipt records tree `851a93898b1acafdf1056edca8a0bcf3a9354a33`, which both artifact
  manifests name as their `source_tree`.
- Release executable: 105,943,056 bytes; SHA-256
  `4977a00a5e6653bc6c9a6119f469489b475f925d5fe770a1622e0eaeb5d856de`.
- Debug executable: 102,071,312 bytes; SHA-256
  `5058cfe54985405c732f8f79e037de22cff77ac82898bfe28aa1c1b5b08797db`.
- Both artifact manifests read back BUILD STAMP `0.7.3/3f72688f`.
- Inspectable export pack: 658 files, zero top-level `data/**` entries; SHA-256
  `d052b9d16e426618b0e88b090f36b9f9a085402857b11e648c2854cca748fe6a`. The only two
  `/data/` substring matches are `scripts/data/EntitySchemaRegistry.gdc` and its
  `.gd.remap`, both engine code.
- Tester bundle: `Project_Prometheus_v0.7.3_tester_bundle.zip`; 10 files;
  SHA-256 `940f4829edf1d58ac30868795f07eca33f3bb58fee1e3f062886c47eda7729f7`.
- Supplied replacement pack: reused unchanged from the v0.7.2 bundle — 150 files under
  the single `prometheus-v071-playwright-test/` root; archive SHA-256
  `36be0615b5799043d341487e40e898636d418a45c041c479ffdc27b3de16a423`.

Use `playtest_checklist_v0.7.3_windows.md`. The round remains unaccepted until native
Windows validates the first-run Campaign Library route, the content-free
launch/replacement-pack lifecycle, and the game-owned filename modal.
