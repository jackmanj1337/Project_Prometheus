---
Type: code-review
Status: Known issue
Last verified: 2026-07-25
---

# v0.5.6 playtest return — triage and root-cause review

## Executive summary

**Verdict: REJECTED / fixes and a focused Windows rerun are required.** The v0.5.6
return verifies the main v0.5.5 repairs: package-owned saves loaded in the exercised
flow, long-list focus stayed visible, Retry-after-Save branched correctly, Z/X typed
inside FileDialog, and the connected two-map flow completed. It also exposes two High
state/load defects, one failed FileDialog fix, two visual defects, and several checks
that remain unverified.

The supplied logs identify the exact build as version `0.5.6`, commit `e7ee9f5`, built
`2026-07-24T17:54:53Z`, running Godot 4.6.3 on Windows 10.0.26200 at 1920x1080. This
review diagnoses that build and does not include product fixes.

Returned evidence is preserved unchanged under:

- `AGENT/Docs/playtests/v0.5.6 playtest results/playtest_checklist_v0.5.6.md`
- `AGENT/Docs/playtests/v0.5.6 playtest results/godot.log`
- `AGENT/Docs/playtests/v0.5.6 playtest results/godot2026-07-24T13.18.37.log`
- the three PNG screenshots in the same directory

## Triage matrix

| ID | Severity | Source | Disposition |
|---|---|---|---|
| V056-01 | High | branching checklist + screenshot + log | Reused Results screen leaves the successor picker disabled after Retry-after-Save, stranding the next branch choice and emitting repeated errors on Save. |
| V056-02 | High | `godot.log` | Normal slot loads still validate against the currently active catalogue; the saved-content validation helper is only wired to portable-save inspection. |
| V056-03 | Medium | FileDialog checklist | Two-stage physical Escape still fails; first Escape closes the dialog. |
| V056-04 | Medium accessibility | 200% screenshot | Results is a fixed, single-column panel; at 200% its title and actions overflow the viewport. |
| V056-05 | Low visual | Settings screenshot | OptionButton text collides with the ornate button ends and the long stretched center makes the decoration look distorted. |
| V056-06 | Low cleanup | both logs | Temporary v0.3.0 display tracing still ships and emits `V030-DSP-TRACE`. |
| V056-07 | Test-instruction gap | checklist | Missing-package rollback was not tested because the checklist gives no safe setup/removal/restoration procedure. |
| V056-08 | Unverified | checklist | Gamepad hotplug, prompt switching, and remaining controller-specific checks were not run because no gamepad was available. |
| V056-09 | UX/test-fixture request | checklist | Branch destinations are named in Prep and telemetry, but the two fixture maps are not visually distinguishable and package provenance has no clearly identified player-facing surface. |

## Findings

### V056-01 — High — Results screen reuse keeps the branch picker disabled

- **Observed:** after Save, Retry, and a second victory in the branching fixture, the
  screen showed the placeholder “Choose the next chapter…”, Continue was disabled,
  the tester could not choose another destination, and Save could be pressed without
  a valid choice. `godot.log` records nine identical errors:
  `CampaignManager: pending victory requires a successor choice`, all from
  `MapResultsScreen._on_save()`.
- **Evidence:** a successful result commit disables `SuccessorPicker`
  (`scripts/ui/MapResultsScreen.gd:257-260`). The same screen is reused after the
  confirmed Retry branch, but `_refresh_result()` clears and rebuilds the picker
  without restoring `disabled = false` (`MapResultsScreen.gd:136-185`). Save remains
  enabled and reaches `_commit_result()` even when Continue correctly reflects that
  no branch is selected (`MapResultsScreen.gd:196-200, 220-255`).
- **Root cause:** transient widget state is not reset at the start of each Results
  presentation. The new Retry-after-Save flow introduced a second Results lifecycle
  on one screen instance, while tests cover campaign state and individual result
  commits but not this repeated UI lifecycle.
- **Recommended fix:** make `_refresh_result()` reset every transient control state,
  including `SuccessorPicker.disabled`, Save enabled state, selected placeholder, and
  button status. Disable Save as well as Continue until a required successor is
  selected. A missing choice is expected UI state, not an engine error; show a local
  instruction instead of calling `commit_pending_result()`.
- **Tests:** instantiate one real Results scene and run victory -> choose River -> Save
  -> confirmed Retry -> victory. Assert the rebuilt picker is enabled, Save/Continue
  are gated until a choice, Ridge can then be chosen, exactly one commit occurs, and
  no `push_error` is emitted. Repeat in the opposite branch order.

### V056-02 — High — installed slot loads bypass saved-catalogue validation

- **Observed:** after the branching-package run, `godot.log` contains 36 validation
  errors while loading shipped slot `node-04-escape-prep-1784923724018`: every normal
  shipped weapon/item is reported missing. This is the inverse of v0.5.5's package
  save failure: the active package catalogue is being used to validate a shipped save.
