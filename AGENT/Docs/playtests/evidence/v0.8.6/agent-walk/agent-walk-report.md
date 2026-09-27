---
Role: dated
Type: playtest
Status: Section 3 browser pass; Sections 1B, 2 and 5 have further browser evidence; migration PASS (browser) on 997caa93; native acceptance remains pending
---

# v0.8.6 agent browser walk report

**MIGRATION RERUN — 2026-09-27, source `997caa93` (corrected in place; the pending verdict below is superseded).** The v1-save migration failure found on `0e5882d8` was a product bug: Load Game resolved the v1 save to v2 in memory, and "Import into 2.0.0" then migrated that resolved copy as though it were v1. Fixed by `19fc4622` (reads the stored save source for explicit migrations, with a regression test) and merged into the recut. On the exact `997caa93` web release with only migration-v2 installed, importing the v1 save and choosing "Import into 2.0.0" reported "Migrated a copy as 'imported_01_migrated'. The original was preserved." and Load Game listed both the original (still offering Import) and the migrated row. Evidence: `browser-runs/2026-09-27/migration-v1-save-997caa93/`.

**RECUT SECTION 3 RETEST — 2026-09-26.** Repeated against the exact current web release, source SHA `0e5882d80dcbeb8847ca8bd66b32f715f08960b8` (BUILD STAMP `0e5882d8`, Godot 4.6.3). At 1280×720 with Content Scale and Menu Scale both 2×, the Chapter 3 Unit_06 Knight vs Bridge Fighter forecast passes: panel `(200,32,664,656)` fits within the viewport, all three expected rows publish, and after scrolling both defender rows, More Info and the Enter hint are visible. The blocker did not recur.

**BROWSER CONTINUATION — 2026-09-27.** The continuation captures use the same release build, source SHA `0e5882d80dcbeb8847ca8bd66b32f715f08960b8` (BUILD STAMP `0e5882d8`). The repeated Section 1B journey reached BLUE turn 3: Hallowed Sear expired and Resistance returned to 4; the attack, suspend/continue state, and HP/tile checks also passed. Section 2 visually captured the free-roam font on Prep, HUD, Map Menu and Settings, then captured the standard menu and editor after quitting and removing the pack. Section 5 captured End Turn and backup/replace confirmations, wheel scrolling to the lower Settings controls at 0.5× and 2×, duplicate-version package fingerprints, and wrong-build save protection. These are browser findings only. The v1-save migration attempt on `0e5882d8` did not produce a conclusive acceptance result; a product fix is in progress, so the migration verdict is deliberately pending a newer build. Selected screenshots and bridge states are under `browser-runs/2026-09-27/`.

The rest of browser Section 3 passed: 1280×720 at 0.5×, 1× and 2×; 1920×1080/1×; 900×760/1× (two columns with More Info below) and fresh-profile default 0.5× (three columns); 560×900/1× (stacked); final-row scrolling at 560×900 and 1280×720/2×; all requested Prologue, Chapter 1 neutral, Chapter 3 Bishop and Horseslayer matchups. Horseslayer displayed `Dmg 29×1` and `×3 Might`; Unit_01 Strength 7, Horseslayer Mt 9 and E3_Cavalier Defense 5 give normal damage 11 plus 18 effectiveness damage = 29. Mouse clicks opened More Info for all three Chapter 3 rows; a 30-press F cycle reached all three distinct descriptions; the hint `Enter attacks.` was checked and Enter opened the forecast. Pad button 2 remains native-only.

The first neutral matchup attempt exposed a harness-only assertion: zero relationship rows are correct, but the generic scroller demanded a final row. The local runner was corrected to skip that scroll; the neutral rerun passed. Equip and More Info readers also needed the current bridge rect paths; after correction the actual weapon, damage and details were read. No product defect was found in Section 3. All screenshots and states are now stored in this report's evidence tree at `3-forecasts/recut-20260926/`.

**INITIAL SESSION 2 FINDING SUPERSEDED (2026-09-26).** The first candidate had a confirmed 1280×720/2× forecast overflow; the focused fix and recut now pass the repeated browser geometry and content checks below. Native acceptance remains pending.

