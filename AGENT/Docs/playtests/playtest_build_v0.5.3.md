---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-07-21
---

# v0.5.3 Windows Playtest Build

- Artifact: `builds/windows/Project_Prometheus/Project_Prometheus.exe`
- Companion fixture: `builds/windows/Project_Prometheus/two-map-skirmish-1.0.zip`
- Source branch: `agent/playtest-release-v0.5.3-telemetry`
- Source commit: `4ddd54c82b2fb1a0565d4e901f43053221cebe11`
- Source tree: `1f5e425db9e1d0b73f06769415f3366165556039`
- Baked version: `0.5.3`
- Baked commit: `4ddd54c`
- Baked UTC timestamp: `2026-07-21T06:34:15Z`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.5.3`
- Platform: Windows Desktop x86-64, embedded PCK
- Executable size: `106042584` bytes
- Executable SHA-256: `86109f8163d9eeb9cbe491189c3098b6fc1c1244a500776e8a03810727e14ba9`
- Fixture size: `4271` bytes
- Fixture SHA-256: `5b5ae637ff782b0b134355bbc409971e590cd1c09e3119a5303a96b3e330123e`
- Artifact manifest: `builds/windows/Project_Prometheus/artifact-manifest.json`
  (records source SHA `4ddd54c8`, source tree `1f5e425d`, preset
  `Project Prometheus v0.5.3`, build-stamp evidence
  `v0.5.3 commit 4ddd54c built 2026-07-21T06:34:15Z`)
- PE inspection: `PE32+ executable (GUI) x86-64 (stripped to external PDB)`, 12 sections
- Automated tests: PASS - all 103 suites green at exact source commit (full receipt
  tree `1f5e425d` matched `HEAD^{tree}`)
- Documentation checks: PASS - all 40 checks green
- Release metadata: PASS - all 5 `test_release_metadata` checks green at v0.5.3
- GDScript format/lint and RNG guard: PASS (235 tracked scripts)
- Embedded stamp inspection: PASS - the exe embeds
  `{"version":"0.5.3","commit":"4ddd54c","built_at":"2026-07-21T06:34:15Z"}`;
  the baked commit matches the exact source commit `4ddd54c`.
- Export result: PASS - the mandated `scripts/export-windows.sh --mode release`
  wrapper returned zero and produced the embedded-PCK executable and manifest.

## Notes

The exporter printed nonfatal `Error saving editor settings`/`Can't save resource
to empty path` messages because the container's `~/.cache` editor-settings path is
not writable. Packing completed, Godot returned zero, the artifact set was
measured, and the embedded stamp was inspected — these are not export failures.

Tooling note: the release wrapper previously failed because the Godot preset name
carries the release version (`Project Prometheus v0.5.3`), which never matches the
per-platform default preset in `repos.yaml`. `scripts/export-project.py` now falls
back to the sole configured preset when the requested name is absent, so the
wrapper works across version bumps without a per-release config edit. This is an
infrastructure change to the container repo, tracked separately from the game
release line.

Live Windows behavior is not proven by headless export. Complete and return
[`playtest_checklist_v0.5.3.md`](playtest_checklist_v0.5.3.md) with its matching
original log and requested screenshots.
