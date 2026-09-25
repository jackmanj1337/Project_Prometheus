---
Role: dated
Type: playtest
Status: Returned evidence; diagnosed 2026-09-25
Last verified: 2026-09-25
---

# v0.8.5 tester style manual walkthrough report

Date: 2026-09-25 UTC
Target: `builds/web/Project_Prometheus`, release web export
Source commit: `02d552da6ff1586e9cdf16d6c56adf554df3ed2f`
Browser: Playwright 1.63.0, Chrome Headless Shell 153.0.8010.12, SwiftShader software renderer; Node v24.21.0 on Linux x86_64 (WSL2)
Viewport/default run: 1280×720, DPR 1; the test bridge was enabled for observation only. Inputs were sent through Playwright mouse/keyboard actions.
**Corrected 2026-09-25 after diagnosis (Claude Code).** Three verdicts below were wrong and are fixed in place: (1) **1B passes.** The post-hit Unit Details reads `Hallowed Sear -3 (1 phase)`, not `(2 phase)` — in the pixel font the digit 1 draws like a small-caps "I" (compare `Growth 1o%` and `Tier 1` on the same screen). The Bearer is the only BLUE unit, so the hit auto-ended BLUE's phase; the AI played RED and BLUE Turn 2 began before Details opened. `(1 phase)` at BLUE Turn 2 and expiry at BLUE Turn 3 is exactly the checklist's sequence, and the Suspend/Continue replay was taken at that same `(1 phase)` checkpoint. (2) **The 3 — 900×760 forecast is not a defect.** That run used the fresh profile's automatic scales (content 0.5, menu 1.0 — bridge viewport 1800×1520), not the 1.0/1.0 the checklist requires, so three columns was correct. (3) **The three 1A 2× failures are real** but are panel-to-panel collisions on canvases at or below the floor (640×360, 450×380, 280×450), not the v0.8.4 in-panel font overlap. Fixed for v0.8.6 in `V086-SCALE-FLOOR-HUD-2026-09-25`. Section 2's editor block was a checklist gap: a working copy comes from Campaign Library → Edit a copy, which the checklist did not name.

Report status: partial browser walkthrough; several requested cases were unavailable or untested. Operational checks and the Section 6/7 prompts have explicit dispositions below; this report does not claim complete checklist coverage.

## Build identity and test conditions

The web `artifact-manifest.json` reports version 0.8.5, release build, Godot 4.6.3, and exact source SHA `02d552da6ff1586e9cdf16d6c56adf554df3ed2f` (short stamp `02d552da`). Its source tree is `ae0230b340d1dc0e1d8a404f0fa392db1891db60`. The tester bundle's release manifest reports the same source SHA/version and release type. `sha256sum -c SHA256SUMS.txt` passed for both bundled Windows executables. The native binaries and physical Windows/GPU/DPI details were not run in this Linux browser environment.

The complete 688-file browser evidence set is preserved in `evidence.zip` beside this report. Relative evidence paths in this report are paths inside that archive; seven key screenshots are also available directly beside the archive at their original relative paths. Browser screenshots and machine-readable bridge snapshots are paired where generated. The WebTestBridge reports screen/layout/campaign state; it does not read Unit Details text, and the checklist's visual text checks were judged from screenshots.

## Section 0 — identity and clean start

| Checklist item | Result | Tester observation |
|---|---|---|
| Build identity agreement | PASS | Web manifest and bundle release manifest both report 0.8.5 / `02d552da`; both Windows executable hashes verify against the bundled sums. Main-menu identity was not separately read before beginning the fixture runs. |
| Clean profile; New Game and Load Game empty states | BLOCKED | Browser fixtures were necessary to reach target states; this pass did not first capture a pristine browser profile's empty screens. |
| Import `free-roam.zip` supplied | PASS | Driven through the Campaign Library import picker in the live-map capture runs; the original bundle ZIP was passed directly, without extraction or modification. Playwright import result is recorded per run. |

## Section 1 — v0.8.5 fixes (priority)

### 1A — free-roam font on a live map

