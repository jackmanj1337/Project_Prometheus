---
Type: playtest
Status: Candidate preparation
Last verified: 2026-08-11
---

# v0.7.4 Windows remediation candidate

This private candidate replaces the rejected v0.7.3 round. It carries the v0.7.3
first-run Campaign Library repair plus the completed remediation programme for exported
pack registries, general text entry, filename ownership, browser file transfer, and
semantic browser-test observability.

The exact returned replacement pack now passes the exported registry gate. A real
Chromium journey imported that archive with zero diagnostics and captured a non-empty
export. The remaining acceptance boundary is deliberately narrow and native: Windows
must confirm pack import and the game-owned filename/modal input behavior with keyboard
and controller.

- Source branch: `agent/playtest-release-v0.7.4`
- Source commit: pending candidate commit and export.
- Baked product version / preset: `0.7.4` / `Project Prometheus v0.7.4`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate and artifact identities: pending exact-commit verification.
- Supplied replacement pack: 89,746 bytes; SHA-256
  `36be0615b5799043d341487e40e898636d418a45c041c479ffdc27b3de16a423`.

Use `playtest_checklist_v0.7.4_windows.md`. This round is not accepted until the native
Windows return confirms the focused checklist.
