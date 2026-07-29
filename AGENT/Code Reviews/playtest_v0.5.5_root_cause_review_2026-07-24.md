---
Type: code-review
Status: Known issue
Last verified: 2026-07-24
---

# v0.5.5 playtest return — triage and root-cause review

## Executive summary

**Verdict: REJECTED / fixes required.** The controller input-ordering repair worked for
Prep, Results, Defeat, and repeated Rewind opens, but the return contains one High
save/Continue failure, two High controller-visibility failures with a shared cause,
and a Medium script error. The supplied build and logs match version `0.5.5`, commit
`6651481`, built `2026-07-23T00:56:21Z`.

This is a document-only review. It diagnoses the build at `6651481`; no product fix
is included. Permanent returned evidence:

- `AGENT/Docs/playtests/playtest_checklist_v0.5.5_returned_2026-07-24.md`
- `AGENT/Docs/playtests/evidence/v0.5.5/godot.log`
- `AGENT/Docs/playtests/evidence/v0.5.5/godot2026-07-24T08.39.05.log`

## Triage matrix

| ID | Severity | Checklist source | Disposition |
|---|---|---|---|
| V055-01 | High | A7 / log | Imported-package campaign save cannot Continue because validation precedes package activation. |
| V055-02 | High | A1, A4 | Prep and Rewind focus can leave the focused control off-screen; both use the same broken `FocusNavigator` coordinate calculation. |
| V055-03 | Medium | log | Deferred New Game focus tracing dereferences a destroyed viewport. |
| V055-04 | Medium request | A5 | HUD editor has only panel-cycle/cancel controller bindings; toolbar actions and movement remain mouse-only. |
| V055-05 | Design decision | A2, A6 | Tester requests Retry remain available after Results Save; present code deliberately hides it after committing the result. |
| V055-06 | Checklist/fixture gap | A3 | Successor dropdown could not be exercised because no supplied campaign has a branching node. |
| V055-07 | UX request | B4 | Escape closes native FileDialog instead of leaving the filename field. Expected focus/cancel semantics need to be chosen. |

## Findings

### V055-01 — High — package saves are validated against the wrong catalogue

- **Observed:** Main Menu Continue displayed “Could not load the campaign save.
  Progress was not resumed.” The log reports six validation failures for
  `crossroads-prep-1784909459805`: both roster units reference
  `training_sword`, which the validator says is absent.
- **Evidence:** `SaveManager._read_save_document()` constructs the save and calls
  `save.validate(_data_manager())` before returning it
  (`scripts/autoloads/SaveManager.gd:502-522`). Inventory validation resolves IDs
  through the currently active `DataManager` (`scripts/save/SaveData.gd:88-110`).
  Package activation does not occur until the later
  `GameState.configure_campaign_resume()` path
  (`scripts/autoloads/GameState.gd:1042-1059`). The fixture itself does contain
  `training_sword` and its adapter test asserts that registration
  (`test_fixtures/campaign_packs/two_map_skirmish/data/catalogue.json`,
  `scripts/tests/test_two_map_campaign_fixture.gd:27`).
- **Root cause:** load is a two-stage operation, but content-dependent validation
  is performed in stage one while package identity is only acted on in stage two.
  A package save loaded after shipped content becomes active is rejected before it
  can select its own catalogue.
- **Recommended fix:** split structural parsing/validation from catalogue-dependent
  reference validation. Read and structurally validate the save, resolve its
  service-owned `package_id`/`package_version`, atomically stage that catalogue,
  then validate inventory/campaign/map IDs before committing live state. On any
  failure, restore the prior catalogue. Do not trust a path from the save.
- **Tests:** save a Tier-2 campaign, switch to shipped content/relaunch, then load
  both a between-map and mid-map save. Assert package activation precedes inventory
  validation, the exact roster restores, and failure leaves the former live
  catalogue/state unchanged. Existing tests validate capture and adapter content
  separately but miss this ordering boundary.

### V055-02 — High — shared scroll lookahead mixes viewport and content coordinates

- **Observed:** A1 focused `Unit_06` while it remained outside the Prep scroll
  viewport. A4 reports Rewind scroll jumping toward the middle while focus remains
  at the bottom, followed by focused rows becoming invisible.