The checklist requests 12 captures, with both scales set to 0.5, 1.0, or 2.0 and four viewport sizes. Playwright launched the exact web export, imported the original `free-roam.zip`, selected `proving_grounds`, began the map, and clicked the first blue unit so Objectives, unit and terrain panels were visible. All 12 target cases have live-map screenshots and state under `1A-live/`. Screenshots at 0.5× and 1.0× show the Objectives, selected Unit_01 panel and terrain panel visible without text overlap at 1280×720, 1920×1080 and 900×760. At 1920×1080/2×, all three panels are visible and separated. At 1280×720/2×, a live-map capture reached by starting at 1920×1080 and resizing to the target shows the Objectives and Unit_01 panels overlapping and their text colliding: FAIL. Starting directly at 1280×720/2× clipped Prep Begin below the view (`y=972`); resizing after the map started followed the checklist allowance to resize. The three small-screen 2× cases were started at 1920×1080 and then resized to target after the live map was running. Direct launch at 1280×720/2× and 900×760/2× failed earlier at Prep because Begin was below the view, but the resize route is allowed by the checklist. The initial 1280×720/0.5× screenshot was superseded by a selected-unit rerun in the same folder.

| Window | 0.5× | 1.0× | 2× |
|---|---|---|---|
| 1280×720 | PASS | PASS | FAIL: Objectives overlaps Unit_01 and text collides |
| 1920×1080 | PASS | PASS | PASS |
| 900×760 | PASS | PASS | FAIL: Objectives/Unit_01 and Unit_01/terrain overlap |
| 560×900 | PASS | PASS | FAIL: severe panel and text overlap/clipping |

### 1B — Hallowed Sear countdown; release web export and normal AI

The exact supplied `interaction-duration-backup.zip` was restored via Manage Library, and Playwright used the visible Retry/Load flow. The resulting board was live at `node_06_hallowed`, Turn 1, with Hallowed Bearer at 24 HP/(2,3) and Revenant at 22 HP/(8,3). No debug build or F9 input was used. The hit was committed with Enter; HP became Bearer 13 at (7,3), Revenant 7 at (8,3), confirming the attack connected and both survived.

The post-hit Unit Details screenshot shows `Hallowed Sear -3 (1 phase)` and Resistance 1, at BLUE Turn 2: the Bearer was BLUE's only unit, so the hit auto-ended BLUE's phase and the AI played RED's before Details opened. After one manual End Turn and the RED AI phase, BLUE Turn 3 showed no Bonus condition and Resistance 4. Both units remained at the same tiles and HP. This matches the checklist: `(1 phase)` at BLUE Turn 2, expiry at BLUE Turn 3. *(Corrected 2026-09-25: this paragraph first read the count as `(2 phase)` and called the sequence a mismatch.)* `(2 phases)` itself cannot be seen while Auto-End Turn is on; the v0.8.6 checklist turns it off for 1B.

A separate fresh replay exercised Suspend & Quit / Continue. The runner confirms the full bridge unit state stayed identical across the operation: Bearer 13 HP at (7,3), Revenant 7 HP at (8,3). The 1B screenshot sequence and JSON are in `1B-duration/ch6-land-hit/`; suspend evidence is in `1B-duration-suspend/ch6-suspend-continue/`.

