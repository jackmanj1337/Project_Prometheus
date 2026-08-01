---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-08-01
---

# v0.6.0 Windows Playtest Build

Combined **visual-validation** build for two code-complete, headless-green feature sets that
need a real Windows visual/input pass the container cannot run: the viewport **expand +
anchoring** work (`IMPL-VIEWPORT-ANCHORING`, incl. the new Viewport Scale setting) and the
**text-entry + FileDialog Escape** work (`IMPL-FILEDIALOG-ESCAPE-TEXTINPUT`). Built from a
throwaway source branch that merges both feature branches; each merges back to `agent/integration`
independently after its half of the checklist passes, so a failure in one does not block the other.

- Artifact: `builds/v0.6.0-playtest/Project_Prometheus_v0.6.0_debug.exe`
- Bundle: `Project_Prometheus_v0.6.0_playtest_bundle.zip`
- Source branch: `agent/from-integration/v0.6.0-visual-pass`
- Source commit (built): `cbd1f83257bc68fad1ccdec0bbcb8d5faa7df295`
- Source tree: `1830a79016aa626d627d11e532539bb0532885d1`
- Baked version: `0.6.0`
- Baked commit: `cbd1f832`
- Baked UTC timestamp: `2026-08-01T03:10:37Z`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.6.0`
- Automated tests: PASS - all suites green at the merged source tree (settings_manager 37,
  settings_screen 33, text_entry 28; menu_scale OK).
- Executable: `102238256` bytes, SHA-256
  `248bbcdf047ea7c59f57587a8cd153169b79621e11b2fdb01764b29fccda3c00`
- `two-map-skirmish-1.0.zip`: `4501` bytes, SHA-256
  `02ce10167db178cd3813b0766299f24b8fa19af30d4dafb683b025b3fa09455f`
- `branching-skirmish-1.0.zip`: `5167` bytes, SHA-256
  `c83924ce80e39b06ac3b347f6d11700fe4d40a063bdd340804519171ff8263e2`
- Export result: PASS - canonical export produced a PE32+ Windows x86-64 executable with
  embedded PCK; baked version `0.6.0` verified present in the pack. (Headless emits two benign
  post-savepack 'editor settings' errors -- no editor settings path in headless; the pack is
  already written and valid.)
- Bundle contents: executable, checklist, this build record, `BUILD_INFO.json`, both campaign
  fixtures, and `SHA256SUMS.txt`.
- Bundle: `34575620` bytes, SHA-256
  `944f794cdca32de6f3bf1913ff9261255b7d2e1a9c3391a50f0476ad32295e99`.

Live Windows validation remains pending. Complete and return
[`playtest_checklist_v0.6.0.md`](playtest_checklist_v0.6.0.md) with logs, screenshots, the
`escape_consumed_by` value, and reproduction artifacts. Carry-forward requirements (all five)
are folded into the checklist per
[`playtest_v0.6.0_carryforward_2026-07-29.md`](playtest_v0.6.0_carryforward_2026-07-29.md).