- **Evidence:** both screens construct `FocusNavigator` with their
  `ScrollContainer` (`scripts/ui/PrepScreen.gd:24-25`,
  `scripts/ui/RewindSelector.gd:15-16`). `_apply_lookahead()` maps the control's
  global position through the scrolling viewport transform, producing a
  viewport-relative value, then compares/assigns it as though it were an absolute
  content offset (`scripts/shared/FocusNavigator.gd:106-119`). It also performs the
  correction immediately, while rebuilt/dynamic container geometry may still be
  settling. The newer `ModalScreen` implementation shows the correct shape:
  defer one frame, compute `content_top = current_scroll + row_y - viewport_y`,
  coalesce stale requests, then clamp (`scripts/ui/ModalScreen.gd:208-258`).
- **Root cause:** the reusable navigator reimplemented scroll lookahead without the
  coordinate conversion and deferred-layout protections already present in the
  modal base.
- **Recommended fix:** extract one shared scroll-reveal helper from the proven
  `ModalScreen` algorithm and use it from `FocusNavigator`; resolve a leaf control
  to its visual row, defer until layout settles, cancel stale requests, compute an
  absolute content-space target, and clamp against scrollbar range. Avoid two
  independent implementations.
- **Tests:** create a fixed-height scroll fixture with more rows than fit. Exercise
  down/up, wrap from controls below the scroll into a late row, dynamic row rebuild,
  and held repeat. After every step assert the focused row rectangle is visible and
  that direction-appropriate lookahead remains. Cover Prep and Rewind integration.

### V055-03 — Medium — deferred diagnostic trace outlives its viewport

- **Observed:** `SCRIPT ERROR: Cannot call method 'gui_get_focus_owner' on a null
  value` at `NewGameScreen.gd:538`, after Two-Map Skirmish starts.
- **Evidence:** `_v030_trace_focus_after_input()` is deferred, and
  `_v030_trace_focus()` calls `get_viewport().gui_get_focus_owner()` without first
  retaining/checking a viewport (`scripts/ui/NewGameScreen.gd:525-540`). Starting a
  campaign tears down the New Game screen before the deferred callback runs.
- **Root cause:** temporary v0.3.0 focus instrumentation remained enabled in a
  production playtest build and assumes node/viewport lifetime across a deferred
  callback.
- **Recommended fix:** remove the obsolete trace if its investigation is closed.
  Otherwise guard `is_inside_tree()` and a local non-null viewport before reading
  focus. A diagnostics path must never generate a runtime error.
- **Tests:** queue the trace and immediately change scene/free the screen; assert no
  error. Prefer testing the guard only if the trace remains.

### V055-04 — Medium request — HUD editor controller contract is incomplete

- **Observed/requested:** left/right panel selection works; tester explicitly asks
  for more complete controller bindings.
- **Evidence:** `_input()` handles only cancel and left/right panel cycling, then
  consumes every non-mouse event (`scripts/ui/HudLayoutEditor.gd:55-71`). Scale,
  Reset, Done, and Cancel are dynamic buttons whose behavior is wired only through
  `pressed` signals (`scripts/ui/HudLayoutEditor.gd:107-153`); panel dragging is
  mouse-motion-only (`scripts/ui/HudLayoutEditor.gd:233-246`).
- **Root cause:** the editor was designed as a mouse tool and later received only a
  reachability fallback, not a complete controller interaction model.
- **Recommended fix:** define an explicit edit mode: cycle panel, move panel in
  small grid increments (with held repeat), scale down/up, reset, done, and cancel,
  with visible controller prompts and a selected-action focus state. Preserve the
  hard modal input gate. This needs a UX decision before implementation because
  stick/d-pad ownership between panel selection and movement is ambiguous.
- **Tests:** controller-only open → select every panel → move/scale → reset → done,
  plus cancel rollback and proof that no input reaches the map/settings underneath.

### V055-05 — Design decision — Retry after Results Save

- **Observed/requested:** the tester twice asks that Save not remove Retry by
  default.
- **Evidence:** Save commits the pending campaign result before writing the manual
  slot (`scripts/ui/MapResultsScreen.gd:214-234`); commit then deliberately hides
  Retry (`scripts/ui/MapResultsScreen.gd:237-253`). This matches the v0.5.5
  checklist's stated “Save commits the result first” contract, so it is a design
  change request, not a regression against this round's specification.
- **Tradeoff:** retaining Retry after commit creates a branch: the written save and
  autosave remain advanced while the active run must be rolled back to the
  pre-result boundary. Simply leaving the button visible would retry from already
  committed campaign state and risks duplicated rewards/progression.
- **Recommendation:** owner decision required. Recommended behavior: keep Retry
  available but show a confirmation explaining that the saved advanced timeline is
  retained while the active run branches back to the pre-battle snapshot. Implement
  a transactional rollback from retained history; never merely unhide the button.