| Checklist item | Result | Observation |
|---|---|---|
| Restore, stale row / Retry, exact two-unit board | PASS with clarity note | Restore result explicitly read 1 campaign package installed, 2 saves restored, 0 failures. Retry and Load reached the expected live board. Initial save row behavior is captured in steps 06–08. It was Turn 1 on resume as specified. |
| Pre-hit Resistance and first landed Hallowed hit | PASS | See attack/Unit Details screenshots; 24/22 HP before, 13/7 after. |
| Hit Details: Hallowed Sear and Resistance -3 | PASS (screenshot) | Screenshot displays `Hallowed Sear -3 (1 phase)` and Res 1 at BLUE Turn 2 (corrected 2026-09-25; first misread as `(2 phase)`). |
| Turn count after one BLUE/RED cycle | PASS | `(1 phase)` at BLUE Turn 2 (the hit auto-ended BLUE's phase), gone at BLUE Turn 3 with Resistance 4. Corrected 2026-09-25 from FAIL. |
| Suspend & Quit / Continue preserves state | PASS | Taken at `(1 phase)`; HP and tiles match before/after, and Details after Continue still reads `(1 phase)` (screenshot comparison; the counter is not in bridge state). Corrected 2026-09-25. |
| Expiry without death/movement | PASS | Condition absent by Turn 3; both units survived and remained at the recorded positions. |

### 1C — Load Game with saves in it

BLOCKED / partial. The 1B restore screen captured a loadable `Resume battle` row beside `[Autosave] Campaign Autosave` still marked `[Needs campaign]` (`1B-duration/ch6-land-hit/07-retry-restored-campaign-save.png` and JSON). The separate campaign-backup journey ran in a fresh browser context, so it did not retain those 1B rows. I attempted to compose both restores in one Playwright context, but the manual restore-picker interaction did not reach a reliable selected-file/result state; no combined-list screenshot was produced. Therefore the exact Section 1C recipe (both backup families side-by-side before Retry) remains unverified. The observed 1B mixed state is supporting partial evidence only.

## Section 2 — carried editor and font fixes

PARTIAL. The Campaign Editor shell opened at 1920×1080, but this clean browser profile had no campaign working copy: the editor visibly said “No working copy” and “No document open.” (`final-attempts/editor-direct-1920.png`). Thus the default Campaign record, Rules truncation/hover, editing/saving and scale restoration could not be tested. Settings was opened manually; captures exist at 1280×720, 500×700/1× and 500×700/0.5×. At 500×700, the settings panel has a scrollbar, but the scale sliders reported clipped below the viewport, and a wheel attempt did not expose them. The 2× settings surface was not reached: direct 2× launch placed the Main Menu Settings button outside the clipped menu viewport. No free-roam pack was active in these final screen probes, so pack-font behavior, Map Menu/Prep and no-pack transition remain unverified.

## Section 3 — attack forecast and weapon relationships

The Prologue fixture was manually driven by Playwright from import/restore through moving Unit_02, selecting Attack and opening the forecast. It produced the expected attacker `▼ Weapon Triangle -10 Hit, -2 Dmg` and defender `▲ Weapon Triangle +10 Hit, +2 Dmg`; the Playwright journey reported 14 actions passed. Evidence (screenshot and bridge JSON) is under `3-forecasts/prologue/interaction-readout/`, with row strings in `interaction-readout-rows.json`.

The Chapter 3 two-row fixture has also reached the forecast at 1280×720/1× and shows exactly the expected three rows: attacker Weapon Triangle −10 Hit/−2 Dmg; defender Weapon Triangle +10 Hit/+2 Dmg; defender Weapon Effectiveness ×3 Might. Evidence is under `3-forecasts/ch3-1280/interaction-readout/`; visual screenshot confirms the separate defender rows are readable at the default size. Prologue and Chapter 3 row text are verified from interactive forecast screens, not only fixture receipts. Chapter 1 Fire versus Thunder also produced zero rows, as expected, and Chapter 3 Unit_04 Fire versus the Chapel Bishop produced the expected `+10 Hit/+2 Dmg` attacker row and `-10 Hit/-2 Dmg` defender row. Both were real 14-action Playwright journeys; evidence is under `3-forecasts/ch1-fire-thunder/interaction-readout/` and `3-forecasts/ch3-magic/interaction-readout/`. Chapter 3 layout was also driven at 900×760 and 560×900. At 900×760 the panel remained three columns side by side (attacker, defender, More Info) rather than moving More Info below the other two as the checklist says; the rows were readable and on-screen, but the layout expectation is a FAIL. At 560×900 it stacked all three blocks vertically inside the panel (panel x=218, width=326, right edge 544/560), and the two defender rows stayed separate/readable; comparison is possible though the narrow screenshot makes the text small. Evidence is under `3-forecasts/ch3-900x760/interaction-readout/` and `3-forecasts/ch3-560x900/interaction-readout/`. The Chapter 1 Horseslayer equip path was driven by selecting Equip, choosing Horseslayer, then attacking E3_Cavalier. The forecast showed `▲ Weapon Effectiveness ×3 Might` and damage `29×1`; evidence is under `3-forecasts/ch1-equip/ch1-equip/`. The requested Chapter 3 layout cases at 1920×1080 and 1280×720/0.5× were captured; the 1280×720/2× forecast was not reached. A full 15-action F-key More Info cycle on Chapter 3 revealed all three authored rows; see `3-forecasts/ch3-moreinfo-cycle/interaction-readout/` (journey JSON and step screenshot). Numeric damage-vs-unequipped baseline was not measured. Controller pad-button 2 is NATIVE-ONLY in this browser.

## Sections 4–5 — remaining walkthrough

Section 4 now has live Chapter 6 forecast evidence. The control fixture board contains both Hallowed Bearer (24 HP at (2,3)) and Free Company Axeman (24 HP at (6,3)) alongside the Revenants. Bearer forecast: Hallowed Rites +5 Dmg, Hit 89%, Dmg 15×1, Crit 3%; Revenant: Hit 70%, Dmg 11×1, Crit 0%. Axeman forecast: Undead Frailty +1 Dmg, Hit 84%, Dmg 12×1, Crit 3%; Revenant: Hit 72%, Dmg 11×1, Crit 0%. The F-key More Info screenshot text says “Overrides in this fight: Undead Frailty.” and contains no snake_case internal ID. The 1B hit details show Hallowed Sear. The Revenant’s effective Resistance was 1 while the Bonus section showed Hallowed Sear −3 (baseline Resistance 4 after expiry); the checklist phrase “Resistance shows −3” could be read as the Resistance stat itself, but the −3 appears under Bonus. The countdown matches the checklist (corrected 2026-09-25). Section 5: `campaign_backup_v2.zip` restored and produced a saved Prologue Prep row. Load Game initially displayed `[Needs campaign] ... Campaign package not installed.` as the checklist predicts for a row drawn before Retry. The stale text was momentarily jarring after the restore result said the package installed, but the explicit Retry instruction resolved it; it did not stop the run. The occupied-slot replacement confirmation was manually opened; it says `Press Enter to keep the existing saves.` with Keep Existing selected. Escape canceled replacement, and the harness proved the original save surface and exported save bytes were unchanged. Evidence is under `5-restore-cancel/restore-cancel/`, with the confirmation screenshot at `11-open-occupied-slot-replacement-confirmation.png`. A separate campaign-backup Retry/Load journey passed: the restored Prologue save retried and loaded into Prep, and the runner verified a return to the same campaign map node. Evidence is under `5-campaign-backup-load/prep-return/`. Migration and collision packs, other dialogs, Settings sizes/scales and diagnostics were not exercised manually. Export Diagnostics fields for native Windows/GPU/DPI/window mode are NATIVE-ONLY.

## Checklist clarity notes collected so far

- Section 1B correctly says the restored battle begins at Turn 1. The header advanced to Turn 2 immediately after the first hit because the Bearer is BLUE's only unit and Auto-End Turn ended the phase. The checklist never says so, and `(2 phases)` cannot be seen at all with Auto-End Turn on. (Diagnosed 2026-09-25; the v0.8.6 checklist turns Auto-End Turn off for 1B.)
- Unit Details is not exposed by the browser bridge (`screen` resolves as `hud`), so condition name/count, Resistance and other text must be read from the screenshot, as the kit README warns.

## Coverage matrix (live status)

| Section | Coverage |
|---|---|
| 0 identity | PASS / partial clean-profile capture |
| 1A live-map font grid | 9 PASS, 3 FAIL at 2× for 1280×720, 900×760 and 560×900 |
| 1B countdown, AI, suspend/continue | PASS (corrected 2026-09-25) |
| 1C populated Load Game | partial mixed state in 1B; combined campaign-backup row BLOCKED |
| 2 Campaign Editor and font surfaces | editor shell opened but no working copy; Settings sampled at 1280, 500×700 and 0.5×; pack-font/map/prep/no-pack checks blocked |
| 3 weapon forecasts and controls | Expected rows pass for Prologue, Ch3, Ch1 neutral, Ch3 magic and equip; 1920/900/560 layouts plus 1280×720/0.5× driven; 900 More Info position differs from checklist; 1280×720/2× not obtained |
| 4 internal Chapter 6 interaction | both units alive; forecast stats and suppression explanation PASS; condition breakdown and countdown verified (corrected 2026-09-25) |
| 5 save packs, dialogs, settings, diagnostics | campaign restore/retry and replace-save safe dialog PASS; remaining pack/dialog/settings checks BLOCKED; diagnostics NATIVE-ONLY |
| 6 included gate receipts and screenshot skim | Supplemental album and pack-gate screenshots visually skimmed; six pack receipts/integrity were also parent-verified. See Section 6 disposition below |

## Final checklist verdict register

`PASS`/`FAIL` below is the tester-style verdict for directly driven behavior. `BLOCKED` means this pass did not produce a direct observation for the exact item; it does not mean the candidate failed. Native diagnostics/controller items are `NATIVE-ONLY`. Relative paths point into this report's `agent-walk/` directory.

| Checklist item | Verdict | Evidence / observation |
|---|---|---|
| 0 — BUILD_INFO, SHA sums, executable stamp and menu identity agree | PASS (version/commit artifacts); PARTIAL (menu) | Web and release manifests match 0.8.5 / `02d552da`; both executable hashes verify. Main Menu screenshots show `v0.8.5`, but the menu does not display the source commit. See `1A-live/1280x720-1/01-boot.png`; manifests are in the staged bundle. |
| 0 — Clean profile, empty New Game and Load Game | BLOCKED | Fixture sessions were used to reach maps; no pristine empty-state capture. |
| 0 — Import original free-roam ZIP | PASS | Fresh direct import succeeded in all 12 runs. Example `1A-live/1280x720-1/live-map-capture.json`. |
| 1A — 1280×720, both scales 0.5× | PASS | `1A-live/1280x720-0.5/01-live-map.png` |
| 1A — 1280×720, both scales 1.0× | PASS | `1A-live/1280x720-1/01-live-map.png` |
| 1A — 1280×720, both scales 2.0× | FAIL | Objectives overlaps Unit_01 and text collides. `1A-live/1280x720-2-resized-after-start/01-live-map.png` |
| 1A — 1920×1080, both scales 0.5× | PASS | `1A-live/1920x1080-0.5/01-live-map.png` |
| 1A — 1920×1080, both scales 1.0× | PASS | `1A-live/1920x1080-1/01-live-map.png` |
| 1A — 1920×1080, both scales 2.0× | PASS | `1A-live/1920x1080-2/01-live-map.png` |
| 1A — 900×760, both scales 0.5× | PASS | `1A-live/900x760-0.5/01-live-map.png` |
| 1A — 900×760, both scales 1.0× | PASS | `1A-live/900x760-1/01-live-map.png` |
| 1A — 900×760, both scales 2.0× | FAIL | Objectives/Unit_01 and Unit_01/terrain overlap with colliding text. `1A-live/900x760-2-resized-after-start/01-live-map.png` |
| 1A — 560×900, both scales 0.5× | PASS | `1A-live/560x900-0.5/01-live-map.png` |
| 1A — 560×900, both scales 1.0× | PASS | Panel text remains separate/readable despite the tight panel boundary. `1A-live/560x900-1/01-live-map.png` |
| 1A — 560×900, both scales 2.0× | FAIL | At 280×450 logical view, panels overlap extensively and text collides/clips across panels and screen edges. `1A-live/560x900-2-resized-after-start/01-live-map.png` |
| 1B — Restore supplied duration backup; Retry and load; exact board | PASS | Started Turn 1; Bearer 24 HP (2,3), Revenant 22 HP (8,3). `1B-duration/ch6-land-hit/06-open-load-game.png`, steps 07–09 JSON/screenshots. |
| 1B — Note pre-hit Resistance; hit Revenant; inspect Hallowed Sear | PARTIAL | Hit and post-hit Details were captured; the explicit pre-hit Details step was skipped. After the hit, Details shows `Hallowed Sear -3 (1 phase)` (corrected 2026-09-25), effective Res 1; see `1B-duration/ch6-land-hit/19-press-more-info-x7-class-hp-str-mag-ski-spd-def-res.png`. |
| 1B — Do not attack again; Wait and end later BLUE turns | PASS (no further attacks) | The journey performed no further attacks; bearer/revenant stayed alive. |
| 1B — RED AI phase then BLUE Turn 2 shows `(1 phase)` | PASS | The hit auto-ended BLUE's phase (only BLUE unit), RED's AI phase ran, and BLUE Turn 2 shows `(1 phase)` (step 19). Corrected 2026-09-25 from FAIL: the pixel-font 1 was misread as 2. |
| 1B — Suspend & Quit at `(1 phase)`, Continue, compare condition/HP/tiles | PASS | The replay suspended at BLUE Turn 2, `(1 phase)`; after Continue, HP/tiles are identical and Details still reads `(1 phase)`: `1B-duration-suspend/ch6-suspend-continue/` steps 18 and 26. Corrected 2026-09-25 from BLOCKED. |
| 1B — Expiry and Resistance return, no death/movement | PASS | At Turn 3, no Bonus remained and Resistance was 4; both units remained 13/7 HP at (7,3)/(8,3). Screenshot step 24; bridge state steps 27–29. |
| 1C — Load Game at 1280×720 shows a loadable and not-loadable row after Section 5 restore | BLOCKED / partial | 1B captured mixed rows after Retry (Resume battle loadable; Autosave `[Needs campaign]`) at `1B-duration/ch6-land-hit/07-retry-restored-campaign-save.png`. The campaign-backup row was not present in that same browser profile, so the exact combined recipe is unverified. |
| 1C — Record installed packs and standard font with internal pack active | BLOCKED | No Load Game screenshot after campaign-backup restore with internal pack active. |
| 2 — Campaign Editor default Campaign fits; Rules truncates to ≤6 lines/ellipsis and hover reveals full value | BLOCKED | Editor shell opened at 1920×1080 but showed “No working copy”; see `final-attempts/editor-direct-1920.png`. No campaign record was available. |
| 2 — Change Campaign value, save, dirty state clears, Menu Scale restored on close | BLOCKED | Editor save workflow not driven. |
| 2 — Free-roam font on Settings, HUD, Map Menu, Prep and forecast | PARTIAL | HUD confirmed in 1A; forecast rendered with pack journeys but font appearance was not separately judged; final Settings probe had no active pack. Map Menu/Prep font not judged. |
| 2 — Campaign Editor uses standard font under free-roam pack | BLOCKED | Editor shell opened but no working copy/active pack; screenshot `final-attempts/editor-direct-1920.png`. |
| 2 — No-pack standard font restored across HUD/Map Menu/Prep | BLOCKED | No-pack reset not driven. |
| 3 — Ch3 Unit_06 vs Bridge Fighter expected attacker/defender rows | PASS | Exact three rows in `3-forecasts/ch3-1280/interaction-readout/interaction-readout-rows.json`. |
| 3 — Ch3 at 1280×720, three columns/readable | PASS | `3-forecasts/ch3-1280/interaction-readout/14-read-the-authored-interaction-rows.png` |
| 3 — Ch3 at 1920×1080, three columns/readable | PASS | `3-forecasts/ch3-1920x1080-1/interaction-readout/14-read-the-authored-interaction-rows.png` |
| 3 — Ch3 at 900×760, More Info below first two | NOT TESTED as specified (corrected 2026-09-25 from FAIL) | The run used the fresh profile's automatic scales (content 0.5, menu 1.0; logical 1800×1520), where three columns is correct. At the checklist's 1.0/1.0 the canvas is 900 wide and the forecast picks two columns (unit-tested). `3-forecasts/ch3-900x760/interaction-readout/14-read-the-authored-interaction-rows.png` |
| 3 — Ch3 at 560×900, all three stacked and easy to compare | PASS with usability note | All three stacked; rows legible and separated but small. `3-forecasts/ch3-560x900/interaction-readout/14-read-the-authored-interaction-rows.png` |
| 3 — Ch3 at 1280×720, both scales 0.5× and 2× | PARTIAL | 0.5× driven; rows stay separate in `3-forecasts/ch3-1280x720-0.5/interaction-readout/14-read-the-authored-interaction-rows.png`. The 2× forecast was not reached. |
| 3 — Prologue sword vs lance; Unit_01 lance vs lance has no row | PARTIAL | Unit_02 vs dummy PASS, exact rows in `3-forecasts/prologue/interaction-readout/interaction-readout-rows.json`; Unit_01 same-weapon no-row case not driven. |
| 3 — Ch1 Fire vs Thunder neutral | PASS | Zero rows in `3-forecasts/ch1-fire-thunder/interaction-readout/interaction-readout-rows.json`. |
| 3 — Ch3 Fire vs light tome magic triangle | PASS | `+10/-10 Hit`, `+2/-2 Dmg` in `3-forecasts/ch3-magic/interaction-readout/interaction-readout-rows.json`. |
| 3 — Equip Horseslayer vs E3_Cavalier, effectiveness and damage arithmetic | PASS for row/equipped damage; PARTIAL arithmetic | Equipping was driven; Horseslayer `Dmg 29×1`, ×3 Might row in `3-forecasts/ch1-equip/ch1-equip/ch1-equip-rows.json`. The damage delta was not separately calculated against an unequipped baseline. |
| 3 — Reach every More Info row by mouse and F; Enter confirms; pad 2 works | PARTIAL / NATIVE-ONLY | Full Chapter 3 F-key cycle exposed all 3 rows (`3-forecasts/ch3-moreinfo-cycle/interaction-readout/`); Hallowed Rites More Info showed the suppression sentence (`4-ch6-bearer-moreinfo/interaction-readout/`). Mouse-per-row and Enter confirmation were not separately tested. Pad button 2 is NATIVE-ONLY. |
| 4 — Reach internal Ch6 with Bearer and Axeman alive; non-weapon stats identical | PARTIAL | Both alive and 24 HP in control fixture board `4-ch6-axeman/interaction-readout/09-assert-map-006-hallowed-is-the-live-board.json`; full stats comparison not recorded. |
| 4 — Bearer and Axeman forecasts; record Hit/Dmg/Crit | PASS | Bearer 89/15×1/3%, Revenant 70/11×1/0%; Axeman 84/12×1/3%, Revenant 72/11×1/0%. Forecast snapshots at `1B-duration/ch6-land-hit/14-read-the-authored-interaction-rows-before-committing.json` and `4-ch6-axeman/interaction-readout/14-read-the-authored-interaction-rows.json`. |
| 4 — Bearer omits Undead Frailty; More Info says Overrides; no internal IDs | PASS | Hallowed Rites F-cycle result has exact player-facing suppression line and no snake_case: `4-ch6-bearer-moreinfo/interaction-readout/15-cycle-more-info-to-an-interaction-row.json`. |
| 4 — Land Hallowed hit; Details names Sear and phase count; Resistance breakdown sums to total | PASS for observed hit/breakdown | Screenshot shows Sear −3 at `(1 phase)` and effective Res 1; after expiry Res 4. Evidence under `1B-duration/ch6-land-hit/` (steps 19, 24). Countdown matches the checklist (corrected 2026-09-25). |
| 5 — Restore campaign_backup_v2.zip; before Retry do 1C | PARTIAL | Restore and stale campaign row captured in `5-restore-cancel/restore-cancel/`; prescribed combined list was not available in this fresh profile. |
| 5 — Retry campaign backup row loads correct campaign and Prep | PASS | 11-action Prep journey passed; `5-campaign-backup-load/prep-return/08-load-campaign-slot-node-00-drill-prep-1789157303583.png` and `journey.json`. |
| 5 — Import migration-v1/v2; refused save names missing/mismatched content plainly | BLOCKED | No manual migration-save refusal journey. Pack gate receipt is reference evidence only. |
| 5 — Import collision-a/b; fingerprint rows differ; wrong pack save not loaded | BLOCKED | Not manually attempted; pack gate receipts do not verify Load Game row fingerprints. |
| 5 — End Turn dialog safe default and Enter description | BLOCKED | End Turn was activated in the countdown journey, but the confirmation surface was not captured before confirming. |
| 5 — Suspend & Quit dialog safe default and Enter description | BLOCKED | Suspend/Continue state was exercised; dialog text/focus before confirmation was not captured. |
| 5 — Quit to Menu destructive-progress dialog | BLOCKED | Not driven. |
| 5 — Replace save dialog safe default and Enter description | PASS | `Press Enter to keep the existing saves.`; Keep Existing focused; cancellation preserved save bytes. `5-restore-cancel/restore-cancel/11-open-occupied-slot-replacement-confirmation.png` and `replacement-cancel-proof.json`. |
| 5 — Settings below 600 px, scale 0.5× and 2× | PARTIAL | Manually opened Settings; 500×700/1× screenshot `final-attempts/04-settings-500x700-1x.png`; 500×700/0.5× screenshot `final-attempts/settings-500x700-0_5x.png`. The panel has a scrollbar, but lower scale controls were clipped and a wheel attempt did not expose them. 2× direct launch clipped Settings off the Main Menu; the 2× Settings view was not reached. |
| 5 — Export Diagnostics includes v0.8.5, Windows, GPU, display, DPI, window mode, packs | NATIVE-ONLY | The Linux web export cannot generate/verify the native Windows Diagnostics ZIP. |
| 6 — Supplemental Playwright gate and pack gate receipts | PASS as included reference only | Parent verified bundle integrity and the six pack receipts; no gate was re-run. |
| 6 — Skim both evidence folders for clipping, overlap or box glyphs | PASS with caveat | Visually skimmed all 40 supplemental screenshots in `screenshot-album/` (contact sheets `section6-skim/supplemental-01.jpg` through `supplemental-04.jpg`) and all 46 pack screenshots in `pack-gate-evidence/` (sheets `section6-skim/packs-01.jpg` through `packs-05.jpg`). Also inspected full-size `screenshot-album/settings__1280x800__menu-2__content-2__safe-12-20-12-24.png`, `screenshot-album/prep__1279x719__menu-0.5__content-0.5__safe-17-11-29-23.png`, and `pack-gate-evidence/internal-single_map__map_006_hallowed.png`. No unexpected clipping, overlap or box glyphs stood out in the pack maps or Settings sample. The HUD screenshots show Main Menu behind the HUD and Game Over uses placeholder “Victory!”; the checklist identifies both as harness artifacts, not live-map evidence. The 0.5× Prep sample is unusually small/sparse, so usability is not established by this skim. |
| 7 — Two relationship rows readable and useful | PASS with layout caveat | Ch3 default forecast keeps attacker and defender rows distinct/readable; at 560×900 they remain separate but small. The 900×760 layout differs from the checklist, as recorded in Section 3. |
| 7 — More Info explains why Undead Frailty is missing | PASS, qualified | “Overrides in this fight: Undead Frailty.” identifies the replacement relationship, but “overrides” may be abstract to a first-time player. Evidence in `4-ch6-bearer-moreinfo/interaction-readout/`. |
| 7 — Relationship names sound like game language, not programmer labels | PASS for observed strings | “Weapon Triangle,” “Weapon Effectiveness,” “Hallowed Rites,” and “Undead Frailty” read as player-facing terms; inspected More Info text contains no snake_case identifier. |
| 7 — Condition name/countdown/−3 explain Resistance | PARTIAL | Details says `Hallowed Sear -3 (1 phase)` and effective Resistance is 1; after expiry it is 4. The arithmetic (4−3=1) is inferable, but checklist wording “Resistance shows −3” is imprecise: −3 appears under Bonus and 1 is the total. |
| 7 — Count goes down once, not twice, across BLUE and RED phases | PASS (mechanics); player judgement still owed | `(1 phase)` after one BLUE+RED pair, gone after the next. Corrected 2026-09-25. Note the walk itself misread the count because the pixel font's 1 looks like "I" — a legibility finding in its own right. |
| 7 — Game playable, clear and polished as stands | MIXED / not accepted | Baseline live-map cases and normal-size forecast rows were readable. Three smaller 2× live-map cases fail with panel/text overlap, and timing/editor/other surface coverage remains incomplete; this pass cannot call the release polished overall. |
| 7 — Return checklist, diagnostics, screenshots, Windows/GPU/display, stamp, sections and repro save | PARTIAL return | This report and screenshots/state evidence are under `agent-walk/`; sections and repro evidence are itemized above. No native Diagnostics ZIP, Windows/GPU/display/DPI/window-mode details, Windows BUILD STAMP or new save export were produced in this Linux headless run. Candidate identity is evidenced by manifests and hashes only. |
| 7 — Delete copy of `internal.zip` | NOT DONE / no separate copy | No separate archive working copy was created. The staged candidate’s `campaign-packs/internal.zip` remains in place; I did not alter candidate files outside `agent-walk/`. No raw archive is duplicated in the report evidence. |

## Section 6 visual skim and Section 7 tester answers

The two requested evidence folders were visually skimmed after the interactive runs. All 40 supplemental screenshots and all 46 pack-gate screenshots were assembled into labeled contact sheets under `section6-skim/`; several full-size examples were then inspected. No unexpected text clipping, overlap or box glyphs stood out in the pack maps or the full-size Settings example. The screenshot album includes expected harness artifacts: HUD captures have the Main Menu behind them, and Game Over says “Victory!” without a battle result. These limitations are stated in the checklist itself. The 0.5× Prep screenshot is unusually small/sparse; this evidence alone does not establish usability.

Tester judgments: the two relationship rows are useful/readable in the default forecast, but become small on the narrow stacked layout. The More Info sentence names Undead Frailty and makes the suppression/replacement clear at a basic level, though “overrides” may be unfamiliar. The observed relationship names are player-facing terms. The condition arithmetic is inferable from baseline Resistance 4, −3 bonus, and effective Resistance 1, but the checklist phrasing is imprecise because −3 appears under Bonus, not as the total. The count went down once across a BLUE and a RED phase, as specified (corrected 2026-09-25). Overall playability/polish is mixed: expected basic forecasts and most live-map cases look clear, while the three smaller 2× HUD cases fail and timing/editor coverage remains incomplete.

Return/deletion disposition: this report and its screenshots/state evidence are in `agent-walk/`. The browser environment was Linux x86_64 WSL2 headless Chrome with SwiftShader; no Windows host, physical display, GPU, DPI, window mode, native BUILD STAMP or Diagnostics ZIP was available. Manifests and SHA sums identify the candidate source SHA; they are not a substitute for a native stamp. No separate `internal.zip` working copy was made, and the staged candidate archive remains untouched per the instruction not to change candidate files outside this directory. No new save export was produced.

## Coverage summary

- Section 1A: 12/12 requested live-map captures made; 9 PASS and 3 FAIL (all three at 2× on smaller viewports).
- Interactive browser sections: Section 1B duration sequence and save persistence, Section 3 forecast cases, Section 4 combat forecasts, and selected Section 5 restore/save flows were driven. Section 1C combined list, Campaign Editor working-copy workflow, migration/collision dialogs, and most confirmation dialogs remain explicitly blocked or partial in the register.
- Each operational checklist item and all Section 6/7 prompts have an explicit verdict or disposition below. This is partial execution: BLOCKED and NATIVE-ONLY items remain outstanding. Evidence references are relative to this `agent-walk/` directory.

## Tester judgement and limitations

- The release export identity is exact, and the 1A live-map rejection is reproducible at 2× for the three smaller viewports. At 1920×1080/2× and all 0.5×/1× cases in the tested grid, the three text panels remained legible and separate.
- The expected 900×760 forecast reflow does not match what the current web export renders: it still uses three side-by-side blocks, though the rows fit. At 560×900, the forecast stacks and remains comparable.
- Section 1B is resolved (2026-09-25): the Turn 1 → Turn 2 jump is Auto-End Turn, and the count read `(1 phase)`, as specified.
- Web runs use SwiftShader and cannot certify Windows GPU, DPI, display, window mode, controller input or the native executable. Bundle manifests and hashes were inspected, but the Windows executables were not launched.
