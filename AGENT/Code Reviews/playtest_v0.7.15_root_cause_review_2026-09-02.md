---
Role: dated
Type: code_review
Status: In review - owner walkthrough pending
Last verified: 2026-09-03
---

# v0.7.15 Windows return — findings and root-cause review

## Executive summary

The returned executable is the intended `0.7.15/7a89c5e9` build and most of the
campaign-library, missing-pack recovery, backup/restore, Compact Settings, physical
controller, and native slider paths passed. The candidate is not ready to promote: the
v1-to-v2 migration fixture fails its advertised migration, the fullscreen phase banner
uses the wrong coordinate space and remains visible after a resumed load, and Load Game
and Campaign Library fight over focus when opened as nested modals. Full save slots and
ordinary free-roam Prep also need better in-context escape/replacement flows.

This is a targeted, document-only review of the returned packet, not a full-project
audit. Findings are held by tracker row
`V0715-RETURN-ROOT-CAUSE-REVIEW-2026-09-02` until the owner walkthrough decides the
implementation scope. No product code was changed.

## Evidence reviewed

- the completed `PLAYTEST_CHECKLIST.md`, all 15 PNGs, six non-empty Godot log runs, two
  exported JSON saves, and
  `campaign-backup.zip` in `Incoming/v0.7.15 return/`;
- the exact candidate at `agent/playtest-release-v0.7.15` / `7a89c5e9`;
- `playtest_checklist_v0.7.15.md` and `playtest_build_v0.7.15.md` from that commit;
- the phase-banner, responsive Settings, portable-save, migration, and backup/restore
  implementations and their focused tests.

The checklist was added on 2026-09-03 and supersedes the review's initial packet-gap
assessment. Per owner instruction, anything not called out in the checklist is accepted
as matching the Playwright baseline; absent screenshots and loose log-directory layout
are not findings. The empty `godot2026-09-02T16.00.12.log` supplies no additional
evidence.

## Verification performed

- `python3 AGENT/Docs/check_docs.py`: PASS.
- `bash run_tests.sh`: 162 of 164 suites green; `test_session8_pack_proof` and
  `test_session9_pack_proof` failed.
- `bash run_tests.sh --rerun-failed`: both failures reproduced serially, so they are not
  parallel-run contention. They are authored FE-pack adopter proofs unrelated to this
  document-only diff. This review does not diagnose or repair them, but the red baseline
  prevents a normal verified push of this branch until their owning work resolves them.
- Exact-export Playwright investigation (2026-09-03), using the shipped web artifact
  bound to source `7a89c5e9`, produced machine-readable state and screenshots under
  `builds/web-harness/v0715-investigation/`:
  - Settings at 360x640 remained geometrically contained, but bridge text metrics found
    14 non-fitting controls at 1x and 79 at 2x; the 3840x2160 case had zero. This proves
    the current containment check can pass while labels are no longer comprehensible.
  - Load Game -> Manage Campaigns left the bridge reporting Load Game as the active modal
    while focus belonged to the absolute Campaign Library path. Arrow, Tab, Shift+Tab,
    and ArrowUp all returned to Campaign Library's Import Package button, and activation
    did not open a file chooser.
  - The returned suspend save exposed `Import into 2.0.0`; activating it produced
    `migration_source_invalid` plus four browser-console destination-missing errors for
    the version-qualified map and three runtime unit IDs. The returned prep artifact did
    not remain as a selectable migration row in the clean v2 profile, consistent with
    the native `migration_source_identity_mismatch` result.
  - A clean browser could not load the returned suspend against the staged v1 artifact,
    and a content-scale-3 fresh launch did not reach the next screen through the bridge's
    coordinate-driven click. Consequently Playwright did not confirm the resumed-banner
    timing failure; the native screenshot/checklist and code-order analysis remain the
    evidence for that part. This limitation is recorded rather than counted as a pass.

## Returned issues and comments

