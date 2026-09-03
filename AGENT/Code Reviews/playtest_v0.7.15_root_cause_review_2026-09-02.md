---
Role: dated
Type: code_review
Status: In review - owner walkthrough pending
Last verified: 2026-09-02
---

# v0.7.15 Windows return — findings and root-cause review

## Executive summary

The returned executable is the intended `0.7.15/7a89c5e9` build and most of the
campaign-library, missing-pack recovery, backup/restore, Compact Settings, physical
controller, and native slider paths produced positive evidence. The candidate is not
ready to promote: the v1-to-v2 migration fixture fails its advertised migration, and the
fullscreen phase banner is visibly sized and positioned against the wrong coordinate
space and was reported not to leave the screen.

This is a targeted, document-only review of the returned packet, not a full-project
audit. Findings are held by tracker row
`V0715-RETURN-ROOT-CAUSE-REVIEW-2026-09-02` until the owner walkthrough decides the
implementation scope. No product code was changed.

## Evidence reviewed

- all 15 PNGs, six non-empty Godot log runs, two exported JSON saves, and
  `campaign-backup.zip` in `Incoming/v0.7.15 return/`;
- the exact candidate at `agent/playtest-release-v0.7.15` / `7a89c5e9`;
- `playtest_checklist_v0.7.15.md` and `playtest_build_v0.7.15.md` from that commit;
- the phase-banner, responsive Settings, portable-save, migration, and backup/restore
  implementations and their focused tests.

The completed checklist was not returned. Therefore a filename is treated as a tester
comment, visible screen text as observed evidence, and any conclusion beyond those is
labelled as an inference. The empty `godot2026-09-02T16.00.12.log` supplies no evidence.

## Verification performed

- `python3 AGENT/Docs/check_docs.py`: PASS.
- `bash run_tests.sh`: 162 of 164 suites green; `test_session8_pack_proof` and
  `test_session9_pack_proof` failed.
- `bash run_tests.sh --rerun-failed`: both failures reproduced serially, so they are not
  parallel-run contention. They are authored FE-pack adopter proofs unrelated to this
  document-only diff. This review does not diagnose or repair them, but the red baseline
  prevents a normal verified push of this branch until their owning work resolves them.

## Returned issues and comments

| ID | Source | Returned observation | Disposition |
|---|---|---|---|
| V0715-01 | `phase banner not disapearing and not cenetered.png` | At fullscreen, `BLUE - PLAYER 1 PHASE` occupies only the left part of the window, its label is left of the map centre, and the filename reports that it remains onscreen. | Release blocker; code defect strongly supported. |
| V0715-02 | `port v1 suspend save to v2.png`, `port v1 to v2 prep save.png`, `godota.log` | Both attempted v1-to-v2 ports are blocked. One reports `migration_source_invalid`; the other reports `migration_source_identity_mismatch`. The log additionally records missing destination map/unit references eight times. | Release blocker; fixture/gate defect confirmed. |
| V0715-03 | five narrow Settings captures | At 1x, the panel and bottom controls remain contained. At 2x, control labels are aggressively ellipsized (`Level-Up Scr...`, `Text Entr...`) and only a narrow keybinding slice is visible, although scrolling remains available. The open Movement Speed popup fits. | UX comment / scope decision, not proven functional failure. |
| V0715-04 | `sliders.png` | Native Windows shows trough, fill, both endcaps, thumb, and values at 0/50/100. The very wide border texture visibly stretches instead of tiling. | Functional pass; known art-quality comment remains. |
| V0715-05 | missing-pack screenshots | Import retains the save as `imported_01`, disables loading, names the missing `v076_migration_fixture` 1.0.0 pack, and offers Manage Campaigns/Retry. Retry does not mutate progress. | Pass. Wording is informative and matches the intended recovery contract. |
| V0715-06 | campaign-library/backup screenshots and backup ZIP | Proving Grounds imports; selecting a campaign ZIP as a restore artifact is rejected before commit; backup restore reports two restored saves and skips one already-installed package. The ZIP contains one pack and two digest-listed saves. | Pass. `Campaign packages installed: 0` is correct because the one archived pack was already installed, and the dialog explains this. |
| V0715-07 | `godot3.log`, `godotb.log`, returned saves | Proving Grounds restore reaches `node_02_seize`; v2 fixture and Proving Grounds saves produce `campaign_restored`, `node_resumed`, and `campaign_restaged` contexts. | Pass for persistence/resume paths represented by these logs. |
| V0715-08 | packet completeness | The requested completed checklist, full screenshot set, and both complete pre/post-profile log directories are absent. One returned log is zero bytes. | Evidence gap. Untested checklist claims must remain unaccepted rather than inferred from silence. |

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
- **Why the non-disappearing half is not fully proven:** `_animate()` does schedule a
  0.3/0.8/0.3-second tween, and the logs contain no runtime error. A single screenshot
  cannot establish elapsed time. Two weaknesses can plausibly produce the report: the
  tween is only a local and overlapping `phase_changed` events are not cancelled, and
  resize/content-scale changes update width without restoring an idle/offscreen state.
  The next implementation pass should reproduce this with timed telemetry before
  choosing between them.
