---
Role: dated
Type: playtest
Status: Session 2 found a 1280x720/2x forecast overflow; candidate acceptance stopped
---

# v0.8.6 agent browser walk report

**SESSION 2 FOUND A PRODUCT FAILURE (2026-09-26) — v0.8.6 acceptance is stopped pending a forecast fix and recut.**

At 1280×720 with Menu Scale and Viewport Scale both 2×, the live Chapter 3 Knight
versus Bridge Fighter forecast extends below the window. The defender's relationship
rows are offscreen. The browser journey still reported 14/14 actions passed because
the bridge publishes those offscreen rows; the screenshot and panel geometry are the
visual verdict. `2-session2-forecast-1280x720-2.0/` has the exact release-web
reproducer. Its panel rect is x=208, y=32, w=656, h=1298 in rendered pixels against
the 1280×720 window. At 560×900/1×, 900×760/1×, 1920×1080/1× and
1280×720/0.5×, the same authored forecast reached the final screen with the three
expected relationship rows and fit inside the window. The 1280×720/2× defect needs
a focused product fix, a new export, and a complete forecast size retest before
native acceptance. The candidate source remains `36686b0a`.

Session 2 also captured the active free-roam font on Prep, HUD, Map Menu and Settings
at 1280×720/1× (`2-session2-font-surfaces/`). Settings opened from the live Map Menu;
the bridge reported `hud` while Settings was visibly on top, so its screen label is a
bridge ordering limitation. At 560×900/0.5× and 2×, mouse-wheel scrolling reached
the bottom of Settings, including Export Diagnostics and Back
(`2-session2-settings-560-*/`). Keyboard and scroll-bar access, font restoration after
pack deactivation, the four dialogs and the native readability judgment remain open.

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

## Focused retest plan — next sessions

Use this sequence against source commit `36686b0a` and the v0.8.6 bundle. Carry
forward the passing evidence above; repeat a passed case only when a finding or a
new candidate changes it. At the end of each session, add the exact build identity,
result, screenshot or state path, and next action to this report and the
`V086-CANDIDATE-CUT-2026-09-25` tracker row. A confirmed product failure stops
acceptance and gets a focused fix/recut task. A harness failure stays explicitly
unverified until the behavior is observed through another route.

| Session | Focus and order | Evidence needed to finish |
|---|---|---|
| 1 — Resolve current blockers | **Done 2026-09-26**, except native hover/readability checks. The step-35 timeout was caused by the driver's extra Enter; turn-3 expiry passed. Both mixed Load Game rows can be exposed by scrolling. Rules wrap, edit/save, and scale restoration passed; hover text did not appear in headless Chromium. | `1B-retest-20260926/`, `1C-retest-scroll-20260926/`, `2-editor-retest-commit-20260926/`; native hover/readability remains in Session 4. |
| 2 — UI and viewport pass | **Stopped on product failure 2026-09-26.** The 1280×720/2× forecast extends below the window. Four other requested forecast layouts passed their browser journey. Prep, HUD, Map Menu and Settings with free-roam active were captured; the Settings wheel reached the bottom at 560×900/0.5× and 2×. | Fix and recut the forecast, then rerun all requested sizes including 1280×720/1×. Pack deactivation/font restoration, dialogs, keyboard/scroll-bar Settings access and native readability remain. |
| 3 — Content and save rules | Run the remaining Section 3 matchups (Prologue, Chapter 1, Chapel Bishop, Horseslayer), numeric damage delta, and mouse/F/Enter/More Info access. In Chapter 6 compare Bearer and Axeman Hit/Dmg/Crit against one Revenant, confirm Bearer has no Undead Frailty row, land a Hallowed hit and capture the Resistance breakdown. Test migration-v1/v2 refusal text and collision-a/b fingerprints and wrong-pack save protection. | Forecast screenshots and values; Chapter 6 condition/breakdown; migration error text and collision save identity. Note any checks that require a fresh save or pack state. |
| 4 — Native Windows acceptance | Run the remaining checklist on the shipped release executable: BUILD STAMP/SHA identity, clean profile, representative 1A layouts on the actual GPU/DPI, the full 1B countdown, populated 1C list, editor at 1920×1080 and Windows 125% scaling, controller navigation, Diagnostics ZIP, and the Section 7 player judgments. Return the checklist, diagnostics, failed-check screenshots, display/GPU/DPI details, and any reproducer save. | Human Windows return reviewed against Sections 0–7. Accept only if all required items pass; otherwise record the finding and recut decision in the tracker. |

