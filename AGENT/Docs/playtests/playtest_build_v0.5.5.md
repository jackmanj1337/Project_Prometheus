---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-07-23
---

# v0.5.5 Windows Playtest Build

Debug build (`--export-debug`, Windows debug template) that carries the v0.5.4
controller/UI rework plus this round's input-ordering repair. v0.5.4 reworked
Prep/Results/Defeat/Rewind for controller navigation and added authored
result-actions; a root-cause review of that build found the directional
suppression was wired into `_unhandled_input` (too late — the engine's built-in
focus navigation already stepped focus in the GUI phase), so Results/Defeat/
Rewind double-stepped, and `FocusNavigator` lacked the embedded-popup gate. This
build **is** the visual pass for those repairs — the container runs headless
tests but cannot validate live Windows visuals or real controller input.

- Artifact: `builds/Project_Prometheus_v0.5.5_debug.exe`
- Companion fixture: `two-map-skirmish-1.0.zip` (unchanged from v0.5.4;
  size `4271` bytes, SHA-256
  `5b5ae637ff782b0b134355bbc409971e590cd1c09e3119a5303a96b3e330123e`)
- Source branch: `agent/playtest-release-v0.5.4-fixes`
- Source commit (built): `6651481c37bba752c1f80cbed63eb7778f122f9e`
- Source tree: `086ea60b69573c5ff7dc2940ca2e40a94d96e3e8`
- Baked version: `0.5.5`
- Baked commit: `6651481`
- Baked UTC timestamp: `2026-07-23T00:56:21Z`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.5.5`
- Platform: Windows Desktop x86-64, embedded PCK, **debug template**
  (`PE32+ executable (GUI) x86-64 (stripped to external PDB)`, 12 sections)
- Executable size: `102184552` bytes
- Executable SHA-256: `f1041663c03afd5a0ee0349fd99171cb63cfb7a5ce6ee74c903a434ad1c6f200`
- Export result: PASS - `export_smoke.sh` wrapping
  `godot --headless --export-debug "Project Prometheus v0.5.5"` returned exit 0 and
  produced the embedded-PCK executable (`"commit": "6651481"` verified in the exe).
- This build record's finalization commit only fills in the measured artifact
  values above; the executable's baked stamp is the build commit.
- Automated tests: PASS - all suites green at the build commit (`bash run_tests.sh`)
- Documentation checks: PASS (`AGENT/Docs/check_docs.py`)
- Release metadata: PASS - `test_release_metadata` green at v0.5.5 (preset name/path/
  product version, Main Menu label, checklist presence, and setup guide all agree)
- Embedded stamp: the exe embeds `build_info.json`
  `{"version":"0.5.5","commit":"<commit>","built_at":"<ts>"}`; the baked commit
  matches the source commit.

## Notes

The exporter may print nonfatal `Error saving editor settings` / `Can't save
resource to empty path` messages because the container's `~/.cache` editor-settings
path is not writable. Packing completes, Godot returns zero, and the artifact is
measured — these are not export failures.

Live Windows behavior is not proven by headless export. Complete and return
[`playtest_checklist_v0.5.5.md`](playtest_checklist_v0.5.5.md) with its matching
original `godot.log` and the requested screenshots.
</content>
</invoke>