| ID | Source | Returned observation | Disposition |
|---|---|---|---|
| V0715-01 | checklist §5 and `phase banner not disapearing and not cenetered.png` | After loading a battle, the blue banner remained for the rest of the player phase. At phase end it disappeared, the red banner replaced it, and subsequent banner behavior was normal. At fullscreen the blue banner also occupies only the left part of the window and is not centred on the map. | Release blocker; resumed-load lifecycle and coordinate-space defect confirmed. |
| V0715-02 | `port v1 suspend save to v2.png`, `port v1 to v2 prep save.png`, `godota.log` | Both attempted v1-to-v2 ports are blocked. One reports `migration_source_invalid`; the other reports `migration_source_identity_mismatch`. The log additionally records missing destination map/unit references eight times. | Release blocker; fixture/gate defect confirmed. |
| V0715-03 | checklist §2 and five narrow Settings captures | At 1x, the panel and bottom controls remain contained. At larger menu scale, labels and selectors are cut off. The tester recommends putting the label and selector on separate rows so both can remain readable. Scrolling and focus traversal pass. | Confirmed usability defect and requested layout direction. |
| V0715-04 | `sliders.png` | Native Windows shows trough, fill, both endcaps, thumb, and values at 0/50/100. The very wide border texture visibly stretches instead of tiling. | Functional pass; known art-quality comment remains. |
| V0715-05 | checklist §6 and missing-pack screenshots | Import retains the save as `imported_01`, disables loading, names the missing `v076_migration_fixture` 1.0.0 pack, and offers Manage Campaigns/Retry. Retry does not mutate progress. | Recovery state passes; its nested Manage Campaigns action has the separate V0715-06 focus defect. |
| PASS-01 | campaign-library/backup screenshots and backup ZIP | Proving Grounds imports; selecting a campaign ZIP as a restore artifact is rejected before commit; backup restore reports two restored saves and skips one already-installed package. The ZIP contains one pack and two digest-listed saves. | Pass. `Campaign packages installed: 0` is correct because the one archived pack was already installed, and the dialog explains this. |
| PASS-02 | `godot3.log`, `godotb.log`, returned saves | Proving Grounds restore reaches `node_02_seize`; v2 fixture and Proving Grounds saves produce `campaign_restored`, `node_resumed`, and `campaign_restaged` contexts. | Pass for persistence/resume paths represented by these logs. |
| V0715-06 | checklist §6 | From a disabled save, Manage Campaigns opens, but focus is continually forced back to Import Package; it can move for one frame, the file picker does not open, and Cancel is the only working return. | High interaction defect; two visible modal screens compete for focus. |
| V0715-07 | checklist §5 | When all campaign-save slots are full, saving tells the player to delete a slot from Load Game, which requires leaving/closing the active pack flow. The tester requests an in-context picker and confirmation for the save to replace. | Medium workflow defect; requested change is appropriate. |
| V0715-08 | checklist §5 | A campaign-map save resumed at Chapter 2 Prep. This works for the current linear next-node case, but ordinary Prep offers no return to the campaign map; only the special cleared-node revisit path does. | Medium free-roam navigation gap; not a data-loss defect in this round. |
| V0715-09 | checklist §5 | Make Proving Grounds Chapter 1 much smaller/easier—one enemy with no defenses and 1 HP—so repeated infrastructure playtests complete faster. | Low test-content/balance request; implement in the authored pack, not engine code. |
| PASS-03 | completed checklist | Build identity/checksum, Compact containment, scrolling/focus return, native sliders, keyboard/Xbox dropdown wrap/select/cancel, Proving Grounds import/progression/revisit escape, map Settings return, empty-profile import, backup/restore, terrain/input, renewal ticking, suspend/reload HP, and compatibility checks passed. | Accepted positive evidence. Unmarked evidence is assumed equal to Playwright by owner instruction. |

## Issues found and root causes

### [High] V0715-01 — Phase banner uses logical viewport width as a fullscreen canvas width

