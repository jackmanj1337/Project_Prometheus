---
Role: dated
Type: code_review
Status: Ratified 2026-09-05 - owner walkthrough complete
Last verified: 2026-09-05
---

# v0.7.16 Windows return — findings and root-cause review

## Executive summary

The returned executable is the intended `0.7.16/9d7ba7a5` build, and the round did what it
was designed to do. Sections 3, 5 and 6 pass; the prologue, nested dialogs, the
replacement picker and both Prep returns all work on a real display for the first time.
The `BANNER_TRACE` instrumentation added for this round produced the measurement it
existed to capture, and that measurement — combined with the tester's own diagnosis in
§2.4 — resolves the phase banner completely.

Three defects remain, and **all three are now reproduced headlessly on Linux, from the
tester's own returned save, against code byte-identical to the shipped build**. No
Playwright, no Windows, no browser was required. This review therefore reports proven
causes rather than hypotheses:

1. The phase banner's **resting position is never re-derived on window resize**. This is
   one defect, not the two that v0.7.15 recorded — the "undersized panel at fullscreen"
   half was the same ghost, misread. Arithmetic below matches both returned screenshots
   to within two pixels.
2. `SaveManager.save_slot()` re-validates against **whatever content session happens to be
   active**, and both the import commit and the migration commit call it from the Main
   Menu, where no pack is active. This is the single cause of every save failure in §7.
3. `SaveMigrationService.preview()` rewrites the save's `source` identity block but not its
   `campaign` block, so a migrated save carries a **v2 version with a v1 fingerprint** and
   can never be loaded. This is latent behind (2): fixing (2) alone would produce saves
   that import successfully and then refuse to open.

Two smaller confirmed defects follow from the tester's §4 and §6 notes.

This is a targeted review of the returned packet plus the implicated code paths, not a
full-project audit. No product code was changed. Findings are held by tracker row
`V0716-RETURN-ROOT-CAUSE-REVIEW-2026-09-05` until the owner walkthrough decides the
implementation scope.

## Evidence reviewed

- the completed `PLAYTEST_CHECKLIST.md`, all 11 PNGs, five Godot logs and two exported
  JSON saves in `Incoming/v0.7.16 return/`;