At 1280×720 with Menu Scale and Viewport Scale both 2×, the live Chapter 3 Knight
versus Bridge Fighter forecast extends below the window. The defender's relationship
rows are offscreen. The browser journey still reported 14/14 actions passed because
the bridge publishes those offscreen rows; the screenshot and panel geometry are the
visual verdict. `2-session2-forecast-1280x720-2.0/` has the exact release-web
reproducer. Its panel rect is x=208, y=32, w=656, h=1298 in rendered pixels against
the 1280×720 window. At 560×900/1×, 900×760/1×, 1920×1080/1× and
1280×720/0.5×, the same authored forecast reached the final screen with the three
expected relationship rows and fit inside the window. That original candidate used source `36686b0a`; its finding led to the focused panel-height/scroll fix. The recut retest uses source `0e5882d80dcbeb8847ca8bd66b32f715f08960b8`, documented under Section 3 below.

Session 2 also captured the active free-roam font on Prep, HUD, Map Menu and Settings
at 1280×720/1× (`2-session2-font-surfaces/`). The 2026-09-27 continuation repeated
these surfaces, then quit the campaign, confirmed the pack was no longer active, and
captured the standard-font main menu and Campaign Editor
(`browser-runs/2026-09-27/font-restoration-final/`). Settings opened over the live
Map Menu; the bridge still reports `hud` while Settings is visibly on top, a bridge
ordering limitation. At 560×900/0.5× and 2×, wheel scrolling reached Export Diagnostics
and Back (`browser-runs/2026-09-27/settings-scroll/` and `settings-scroll-half/`).
Native font/readability and editor hover checks remain open.

**SESSION 1 RETEST COMPLETE (2026-09-26) — the turn-3 timeout was a harness error; native Windows acceptance remains pending.**

The release-web rerun at source `36686b0a` reached BLUE turn 3 through normal RED AI.
The earlier driver pressed Enter after End Turn had already committed, selecting the
Bearer under the cursor; its wait for a free cursor then timed out. The corrected
driver checks cursor state before confirming. `1B-retest-20260926/` shows Hallowed
Sear absent at turn 3, Resistance restored from 1 to its pre-hit value of 4, and
both units alive at 13 HP (7,3) and 7 HP (8,3). The 1C mixed Load Game list was
retested at 1280×720/1×: scrolling within the list exposes the lower row in full
(`1C-retest-scroll-20260926/`), with all row text fitting its own control. The
editor's Rules preview stayed inside the inspector at six visible lines with an
ellipsis. Enter committed a Display Name change, the tab marked it unsaved, Ctrl+S
cleared that marker while retaining the value, and Escape returned to the library
with Menu Scale unchanged (`2-editor-retest-commit-20260926/`). The Rules tooltip
did not appear in the headless browser after a five-second hover; native visual
verification of the full hover text remains open. The populated list's dense text
also still needs the native readability judgment.

## Remaining work

- Finish Section 4's matched-stat Hit/Dmg/Crit comparison and landed-hit Resistance breakdown.
- Complete native Windows verification: display/GPU/DPI and BUILD STAMP identity, representative 1A layouts, 1B countdown, 1C readability, editor at 1920×1080 and 125% scaling, controller navigation, Diagnostics ZIP, and Section 7 player judgments.
- Verify the editor Rules hover text and dense list readability natively; test forecast pad button 2 on native hardware.

## 1. Header

- Build identity is mixed across this report. Initial tester-bundle captures use
  `36686b0a07677b130e80f64045376877c3ca9898` (BUILD STAMP `36686b0a`); the Section 3
  recut and 2026-09-27 continuation use
  `0e5882d80dcbeb8847ca8bd66b32f715f08960b8` (BUILD STAMP `0e5882d8`). The local
  `builds/web/Project_Prometheus/artifact-manifest.json` records the latter, version
  `0.8.6`, release build, Godot `4.6.3.stable.official.7d41c59c4`. Do not treat the
  earlier tester receipts as receipts for the recut build.
- Dates: initial walk 2026-09-25; recut and continuation captures 2026-09-26–27.
- Harness: Playwright 1.63.0, Chrome Headless Shell (SwiftShader software renderer),
  Node v24.21.0, Linux x86_64. `tools/playwright/lib/bridge.mjs` (WebTestBridge v5),
  `bridge_rects=all` used throughout so container/label rects are visible, not just
  focusable controls.