- **Evidence:** `load_slot()` calls `_read_save_document()`
  (`scripts/autoloads/SaveManager.gd:190-193`), which still calls
  `save.validate(_data_manager())` against whichever catalogue is active
  (`SaveManager.gd:500-522`). v0.5.6 added the correct two-stage
  `_validate_for_saved_content()` helper (`SaveManager.gd:525-550`), but its only
  production caller is `inspect_portable_save()` (`SaveManager.gd:251-263`). The
  focused test calls the private helper directly, so it did not prove `load_slot()`.
- **Root cause:** the fix implemented and unit-tested the helper, but did not wire the
  ordinary installed-slot read path to it. This leaves both package-to-shipped and
  shipped-to-package catalogue switches dependent on ambient active state.
- **Recommended fix:** have the one internal document-read path perform structural
  validation, temporarily select the trusted saved source, perform reference
  validation, and restore the prior source on every exit. Portable and installed
  loads should share that seam. Preserve the later permanent transactional activation
  in `GameState`; do not trust a package path stored in the save.
- **Tests:** exercise `load_slot()` itself, not the private helper: shipped -> package,
  package -> shipped, cold restart for each, missing package, invalid references, and
  restoration of the previously active catalogue after both success and failure.

### V056-03 — Medium — FileDialog still owns Escape before the intended guard

- **Observed:** printable Z/X behavior passes, but the first physical Escape closes
  the FileDialog instead of moving focus from the filename editor to the file tree.
- **Evidence:** `FileDialogInputGuard._input()` has the intended two-stage branch and
  calls `set_input_as_handled()` when `get_line_edit().has_focus()`
  (`scripts/ui/FileDialogInputGuard.gd:7-21`). Live Windows behavior proves that this
  condition/path does not intercept the event in the tested native dialog state.
- **Root cause status:** the exact engine-side ordering is not proven by these logs;
  likely candidates are that the filename LineEdit is not the actual focus owner at
  dispatch time or that native FileDialog cancel handling runs outside the embedded
  viewport path this script marks handled. Do not claim one without an instrumented
  Windows reproduction.
- **Recommended fix:** add a temporary focused-control/event trace to the dialog and
  reproduce all import/export call sites on Windows. Move interception to the earliest
  dialog/window callback that can demonstrably suppress the native close, explicitly
  focus the visible Tree, and only allow the next Escape to close. Remove the trace
  after the fix.
- **Tests:** engine-dispatch physical Escape with the real FileDialog open, assert it
  remains visible and Tree owns focus after press one, then closes after press two.

### V056-04 — Medium accessibility — Results cannot contain 200% content

- **Observed:** at 200% menu scale, “Victory!” is clipped beyond the top edge and the
  lower action list extends beyond the bottom edge. The returned screenshot makes the
  screen unusable without reducing scale.
- **Evidence:** `MapResultsScreen.tscn:20-80` authors a fixed 500x430 Panel with one
  unscrollable VBox containing title, summaries, successor UI, and four actions.
  `MenuScale` enlarges fonts and spacing, then recenters the target; the current test
  checks centering and crisp rendering at every scale but does not assert that each
  real screen's content stays inside the viewport
  (`scripts/tests/test_menu_scale.gd:27-49, 58-94`).
- **Root cause:** this screen's vertical information architecture cannot fit at the
  supported maximum scale, and the automated contract checks center rather than
  containment/reachability.
- **Recommended fix:** use a viewport-bounded Results layout. Prefer a scrollable
  summary column with a separate persistent action column at wide aspect ratios, then
  collapse to a single scrollable layout at narrow widths. Keep every action reachable
  by keyboard/controller. Add safe-area padding rather than merely shrinking type.
- **Tests:** at 100%-200% and representative 720p/1080p viewports, assert the title and
  focused action rectangle are inside the visible safe rect and every action remains
  reachable. Include both linear and branching Results content.

### V056-05 — Low visual — ornate OptionButton skin and text bounds disagree

- **Observed/requested:** selected dropdown labels overlap the left gold ornament;
  the long blue bar also makes the decorative treatment look stretched.
- **Evidence:** Settings OptionButtons inherit the generic Button style. The style is
  a 96x22 atlas region stretched across controls several hundred pixels wide, with
  14px texture margins and 12px content margins
  (`assets/themes/manasoul_ui.tres:18-50, 99-112`). The screenshot shows those generic
  margins do not reserve enough room for the OptionButton's ornate ends and arrow.
- **Recommended fix:** give OptionButton its own StyleBox/content margins and text
  alignment. Re-cut the atlas or adjust its true cap boundaries so only a plain center
  strip stretches; use a dedicated 9-slice if the current frame has decoration inside
  the stretch region. Verify normal, hover, pressed, disabled, and focus states.

### V056-06 — Low cleanup — obsolete v0.3.0 display trace remains enabled