- `Incoming/v0.7.15 return/phase banner not disapearing and not cenetered.png`,
  re-measured (it turns out to show the same defect as this round's capture);
- the shipped candidate `agent/playtest-release-v0.7.16` / `9d7ba7a5`. Every file cited
  below is byte-identical between that commit and the reviewed checkout, so the probe
  results describe the executable the tester ran;
- `scripts/ui/PhaseBanner.gd`, `scenes/ui/PhaseBanner.tscn`,
  `scripts/autoloads/SaveManager.gd`, `scripts/save/SaveMigrationService.gd`,
  `scripts/save/SaveCodec.gd`, `scripts/autoloads/DataManager.gd`,
  `scripts/autoloads/GameState.gd`, `scripts/ui/SettingsScreen.gd`,
  `scripts/ui/ManualSaveReplacementPicker.gd`, `scripts/ui/OverworldScreen.gd`, and the
  suites that were supposed to cover them.

## Verification performed

- `python3 AGENT/Docs/check_docs.py`: PASS (baseline, before this document was added).
- Four throwaway headless probes were run against the shipped code and then deleted. They
  are reproduced in full in the appendix so the next session can re-run or promote them
  into real suites. Their results:

**Probe 1 — the banner ghost.** Instantiate `PhaseBanner.tscn`, settle the panel exactly
where `_animate()` leaves it, then grow the viewport:

```
settled @1280:        x=-1280.0  w=1280.0  right_edge=0.0     visible=true
after grow to 1920:   x=-1280.0  w=1920.0  right_edge=640.0   visible=true
GHOST STRIPE WIDTH = 640.0 px  (banner on screen: true)
after shrink back:    right_edge=0.0                          (on screen: false)
```

640 px is precisely the stripe in `load map at standard size, then maximize.png`, and the
shrink case reproduces the tester's "goes away if you shrink the screen again".

**Probe 2 — the import gate.** Install the v1 fixture pack, then import the tester's
actual returned `crossroads-prep-1788559844038.json` from a Main-Menu-like state:

```
installed: v076_migration_fixture 1.0.0 fp=sha256:74e9e91e…   <- matches the returned save exactly
has_weapon(training_sword) at MAIN MENU (pack installed, not active): false
has_weapon with pack ACTIVE:                                          true
inspect_portable_save     -> ok=true  state=ready  errors=[]
import_portable_save      -> ok=false errors=["The imported save could not be stored in the selected slot."]
  ERROR: SaveManager: slot 'probe_01' rejected: SaveData roster.units[0].inventory.entries[0] weapon 'training_sword' not found
  ERROR: SaveManager: slot 'probe_01' rejected: SaveData roster.units[1].inventory.entries[0] weapon 'training_sword' not found
same import WITH the pack session active -> ok=true  errors=[]
```

Both the log lines and the on-screen sentence in
`load migration v1 save after pack was installed failure message.png` are reproduced
byte-for-byte. The only variable is whether a content session is active.

**Probe 3 — the migration edge.** Build both fixtures with
`scripts/tools/build_migration_fixtures.gd`, store the returned v1 save, then migrate:

```
v2 declares 1 migration edge
migrate v1 -> v2 from the MAIN MENU  -> ok=false errors=["migration_commit_failed"]
  ERROR: SaveManager: slot 'dst01' rejected: … weapon 'training_sword' not found
migrate v1 -> v2 with the v2 session active -> ok=true errors=[]
  migrated save.source.package_version      = 2.0.0
  migrated save.source.content_fingerprint  = sha256:45391892…   (v2, correct)
  migrated save.campaign.package_version    = 2.0.0
  migrated save.campaign.content_fingerprint= sha256:74e9e91e…   (v1, STALE)
loading it the way GameState does (campaign block):
  ERROR: DataManager: saved campaign fingerprint does not match installed content
  select_saved_campaign_source FROM CAMPAIGN BLOCK = false
  select_saved_campaign_source FROM SOURCE BLOCK   = true
```

That final `ERROR` is the first line of the tester's `godot migration attempt.log`.

**Probe 4 — the tester's workaround.** Import with no pack installed, then install and
Retry:

```
step 1: import with NO pack installed  -> ok=true state=disabled has_slot=true
step 2: install pack, then Retry       -> ok=true state=ready   errors=[]
```

This confirms the tester's §7 note ("If save was loaded first, then pack added, load into
v1 was successfull") and explains it: `revalidate_slot()` never calls `save_slot()`, so it
never meets the gate that fails the direct path.

- The migration-fixture rebuild also independently confirms fixture health: the staged v1
  fingerprint `sha256:74e9e91e…` is exactly the one in the tester's save, and the v2
  manifest validates. **V0715-02's "the fixtures are broken" diagnosis no longer holds** —
  the fixture pair is sound and the migration preview succeeds. The failure moved to the
  commit and the load.

- `run_tests.sh` was **not** run for this review; it is a document-only change and the
  v0.7.15 review already records `test_session8_pack_proof` / `test_session9_pack_proof`
  as an unrelated red baseline. Confirm that baseline before starting implementation.

## Returned observations

| ID | Source | Returned observation | Disposition |
|---|---|---|---|
| V0716-01 | §2.2/§2.4, `load map at standard size, then maximize.png`, `…expand sligtly.png`, `godot2026-09-04T15.10.06.log` | The banner leaves promptly on load. Maximising mid-phase reveals a greyed box on the left that persists until the next phase change or until the window is shrunk. The tester's own diagnosis: the banner slides left until its right edge clears the old screen edge, and does not re-check when the screen grows. | Release blocker. Confirmed and reproduced; tester's diagnosis is exactly right. |
| V0716-02 | §7, `godot migration attempt.log`, `godot load v1 save after fresh v1 pack install.log`, failure-message PNG | Importing a v1 save after installing its pack fails with "The imported save could not be stored in the selected slot." Migrating v1→v2 fails. Importing first and installing after succeeds. | Release blocker. Reproduced headlessly. |
| V0716-03 | same logs | "Could not migrate from v1 to v2"; log opens with `DataManager: saved campaign fingerprint does not match installed content`. | Release blocker, distinct from V0716-02. Reproduced headlessly. |
| V0716-04 | §4, `compact-settings-controls-menu scale 2x.png` | Compact rows stack correctly, but at higher menu scales some control labels are still cut off (`W / D-pad Up / Lef…`). | Confirmed; V0715-03 is partially unfixed for one row shape. |
| V0716-05 | §6, `replace save menu.png` vs `replace save menu take 2.png` | The replacement dialog was off-centre the first time it opened and correct the second time. | Confirmed; first-open sizing race. |
| V0716-06 | not reported; visible in both banner captures | The banner panel sits at a hard-coded y of 300–420 regardless of window height, so at 1009 px tall it is above centre. | Cosmetic; the y-axis sibling of V0716-01. Cheap to fix in the same change. |
| PASS-01 | §3 | Prologue - Drill Yard exists, has one enemy, is winnable on turn one, and Chapter 1 still sits behind it. | Pass. The round's stated goal of a fast save-test loop is met. |
| PASS-02 | §5 | Nested dialogs layer, take input, restore keyboard focus and do not flicker. | Pass. V0715-06 is fixed. |
| PASS-03 | §6 | Manual save replacement uses a picker; cancelling is non-destructive; both Prep returns land correctly. | Pass. V0715-07 and V0715-08 are fixed. |
| PASS-04 | all logs | 4–7 error lines per session, all from the two save defects. No error storm. | Pass. V0715-05's spam is gone. |
| KNOWN-01 | §4 | Slider trough, fill and both endcaps render; border art still stretches at large scale. | Accepted known issue (was V0715-04). |

## Issues found and root causes

### [High] V0716-01 — The banner's resting position is never re-derived on resize

- **Location:** `scripts/ui/PhaseBanner.gd:64-70,81-84,102-124`;
  `scenes/ui/PhaseBanner.tscn:12-17`; `scripts/tests/test_phase_banner.gd:104-128`.
- **Problem:** After the slide-out, the panel is left at `position.x = -viewport_width`
  with `visible == true`. It is hidden only by sitting exactly one screen-width to the
  left. `_ready()` connects `size_changed` to `_sync_panel_width()`, which updates
  `_panel.size.x` and **nothing else**. When the window grows from `W_old` to `W_new`, the
  panel's width becomes `W_new` while its position stays `-W_old`, so its right edge lands
  at `W_new - W_old` — that many pixels of banner, on screen, until something moves it.
- **Root cause:** two pieces of the banner's geometry are derived from the viewport
  (`_offscreen_left/right`, and the width) but only one of them is refreshed when the
  viewport changes. The banner has no idle/hidden state that is independent of the
  viewport size, so "hidden" is a coordinate that silently expires.
- **Why the next phase change clears it:** `_animate()` re-reads `_offscreen_right()` and
  reassigns `position.x` before every slide, which repairs the stale coordinate as a side
  effect. That is precisely the tester's §2.4 observation.
- **Why shrinking clears it:** the right edge moves to `W_new - W_old < 0`, back off-screen.
- **Confirmation, this round:** the trace records the mismatch directly —
  `phase_changed:1:red | panel_x=-1280.0 panel_w=1920.0 visible_rect=1920.0x1009.0`
  (right edge at +640) and, on the shrink,
  `phase_changed:1:red | panel_x=-1920.0 panel_w=1280.0` (right edge at −640, invisible).
  Probe 1 reproduces the 640 px stripe headlessly.
- **Confirmation, and a correction, from v0.7.15:** measuring
  `phase banner not disapearing and not cenetered.png` (3837 px wide) gives a stripe
  ending at x≈2559 with its label centred at x≈645. A panel at `x=-1280`, `w=3837` predicts
  a right edge at 2557 and a label centre at 638. **Both within two pixels.** The v0.7.15
  capture is not an undersized panel with a centred label; it is a full-width panel parked
  at a stale `-1280` — the same defect, seen at a bigger ratio. There is no separate width
  bug and no logical-versus-physical coordinate leak: every trace line reports
  `stretch_scale=1.0`, and `panel_w == visible_rect.x` in all 46 of them.
- **Why the test suite missed it:** `test_phase_banner.gd:117-119` asserts
  `settled_panel.position.x < 0.0` — which is true at `-1280` with 640 px of panel on
  screen. The correct invariant is `position.x + size.x <= 0`. The "resize while idle" case
  at lines 122-128 calls `_sync_panel_width()` without ever changing the viewport size, so
  it asserts a tautology, and it checks only `size.x`.
- **Second, smaller defect in the same file:** `_animate()` calls `create_tween()` and
  keeps no handle, so a phase change arriving mid-animation starts a second tween on the
  same property without killing the first. The trace caught this at 21:58:52 —
  `animate_start`, then a `phase_changed` at `panel_x=0.0`, then one more `animate_start`
  and **two** `tween_finished` lines. Two tweens wrote `position:x` concurrently. It did
  not visibly misbehave here, but it is the mechanism the v0.7.15 review guessed at, and
  it should be closed while the file is open.
- **Recommended fix:** small and local. Keep the panel free-positioned; store the tween
  and `kill()` it before starting a new one; on completion set `_panel.visible = false`
  (and set it back to `true` at `animate_start`), so the hidden state stops depending on a
  coordinate. Then make `_sync_panel_width()` a `_sync_panel_geometry()` that also
  re-parks an idle panel at the current `_offscreen_left()`. Any one of those three
  changes fixes the reported symptom; the visibility flag is the one that makes the class
  of bug unreachable, and is the recommended primary.
- **Tests:** invert the two "CURRENT STATE" checks the suite already flags for inversion;
  change the settled assertion to `position.x + size.x <= 0`; add a resize-while-idle case
  that actually changes `root.content_scale_size` between 1280 and 1920 and asserts the
  panel stays off-screen (Probe 1 is this test, ready to promote); add a
  two-phases-in-quick-succession case asserting exactly one live tween.
- **Tradeoff:** none material. This is a much smaller change than the wrapper/normalized-
  transform rearchitecture V0715-01 recommended, and the measurement now shows that
  rearchitecture would have been solving a problem that does not exist.

### [High] V0716-02 — `save_slot()` gates on the ambient content session, so import and migration commits fail

- **Location:** `scripts/autoloads/SaveManager.gd:121-126` (the gate),
  `:351-356` (import commit), `:561-565` (migration commit),
  `:1005-1023` (`_prepare_for_saved_content` activating and then *restoring*);
  `scripts/save/SaveCodec.gd:284-293`; `scripts/autoloads/DataManager.gd:1922-1923`.
- **Problem:** importing a save whose pack is correctly installed fails with "The imported
  save could not be stored in the selected slot.", and v1→v2 migration fails with
  `migration_commit_failed`. The logs name the real reason, which never reaches the player:
  `SaveData roster.units[0].inventory.entries[0] weapon 'training_sword' not found`.
- **Root cause:** `save_slot()` ends with `save.validate(_data_manager())`, and
  `SaveCodec.validate_inventory_entry_dict()` resolves every weapon id through
  `DataManager.has_weapon()`. `has_weapon()` answers from `_weapons`, which holds
  **whichever content session is currently active** — not what is installed.
  `training_sword` is defined by the campaign pack, so at the Main Menu the answer is
  `false` even though the pack is installed and its fingerprint matches the save exactly.
  `_prepare_for_saved_content()` gets this right: it calls
  `select_saved_campaign_source(...)`, validates, and then deliberately calls
  `restore_content_session(previous)`. The import path then hands the just-approved save
  to `save_slot()`, which asks the same question again with the session already put back.
  The document is validated twice, under two different catalogues, and only the second one
  is wrong.
- **The comment in the file already names the confusion.** `_store_disabled_slot` is
  documented as "save_slot's transaction without its catalogue gate: the gate asks whether
  the ACTIVE library can run the document". For a *disabled* save that question is
  correctly skipped. For a *ready* save it is asked at the one moment the active library is
  guaranteed to be the wrong one.
- **Why the tester's workaround works:** with no pack installed, the import is classified
  disabled and stored through `_store_disabled_slot`, which bypasses the gate entirely.
  Installing the pack and pressing Retry runs `revalidate_slot()`, which calls only
  `_prepare_for_saved_content()` — the path that activates the pack properly. Probe 4
  confirms this end to end. Every route that succeeds is a route that does not call
  `save_slot()`.
- **Recommended fix:** decide what `save_slot()`'s gate actually means, then apply it once.
  The cleanest option: have `save_slot()` take an already-validated flag (or an explicit
  content-session scope) so callers that have just validated under the correct catalogue do
  not re-validate under the wrong one. The narrower option: wrap the two commit sites in
  `capture_content_session` / `select_saved_campaign_source` / `restore_content_session`,
  mirroring `_prepare_for_saved_content`. Prefer the first — the second leaves a
  correctness-critical invariant restated at every call site, which is how this arrived.
- **Second, independent defect:** the player-facing sentence discards the diagnosis. The
  log knows the exact missing id; the dialog says only that storing failed. Whatever the
  gate becomes, a refusal should name the content it could not resolve, in the same
  register the disabled-save recovery messages already use.
- **Why the test suite missed it:** `test_pack_save_load_migration.gd:203-245` covers
  import only when the package is **absent** (the disabled path);
  `test_save_manager.gd:351-399` covers oversize and malformed documents; and
  `test_v076_save_migration.gd:429-448` exercises `migrate_save_document_into_slot` only
  through its deliberately-failed rollback case. No suite imports or migrates a save whose
  pack is installed but not active — which is the only state the Main Menu is ever in.
- **Tests:** promote Probes 2 and 3 verbatim. They are fifteen lines each and they fail on
  the shipped code.

### [High] V0716-03 — Migration rewrites the `source` identity block but not the `campaign` block

- **Location:** `scripts/save/SaveMigrationService.gd:386-392`;
  `scripts/autoloads/GameState.gd:1178-1194` (`_activate_saved_campaign_source`);
  `scripts/autoloads/DataManager.gd:676-683`.
- **Problem:** `DataManager: saved campaign fingerprint does not match installed content`
  — the first line of `godot migration attempt.log`.
- **Root cause:** `preview()` writes four identity fields into `payload["source"]`
  (`package_id`, `package_version`, `content_schema_version`, `content_fingerprint`) but
  only two into `payload["campaign"]` (`package_id`, `package_version`). The campaign block
  keeps its own `content_schema_version` and `content_fingerprint`, and those are left at
  the v1 values. `GameState._activate_saved_campaign_source()` reads the **campaign** block,
  not the source block. A migrated save therefore claims to be package version 2.0.0 while
  carrying the v1 content digest, and `DataManager` correctly refuses it.
- **Confirmation:** Probe 3 shows the migrated document with
  `campaign.package_version = 2.0.0` beside
  `campaign.content_fingerprint = sha256:74e9e91e…` (v1), and shows
  `select_saved_campaign_source` returning `false` from the campaign block and `true` from
  the source block on the same file.
- **This is latent behind V0716-02.** Fixing the commit gate alone would let a migrated
  save be written and listed, and it would then fail at load — a worse failure than the
  current one, because the player has by then been told the migration succeeded.
- **Recommended fix:** extend the identity rewrite at `:386-387` to the remaining two
  campaign fields, so the two blocks cannot disagree. Better, since this class of bug is
  the reason two rounds have been lost: give the save one identity writer that both blocks
  are derived from, and assert in `_validate_candidate_payload()` that
  `payload["campaign"]` and `payload["source"]` agree on all four fields before a candidate
  may be committed. The duplication between the blocks is itself worth a decision — see
  the architectural observations.
- **Tests:** assert the four-field agreement on a migrated candidate, and add a load-back
  case that drives the migrated document through the same activation call `GameState` makes.

### [Medium] V0716-04 — Compact stacking gives the full row only to a row's first label

- **Location:** `scripts/ui/SettingsScreen.gd:1246-1250` versus `:1274-1279`;
  `:1282-1310`.
- **Problem:** at Compact width with 2x menu scale the keybinding rows read
  `W / D-pad Up / Lef…`. The stacked layout the tester asked for is working; the text in it
  is still being trimmed.
- **Root cause:** `_stabilize_settings_rows()` treats the row's **first** child specially —
  if it is a `Label` it gets `clip_text = false` in Compact and keeps its full text. Every
  other child keeps the desktop-era policy: `clip_text = compact` (i.e. `true`) plus
  `OVERRUN_TRIM_ELLIPSIS`. In a horizontal row that was right, because a second label was
  competing for a narrow column. In the new vertical row it is wrong: the binding summary
  now owns the full row width and is being ellipsised on a single line anyway. The rows
  never gained a wrapping policy to go with their new orientation.
- **Recommended fix:** in Compact, set `autowrap_mode = AUTOWRAP_WORD_SMART` and
  `clip_text = false` on text-bearing `Label` children, not just on the leading one; keep
  clipping for `BaseButton` children, where the popup still presents the full option text
  and an ellipsised button face is acceptable. Restore both on the way back out of Compact
  through the existing `_ROW_CLIP_META` mechanism.
- **Tests:** the check should be that no Compact `Label` is ellipsised at any supported
  menu scale, not that the panel stays in bounds — the v0.7.15 review already established
  that containment can pass while comprehension fails.
- **Tradeoff:** wrapping makes the Controls list taller and increases scrolling. That is
  the tradeoff the owner already accepted when approving vertical rows.

### [Medium] V0716-05 — The replacement picker is centred before its own content is measured

- **Location:** `scripts/ui/ManualSaveReplacementPicker.gd:29-45`;
  `scripts/ui/OverworldScreen.gd:129-146`; `scripts/ui/PrepScreen.gd` (same shape).
- **Problem:** the dialog opens off-centre the first time and correctly the second.
- **Root cause:** `configure()` creates the `OptionButton`, sets `dialog.min_size` to
  `(552, 180)`, and fills in the item text — then `popup_centered()` runs in the same frame.
  `popup_centered()` positions the window from the size it has *now*; the `OptionButton`'s
  content-driven minimum size has not been applied yet. The window is centred at roughly
  624 px wide, then the layout pass grows it to fit the item string while keeping its
  left edge. In `replace save menu.png` the dialog spans x≈648–1610 in a 1920 px window:
  left edge 648 is exactly where a 624 px-wide dialog would have been centred. The second
  open is correct because the picker already exists at its final size.
- **Contributing:** the picker is added as an absolutely positioned child
  (`position = Vector2(16, 70)`) of a dialog that manages its own layout, and
  `describe()` builds a single ~890 px row —
  `Chapter 1 - First Blood — Prep | prometheus-proving-grounds/proving_grounds | node_01_rout | 2026-09-04 21:58:29`.
  That string is why the dialog is 962 px wide, and it means this dialog cannot fit a
  Compact window at all.
- **Recommended fix:** `await get_tree().process_frame` (or use
  `child_controls_changed` / `reset_size()`) before `popup_centered()`, so the dialog is
  centred at its final size. Put the picker in the dialog's content container instead of
  positioning it absolutely. Separately, shorten `describe()` — the package/campaign path
  is constant across every row in the list and identifies nothing; label plus location plus
  timestamp is the distinguishing information.
- **Tests:** there is no suite for `ManualSaveReplacementPicker` at all. Add one covering
  `eligible_rows` filtering/ordering, `describe()` width, and dialog geometry on first open.

### [Low] V0716-06 — The banner's vertical placement is still hard-coded

- **Location:** `scenes/ui/PhaseBanner.tscn:12-17` (`layout_mode = 0`,
  `offset_top = 300.0`, `offset_bottom = 420.0`).
- **Problem:** the panel occupies y 300–420 whatever the window height, so in a 1009 px
  window it sits well above centre. Visible in both returned banner captures; the ghost
  stripe in `…expand sligtly.png` sits at the same band.
- **Root cause:** `V070-09` derived the panel's **width** from the viewport and left its
  vertical geometry as authored offsets. The y axis has the same fixed-pixel assumption the
  x axis was fixed for.
- **Recommended fix:** derive the vertical centre in the same place the horizontal geometry
  is computed, and scale the 120 px height with menu scale if the banner is meant to
  respect it. Fold into V0716-01 rather than shipping separately.

## Positive observations

1. **The instrumentation worked.** `PROMETHEUS_BANNER_TRACE` produced 46 usable lines
   across six sessions and turned a defect that had resisted two rounds of Playwright work
   into a fifteen-line headless repro. This was the right call, and the trace's
   `stretch_scale` and `visible_rect` fields are exactly what disproved the standing
   hypothesis.
2. **The tester's §2.4 diagnosis is correct in every particular** and arrived before ours.
   It should be quoted in the fix commit.
3. The short prologue works and achieves what it was for: the save-heavy sections were all
   reachable without playing a full battle.
4. Nested modals, both Prep returns and the replacement picker's *behaviour* all pass on a
   real display — V0715-06, V0715-07 and V0715-08 are fixed.
5. The disabled-save error spam is gone (V0715-05); logs now carry 4–7 error lines, all of
   them real.
6. Missing-pack recovery remains genuinely non-destructive, and is currently the only
   working route for a v1 save. It is also, by accident, the diagnostic that isolated
   V0716-02.
7. The migration fixture pair is sound. `build_migration_fixtures.gd` regenerates a v1
   whose fingerprint matches the tester's returned save exactly, and its v2 manifest
   validates — V0715-02's fixture diagnosis can be closed.

## Architectural observations

- **`has_weapon()` answers a different question than its callers ask.** Save validation
  wants "can this content be resolved for this save", and it is calling something that
  means "is this in the catalogue I happen to have loaded". Every save-validation caller
  outside gameplay is therefore correct only by coincidence of timing. This is worth one
  deliberate pass over `SaveCodec`'s `data_manager` parameter: either it always receives a
  session scoped to the document, or it should not be asking content questions at all.
- **The save document carries its identity twice**, in `campaign` and in `source`, with
  `GameState._mirror_source_identity()` copying one into the other and
  `SaveMigrationService.preview()` updating them separately. V0716-03 is the predictable
  result. Either make one derived from the other at write time, or assert their agreement
  in `SaveData.validate()`.
- **Validation runs twice on the import path, under two different catalogues, and the
  second run is the one that decides.** Wherever a check is worth doing once, doing it
  again later under weaker preconditions can only lose information.
- **"Hidden" should be a state, not a coordinate.** The banner is the second UI element in
  this project to be hidden by being positioned outside the viewport and then to reappear
  when the viewport changed. A `visible` flag cannot go stale.
- **Two of this round's five defects are first-frame sizing races** (V0716-05 explicitly,
  V0716-01 in the same family). Any dialog that populates and pops in one call has this
  shape; a shared "populate, settle, centre" helper would retire the category.