- **Location:** `scripts/ui/PhaseBanner.gd:13-16,30-33,49-67`;
  `scenes/ui/PhaseBanner.tscn:13-28`; `scenes/core/GameMap.tscn:104-107`.
- **Problem:** The screenshot is 3837 px wide, but the banner finishes around the first
  third of the physical window and its supposedly centred label is correspondingly left
  of the displayed map. The screenshot filename also reports that the banner does not
  disappear.
- **Root cause:** The August fix replaced a fixed 1280-pixel panel with
  `get_viewport().get_visible_rect().size.x`, while the banner lives on a root
  `CanvasLayer`. With Godot content scaling, the root viewport can remain roughly 1280
  logical units while the native window is 3840 physical pixels. The code therefore
  repeats the old 1280-wide result at fullscreen under a different source of truth.
  `CENTER_X = 0` then centres the label inside that undersized panel, not inside the
  displayed map or window. There is no phase-banner test at all, so the regression was
  outside the 159-suite gate.
- **Resumed-load lifecycle evidence:** The completed checklist narrows this to the opening
  blue phase after a load: it remained until phase end, then the red banner and later
  transitions behaved normally. `TurnManager.start_map_from_suspend()` restores the saved
  phase by calling `GameState.set_phase()` during `GameMap` setup
  (`scripts/core/TurnManager.gd:147-172`), which sends an ordinary phase-transition
  animation through a scene that is still restoring. The banner has no explicit idle
  visibility state, stored tween, completion reset, or distinction between “restore the
  current phase label” and “announce a new phase.” That makes load ordering the likely
  lifetime trigger. A 2026-09-03 exact-export Playwright attempt could not make the
  returned suspend loadable against the clean staged v1 profile, so it did not observe
  tween state over time. The exact reason the opening tween fails to complete remains a
  hypothesis requiring instrumentation; the checklist proves the scope, not the internal
  stalled state. Confidence is therefore high for the width defect and medium for the
  persistence mechanism.
- **Recommended fix:** Make one responsive layout owner compute the banner rectangle in
  the same coordinate space as the `CanvasLayer`. Prefer full-rect anchors for the
  banner host and tween a child wrapper or a normalized progress/transform, instead of
  manually copying a viewport width into a free-positioned panel. Store the active
  tween, kill it before restarting, and on completion explicitly hide/reset the banner.
  Restore the current phase without playing a transition, or defer the announcement
  until map setup is complete; do not treat deserialization as a new phase. Recompute the
  offscreen endpoints on resize. If the intended centre is the playable map rather than
  the whole safe viewport, obtain that rect from the map layout owner rather than
  guessing from window dimensions.
- **Tests:** Add a focused `PhaseBanner` suite covering 1280x720, fullscreen/content
  scale 3, resize during animation, two rapid phase changes, final hidden/offscreen
  state after 1.4 seconds, and label centre against the selected layout rect. Retain one
  native fullscreen visual check because logical geometry alone missed this defect.
- **Tradeoff:** A wrapper/normalized tween is a slightly larger change than swapping one
  width call, but it removes the logical-versus-physical coordinate leak instead of
  applying a second resolution-specific patch.

### [High] V0715-02 — Generated v1/v2 fixtures declare a migration edge without a usable transformation

- **Location:** `scripts/tools/build_migration_fixtures.gd:27-74,78-105,156-179`;
  `scripts/save/SaveMigrationService.gd:665-685`; returned `godota.log:27-42`.
- **Problem:** The exact fixtures created to validate package-scoped migration cannot
  migrate both returned v1 saves. The UI reports source-validation/identity failures,
  while the log also identifies pass-through references that do not exist in the v2
  destination: the version-qualified `skirmish_02` map URI and `red_02_a/b/c` units.