The next session starts with Session 2 or 3. Session 4 uses the exact candidate
that survives those checks.

## 1. Header

- Build identity: `artifact-manifest.json` in `builds/web/Project_Prometheus` reports
  `source_sha=36686b0a07677b130e80f64045376877c3ca9898`, `commit=36686b0a`,
  `version=0.8.6`, `build_type=release`, `godot_version=4.6.3.stable.official.7d41c59c4`.
  This matches the commit required for this round. The tester bundle's
  `bundle-pack-gate-receipt.json` and `playwright-supplemental-gate-receipt.json` both
  also name `36686b0a07677b130e80f64045376877c3ca9898` for the same tree.
- Date: 2026-09-25 (harness run date).
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
| 0 — Build identity | PASS | manifest + both receipts agree on 36686b0a |
| 0 — Clean profile empty states | PASS | Fresh browser contexts: Load Game says “No campaign saves yet”; New Game reports 0 compatible records. Evidence: `0-clean-load/`, `0-clean-new-game/`. |
| 0 — Import free-roam.zip | PASS | done during 1A/1B/3 runs, unmodified zip via file chooser |
| 1A — 12 live-map cases | PASS (12/12) | zero panel-to-panel overlaps measured; see detail |
| 1A — three "on purpose" behaviours | PASS (all 3) | Objectives collapse/restore, 2x(1x) cap, unit-above-terrain |
| 1B | PASS (browser) | Corrected driver reached BLUE turn 3: condition gone, Resistance 4 restored, HP/tiles unchanged. Native release check remains. |
| 1C | PASS for scrolling; native readability pending | The lower row becomes fully visible when the list is scrolled; row text fits its control. |
| 2 | PARTIAL | Rules six-line ellipsis, dirty → saved, and scale restore passed. Full hover text did not appear in headless Chromium; other font surfaces remain pending. |
| 3 | PARTIAL | Chapter 3 Knight vs Bridge Fighter browser forecast passed with all three expected rows. Other matchups, viewport comparisons, mouse/pad navigation and damage arithmetic remain pending. |
| 4 | PARTIAL | Chapter 6 browser fixtures confirmed Bearer `Hallowed Rites +5 Dmg`, Axeman `Undead Frailty +1 Dmg`, and More Info suppression sentence. No hit/condition expiry or full stats/Hit/Dmg/Crit comparison. |
| 5 | PARTIAL | 1C mixed save-list and Retry→Prep succeeded; small Settings screens captured at 0.5×/2×, but scroll behavior not verified. Migration/collision, confirmation-dialog, and Diagnostics checks remain. |
| 6 | PASS (skim) | v0.8.6 supplemental receipt passed (40 cases, zero errors); pack-gate receipt passed. Visually skimmed all 40 album images and all 46 pack screenshots; contact sheets at `section6-skim/`. |
| 7 | PARTIAL | Browser evidence supports row labels/readability only; native and subjective judgments remain pending. |

## 3. Defects found

The 1280×720/2× forecast extends below the window, hiding the defender's
relationship rows. This is a confirmed product failure in Session 2, so v0.8.6
acceptance is stopped pending a focused fix and recut. The original 1B timeout was
a harness error: End Turn had already advanced to BLUE turn 3 with a free cursor;
the extra Enter selected the Bearer. The corrected run passed the expiry check.

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
HP and tiles. The native Windows countdown and human digit judgment remain open.

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
campaign-font use elsewhere.

