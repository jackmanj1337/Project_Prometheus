---
Type: playtest
Status: Superseded by v0.7.3
Last verified: 2026-08-09
---

# v0.7.2 Windows remediation candidate

This private candidate recuts the rejected v0.7.1 round after the complete automated
remediation programme. It repairs installed-pack discovery, makes package-backed resume
and legacy user-data migration atomic, replaces native FileDialog filename editing with
a game-owned modal, and removes built-in `data/**` catalogues from player exports.

- Source branch: `agent/playtest-release-v0.7.2`
- Source commit: `d0746d4bcd9eff9fb60486442c00641c415c0612`.
- Baked product version / preset: `0.7.2` / `Project Prometheus v0.7.2`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: all 136 suites passed on the exact exported commit.
- Release executable: 105,942,416 bytes; SHA-256
  `72370b9b76f613b918aaa9155e85d0e75ba811675e70bad64d5d883ab413c3a6`.
- Debug executable: 102,070,672 bytes; SHA-256
  `1794dddd7f6ec2860a8f264a40b6b1bf61522aa965e3814f8d5f7222dc85231d`.
- Both artifact manifests read back BUILD STAMP `0.7.2/d0746d4b`.
- Inspectable export pack: 658 files, zero top-level `data/**` entries; SHA-256
  `836b7976e790858816cfcb4b4aceac46736effe564960f7f9b823ae6ef0a597e`.
- Tester bundle: `Project_Prometheus_v0.7.2_tester_bundle.zip`; 10 files;
  SHA-256 `be0c21f33b2bfe16bde07473d13df095c178361374b23b1773d39da5afcaa250`.
- Supplied replacement pack: 150 files under the single
  `prometheus-v071-playwright-test/` root; archive SHA-256
  `36be0615b5799043d341487e40e898636d418a45c041c479ffdc27b3de16a423`.

Use `playtest_checklist_v0.7.2_windows.md`. The round remains unaccepted until native
Windows validates the content-free launch/replacement-pack lifecycle and the game-owned
filename modal.