- **The suites assert the shape of the current implementation rather than the invariant.**
  `position.x < 0.0` instead of `position.x + size.x <= 0`; a resize test that does not
  resize; migration commit tested only in its rollback case. Each of these passes on code
  that is wrong in the exact way the round reported.

## Root-cause confidence

| Finding | Confidence | Basis |
|---|---|---|
| V0716-01 banner resting position | **Proven** | Headless repro produces the exact 640 px stripe; the returned trace shows the mismatched `panel_x`/`panel_w` directly; the v0.7.15 fullscreen capture measures to within 2 px of the model's prediction. |
| V0716-01 stale-tween secondary | High | Two `tween_finished` for one pair of `animate_start` in the returned trace. Not the reported symptom; a real latent defect. |
| V0716-02 save_slot catalogue gate | **Proven** | Headless repro from the tester's own save reproduces both log lines and the dialog sentence; toggling only the content session flips the outcome. |
| V0716-03 campaign/source identity split | **Proven** | Headless repro shows the migrated document's mismatched fields and the same `DataManager` error the tester's log opens with. |
| V0716-04 Compact label ellipsis | High | Code path is unambiguous and the screenshot matches. Not separately reproduced. |
| V0716-05 dialog first-open centring | High | Measured left edge (648 px) matches a 624 px-wide dialog centred in 1920 px, and the code orders `min_size`-set and `popup_centered()` in the same frame. Not separately reproduced. |
| V0716-06 hard-coded banner y | High | Scene file states it; both captures show it. |
| V0715-02 fixtures broken | **Withdrawn** | The regenerated fixtures are correct and the migration preview succeeds. The failures were downstream, at commit and load. |
| V0715-01 separate width defect | **Withdrawn** | There is no width defect and no content-scale coordinate leak. One defect, one cause. |