### Sections 3–5 and 7 — Item-level disposition

See the checklist disposition table below. Items that require further independent
browser flows were left open; items requiring native Windows display/input or human
judgment remain explicitly pending.

### Section 3 — Attack forecast and weapon relationships

Built a Chapter 3 forecast fixture from the v0.8.6 Proving Grounds campaign data and
ran it against the exact 36686b0a web export. The 14-action browser journey passed.
The attack forecast showed Unit_06 Knight’s `▼ Weapon Triangle -10 Hit, -2 Dmg`,
the Bridge Fighter’s `▲ Weapon Triangle +10 Hit, +2 Dmg`, and `▲ Weapon
Effectiveness ×3 Might`. Text and the three relationship rows were separate and
readable at 1280×720. Evidence and fixture sidecar are in
`3-forecasts/c3-knight-bridge/`. Other checklist matchups and viewport variants were
not run here.

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
backup row retried and loaded into Prep. See Section 1C above. Settings was also
opened at 560×900 with Menu/Content Scale set to 0.5× and 2×. Both browser snapshots
rendered the Settings screen with a scrollbar, but lower controls extended beyond the
visible area; no wheel, scrollbar, or keyboard scroll-to-bottom check was completed.
See `5-settings-560x900-0.5/` and `5-settings-560x900-2.0/`. Migration/collision
saves, confirmation dialogs, and native Diagnostics export remain pending.

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
| 2 — Free-roam font on Settings/HUD/Map Menu/Prep/forecast | NOT RUN | 1A covers only live map; other surfaces not driven. |
| 2 — Campaign Editor uses standard font | NOT RUN | Not checked. |
| 2 — Standard font after pack removal | NOT RUN | Not checked. |
| 3 — Ch3 Knight vs Bridge Fighter relationship rows | PASS | Three rows captured in live forecast at 1280×720. |
| 3 — Forecast layout at requested sizes/scales | NOT RUN | One default-size browser capture only. |
| 3 — Prologue weapon triangle cases | NOT RUN | Not driven. |
| 3 — Ch1 Fire vs Thunder neutral | NOT RUN | Not driven. |
| 3 — Ch3 Fire vs Bishop magic triangle | NOT RUN | Not driven. |
| 3 — Horseslayer effectiveness and damage delta | NOT RUN | Not driven. |
| 3 — Mouse/F/Enter/pad navigation | PARTIAL | Browser F/Enter journey path exercised; mouse-per-row and pad input not tested. |
| 4 — Chapter 6 party/stat identity | PARTIAL | Fixtures reached the live Chapter 6 scenario; full identical-stat comparison not recorded. |
| 4 — Bearer/Axeman forecasts | PARTIAL | Each expected player-facing row observed; comparative Hit/Dmg/Crit values not tabulated. |
| 4 — Bearer suppression and More Info wording | PASS (browser) | More Info names Undead Frailty; no programmer-style identifier in captured text. |
| 4 — Land Hallowed hit; condition/Resistance breakdown | NOT RUN | No hit or Unit Details countdown in this Section 4 continuation. |
| 5 — campaign_backup restore and Retry→Prep | PASS | Restored row loaded into Prep. |
| 5 — Migration save rejection messages | NOT RUN | Not driven. |
| 5 — Collision fingerprints and wrong-pack protection | NOT RUN | Not driven. |
| 5 — End Turn / Suspend / Quit / replace-save dialogs | NOT RUN | Dialogs were not captured before confirmation. |
| 5 — Settings under 600px at 0.5×/2× and scrolling | PARTIAL | 560×900 screenshots captured at 0.5× and 2×; scrollbars visible, but reaching lower controls was not verified. |
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