- **Recommended fix:** Make one responsive layout owner compute the banner rectangle in
  the same coordinate space as the `CanvasLayer`. Prefer full-rect anchors for the
  banner host and tween a child wrapper or a normalized progress/transform, instead of
  manually copying a viewport width into a free-positioned panel. Store the active
  tween, kill it before restarting, and on completion explicitly hide/reset the banner.
  Recompute the offscreen endpoints on resize. If the intended centre is the playable
  map rather than the whole safe viewport, obtain that rect from the map layout owner
  rather than guessing from window dimensions.
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
- **Recommended fix:** Treat this as an owner choice, not an automatic bug fix. Preferred
  option: at Compact width, cap effective menu scale to the largest value that preserves
  the required label vocabulary and disclose the effective cap. Alternative: switch
  Settings rows to a two-line/vertical compact layout at 2x so labels keep full text.
  Do not merely widen the panel beyond the supported viewport or shorten strings ad hoc.
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

### [Medium] V0715-06 — Return packet does not support a complete acceptance decision

- **Location:** `Incoming/v0.7.15 return/` compared with checklist Sections 0-8.
- **Problem:** There is no completed checklist, several named screenshots are absent,
  the requested pre/post user-data log directories are not preserved as directories,
  and one log is empty. Physical-controller connection is logged, but the exact dropdown
  wrap/skip/Escape results and several focus-return claims are not recorded.
- **Root cause:** The return process has no manifest or completeness check; filenames are
  the only comments when the checklist is omitted.
- **Recommended fix:** For the replacement round, use a short focused checklist for only
  failed/unsupported claims and include a return manifest generated beside the bundle.
  The manifest should list required artifacts and hashes and fail locally if a completed
  checklist or required evidence is absent. Under the one-in-one-out rule, this should
  replace—not add alongside—the current manual “Return all of” packet convention.
- **Tradeoff:** A manifest adds packaging work. Keeping the rerun focused limits that
  burden and avoids asking the tester to repeat already-positive sections.

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

## Prioritized action plan for the next session

1. Reject promotion/tagging of v0.7.15 pending V0715-01 and V0715-02.
2. Walk through the owner choices: banner centre target (safe viewport or playable map),
   Compact 2x policy (cap or vertical rows), and whether stretched slider art is release
   blocking.
3. Reproduce the phase-banner lifetime on the exact candidate with elapsed-time and
   resize/rapid-phase cases; then implement one coordinate-space-aware banner fix plus a
   focused test suite.
4. Repair the migration fixture into a real v1→v2 delta and make generation execute both
   prep and suspend saves through the production migration service.
5. Downgrade/deduplicate expected disabled-save diagnostics only after the end-to-end
   migration gate reliably distinguishes expected recovery state from broken fixtures.
6. Cut a focused replacement round containing only banner, migration, Compact 2x owner
   disposition, dropdown/controller claims not evidenced here, and packet completeness.

## Delta from v0.7.13 / intended v0.7.15 scope

- **Fixed/reconfirmed:** Compact Settings containment; native slider components visible;
  free-roam Proving Grounds imports; missing-pack save retention; backup/restore; v2 and
  Proving Grounds resume paths.
- **Still known:** slider border stretching and no visible Menu Density effect on the
  Settings screen itself.
- **Newly exposed:** fullscreen phase-banner coordinate/lifetime defect; generated
  migration pair cannot migrate returned prep/suspend artifacts; expected disabled-save
  validation pollutes logs at error severity.
- **Unresolved for lack of evidence:** complete keyboard/controller dropdown semantics,
  all requested focus returns, cleared-node revisit escape, later-node prerequisite text,
  and a clean complete log-directory acceptance pass.