## Answering the checklist's open questions

- **"Please attempt to do this step with playwright to see the errors, or explain why it is
  impossible."** Playwright was not needed and would have been the slower path. All three
  save-and-banner defects reproduce in a headless Godot script in about ten seconds each,
  because none of them depend on rendering, on Windows, or on a browser — they depend on
  which content session is active and on when a viewport is resized. The appendix probes
  are the answer to this request; promoting them into `scripts/tests/` is the durable form.
- **"Consider adding extra logging around these systems if you want to get exact error
  codes."** The exact codes were already in the returned logs (`training_sword not found`,
  `fingerprint does not match installed content`); what was missing was those codes
  reaching the *player*, which is the second half of V0716-02. No new logging is needed.
- **"Consider checking how the rest of the HUD adjusts to changing screen size and see if
  any of that mechanism can be reused."** Worth doing, but note the finding: the rest of
  the HUD adjusts correctly because it is anchored, and the banner deliberately is not
  (the tween drives `position.x`, and anchors would fight it — `PhaseBanner.gd:79-80`). The
  reusable idea is not the anchoring; it is that anchored controls have no resting
  coordinate to go stale. A `visible` flag buys the banner the same property.

## Decisions for the next session

These are the choices the walkthrough needs to settle; everything else follows from them.

