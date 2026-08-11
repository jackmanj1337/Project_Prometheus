---
Type: playtest
Status: Awaiting Windows return
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
- Source commit: `1e874231daa299ef3b3a391d14bf3bf16dac5607`.
- Baked product version / preset: `0.7.4` / `Project Prometheus v0.7.4`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: all 138 suites passed on the exact exported commit; the full-check
  receipt and both artifact manifests name source tree
  `ef297b452aa9e93a218ea6b77915c1cb57da96a8`.
- Release executable: 105,993,448 bytes; SHA-256
  `f730d5ff06b30bfcb26c644a8786e9536f1f6fbeb47b52cc59783f342f577564`.
- Debug executable: 102,121,704 bytes; SHA-256
  `52ae19a1948efbc5e83897b0e9b3572497691020111e73a208379c35c7228039`.
- Both artifact manifests read back BUILD STAMP `0.7.4/1e874231`.
- Tester bundle: `Project_Prometheus_v0.7.4_tester_bundle.zip`; 10 files;
  SHA-256 `a942a36c87f1bc616147fbd3b7dc99ea3a6dd15f8bef7def5169669021841441`.
- Supplied replacement pack: 89,746 bytes; SHA-256
  `36be0615b5799043d341487e40e898636d418a45c041c479ffdc27b3de16a423`.

Use `playtest_checklist_v0.7.4_windows.md`. This round is not accepted until the native
Windows return confirms the focused checklist.
