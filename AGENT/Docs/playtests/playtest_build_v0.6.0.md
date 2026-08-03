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
- Source commit (built): `__FILL_AFTER_EXPORT__`
- Source tree: `__FILL_AFTER_EXPORT__`
- Baked version: `0.6.0`
- Baked commit: `__FILL_AFTER_EXPORT__`
- Baked UTC timestamp: `__FILL_AFTER_EXPORT__`
- Godot version: `4.6.3.stable`
- Preset: `Project Prometheus v0.6.0`
- Automated tests: PASS - all suites green at the merged source tree (settings_manager 37,
  settings_screen 33, text_entry 28; menu_scale OK).
- Executable: `__FILL_AFTER_EXPORT__` bytes, SHA-256 `__FILL_AFTER_EXPORT__`
- `two-map-skirmish-1.0.zip`: `__FILL_AFTER_EXPORT__` bytes, SHA-256 `__FILL_AFTER_EXPORT__`
- `branching-skirmish-1.0.zip`: `__FILL_AFTER_EXPORT__` bytes, SHA-256 `__FILL_AFTER_EXPORT__`
- Export result: `__FILL_AFTER_EXPORT__`
- Bundle contents: executable, checklist, this build record, `BUILD_INFO.json`, both campaign
  fixtures, and `SHA256SUMS.txt`.
- Bundle: `__FILL_AFTER_EXPORT__` bytes, SHA-256 `__FILL_AFTER_EXPORT__`.

Live Windows validation remains pending. Complete and return
[`playtest_checklist_v0.6.0.md`](playtest_checklist_v0.6.0.md) with logs, screenshots, the
`escape_consumed_by` value, and reproduction artifacts. Carry-forward requirements (all five)
are folded into the checklist per
[`playtest_v0.6.0_carryforward_2026-07-29.md`](playtest_v0.6.0_carryforward_2026-07-29.md).