**RATIFIED 2026-09-05.** Verification against the branches found the code had already
taken decisions 1-6; decision 7 is answered by
`AGENT/Docs/plans/v0717_round_work_order_2026-09-05.md`, whose "Decisions settled
2026-09-05" section carries the evidence table and supersedes the recommendations below
where they differ. The one unfinished item is decision 3's *scheduled* unification of the
`campaign` and `source` identity blocks, now tracked as
`SAVE-IDENTITY-BLOCK-UNIFICATION-2026-09-05`.

1. **Is v0.7.16 blocked?** Recommendation: yes, on V0716-01, V0716-02 and V0716-03. All
   three are proven and none is large.
2. **V0716-02's gate:** does `save_slot()` keep a catalogue gate at all? Recommendation:
   give it an explicit content scope, so validation happens once under the right catalogue
   rather than twice under two. The per-call-site wrapper is the cheaper change and leaves
   the invariant restated in three places.
3. **V0716-03's identity duplication:** patch the two missing fields, or make `campaign`
   and `source` derive from one writer? Recommendation: patch now, assert agreement in
   `_validate_candidate_payload()` in the same change, and schedule the unification.
4. **How much of V0716-01 to take:** the one-line re-park, or the `visible`-flag state plus
   tween ownership plus V0716-06's vertical geometry? Recommendation: all of it — it is
   still a small diff and it closes the category.