- **Root cause:** The builder copies the same source data into v1 and v2 and changes only
  the manifest version. It then creates empty alias dictionaries for every family. That
  is insufficient for version-qualified map references and for runtime units that are
  not valid destination registry entries. Its proof stops after loading the catalogues,
  parsing the manifest, exporting, and installing/launching the packs. It never migrates
  a real prep save and suspend save through `SaveMigrationService` and validates the
  resulting copy. The pack gate therefore proved launchability, not the feature the
  fixture claims to test.
- **Playwright confirmation:** Against the exact export, the suspend row offered the
  declared v1-to-v2 action but production migration returned `migration_source_invalid`.
  Chromium also captured `migration_destination_missing` for
  `campaign-pack://v076_migration_fixture/1.0.0/skirmish_02` and `red_02_a/b/c`. This
  independently confirms that the declaration, persisted references, and destination
  catalogue do not form a usable migration edge.
- **Recommended fix:** Give v2 an intentional, minimal content delta and explicit aliases
  for every changed persisted reference. Decide separately how placed/runtime unit IDs
  are validated: either map them to stable destination identities, or classify these
  instance IDs as save-owned pass-through values that are validated with their owning
  map rather than against a global unit registry. After staging both packs, the builder
  must generate/load representative v1 between-map and suspend saves, run the actual
  migration service, assert zero errors, assert expected renamed/pass-through counts,
  validate the new v2 save, and preserve the v1 original. The release bundle gate should
  consume that receipt.
- **Tests:** Add negative cases for stale fingerprints and undeclared aliases, plus
  end-to-end positive tests for both returned save shapes. Assert UI classification too:
  invalid source, identity mismatch, missing destination, and successful migrated-copy
  preview must not collapse into one generic result.
- **Tradeoff:** A meaningful fixture needs maintained v1/v2 expectations. That cost is
  warranted because identical packs with empty aliases exercise almost none of the
  migration contract and already produced two unusable release rounds.

### [Medium] V0715-03 — Compact 2x density preserves containment by sacrificing comprehension

- **Location:** `scripts/ui/SettingsScreen.gd:1224-1279`;
  `scenes/ui/SettingsScreen.tscn:23,57-362`.
- **Problem:** The 2x captures technically stay inside the viewport, but several labels
  lose their distinguishing words and the keybinding area displays very little context.
  This meets a geometric containment assertion while weakening the setting's usability.
- **Root cause:** Compact mode uses fixed narrow label columns, clears control minima,
  and enables ellipsis. Menu scale then enlarges type and controls inside the same
  approximately 360-pixel physical width. The implementation has no semantic
  readability threshold; it can only trade text away until the geometry fits.
- **Playwright confirmation:** At 360x640 the same geometry gate reported containment,
  while the bridge measured 14 text-fit failures at 1x and 79 at 2x. Examples at 2x
  include `Master Volume` (152 px measured in 112 px), `Movement Speed` (168/112),
  `Phase Banner` (139/112), keybinding descriptions (up to 351/80), and slider-value
  labels with only one pixel of available width. At 3840x2160 there were none.
- **Recommended fix:** Follow the tester's requested responsive pattern: switch Settings
  rows to a two-line/vertical layout at Compact width when the selected menu scale cannot
  preserve both columns. Put the full label above its slider/selector and let that control
  use the complete second row. This preserves the selected type size and avoids ad-hoc
  abbreviations. A disclosed effective-scale cap remains the fallback if vertical rows
  make the screen impractically long; do not widen the panel beyond the supported
  viewport.
- **Tests:** Assert full required labels (or an accessible full-name tooltip/announcement)
  at the supported Compact width for each menu scale, not just panel bounds.
- **Tradeoff:** Capping scale weakens the literal 2x promise; vertical rows increase
  scrolling. The vertical layout better preserves accessibility if 2x must remain real.

### [Low] V0715-04 — Slider border texture stretches across wide tracks

- **Location:** the HSlider theme assets referenced by `assets/themes/manasoul_ui.tres`
  (visual evidence in `sliders.png`).