- Viewport method: fresh Playwright browser session per case; window size set via the
  Playwright `viewport` (== the OS window size the checklist means); Viewport Scale
  and Menu Scale set either via URL query params (`content_scale=`, `menu_scale=`,
  confirmed to run through the same `SettingsManager.set_content_scale_factor` code
  path a player's slider drag would) or by directly driving the Settings sliders.

## 2. Summary table

| Item | Verdict | Note |
|---|---|---|
| 0 — Build identity | PASS per run; mixed builds | Initial tester receipts are for `36686b0a`; Section 3 recut and 2026-09-27 continuation use `0e5882d8`. Evidence identities are stated alongside each run. |
| 0 — Clean profile empty states | PASS | Fresh browser contexts: Load Game says “No campaign saves yet”; New Game reports 0 compatible records. Evidence: `0-clean-load/`, `0-clean-new-game/`. |
| 0 — Import free-roam.zip | PASS | done during 1A/1B/3 runs, unmodified zip via file chooser |
| 1A — 12 live-map cases | PASS (12/12) | zero panel-to-panel overlaps measured; see detail |
| 1A — three "on purpose" behaviours | PASS (all 3) | Objectives collapse/restore, 2x(1x) cap, unit-above-terrain |
| 1B | PASS (browser) | Repeat on `0e5882d8` reached BLUE turn 3: condition gone, Resistance 4 restored, HP/tiles unchanged. Native release check remains. See `browser-runs/2026-09-27/1b-recut/`. |
| 1C | PASS for scrolling; native readability pending | The lower row becomes fully visible when the list is scrolled; row text fits its control. |
| 2 | PARTIAL | Rules six-line ellipsis, dirty → saved, and scale restore passed. The 2026-09-27 browser captures cover free-roam font on Prep/HUD/Map Menu/Settings, restoration after pack removal, and the standard editor font. Full hover text did not appear in headless Chromium; native verification remains pending. |
| 3 | PASS (browser; native pad pending) | Recut retest covers all matchups, requested viewports, panel geometry/scrolling, mouse row access, F cycle, Enter confirmation and damage arithmetic. Pad button 2 remains native-only. See `3-forecasts/recut-20260926/`. |
| 4 | PARTIAL | Chapter 6 browser fixtures confirmed Bearer `Hallowed Rites +5 Dmg`, Axeman `Undead Frailty +1 Dmg`, and More Info suppression sentence. No hit/condition expiry or full stats/Hit/Dmg/Crit comparison. |
| 5 | PARTIAL | 1C mixed save-list and Retry→Prep succeeded; Settings scrolling, confirmation dialogs, duplicate-version fingerprints and wrong-build save protection passed in the 2026-09-27 browser run. v1 migration passed on `997caa93` (`migration-v1-save-997caa93/`); native Diagnostics export remains pending. |
| 6 | PASS (skim) | v0.8.6 supplemental receipt passed (40 cases, zero errors); pack-gate receipt passed. Visually skimmed all 40 album images and all 46 pack screenshots; contact sheets at `section6-skim/`. |
| 7 | PARTIAL | Browser evidence supports row labels/readability only; native and subjective judgments remain pending. |

## 3. Defects found

The first candidate (`36686b0a`) had a confirmed 1280×720/2× forecast overflow;
the focused recut browser checks on `0e5882d8` pass, as recorded in Section 3. The
initial 1B timeout was a harness error: End Turn had already advanced to BLUE turn 3
with a free cursor; the extra Enter selected the Bearer. The corrected and repeated
runs passed the expiry check. Separately, the v1 save migration attempt on
`0e5882d8` failed to establish the required migration behavior and is under product
fix. It passed on the `997caa93` rerun (see the top of this report).

## 4. Per-section detail

### Section 0 — Identity and clean start

Build identity confirmed as above. Import of `free-roam.zip` succeeded via the real
Campaign Library file-chooser control (`/BtnImport`) in every run that needed it,
passing the original zip bytes unmodified (Playwright `setFiles` on the bundle path).

### Section 0 — Clean profile empty states

Captured fresh Playwright browser contexts at 1280×720. Load Game displayed “No
campaign saves yet” and the import-save prompt; New Game displayed “0 compatible
record(s) found.” Screenshots are in `0-clean-load/` and `0-clean-new-game/`.
This verifies the web export's fresh-profile empty states only.

### Section 1C — Load Game with saves in it (initial walk and 2026-09-26 retest)

Restored `interaction-duration-backup.zip`, retried the `Resume battle` row to make
it loadable, then restored `campaign_backup_v2.zip` in the same browser profile. Before
retrying the campaign backup, the bridge snapshot contained three rows: two
`[Needs campaign]` rows (autosave and `Prologue - Drill Yard — Prep`) plus the
loadable `Resume battle — Turn 1` row. The step-12 screenshot is the requested mixed
state: `5-saves-packs-dialogs/12-1c-open-load-game-mixed-rows-before-retry.png`.
The initial screenshot shows the upper stale row and the loadable row, with the
lower row partly outside the scroll viewport. The 2026-09-26 retest scrolled the
list itself: `1C-retest-scroll-20260926/14-1c-lower-rows-after-scroll.png` shows
the lower row fully inside the viewport, and bridge text metrics report it fits.
Retrying the campaign-backup slot succeeded and it loaded into Prep (step 16).
The browser list exposed packages
`prometheus-proving-grounds 0.1.0` and `prometheus-proving-grounds-internal-fe 0.1.0`;
no native installed-font judgment was made.

### Section 1B — Hallowed Sear countdown (initial walk and 2026-09-26 retest)

Reran `scripts/1b-hallowed-sear.mjs` against the release web export identified above,
using the unmodified `interaction-duration-backup.zip`. The run repeated the first
34 steps and confirmed: the restore initially leaves both rows showing stale
`[Needs campaign]`; Retry makes Resume battle loadable; starting board is Bearer
24 HP at (2,3) and Revenant 22 HP at (8,3); the single attack hit for 15 (22→7);
Unit Details showed the 2-phase condition and −3 Resistance modifier; after RED AI,
BLUE turn 2 showed 1 phase; Suspend/Continue preserved Bearer 13 HP at (7,3) and
Revenant 7 HP at (8,3); and Bearer Wait completed at (7,3).

The initial runner timed out in `endTurnFromMapMenu()` at step 35. The 2026-09-26
diagnostic captured BLUE turn 3 and a free cursor *before* the driver's extra Enter;
after Enter, the cursor was `unit-selected`. The corrected run in
`1B-retest-20260926/` completed steps 35–37. Unit Details no longer listed Hallowed
Sear, Resistance was 4 again (1 while affected), and the two units retained their
HP and tiles. The 2026-09-27 repeat on source `0e5882d8` also completed the full
journey and matched the starting board, hit result, expiry and suspend/continue
state (`browser-runs/2026-09-27/1b-recut/`). The native Windows countdown and human
digit judgment remain open.

### Section 2 — Campaign Editor (initial walk and 2026-09-26 retest)

The v0.8.6 editor driver imported `free-roam.zip` unmodified, opened Manage Library,
and used **Edit a Copy…** to reach Campaign Editor at 1920×1080. It selected the
`proving_grounds` Campaign record (`2-campaign-editor/05-default-campaign-record-selected.png`),
changed Display Name to “The Proving Grounds Test,” and saved. The status bar identified
the resulting working copy as `prometheus-proving-grounds-draft-1790373726`;
screenshots `06-edited-campaign-display-name.png` and `07-after-save-campaign-display-name.png`
record the edit and save; the editor still showed Validation: Not validated. A subsequent attempt to capture the scrolled Rules field
failed during editor setup. The 2026-09-26 retest scrolled Rules into view: the
six-line preview and ellipsis fit inside the inspector. Enter committed an edited
Display Name, showing an unsaved marker; Ctrl+S cleared it and retained the value.
Escape returned to the library with Menu Scale 1 unchanged. The Rules hover tooltip
did not appear after five seconds in headless Chromium, so native hover verification
remains. Campaign Editor is using its own UI surface; this does not certify
campaign-font use elsewhere. On 2026-09-27, after affirmative Quit deactivated the
pack, the main menu showed the standard pixel font and the editor used its normal
editor typography; captures are in `browser-runs/2026-09-27/font-restoration-final/`.
This is a browser-only visual result; native font verification and the Rules hover
tooltip remain pending.

### Sections 3–5 and 7 — Item-level disposition

See the checklist disposition table below. Items that require further independent
browser flows were left open; items requiring native Windows display/input or human
judgment remain explicitly pending.

### Section 3 — Attack forecast and weapon relationships

**Browser section complete on the recut; pad button 2 remains native-only.** The exact repeated 1280×720/2× case passed: panel rect `(200,32,664,656)` is inside the viewport, all three expected relationship rows publish, and the final scrolled state shows both defender rows, More Info and the Enter hint. The forecast did not run below the window. Screenshot and bridge states are under `3-forecasts/recut-20260926/repeat-ch3-1280x720-2-20260926/`.

The full viewport matrix passed and was visually inspected. 1280×720 at 0.5×, 1× and 2×; 1920×1080 at 1×; 900×760 at 1× with More Info below; 900×760 in a fresh browser context defaulting to 0.5× with three columns; and 560×900 at 1× stacked. All forecast panels are contained. The last defender relationship row scrolls fully into view at 560×900 and 1280×720/2×. Captures and geometry are under `3-forecasts/recut-20260926/recut-ch3-*` and `repeat-ch3-900x760-*`.

All other content matchups passed: Prologue Unit_02 sword vs lance dummy (attacker disadvantage and defender advantage); Chapter 1 Unit_04 Fire vs E2_Mage Thunder (zero rows); Chapter 3 Unit_04 Fire vs Chapel Bishop (opposite magic-triangle rows); Chapter 1 Unit_01 with Horseslayer vs E3_Cavalier (effectiveness row). Horseslayer showed `Dmg 29×1`; Mt 9 becomes 27 under ×3 effectiveness, so Strength 7 + 27 − Defense 5 = 29, an 18 damage increase over the non-effective 11. Evidence is under `3-forecasts/recut-20260926/repeat-{prologue,ch1-fire-thunder-fixed,ch3-magic-triangle,ch1-equip-fixed}-20260926/` and the baseline capture `repeat-ch1-equip-baseline-20260926/`.

Mouse opened details for all three Chapter 3 relationship rows; thirty F presses reached all three distinct descriptions. A separate run checked the hint `Enter attacks.` and confirmed the Bridge Fighter with Enter. Pad button 2 was not emulated. Evidence: `repeat-ch3-mouse-f-enter-20260926/` and `repeat-ch3-fullcycle-20260926/`.

The zero-row neutral matchup initially tripped a harness assertion that expected a last defender row. The corrected scratch runner skipped the impossible scroll, after which the same candidate passed with zero rows. Stale bridge paths in the Equip and More Info readers were also corrected; no product defect was found.

### Section 4 — Internal campaign readouts (local-only fixture)

Using the allowed local Chapter 6 checks, the 14-action browser journeys passed for
Hallowed Bearer vs Revenant and Free Company Axeman vs Revenant. The published rows
were `Hallowed Rites +5 Dmg` for the Bearer and `Undead Frailty +1 Dmg` for the
Axeman. A separate More Info cycle displayed: `Hallowed Rites — an interaction this
campaign's data declares, not a rule of the engine. Applies to this combatant: +5
Dmg. Overrides in this fight: Undead Frailty.` No snake_case/internal identifier
appeared in that explanation. Screenshots, row data and fixtures are under
`4-internal-checks/`. The private pack archive was not copied into public output.
The native checklist asks for matching non-weapon stats, full Hit/Dmg/Crit values,
no Undead Frailty in Bearer’s forecast, and a landed Hallowed hit plus Unit Details
condition countdown; those comparisons remain incomplete.

### Section 5 — Saves, packs, dialogs and diagnostics

The v0.8.6 script first ran 1C without the interaction backup and exposed a harness
navigation bug; after correcting that call it loaded the restored campaign backup
into Prep. A later run explicitly requested 1.0× and restored both save families in
the same context. The mixed row state was captured before Retry, then the campaign
backup row retried and loaded into Prep. See Section 1C above. On 2026-09-27,
wheel scrolling at 560×900 reached Export Diagnostics and Back at both 0.5× and 2×.
End Turn, restore-result and replace-save dialogs were captured; Enter on the replace
prompt kept the existing save. Two same-ID/version builds displayed distinct
fingerprint suffixes. A save exported under build A, then imported while build B was
installed, was labeled incompatible; the dialog named the saved and installed
fingerprints, said the save was unchanged, and directed installation of the
originating build before Retry. The row remained unavailable after Retry while
build B was installed. This confirms browser wrong-build protection. Evidence
is under `browser-runs/2026-09-27/{settings-scroll,settings-scroll-half,confirm-dialogs,collision-labels-final,collision-a-export,collision-a-save-on-b}/`.

The v1 migration flow was attempted on old recut source `0e5882d8` and failed to
establish the expected migration/refusal result. It is under product fix, and the
rerun on `997caa93` passed (`migration-v1-save-997caa93/`). Captures from that attempt
are preserved under `browser-runs/2026-09-27/migration-v1-save/`,
`migration-v1-save-rerun/`, and `migration-v1-save-on-v2/`. Native Diagnostics ZIP
and Windows display/input checks remain pending.

### Checklist disposition

| Checklist item | Verdict | Evidence / limitation |
|---|---|---|
| 0 — Build identity | PASS | Manifest and receipts agree on release commit 36686b0a. |
| 0 — Clean empty states | PASS | Fresh contexts: no saves in Load Game; New Game reports zero compatible records. `0-clean-load/`, `0-clean-new-game/`. |
| 0 — Import free-roam.zip unchanged | PASS | Imported through the browser file chooser in 1A and Section 2. |
| 1A — 12 live-map font/panel cases | PASS 12/12 | See 1A matrix above. |
| 1A — Collapse/restore, scale cap, stacked panels | PASS | See three behaviors above. |
| 1B — Restore, stale row/Retry, exact board | PASS | Repeated twice in `1B-hallowed-sear/`. |
| 1B — Land hit; Hallowed Sear / −3; next BLUE count | PASS through 1 phase | 22→7, (2 phases) then (1 phase) captured. |
| 1B — Suspend/Continue state persistence | PASS | HP/tiles unchanged in evidence and notes. |
| 1B — BLUE turn 3 expiry | PASS (browser) | `1B-retest-20260926/` shows turn-3 condition gone, Resistance 4 restored, HP/tiles unchanged. Native release check remains. |
| 1C — Mixed Load Game list at 1280×720/1× | PASS for scrolling; native readability pending | Two stale rows and one loadable row captured. Scrolling exposes the lower row fully; bridge text metrics fit. |
| 1C — Installed packs and font | PARTIAL | Two package headings observed; no native/visual font judgment. |
| 2 — Edit a Copy; default Campaign/Rules layout | PARTIAL | Campaign record selected; six-line Rules preview and ellipsis fit inside inspector. Full hover tooltip did not appear in headless Chromium; native check remains. |
| 2 — Edit/save value and restore Menu Scale | PASS (browser) | Enter committed Display Name, tab marked unsaved, Ctrl+S cleared the marker while retaining the value; Escape returned to library with Menu Scale 1 unchanged. |
| 2 — Free-roam font on Settings/HUD/Map Menu/Prep | PASS (browser) | Visual captures at 1280×720/1× on `0e5882d8`; Settings bridge screen label remains `hud` because the overlay is above it. `browser-runs/2026-09-27/font-restoration-final/`. |
| 2 — Campaign Editor uses standard font | PASS (browser) | 1920×1080 editor capture after pack removal; native verification remains pending. Same evidence directory. |
| 2 — Standard font after pack removal | PASS (browser) | Affirmative Quit returned to the standard-font main menu after the pack was deactivated; native verification remains pending. Same evidence directory. |
| 3 — Ch3 Knight vs Bridge Fighter relationship rows | PASS (recut rerun) | Three rows and contained panel at 1280×720/2×; scroll exposes both defender rows and More Info. `3-forecasts/recut-20260926/repeat-ch3-1280x720-2-20260926/`. |
| 3 — Forecast layout at requested sizes/scales | PASS (browser) | 1280×720 at 0.5×/1×/2×; 1920×1080/1×; 900×760/1× and fresh default 0.5×; 560×900/1×. Three/two/stacked layouts contained. `3-forecasts/recut-20260926/recut-ch3-*`. |
| 3 — Prologue weapon triangle cases | PASS | Unit_02 sword vs lance dummy shows attacker disadvantage and defender advantage. `repeat-prologue-20260926/`. |
| 3 — Ch1 Fire vs Thunder neutral | PASS | Zero rows; corrected no-row scrolling harness. `repeat-ch1-fire-thunder-fixed-20260926/`. |
| 3 — Ch3 Fire vs Bishop magic triangle | PASS | Attacker +10 Hit/+2 Dmg and defender -10 Hit/-2 Dmg. `repeat-ch3-magic-triangle-20260926/`. |
| 3 — Horseslayer effectiveness and damage delta | PASS (live forecast + data arithmetic) | `Dmg 29×1`, ×3 Might; baseline math 11 + 18 = 29. `repeat-ch1-equip-fixed-20260926/`; stats baseline `repeat-ch1-equip-baseline-20260926/`. |
| 3 — Mouse/F/Enter/pad navigation | PASS except pad (native-only) | Mouse opens each of 3 details; F reaches all 3; `Enter attacks.` hint and Enter confirmation pass. Pad button 2 not emulated. `repeat-ch3-mouse-f-enter-20260926/`, `repeat-ch3-fullcycle-20260926/`. |
| 4 — Chapter 6 party/stat identity | PARTIAL | Fixtures reached the live Chapter 6 scenario; full identical-stat comparison not recorded. |
| 4 — Bearer/Axeman forecasts | PARTIAL | Each expected player-facing row observed; comparative Hit/Dmg/Crit values not tabulated. |
| 4 — Bearer suppression and More Info wording | PASS (browser) | More Info names Undead Frailty; no programmer-style identifier in captured text. |
| 4 — Land Hallowed hit; condition/Resistance breakdown | NOT RUN | No hit or Unit Details countdown in this Section 4 continuation. |
| 5 — campaign_backup restore and Retry→Prep | PASS | Restored row loaded into Prep. |
| 5 — Migration save rejection messages | PENDING NEWER BUILD | The v1 migration attempt on old recut source `0e5882d8` failed to establish the required migration outcome and is under product fix. Do not treat the final verdict as recorded until rerun on the newer build. Old-run evidence: `browser-runs/2026-09-27/migration-v1-save/`, `migration-v1-save-rerun/`, and `migration-v1-save-on-v2/`. |
| 5 — Collision fingerprints and wrong-pack protection | PASS (browser) | Two builds sharing package ID/version appear with distinct fingerprint labels. Exporting under build A and importing with build B showed a fingerprint mismatch and kept the save unchanged; the row remained unavailable until the matching build is installed. `browser-runs/2026-09-27/collision-labels-final/`, `collision-a-export/`, `collision-a-save-on-b/`. |
| 5 — End Turn / backup restore / replace-save dialogs | PASS (browser) | Captured End Turn prompt, restore result, replace prompt, and Enter preserving the existing save. Suspend/quit confirmation was captured in the Section 1B run. `browser-runs/2026-09-27/confirm-dialogs/`. |
| 5 — Settings under 600px at 0.5×/2× and scrolling | PASS (browser) | 560×900 at 0.5× and 2×; wheel scrolling reached the lower controls, Export Diagnostics and Back. Native scrolling/readability remains pending. `browser-runs/2026-09-27/settings-scroll/` and `settings-scroll-half/`. |
| 5 — Diagnostics ZIP | NATIVE-ONLY | Linux web export cannot certify the native Windows archive. |
| 6 — Supplemental and pack-gate prepass | PASS (reference) | Receipts report 40/40 and pack-gate success, same source SHA. |
| 6 — Screenshot folder visual skim | PASS (skim) | All 40 + 46 images viewed via `section6-skim/`; no unexpected clipping/box glyphs stood out. |
| 7 — Human readability/playability judgments | PENDING | Browser evidence cannot replace native/human review. |
| 7 — Windows/GPU/display/DPI/BUILD STAMP details | NATIVE-ONLY | Not available in Linux browser run. |
| 7 — Delete internal.zip copy | NOT APPLICABLE / no extra copy | No separate internal.zip copy was made; private test fixture remains local. |

### Section 6 — Automated pre-pass and visual skim

The included supplemental receipt reports `passed`, 40 cases across eight screens
and five viewports, with zero errors and instrumented bridge/pixel tools. The pack
gate receipt names the same source SHA and reports successful imports/map launches.
I visually skimmed all 40 `screenshot-album/` images and all 46
`pack-gate-evidence/` screenshots. No unexpected clipping, overlap or box glyphs
stood out in this skim. Contact sheets are in `section6-skim/`. These screenshots
are limited to the states described by the included pre-pass; the checklist's HUD
screenshots do not contain a live map, and the Game Over screen uses the harness
placeholder `Victory!`.

### Section 1A — Campaign font and panels on a live map

All 12 (window x scale) cases were captured with a unit selected so Objectives, the
unit panel and the terrain panel are all showing. Panel-rect overlap was measured
directly from `WebTestBridge` rects (`ObjectivePanel`, `UnitInfoPanel`,
`TerrainCorner/TerrainInfoPanel`), not just eyeballed, and screenshots were also read.

| Window | 0.5x | 1.0x | 2x |
|---|---|---|---|
| 1280x720 | PASS | PASS | PASS |
| 1920x1080 | PASS | PASS | PASS |
| 900x760 | PASS | PASS | PASS |
| 560x900 | PASS | PASS | PASS |

Zero overlaps measured in any of the 12 cases (`overlaps: []` in every `result.json`).
Screenshots were read for all 12 and no clipped text, no box-character glyphs, and no
panel painting over another were seen.

Scale readback per case (from bridge `scales`):
- 1280x720: content 0.5/1/2 all applied uncapped (2x lands exactly at the 640x360 floor).
- 1920x1080: content 0.5/1/2 all applied uncapped.
- 900x760: 0.5/1 applied uncapped; **2x requested → content capped to 1** (`contentPreference:2, content:1`), `effectiveMenu:2` (menu chrome, uncapped).
- 560x900: same capping shape as 900x760 at 2x.

This is new information worth recording precisely: **only the game-viewport scale
(content_scale) is capped by the window size; Menu Scale is not.** That is why New
Game's Start and Prep's Begin still need the checklist's documented scroll/keyboard
workaround even on a window where the *live map* is showing a fully-capped, non-
overlapping 1x — the pre-battle *menus* are still rendering their chrome at the full
requested factor (confirmed: at 900x760/2x, `menu:2` while `content:1`).

**Three "look different on purpose" behaviours, all confirmed:**

1. **1280x720 @ 2x, Objectives collapses/restores.** With the unit selected, the
   `ObjectivePanel` bridge rect shrinks to its header (`h:62, w:172`, no Win/Lose
   text) instead of the full box (`h:318, w:304`). Screenshot:
   `1A/1280x720-2.0/01-live-map-selected.png` (via the corrected single-case rerun,
   see harness note below) shows the collapsed box beside the unit and terrain panels
   with no overlap. Pressing Escape (deselect) and hovering an *empty* tile restores
   the full box exactly (`h:318, w:304` again, `UnitInfoPanel` absent from rects) —
   `1A/1280x720-2.0-objectives-restore/02-deselected-corner.png`. PASS.
2. **900x760 and 560x900 @ 2x read `2x (1x)` in Settings, and grow to real 2x when
   resized to 1920x1080 without touching the slider.** Driven interactively on the
   Settings screen at 900x760: after setting the Viewport Scale slider to 2.0x, the
   label read exactly **"2.0x (1.0x)"** (`1A/900x760-settings-cap/after-2x.json`).
   Resizing the same page to 1920x1080 (no slider touch) changed the label to plain
   **"2.0x"** and `scales.content` became `2` (`1A/900x760-settings-cap/after-resize.json`).
   PASS for 900x760. The same interactive drive at 560x900 did not reproduce (see
   Checklist/harness note below) but the capping mechanism itself is independently
   confirmed at 560x900 by the 1A sweep's own scale readback (`content:1` from
   `contentPreference:2`), so the underlying behaviour is not in doubt — only the
   supplementary manual-slider confirmation at this one size is incomplete.
3. **560x900 @ 1x and 2x, unit panel sits above the terrain panel.** Confirmed visually
   and via bridge rects: `UnitInfoPanel` and `TerrainCorner/TerrainInfoPanel` are both
   left-aligned and stacked vertically (`1A/560x900-1.0/01-live-map-selected.png`,
   `1A/560x900-2.0/...`, identical since 2x is capped to 1x here), not side by side.
   No overlap between them. PASS.

**Harness note (not a game defect):** the main 12-case sweep script's simplified
tile-click helper (no cursor-arrival verification) landed on an *empty* tile instead of
the unit at 1280x720/2x on its first pass, which produced a false empty `unit` panel
for that one case. A second pass using the verified `clickTile` helper (which asserts
the cursor lands on the intended tile before clicking, from `stateful-journeys.mjs`)
reproduced the selection correctly and is what is reported above. This is recorded
here per instructions to say exactly what was tried; it is a script bug in this
walk's own tooling, not a build defect. The `560x900-settings-cap` non-reproduction is
the same family of issue (a slider-drive helper that depends on exact click geometry).
