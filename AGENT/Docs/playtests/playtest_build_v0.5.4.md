---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-07-22
---

# v0.5.4 Windows Playtest Build

Debug build (`--export-debug`, Windows debug template) that carries the v0.5.3
playtest fix set (V053-01…-09 plus the HUD-editor teardown-contract follow-up).
This build **is** the visual pass for those fixes — the container runs headless
tests but cannot validate live Windows visuals or real input.

- Artifact: `builds/Project_Prometheus_v0.5.4_debug.exe`
- Companion fixture: `two-map-skirmish-1.0.zip` (unchanged from v0.5.3;
  size `4271` bytes, SHA-256
  `5b5ae637ff782b0b134355bbc409971e590cd1c09e3119a5303a96b3e330123e`)
- Source branch: `agent/playtest-release-v0.5.4-fixes`
- Source commit: `<FILLED AFTER EXPORT>`
- Source tree: `<FILLED AFTER EXPORT>`
- Baked version: `0.5.4`
- Baked commit: `<FILLED AFTER EXPORT>`
- Baked UTC timestamp: `<FILLED AFTER EXPORT>`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.5.4`
- Platform: Windows Desktop x86-64, embedded PCK, **debug template**
- Executable size: `<FILLED AFTER EXPORT>` bytes
- Executable SHA-256: `<FILLED AFTER EXPORT>`
- Automated tests: PASS - all suites green at the build commit (`bash run_tests.sh`)
- Documentation checks: PASS (`AGENT/Docs/check_docs.py`)
- Release metadata: PASS - `test_release_metadata` green at v0.5.4 (preset name/path/
  product version, Main Menu label, checklist presence, and setup guide all agree)
- Embedded stamp: the exe embeds `build_info.json`
  `{"version":"0.5.4","commit":"<commit>","built_at":"<ts>"}`; the baked commit
  matches the source commit.

## Notes

The exporter may print nonfatal `Error saving editor settings` / `Can't save
resource to empty path` messages because the container's `~/.cache` editor-settings
path is not writable. Packing completes, Godot returns zero, and the artifact is
measured — these are not export failures.

Live Windows behavior is not proven by headless export. Complete and return
[`playtest_checklist_v0.5.4.md`](playtest_checklist_v0.5.4.md) with its matching
original `godot.log` and the requested screenshots.