- **Observed:** the retired New Game `[V030 TRACE]` error does not recur, and normal
  BUILD STAMP/logging works. However, both returned logs contain five
  `V030-DSP-TRACE` lines during window/maximize changes.
- **Evidence/root cause:** `SettingsManager.V030_RESIZE_TRACE_ENABLED` is still `true`
  and explicitly described as temporary v0.3.0 rerun logging
  (`scripts/autoloads/SettingsManager.gd:62-64, 744-760`).
- **Recommended fix:** remove the trace and its temporary state if the resize question
  is closed; otherwise gate it behind an explicit diagnostic setting that is off in
  normal playtest/release builds. Keep BUILD STAMP, runtime, and PLAYTEST CONTEXT logs.

## Comments, requests, and incomplete checks

### V056-07 — missing-package rollback instructions were not executable

The tester reasonably marked “don't know how to test this.” The next checklist must
name a disposable fixture, the exact installed-package directory or supported UI
action to remove it, the expected error, proof that the prior campaign/catalogue stays
active, and how to reinstall the fixture afterward. This remains **unknown**, not a
failure and not a pass.

### V056-08 — gamepad and hotplug remain unknown

No gamepad was available this round, so there can be no controller-connect line in
these logs. Extensive controller use in v0.5.5 is useful prior evidence, but it does
not verify the v0.5.6 hotplug/prompt-refresh checklist. Absence from this log is not
evidence that controller support broke. Carry the focused hotplug and prompt checks to
the rerun.

### V056-09 — branch/provenance feedback is too implicit

The log proves that River Pass loaded (`campaign_restored` and `node_launch` both name
`river_pass`), and the tester reports the Prep title changed correctly. The fixture
maps themselves looked indistinguishable, so visual confirmation of both branches was
weak. Make River and Ridge visibly distinct (terrain, objective, units, or a large
fixture-only label) and state those differences in the checklist.

The checklist also says package provenance should be “visible” without naming where.
Telemetry contains exact package id/version/path, but that is diagnostic evidence, not
necessarily player-facing UI. Decide whether the acceptance target is logs, Prep/run
details, or a future Campaign Library details surface, then write the exact expected
label. The Campaign Library is the recommended long-term player-facing home.

The tester's Results-layout suggestion is accepted as the recommended direction in
V056-04. The Settings padding/9-slice request is accepted as V056-05. The complete HUD
Layout editor controller scheme remains deliberately deferred to
`PLAN-UIUX-REUSE-PASS-2026-07-24` and is not a v0.5.6 rejection reason.

## Checklist disposition

- **Bundle integrity:** PASS; version, commit, timestamp, and fixtures match.
- **Package-owned exercised loads:** PASS for the path tested, but V056-02 proves the
  general installed-slot boundary is still broken and the missing-package case is
  unknown.
- **Long-list focus:** PASS for movement, visibility, repeat, and popup isolation in
  exercised screens. Successor lifecycle fails under V056-01.
- **Retry after Save:** core branch semantics PASS. The second Results presentation
  exposes V056-01.
- **FileDialog printable keys:** PASS. Two-stage Escape FAIL (V056-03).
- **Trace lifetime:** old New Game trace error absent; normal telemetry PASS; temporary
  display trace cleanup FAIL (V056-06).
- **Two-map connected flow:** PASS.
- **Branching flow:** partial; River launch/provenance is in the log, but repeated
  branch choice is blocked by V056-01 and visual branch distinction is weak.
- **100%/200% visual pass:** FAIL at 200% Results (V056-04) and Settings dropdown skin
  needs polish (V056-05).
- **Gamepad hotplug/prompt switching:** UNKNOWN (V056-08).
- **Quit/Continue/Retry/Rewind/Load/Main Menu smoke:** PASS as recorded.

## Prioritized action plan

1. Fix V056-01 and add the repeated Results lifecycle regression test.
2. Wire ordinary `load_slot()` through saved-content validation and add bidirectional,
   cold-start, and rollback tests (V056-02).
3. Instrument and fix the real Windows FileDialog Escape path (V056-03).
4. Make Results viewport-bounded at 200% and add real-screen containment tests
   (V056-04).
5. Correct the OptionButton skin/text margins and remove or explicitly gate temporary
   V030 display tracing (V056-05/06).
6. Cut a focused Windows rerun with exact missing-package instructions, visibly
   distinct branch fixtures, both branch orders, and a real gamepad hotplug pass.

## Positive observations

- The FocusNavigator repair holds focus visibility through long lists, repeat, and
  popup capture in the exercised keyboard flow.
- Retry-after-Save preserves the advanced save while correctly returning the active
  run to the completed battle at round zero; re-winning advances once.
- Two-Map Skirmish preserves roster, levels, inventory, gold, and campaign rules into
  map two.
- The return has strong provenance: build identity, runtime environment, package id,
  version, node launches, restores, restaging, and Retry branching are all logged.
- The catalogue failures are fail-closed rather than partially applying invalid state;
  the required correction is shared validation ordering, not weaker validation.