### V055-06 — Checklist/fixture gap — successor dropdown was unreachable

- **Observed:** tester could not find a successor dropdown.
- **Evidence:** Results only shows `SuccessorPicker` when
  `get_pending_successor_options()` returns more than one option
  (`scripts/ui/MapResultsScreen.gd:143-179`). A scan of all shipped campaign and
  test-fixture JSON at `6651481` found no `next_node_ids` array with more than one
  entry. The supplied Two-Map Skirmish is linear.
- **Root cause:** the checklist requested branching behavior without shipping a
  branching test campaign or exact setup instructions.
- **Recommended fix:** add a minimal deterministic three-node fixture whose first
  node branches to two successors, include it in the return package, and name the
  exact path through the fixture in the checklist. Add a headless UI test proving an
  open OptionButton prevents the host navigator from moving focus.

### V055-07 — UX request — Escape ownership inside FileDialog

- **Observed/requested:** printable X/Z input is fixed, but Escape closes the whole
  FileDialog instead of backing out of the filename field.
- **Evidence:** `FileDialogInputGuard` intercepts only printable mirrored action
  keys while the line edit owns focus (`scripts/ui/FileDialogInputGuard.gd:7-34`).
  Escape is non-printable and therefore retains native FileDialog cancel behavior.
- **Recommendation:** treat as an interaction decision, not an automatic fix.
  Recommended two-stage behavior: when the filename editor owns focus and has an
  active edit/selection, Escape clears selection or returns focus to the file list;
  a subsequent Escape closes the dialog. Provide visible focus after stage one and
  preserve one-press cancel when focus is already outside the editor.

## Checklist comments and unverified areas

- **A1:** core controller reachability/repeat passed; scroll visibility failed as
  V055-02. The tester's broader Prep refinement priority is already the appropriate
  long-term home; V055-02 remains a release fix because it hides focus.
- **A2:** single-step, repeat, wrap, confirm/cancel passed. The comment belongs to
  V055-05 rather than navigation.
- **A3:** unknown because the fixture could not expose it (V055-06), not a pass.
- **A4:** reopen/restore behavior passed; visibility/lookahead failed (V055-02).
- **A5:** toolbar buttons, panel cycling, save/cancel passed. Top-edge mouse drag was
  not checked, so it remains unknown. No toolbar anchor/size warnings appear in the
  returned logs. Controller expansion is V055-04.
- **A6:** authored actions and their tested semantics passed; V055-05 is a requested
  change to the approved Save/Retry relationship.
- **A7:** log sequences show single `campaign_restored` events with distinct
  `campaign_restaged` events; no duplicate pair was found. Results-only Return to
  Menu was not explicitly exercised. Continue itself failed as V055-01.
- **B1:** logs contain controller-connect lines but no disconnect line; hotplug is
  not verified. “No crash noticed” is insufficient to close this carry-forward.
- **B2:** every returned run begins with the matching BUILD STAMP and populated
  Windows runtime block. Campaign start/node launch/restore/resume context lines are
  present. This passes for exercised flows.
- **B3:** passed with a fresh 3400-gold Proving Grounds record and one Medal.
- **B4:** printable binding passed; Escape request is V055-07.
- **Part C:** every item is blank, so the regression sweep remains unknown. Do not
  infer acceptance from absence of comments.

## Prioritized action plan

1. Fix V055-01 and add package-save cold-load ordering tests.
2. Replace `FocusNavigator` lookahead with the shared, deferred content-coordinate
   algorithm; add visibility tests for Prep and Rewind (V055-02).
3. Remove or lifetime-guard New Game focus diagnostics (V055-03).
4. Add the branching fixture and rerun A3; rerun A1/A4 and the blank Part C sweep.
5. Obtain owner decisions for Retry-after-Save (V055-05), HUD controller interaction
   (V055-04), and two-stage FileDialog Escape (V055-07), then schedule them without
   disguising requests as regression fixes.

## Positive observations

- The v0.5.5 input-stage repair restored controller access, exact single stepping,
  held repeat, and wrap on the targeted major screens.
- Rewind can be reopened repeatedly and restores off-screen boundaries correctly;
  the remaining defect is visual focus tracking rather than state corruption.
- Provenance is unusually strong: every run is traceable to the exact build, runtime
  environment, controller, campaign/package, and restore event.
- The package failure is fail-closed: invalid-against-current-catalogue data was not
  partially applied. The needed correction is ordering plus rollback, not weaker
  validation.