- **Problem:** The state is readable and all required pieces render, but decorative
  pixels visibly elongate across a 4K-width trough. This was explicitly listed as known
  in the v0.7.15 checklist and is reconfirmed, not newly introduced.
- **Root cause:** The theme stretches a decorative texture over arbitrary width rather
  than preserving fixed-size endcaps and tiling/stretching only a deliberately scalable
  centre strip.
- **Recommended fix:** Use a `StyleBoxTexture` with correct patch margins and an
  intentional axis-stretch mode, or split endcaps from a tileable centre/fill asset.
  Verify 0/50/100, hover, focus, disabled, 1x/2x/3x, and 360/1280/3840 widths.
- **Tradeoff:** Asset slicing takes art review and should not block functional release if
  the owner accepts the current appearance.

### [Medium] V0715-05 — Expected disabled-save validation is emitted as engine ERROR spam

- **Location:** returned `godota.log:27-42`; the save validation path that calls
  `push_error` for `migration_destination_missing` diagnostics.
- **Problem:** The checklist asks for no migration errors, but an intentionally retained,
  disabled v1 save generates eight red engine errors during ordinary row rebuilds. The
  same four diagnostics appear twice, making real faults harder to spot and making the
  acceptance criterion self-contradictory.
- **Root cause:** A recoverable content-state diagnostic and an unexpected engine failure
  share the same logging severity. Rebuilding/validating the row repeats the report with
  no deduplication.
- **Recommended fix:** Return structured diagnostics to the Load Game UI without
  `push_error` for expected disabled/migration-preview states. Emit one warning or
  telemetry record per slot/state transition if operational visibility is needed;
  reserve `push_error` for malformed data or a contract violation. Cache or deduplicate
  identical validation results during one row rebuild.
- **Tradeoff:** Lower severity can hide a genuine fixture regression unless the
  end-to-end migration gate from V0715-02 becomes authoritative first.

### [High] V0715-06 — Nested Load Game and Campaign Library modals compete for focus

- **Location:** `scripts/ui/LoadGameScreen.gd:254-255`;
  `scripts/ui/MainMenu.gd:389-402`; `scripts/ui/CampaignLibraryScreen.gd:63-66`;
  shared `scripts/ui/ModalScreen.gd` focus containment.
- **Problem:** Manage Campaigns opens from a disabled save, but focus is locked onto
  Import Package. It can move for one frame before snapping back, and activating Import
  does not show the file picker. Cancel still returns to Load Game.
- **Root cause:** `_on_manage_campaigns_requested()` opens Campaign Library without
  closing or hiding Load Game. Both remain visible modal screens and both retain the
  shared focus-containment behavior, so each can reclaim focus into its own subtree.
  `_return_to_load_game` remembers only where Back goes; it is not a modal-stack owner.
- **Playwright confirmation:** This is reproduced directly, not inferred. The bridge kept
  `screen: load-game` and `modalStack: [load-game]` while its focus owner was
  `/root/MainMenu/CampaignLibraryScreen/Panel/VBox/BtnImport`. Five navigation inputs
  could not leave that button, and clicking it raised no browser file chooser. The
  contradictory active-modal and focus-owner paths are concrete evidence that two
  visible modal controllers remain active together.
- **Recommended fix:** Main Menu should own one modal stack. Suspend/hide Load Game before
  opening Campaign Library, remember the selected save and focused recovery action, then
  reopen/restore them when Campaign Library closes. At minimum, only the topmost visible
  modal may run focus containment or receive input. Do not fix this with a delay or
  repeated `grab_focus()`, which would preserve the race.
- **Tests:** Open Campaign Library from a disabled row, traverse every control, activate
  Import, cancel the native file dialog, return, and assert the original save/action is
  selected. Cover keyboard and controller input and assert only one modal is input-active.
- **Tradeoff:** A reusable modal stack is broader than this one path but prevents the same
  focus race elsewhere. A local hide/reopen fix is acceptable if it preserves selection.