5. **V0716-05's row text:** what identifies a save in the picker? The package/campaign path
   is identical on every row and is the reason the dialog is 962 px wide.
6. **Do the probes become suites?** Recommendation: yes, all four, before any fix lands —
   they currently fail on shipped code, which is the property that makes them worth having.
7. **What the next round tests.** Recommendation: keep it as short as this one was. The
   banner needs one resize-mid-phase case and one fullscreen capture; the save work needs
   §7 re-run in both orders. Sections 3, 5 and 6 passed and need no more than smoke.

## Appendix — reproduction probes

Each was written to `scripts/tests/`, run with
`godot --headless --path . --script res://scripts/tests/<name>.gd`, and deleted. Run
`godot --headless --path . --import` once first. Probe 3 requires the fixtures built by
`godot --headless --path . --script res://scripts/tools/build_migration_fixtures.gd -- --out <dir>`.

**Probe 1 — banner ghost.** Instantiate `res://scenes/ui/PhaseBanner.tscn` under a
`CanvasLayer`; set `root.content_scale_size = Vector2i(1280, 720)`; call
`banner._sync_panel_width()`; set `panel.position.x = banner._offscreen_left()`; set
`root.content_scale_size = Vector2i(1920, 1009)`; call `banner._sync_panel_width()`; print
`panel.position.x + panel.size.x`. Expect `640.0` — the assertion is that it must be `<= 0`.