### [Medium] V0715-07 — Full campaign-save pools cannot replace a different slot in context

- **Location:** `scripts/ui/OverworldScreen.gd:107-141,145-171`;
  `scripts/ui/PrepScreen.gd:295-337,340-350`.
- **Problem:** Saving can overwrite only a slot with the same generated label. If all
  slots are occupied by other labels, the player is told to delete one in Load Game,
  which is unreachable without leaving the active campaign flow.
- **Root cause:** Both screens implement a binary path: replace `_same_label_slot_id()` or
  allocate `_next_manual_slot_id()`. The budget-full branch has no selection UI even
  though `SaveManager` supports atomic replacement when an existing manual slot ID is
  supplied.
- **Recommended fix:** Extract one reusable manual-save picker. When the pool is full,
  show the eligible same-class slots with label/package/campaign/location/timestamp,
  default to the oldest or current-scope slot without confirming automatically, and
  require explicit replacement confirmation. Pass the chosen slot ID through the
  existing atomic overwrite path. Keep automatic/autosave slots ineligible.
- **Tests:** Full pool with mixed campaigns, cancel, confirm one replacement, failed-write
  rollback, keyboard/controller focus, and preservation of unselected slots.
- **Tradeoff:** This adds a modal to Save, but it removes a forced process exit and makes
  the existing bounded-slot policy usable.

### [Medium] V0715-08 — Ordinary free-roam Prep has no route back to the campaign map

- **Location:** `scripts/ui/PrepScreen.gd:280-292`; campaign resume routing in
  `scripts/autoloads/GameState.gd:1047-1118`.
- **Problem:** The returned campaign-map save resumed at Chapter 2 Prep. That is usable
  today, but the only Prep escape is gated by `_is_revisited_hub()`. A normal current-node
  Prep in a free-roam campaign cannot return to the campaign map, which will become a
  trap once choosing among revisitable/current nodes matters.
- **Root cause:** Return-to-map was implemented narrowly as the v0.7.10 cleared-node
  dead-end repair. It models “revisited hub” rather than the broader navigation contract
  “Prep was entered from a free-roam campaign map.” Save resume restores the destination
  Prep but does not retain/expose a navigation origin that would authorize Back.
- **Recommended fix:** Record a non-save-critical launch origin (`campaign_map` versus
  direct/linear) in campaign runtime state and expose Return to Campaign Map for any
  free-roam Prep entered from that map, including between-map save resumes. Returning
  must abandon only uncommitted deployment edits and must not mark/clear the node.
- **Tests:** Fresh node, revisited cleared node, and resumed between-map save in free-roam;
  confirm Return/Cancel work and linear campaigns do not gain an invalid map route.
- **Tradeoff:** An always-visible Back action changes Prep flow, so scope it by traversal
  mode/origin rather than making it universal.

### [Low] V0715-09 — Proving Grounds Chapter 1 is too slow for repeated acceptance runs

- **Location:** the authored Proving Grounds Chapter 1 map in
  `Project_Prometheus_Campaign_Pack_0` (exact pack path to confirm during implementation).
- **Problem:** The tester requests a much smaller/easier opening battle—one enemy, zero
  defenses, 1 HP—so campaign/save infrastructure rounds do not spend most of their time
  clearing an unrelated balance scenario.
- **Root cause:** One authored campaign currently is serving both gameplay demonstration
  and high-frequency acceptance-fixture roles. Those goals have different pacing needs.
- **Recommended fix:** Prefer a dedicated minimal acceptance campaign/map in the pack and
  keep the real Proving Grounds balance meaningful. If Chapter 1 is intentionally the
  acceptance fixture, apply the requested one-enemy/1-HP/zero-defense tuning there and
  update the pack tests. Do not hardcode a test shortcut in the engine.
- **Tradeoff:** A separate campaign adds authored content but avoids distorting the public
  example's balance. Directly shrinking Chapter 1 is cheaper and matches the explicit
  request.

## Positive observations

1. The exact build identity is present in every non-empty log and agrees with the
   candidate (`0.7.15/7a89c5e9`), so the defects are attributable to the intended build.
2. Missing-pack import is non-destructive: the save is kept, clearly disabled, identifies
   the required package/version, and exposes Manage Campaigns and Retry.
3. Backup restore is transactional for the wrong-artifact case, and the successful
   summary correctly separates newly installed packages from already-installed skips.
4. Returned contexts show real campaign restore/resume/restage for both the v2 fixture
   and Proving Grounds, including fullscreen native Windows/NVIDIA runs.
5. Compact Settings no longer escapes the window, the dropdown popup remains on-screen,
   and native slider state visibility now agrees with the browser precheck.
6. Keyboard and physical Xbox-controller dropdown operation passes open, wrap/skip,
   selection, Escape/cancel, and sensible focus return on native Windows.
7. Cleared Chapter 1 now returns to the campaign map without the v0.7.10 dead end;
   Chapter 2 and its later prerequisite text are reachable; campaign-map Settings returns
   focus correctly.
8. Renewal and compatibility smoke passed: HP moved 16→6 after attack, 6→7 at the next
   phase, suspend/reload restored 7, and the following phase advanced it to 8.

## Architectural observations

- Responsive UI has two competing coordinate systems: root viewport logical geometry
  and native/displayed canvas geometry. The phase banner bypasses the existing responsive
  layout ownership and manually copies a width, which is why a prior resolution fix
  regressed at another scale.
- The migration fixture pipeline validates endpoints and pack launch, but not the edge
  between them. A migration fixture is only credible when a persisted v1 artifact is
  transformed and accepted as v2 by the production save path.
- Several automated UI checks grade containment rather than task comprehension. Compact
  2x demonstrates that a panel can pass bounds checks while its labels become ambiguous.
- Modal navigation is coordinated with booleans such as `_return_to_load_game` while
  focus containment remains local to each screen. Nested overlays need a single topmost
  input/focus owner, not independent visible modals.
- Prep's campaign-map escape is expressed as a cleared-node exception, while save resume
  exposes the need for a traversal/origin capability. Navigation should follow how Prep
  was entered, not only whether its node was previously cleared.

## Root-cause confidence after Playwright investigation

| Finding | Confidence | Basis and remaining uncertainty |
|---|---|---|
| V0715-01 banner width | High | Native 3840 capture matches the manual logical-width assignment on a root CanvasLayer. Playwright did not reproduce the native display coordinate conversion, so the replacement must still be validated on Windows fullscreen. |
| V0715-01 resumed persistence | Medium | Restore calls the ordinary phase-transition signal during map setup, and the banner has no explicit idle/reset contract. The exact stalled-tween state was not observable because the returned suspend was not loadable in the clean web profile. Instrument before choosing the lifecycle patch. |
| V0715-02 migration fixtures | Very high | Builder inspection shows identical endpoints/empty aliases/no migration proof; exact-export Playwright reproduces the suspend failure and missing destination identities. The correct policy for runtime unit IDs still needs an owner decision. |
| V0715-03 Compact Settings | Very high | Exact-export bridge metrics quantify 14/79 text-fit failures while containment passes. Vertical rows are the best current implementation direction, though the supported density/scrolling tradeoff is a product choice. |
| V0715-04 slider art | High | The native image and theme construction explain stretching. This is an art-quality diagnosis, not a functional defect. |
| V0715-05 error severity/duplication | High | Exact-export console reproduces the four expected validation conditions at error severity; the returned native log shows the repeated rebuild. Deduplication boundary is an implementation choice. |
| V0715-06 nested focus | Very high | Playwright directly records Load Game as active modal while Campaign Library owns focus, repeated focus capture, and no file chooser. A single topmost modal owner is the durable fix. |
| V0715-07 full save pool | High | Both callers have only same-label replacement or next-free allocation, although the manager already accepts an existing slot ID. Picker presentation/default selection remains product design. |
| V0715-08 Prep return | High | Code gates escape on revisited hub rather than free-roam navigation origin. Whether resumed Prep should always return to the map remains product policy. |
| V0715-09 faster Chapter 1 | Not a defect root cause | This is an explicit content/productivity request. A dedicated acceptance map avoids mixing demonstration balance with repetitive infrastructure proof; directly shrinking Chapter 1 is cheaper. |