**Probe 2 — import gate.** Stage `res://test_fixtures/campaign_packs/two_map_skirmish` into
`CampaignPackRegistry.installed_path(..., "v076_migration_fixture", "1.0.0")` with the
manifest's `id`/`version` rewritten and `save_migrations` erased (this is exactly what
`build_migration_fixtures.gd::_stage` does). Copy
`Incoming/v0.7.16 return/crossroads-prep-1788559844038.json` to a `user://` path. With no
content session active, call `SaveManager.inspect_portable_save` (returns ready) and then
`SaveManager.import_portable_save` (fails). Repeat after
`DataManager.select_tier2_campaign_source(...)` — succeeds.

**Probe 3 — migration edge.** Install both staged fixtures. Activate v1, `save_slot` the
returned save. Deactivate, then `migrate_save_into_slot` using the v2 summary's
`save_migrations[0]` and a `destination_exists` closure over its `content_ids` — fails with
`migration_commit_failed`. Activate v2 and repeat — succeeds; then read the stored document
and compare `campaign.content_fingerprint` against `source.content_fingerprint`, and call
`DataManager.select_saved_campaign_source` with each block's four fields.

**Probe 4 — the workaround.** With no pack installed, `import_portable_save` the returned
save (stores disabled). Stage the pack, then `revalidate_slot` — promotes to ready.