The investigation materially raises confidence for migration, Compact Settings, expected
diagnostic severity, and nested-modal focus. It does **not** justify claiming a proven
internal cause for the resumed banner persistence. That item should remain an instrumented
reproduction task rather than be patched solely from the current hypothesis.

## Prioritized action plan for the next session

1. Reject promotion/tagging of v0.7.15 pending V0715-01, V0715-02, and V0715-06.
2. Walk through the owner choices: banner centre target (safe viewport or playable map),
   approve the tester-requested vertical Compact rows, choose local modal suspension or a
   shared modal stack, decide Prep return scope, choose save-replacement picker behavior,
   and decide whether the slider art or test-map balance changes block the next release.
3. Instrument the phase banner's visibility, tween identity/progress, viewport transform,
   and phase signal during a native resumed load. Reproduce elapsed-time plus
   resize/rapid-phase cases; then implement one coordinate-space-aware banner fix plus a
   focused test suite. Do not conflate the proven width defect with the still-hypothetical
   persistence mechanism.
4. Repair the migration fixture into a real v1→v2 delta and make generation execute both
   prep and suspend saves through the production migration service.
5. Fix Load Game → Campaign Library as one modal stack/suspension flow and retain the
   originating save/action focus on return.
6. Add an in-context, confirmed manual-slot replacement picker shared by campaign-map and
   Prep saves; add free-roam Prep return based on navigation origin.
7. Implement vertical Compact Settings rows and the chosen authored-pack balance approach.
8. Downgrade/deduplicate expected disabled-save diagnostics only after the end-to-end
   migration gate reliably distinguishes expected recovery state from broken fixtures.
9. Cut a focused replacement round containing banner, migration, nested-modal focus,
   full-slot replacement, Prep return, and the accepted UI/content changes. Do not repeat
   the already-passing dropdown, slider, backup/restore, renewal, or compatibility suites
   beyond regression smoke.

## Delta from v0.7.13 / intended v0.7.15 scope

- **Fixed/reconfirmed:** Compact Settings containment; native slider components visible;
  keyboard/Xbox dropdown behavior; free-roam Proving Grounds import, progression and
  cleared-node return; campaign-map Settings focus return; missing-pack save retention;
  backup/restore; renewal/suspend compatibility; v2 and Proving Grounds resume paths.
- **Still known:** slider border stretching and no visible Menu Density effect on the
  Settings screen itself.
- **Newly exposed:** fullscreen/resumed-load phase-banner coordinate/lifetime defect;
  generated migration pair cannot migrate returned prep/suspend artifacts; nested Load
  Game/Campaign Library focus conflict; unusable full-slot save workflow; missing ordinary
  free-roam Prep return; expected disabled-save validation pollutes logs at error severity.
- **Requested improvements:** vertical Compact label/control rows and a deliberately fast
  Proving Grounds Chapter 1 (or a separate minimal acceptance campaign).
- **Evidence disposition corrected 2026-09-03:** the completed checklist was added. Per
  owner instruction, unremarked items are accepted as matching Playwright; the earlier
  packet-completeness concern is withdrawn.
- **Root-cause confidence corrected 2026-09-03:** exact-export Playwright directly
  confirmed the Compact semantic-fit gap, suspend migration failure/error diagnostics,
  and nested-modal ownership conflict. It could not exercise the returned resumed battle
  in a clean web profile, so banner persistence is explicitly retained as a medium-
  confidence mechanism hypothesis rather than a proven root cause.
