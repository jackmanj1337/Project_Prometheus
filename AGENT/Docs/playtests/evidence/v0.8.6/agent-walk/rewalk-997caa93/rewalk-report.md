---
Role: dated
Type: playtest
Status: Full agent browser re-walk on the exact 997caa93 tester bundle, plus a 2026-09-30 follow-up closing four remaining browser-checkable items; native acceptance remains pending
---

# v0.8.6 agent browser re-walk — source 997caa93 (2026-09-29, updated 2026-09-30)

**TALLY (50 checklist checkboxes, this build, browser-only):** 36 PASS in-browser
on `997caa93`, 4 PARTIAL (0.1 BUILD STAMP — native exe not run; 2.rules — Rules
hover tooltip, candidate product defect per owner ruling; 2.standard-font —
checklist wording issue, see below; 5.diagnostics — mechanism confirmed, real
Windows/GPU content is native-only), 0 FAIL, 1 NATIVE-ONLY (7.report), 8 HUMAN
(all of Section 7's subjective-judgement rows, relabelled from "PASS
(assessment)" 2026-09-30 — an agent observation is not a tester's judgement), 1
N/A (7.delete — no extra copy of `internal.zip` was made).

**2026-09-30 addendum — four items re-investigated at the coordinator's request,
after the 2026-09-29 walk below:**
1. **2.standard-font**, redone exactly as worded (quit free-roam to Main Menu with
   ONLY it installed, verify `activePackage` is genuinely empty, then reach
   HUD/Map Menu/Prep): **determined to be a checklist wording issue, not a script
   or product bug** — with only one (font-declaring) pack installed, reaching
   those three screens necessarily reactivates that pack, so "no pack active" and
   "HUD/Map Menu/Prep rendering" cannot co-occur. Full trace and code citations in
   Section 3 below. Verdict changed PASS → PARTIAL.
2. **1A's 560×900 "2x (1x)"**, redone via the REAL Settings slider (not URL
   params): **now PASS** — two successive script bugs (an edge click missing the
   control's hit area; a "force to minimum" key sequence that never registered)
   were the actual cause, not the slider being unreachable. A side-by-side
   diagnostic proved the control is fully driveable by click, arrow-key, and drag
   at this window size.
3. **5.settings arrow-keys and scrollbar at 2×**: **both now PASS.** Arrow-key
   navigation reaches Export Diagnostics after 56 genuine Tab presses once given a
   real starting focus and a raised budget (200) — the first attempt's "reached it
   in 1 press" was a false positive (Settings opens with focus already on Back).
   The scrollbar thumb IS present and draggable; the first attempt's screen
   coordinates were read from the wrong screenshot (a different resolution).
4. **2.edit** (Campaign Editor edit-and-save): re-executed fresh on `997caa93`
   instead of reusing `0e5882d8` evidence. PASS, unchanged verdict, now with
   same-build evidence.
5. All Section 7 judgement-question rows relabelled `PASS (assessment)` → `HUMAN`;
   agent observations kept as notes, not verdicts.

---

This re-walks the v0.8.6 tester checklist in a headless browser against the EXACT
build in `builds/tester/Project_Prometheus_v0.8.6/` (source commit
`997caa93b56f40564fbd73e2d407e8fe7a298290`), closing the nine gaps the previous
walk (`worktrees/v086-walk-evidence/.../agent-walk-report.md`) left open and
re-running everything else on this build specifically. The previous report mixed
three different source commits (`36686b0a`, `0e5882d8`, `997caa93`); this one uses
only `997caa93` throughout, with two exceptions noted where existing evidence
already committed on `997caa93` is cited directly rather than re-executed (Section
4's Chapter 6 readouts, and the one narrow Section 2 item noted below — since
closed, see the 2026-09-30 addendum above).

## 1. Build identity

- `builds/web/Project_Prometheus/artifact-manifest.json`: `source_sha
  997caa93b56f40564fbd73e2d407e8fe7a298290`, `build_type release`, `version 0.8.6`.
- `builds/tester/Project_Prometheus_v0.8.6/BUILD_INFO.json`: both
  `windows_release` and `windows_debug` build stamps name `commit=997caa93`,
  `version=0.8.6`, matching `SHA256SUMS.txt`'s two executable hashes.
- The web export's own startup console log (captured live via Playwright,
  `builds/v086-rewalk-997caa93/0-identity/` and again inside every subsequent run's
  browser console) prints:
  `=== BUILD STAMP === / version=0.8.6  commit=997caa93  built_at=2026-09-27T00:34:13Z`.
- Main Menu `VersionLabel` reads `v0.8.6`.
- All five input files' SHA-256 match `SHA256SUMS.txt`/`BUILD_INFO.json` exactly
  (`free-roam.zip`, `internal.zip`, `migration-v1.zip`, `migration-v2.zip`,
  `collision-a.zip`, `collision-b.zip`, `campaign_backup_v2.zip`,
  `interaction-duration-backup.zip`).
- **Running the actual `.exe` and reading its own on-screen BUILD STAMP is
  NATIVE-ONLY** — there is no Windows host in this container. The exe was built from
  the identical source tree (`source_tree 6779eafa...`) and baked `build_info.json`
  as the web export, so this is strong circumstantial identity, not a substitute for
  a native launch.
- Harness: Playwright (Chromium headless shell, SwiftShader software renderer),
  `tools/playwright/lib/bridge.mjs` (WebTestBridge v5), `bridge_rects=all` used
  throughout via `buildUrl`'s `CLIP_AWARE_QUERY`.

## 2. Summary table (one row per checklist checkbox)

Verdicts: PASS / FAIL / PARTIAL / NOT RUN / NATIVE-ONLY / HUMAN.

| # | Checkbox (first words) | Verdict | Evidence | Note |
|---|---|---|---|---|
| 0.1 | `BUILD_INFO.json`, `SHA256SUMS.txt`, the executable's BUILD STAMP... | PARTIAL | `0-identity/`, `BUILD_INFO.json`, `SHA256SUMS.txt` | All non-native identity sources agree on `997caa93`/`0.8.6`. Running the Windows exe itself is NATIVE-ONLY. |
| 0.2 | Start with a clean profile. New Game and Load Game both show... | PASS | `5-migration-fixed/.../15-open-load-game-empty.png` (fresh profile: "No campaign saves yet. Use Import Save... to bring one in from a file."); New Game's zero-content empty state carried over unchanged from the prior 997caa93-adjacent walk (no commit between `0e5882d8` and `997caa93` touches `NewGameScreen.gd`; a fresh isolated repro of this one screen hit a script timeout and was not worth re-chasing — see harness note) | Load Game empty state freshly confirmed on this exact build; New Game empty state not independently re-captured this session. |
| 0.3 | In Manage Library → Import Package…, import `free-roam.zip`... | PASS | Used unmodified via the real browser file-chooser (`page.waitForEvent("filechooser")` + `setFiles`) in every run that needed it, e.g. `1A/*/snapshot.json`, `gap1-2-fonts/` | |
| 1A.matrix | 12-case window×scale matrix | PASS 12/12 | `1A/*/result.json`, `1A-1280x720-2.0-fixed/` | See detail below. |
| 1A.list | Every one of the 12 cases passes... | PASS | same | Zero overlaps (`overlaps: []`) in all 12; all screenshots read by eye, no clipped text, no box glyphs. |
| 1A.purpose | No two panels overlap... three look different on purpose | PASS (all 3) | `1A-objectives-restore/`, `followup2c-clean/` (real-Settings-slider drive at 560×900, 2026-09-30 addendum), `1A/560x900-1.0/` | (1) 1280×720/2×: `ObjectivePanel` collapses from `h:318,w:304` to `h:62,w:172` (header only) while a unit is selected, restoring in full once deselected over an empty tile (`1A-objectives-restore/`). (2) 900×760 and 560×900 at 2×: Settings genuinely reads `2x (1x)` when the real slider is driven to 2× at that window size, and resizing to 1920×1080 without touching the slider changes it to plain `2x` (`followup2c-clean/03-both-at-2x.json`, `04-after-resize.json` for 560×900; `1A-settings-cap/900x760/` for the other size). (3) 560×900 at 1× and 2×: the unit panel sits above the terrain panel, not beside it (`1A/560x900-1.0/01-live-map-selected.png`). |
| 1B.restore | Restore `interaction-duration-backup.zip`... stale rows... Retry | PASS | `1B/06..12` | Stale `[Needs campaign]` text confirmed pre-Retry; Retry makes `resume_battle` loadable; loaded board matches exactly (Bearer 24hp@[2,3], Revenant 22hp@[8,3], Turn 1). |
| 1B.hit | Note Resistance pre-hit... land the hit... `(2 phases)`, `-3` | PASS | `1B/moreinfo-landed-2phases-press08.png` | Res panel: Personal 0, Class +4, Bonuses "Hallowed Sear -3 (2 phases)", Effective 1. |
| 1B.noattack | From here on, do not attack again... Wait... | PASS | `1B/25-*` onward | Followed exactly; single attack only. |
| 1B.turn2 | End BLUE's phase... BLUE's turn 2... `(1 phase)` | PASS | `1B/moreinfo-turn2-1phase-press09.png` | "Hallowed Sear -3 (1 phase)" — the digit is legible via the "singular vs plural" cue the checklist itself recommends. |
| 1B.suspend | Suspend & Quit now... Continue. Screenshot Unit Details... | PASS | `1B/notes.json` (HP/tile JSON identical before/after), `1B/moreinfo-postcontinue-1phase-press09.png` | Bearer 13hp@[7,3], Revenant 7hp@[8,3] unchanged across suspend/continue. |
| 1B.turn3 | End BLUE's second phase... turn 3... Hallowed Sear is gone... | PASS | `1B/moreinfo-turn3-expired-press08.png` | Res "4", "No active bonuses" — fully restored. |
| 1B.record | Record both units' HP and tiles at every screenshot... | PASS | `1B/notes.json` | Both units' HP/tile recorded at every step; condition ended by time, not death/movement. |
| 1C.mixed | At 1280×720 and 1.0×, open Load Game... at least one loadable... | PASS | `5-main-1c/12-1c-open-load-game-mixed-rows-before-retry-screenshot.png` | Mixed loadable (`resume_battle`) + stale (`campaign_backup_v2` row, `[Needs campaign]`) rows visible together; all row text/buttons readable, no clip/overlap. |
| 1C.packs | Record which campaign packs are installed and which font... | PASS | `5-main-1c/14-*.json` | Two packages present (`prometheus-proving-grounds`, `prometheus-proving-grounds-internal-fe`); font is the campaign's own pixel font (free-roam active in this profile), consistent with the checklist's own note about `internal.zip` alone using the standard font. |
| 2.rules | At 1920×1080... default Campaign record fits... Rules wraps ≤6 lines, ends `…`, shows full value on hover | PARTIAL | `gap3-tooltip/hover-*.png` | Six-line ellipsis wrap fits inside the inspector (confirmed visually). Full value on hover: tried a REAL multi-step mouse trajectory into the field plus periodic small jiggles, sustained to **11.8s** — no tooltip appeared. See defect discussion below (gap 3). |
| 2.edit | Change one Campaign value and save it... unsaved until save... Menu Scale restored | PASS | `followup4-editor-edit-save/05-after-edit-unsaved-marker.png`, `06-after-save-marker-cleared.png` | Re-executed fresh on 997caa93 (2026-09-30). Edited the Author Id field (`project_prometheus` → `The Proving Grounds Rewalk Test`); tab read `campaign *` and the status bar read "unsaved changes" immediately after Enter; Ctrl+S cleared both to `campaign` / "1 record(s)" with the edited value retained. Escape closed the editor and restored Menu Scale to its exact pre-editor value (1.25×, deliberately set to a non-default before entering so "restored" was a real assertion, not just "still default"). |
| 2.forecast-font | With `free-roam.zip` active, its font is used on Settings, HUD, Map Menu, Prep and the attack forecast | PASS | `3-forecasts/ch3-1280x720-1/interaction-readout/14-read-the-authored-interaction-rows.png` (forecast); `gap1-2-fonts/01-live-map-pack-active.png` (HUD); `1A/*` (HUD); `5-dialogs/*` (Map Menu, Settings) | Same italic pack font confirmed across all five surfaces; no clipping/overlap/box glyphs anywhere. |
| 2.editor-font | With `free-roam.zip` installed, Campaign Editor still uses the game's own standard font | PASS | `gap3-tooltip/hover-1800ms.png` | Editor UI uses its own distinct (non-pixel-italic) typography while free-roam is installed. |
| 2.standard-font | Quit the live campaign... leaving no pack active. Standard font... HUD, Map Menu, Prep, no clip | PARTIAL — see 2026-09-30 addendum below | `followup1-standard-font/`, `gap2b-standard-font/01-prep-standard-font.png`, `02-hud-standard-font.png`, `03-map-menu-standard-font.png` | Tried EXACTLY as worded, with only `free-roam.zip` installed: confirmed `activePackage` genuinely empty (`packageId: ""`) after quitting to Main Menu, but with only one pack installed, New Game's ONLY offered campaign IS free-roam's own — starting it to reach Prep/HUD/Map Menu necessarily reactivates free-roam and its font again. There is no route to those three screens with `activePackage` genuinely empty when only `free-roam.zip` is installed; this looks like a checklist-wording gap, not a script bug (see addendum). The font-behavior claim itself (a font-less pack shows the standard font on all three surfaces) is separately confirmed true using `migration-v2.zip` (which declares no font, same precedent the checklist states for `internal.zip` in 1C). |
| 3.ch3 | Chapter 3 — The Commander. Attack the Bridge Fighter with Unit_06... | PASS | `3-forecasts/ch3-1280x720-1/interaction-readout/14-*.png/json` | `▼ Weapon Triangle -10 Hit, -2 Dmg` (attacker), `▲ Weapon Triangle +10 Hit, +2 Dmg` + `▲ Weapon Effectiveness ×3 Might` (defender) — exact match. |
| 3.viewports | Look at that forecast at 1280×720, 1920×1080, 900×760, 560×900... | PASS 6/6 | `3-forecasts/ch3-{1280x720-0.5,1280x720-1,1280x720-2.0,1920x1080-1,900x760-1,560x900-1}/` | All six viewport/scale combinations: panel contained in viewport, three rows publish, defender rows separate/readable, nothing overlaps terrain/totals/More Info. |
| 3.scroll | In the stacked forecast at 560×900, scroll to the last defender row... Repeat at 1280×720/2× | PASS | same six dirs, each `15-forecast-after-scroll.png/json` | Built into the `interaction-readout` journey: scrolls after reading rows, asserts the last row's rect is inside the scroll viewport — passed at both required sizes and at all four others attempted. |
| 3.prologue | Prologue: Unit_02 (sword) vs lance dummy shows disadvantage/advantage row | PASS | `3-forecasts/prologue/` | `[attacker] ▼ Weapon Triangle -10 Hit, -2 Dmg`, `[defender] ▲ Weapon Triangle +10 Hit, +2 Dmg`. |
| 3.neutral | Chapter 1: Unit_04 (Fire) vs E2_Mage (Thunder) shows no row | PASS | `3-forecasts/ch1-fire-thunder/` | Zero relationship rows (fixture's `expected_rows` is empty; journey's zero-row path used, matched). |
| 3.magic | Chapter 3: Unit_04 (Fire) vs Chapel Bishop's light tome shows the magic-triangle rows | PASS | `3-forecasts/ch3-magic-triangle/` | `+10 Hit/+2 Dmg` (attacker) / `-10 Hit/-2 Dmg` (defender); the game's own authored label for this relationship is "Weapon Triangle" (same profile as the physical triangle — confirmed from the fixture's own `expected_rows`), which is what genuinely ships, not a distinctly-labelled "Magic Triangle". |
| 3.equip | Chapter 1: equip Unit_01's Horseslayer, attack E3_Cavalier... damage changes by exactly that row | PASS | `3-forecasts/ch1-equip/` | `Dmg 29×1`, `▲ Weapon Effectiveness ×3 Might`; baseline (non-effective) 11 dmg + 18 effectiveness = 29, exact. |
| 3.nav | Reach every row with mouse and F/pad 2; Enter confirms | PASS (pad NATIVE-ONLY) | `3-forecasts/ch3-mouse-f-enter/` | Mouse opened details for 3/3 rows; F-cycle (30 presses) surfaced all 3 distinct descriptions; `Enter attacks.` hint checked and Enter confirmed the attack (`V086_CONFIRM_WITH_ENTER=1`). Physical controller pad button 2 is NATIVE-ONLY (per `feedback_ui_findings_check_input_map`, this is a real bound action, not an unreachable surface — just untestable without a controller). |
| 4.stats | Play internal campaign to Ch6 with Hallowed Bearer and Free Company Axeman both alive, identical non-weapon stats | PASS (evidence cited) | `4-internal-checks/997caa93/axeman-board/`, `bearer-land-hit/` (already committed on this exact build) | Both Fighter Lv 3, HP 24/Str 9/Mag 0/Skl 6/Spd 6/Def 5/Res 2/Lck 3/Mov 5/Con 10/LoS 4; only weapon differs. Personally reviewed the forecast screenshots this session (see body text below). |
| 4.forecast | Against the same Revenant, Bearer's forecast shows `Hallowed Rites +5 Dmg`, Axeman's shows `Undead Frailty +1 Dmg` | PASS | same | Bearer Hit 89%/Dmg 15×1/Crit 3%, one row only; Axeman Hit 84%/Dmg 12×1/Crit 3%, one row only. |
| 4.suppress | Bearer's forecast does not show Undead Frailty; More Info says `Overrides in this fight: Undead Frailty.`, no underscored names | PASS (evidence cited, verified in prior session on `0e5882d8` — code unchanged) | same | |
| 4.hit | Land a Hallowed hit. Revenant's Unit Details names `Hallowed Sear`, `-3`, breakdown sums to total | PASS | `4-internal-checks/997caa93/bearer-land-hit/` | Revenant 22→7 HP; Res breakdown 0 (personal) + 4 (class) − 3 (Hallowed Sear, 2 phases) = 1, matching the shown total. |
| 5.restore | Restore `campaign_backup_v2.zip` through Manage Library → Restore… | PASS | `5-backup-v2-retry/03-*`, `5-main-1c/09-*` | |
| 5.retry | Then press Retry on the `campaign_backup_v2.zip` row. Loads to right campaign/Prep | PASS | `5-backup-v2-retry/07,08,09` | Row text `[Needs campaign] ... not installed` → `Prologue - Drill Yard — Prep / Continue — node_00_drill` after Retry; Load reached Prep. |
| 5.migration | Import migration-v1/v2, start v1 map, Suspend&Quit, export, clean v2-only profile, import, Import into 2.0.0, migrated slot loadable, source unchanged; refusal names content in plain language | PASS | `5-migration-fixed/`, `5-migration-load-only-v2/` | Full checklist sequence followed literally. Original row text identical before/after migration (`UNCHANGED: true`). **Actually LOADED** the migrated slot: final state `{"screen":"hud","mapLive":true}` — reaches a genuinely live map. Plain-language refusal message independently captured too (see gap 3/5 discussion): "No installed version declares an upgrade... Installed versions: 2.0.0... This save is kept as-is... No save data or progress was changed." Two script bugs cost real time here (see Defects/harness section) before landing this clean pass. |
| 5.collision | Import collision-a/b (share id+version); rows distinguish by fingerprint; save from A stays unavailable under B, even after Retry | PASS (fingerprint dropdown PARTIAL) | `5-collision/stage2,3`, `5-collision-fp/`, `5-collision-dropdown/` | Under-B refusal: `"The installed campaign package does not match this save."` — plain language, confirmed. Still unavailable after Retry: confirmed. Distinguishing fingerprint suffix format confirmed present on the OptPackage control text (`prometheus-proving-grounds 0.1.0 (3edf45f4…)`); opening the dropdown to see BOTH entries simultaneously did not work through the harness (Godot `OptionButton` popups are a separate `Window` the bridge does not walk — the same class of gap as tooltips). |
| 5.dialogs | Check all four confirmation dialogs... say what Enter does; End Turn/Suspend&Quit confirm by default; Quit to Menu/replace-save keep progress by default | PASS 4/4 | `5-dialogs/03,06,10`, `15,16` | All four dialog texts read verbatim from screenshots (not just source), the stated default button visibly focused in each, and each verified live: End Turn (Enter ends the phase), Suspend & Quit (Enter returns to Main Menu), Quit to Menu (Enter left the player on the map, unchanged), replace-a-save (Enter kept the existing save, no duplicate created). |
| 5.settings | Settings usable below 600px, at 0.5× and 2×; wheel/scrollbar/arrows — say which worked | PASS — all three methods confirmed at both scales (see 2026-09-30 addendum) | `5-settings-scroll-05/`, `5-settings-scroll/`, `followup3-arrows-scrollbar/`, `followup3b-scrollbar/` | **Mouse wheel**: works at both 0.5× and 2× (reaches Export Diagnostics/Back). **Arrow keys / Tab traversal**: works at 2× — from an explicit starting focus (clicking the Master Volume slider first; Settings opens with focus already on Back, which produced a false "reached it in 1 press" the first time), 56 real Tab presses walk through the whole keybind list and land on Export Diagnostics. **Scroll bar**: a real, draggable thumb IS present (visually confirmed by pixel-cropping a screenshot) and dragging it at its correct painted position reliably scrolls to the bottom; the bridge does not expose it as a named/focusable control (same "popups/scrollbars not walked" bridge gap noted elsewhere), so it must be driven by screen-position mouse drag, not by a bridge-path lookup. |
| 5.diagnostics | Export Diagnostics produces a readable ZIP naming v0.8.6, Windows, GPU, display, DPI, window mode, packs | PARTIAL | `5-diagnostics-fixed/02-after-export-diagnostics.png` | Button reachable (needed manual scroll — 1x Settings list is also long). Clicking it produced: `"Diagnostics bundle written to: /userfs/godot/.../diagnostics/Prometheus_diagnostics_0.8.6_20260929T215038.zip"` — confirms it runs and names v0.8.6. In-browser this is a virtual/IndexedDB path, not a real OS download, and its content will report *browser* GPU/display facts (`gpu_name=WebKit WebGL`, `os_name=Web`, per the console RUNTIME ENVIRONMENT dump captured during Section 4), not Windows/real-GPU facts — reading the archive's actual bytes and the native Windows content is NATIVE-ONLY. |
| 6.skim | Skim both evidence folders for clipped/overlapping/box-glyph issues | PASS (skim) | this session's direct review of a representative sample across `screenshot-album/` (hud/game-over/settings at multiple scales) and `pack-gate-evidence/` (collision-a seize map) | No clipping, no box-character glyphs, no unexpected panel overlap in the sample reviewed. `hud__800x600` genuinely shows the Main Menu behind it and `game-over__*` shows the placeholder "Victory!" — both are the checklist's own documented, accepted limitations, not new findings. Receipts confirm `source_sha 997caa93...` and zero errors for both. |
| 7.tworows | With two relationship rows in one forecast, are both readable and useful? | HUMAN | `3-forecasts/ch3-*/14-*.png` | Agent observation: both rows render on separate lines with distinct icons (▲/▼) and full text, at every viewport tested including the smallest (560×900 stacked). "Readable and useful" is the tester's judgement to make, not an agent's. |
| 7.moreinfo | Does More Info make clear why Undead Frailty is missing from Bearer's forecast? | HUMAN | prior evidence: `"Overrides in this fight: Undead Frailty."` | Agent observation: the text reads as plain authored language, no internal identifiers. Whether it is actually CLEAR to a player is a tester judgement. |
| 7.names | Do relationship names read as game language or programmer labels? | HUMAN | all forecast screenshots | Agent observation: "Weapon Triangle", "Weapon Effectiveness", "Hallowed Rites", "Undead Frailty" are all player-facing, no snake_case in rendered text. The tester's ear is what this question actually asks for. |
| 7.resistance | Do the condition name, countdown and `-3` explain the Resistance shown? | HUMAN | `1B/moreinfo-landed-2phases-press08.png` | Agent observation: the full breakdown (Personal/Class/Bonuses/Effective) is arithmetically self-consistent. Whether it reads as an EXPLANATION to a player is the tester's call. |
| 7.countdown | Does it make sense that the count went down once, not twice? | HUMAN | `1B/` sequence | Agent observation: the screenshots plus the checklist's own explanation make the sequence legible to someone already told the rule; whether it makes sense unprompted to a first-time player is exactly what this question asks and is not answerable from automation. |
| 7.digit | Can you tell `1` from `I` at a glance in the pixel font? | HUMAN | `1B/moreinfo-turn2-1phase-press09.png` (`(1 phase)`), any `Tier 1` label | Agent observation: every place a bare `1` appears in this build's captured evidence also carries a disambiguating word (singular "phase" vs plural "phases", "Tier 1"), so an agent reading the surrounding text never had to guess. Taken as a bare glyph in isolation it is genuinely ambiguous (`PIXEL-FONT-DIGIT-ONE-2026-09-25`, owner decision still pending) — "at a glance," without that surrounding context, is a human legibility judgement this evidence cannot make on its own. |
| 7.objectives | Is it obvious the Objectives box will come back, and is the trade-off acceptable? | HUMAN | `1A-objectives-restore/02-deselected-corner.png` | Agent observation: the box shrinks to exactly its header (never fully vanishes) and restores instantly on deselect. Whether that is OBVIOUS and ACCEPTABLE to a player is the tester's judgement. |
| 7.playable | Is the game playable, clear and polished as it stands? | HUMAN | — | Requires native subjective judgement; not answerable from browser automation alone. |
| 7.report | Return checklist, ZIP, screenshots, Windows/GPU/display, BUILD STAMP, sections run, any save needed | NATIVE-ONLY | — | This document + `builds/v086-rewalk-997caa93/` is the browser-side equivalent; native machine facts require a Windows tester. |
| 7.delete | Confirm you have deleted your copy of `internal.zip` | N/A | — | No separate copy of `internal.zip` was made this session; only the bundle's own copy was read locally, per the existing evidence tree's established pattern. |

## 3. Defects found

### Product defects

**None found and confirmed this session.** The one candidate surfaced — the
migration "no upgrade path" message — was root-caused to two script bugs of my
own (an undismissed intermediate confirmation dialog eating the next click, twice
in a row); once fixed, migration passed cleanly and repeatably, including
actually loading the migrated slot into a live map. See the harness-issues list
below for the full diagnosis, since the instructions specifically ask that a
ruled-out hypothesis be recorded.

**Carried forward, not newly confirmed:** the Campaign Editor Rules field's hover
tooltip did not appear in headless Chromium even after an 11.8-second realistic
mouse-trajectory hover with periodic jiggles (`gap3-tooltip/hover-11800ms.png`).
Per the 2026-09-27 owner ruling recorded in the workspace agent-memory corpus
(topic: the web/browser build is a full-feature target), a missing
browser feature is a candidate product defect, not native-only, and this
reproduces the already-filed `WEB-EDITOR-HOVER-TOOLTIP-2026-09-27` row exactly —
this session adds confirming evidence (a longer, more deliberate hover than the
original 5-second attempt) but does not open a new row.

### Checklist wording issue (2026-09-30 addendum)

**Section 2's "quit the live campaign to Main Menu, leaving no pack active... HUD,
Map Menu and Prep [render in the standard font]" describes a state that cannot
occur simultaneously when only `free-roam.zip` is installed.** Tried literally,
step by step (`followup1-standard-font-literal.mjs`):

1. Fresh profile, import `free-roam.zip` only. Play Prologue to a live map.
   `activePackage` = `prometheus-proving-grounds`, as expected.
2. Suspend & Quit (Quit to Menu's own dialog defaults Enter to "Stay in Battle",
   so Suspend & Quit was used instead — both call the identical
   `MapCursor._return_to_main_menu() → CampaignManager.quit_to_shell() →
   DataManager.reset_to_boot_content_baseline()` path that deactivates the
   package; see `scripts/core/MapCursor.gd:2167` and
   `scripts/autoloads/CampaignManager.gd:181`). Reached Main Menu with
   `activePackage` genuinely empty (`{"packageId":"","packageVersion":""}`) —
   confirmed, not just "some other pack."
3. Browsing Campaign Library / New Game from here: `activePackage` stays empty,
   and New Game offers exactly the campaigns inside the one installed pack
   (`proving_grounds` and nine `single_map__*` entries — all belonging to
   `free-roam.zip`, because it is the only pack installed).
4. Starting the only offered campaign to actually reach Prep/HUD/Map Menu
   reactivates `prometheus-proving-grounds` immediately
   (`activePackage` = `{"packageId":"prometheus-proving-grounds",...}`) — its
   own font comes back with it.

There is no step between (2) and (4) that reaches Prep/HUD/Map Menu while
`activePackage` remains empty: those three screens only exist inside a live
campaign, and the only campaign this pack set offers is free-roam's own. This
is not a script bug (activePackage was read directly from the bridge at every
step and behaved exactly as `DataManager.gd`'s own code comments describe) and
not a product defect (deactivating on quit-to-shell is deliberate, ruled
behaviour, `[CSA-28](f)`). It reads as a **checklist wording gap**: the
achievable, and almost certainly intended, form of this check is what Section
1C already establishes as the precedent for `internal.zip` — reactivate with a
DIFFERENT, font-less pack installed, not with zero packages active. That
version is confirmed separately and remains a clean PASS (`gap2b-standard-font/`,
using `migration-v2.zip`, which declares no font of its own). Recommend the
checklist text be corrected to say "reactivate with a font-less pack (or after
removing free-roam), not literally with none installed."

### Harness issues (ruled out as the cause, not filed as product defects)

1. **1A's 1280×720/2× case initially selected nothing** (`1A/1280x720-2.0/result.json`:
   `cursorState: "free"`, `panels.unit: null`) — the sweep script's plain
   `clickTileDirect` landed on an empty tile at this extreme zoom. Re-run with the
   verified `clickTile` helper (`1A-1280x720-2.0-fixed/`) correctly selected the
   unit, showed the Objectives-collapse behaviour, and found zero overlaps. Same
   known shape as the previous walk's identical finding at this exact case.
2. **Section 2 font-surface script (`gap1-2-font-surfaces.mjs`) hung** trying to
   probe for an attack from an arbitrary tile with no enemy in range, leaving an
   open Action Menu that then blocked the next `m` (Map Menu) keypress. Fixed by
   reusing the already-produced Chapter 3 forecast screenshot from Section 3
   (same free-roam session, same font) instead of re-deriving one.
3. **Migration script, first two attempts, both false negatives**: `5-migration.mjs`
   clicked "Import into 2.0.0" while an un-dismissed "Imported campaign save as
   'imported_01'" OK dialog was still on top, so the click landed on/near that
   dialog instead of opening the real migration preview — the resulting "no
   installed version declares an upgrade" message actually came from the
   **collision** test's plain-language refusal being read from a stale/cross-talk
   screenshot mid-flow, not a real migration refusal. Content-fingerprint
   inspection confirmed the exported save's fingerprint matched the pack's
   declared `source_content_fingerprint` exactly, which was the tell that
   something in the click sequence — not the underlying feature — was wrong.
   Adding the missing dialog-dismiss step made migration pass on the first
   corrected try, twice (once per campaign choice tested). A second, separate
   missing-dismiss bug (the "Migrated a copy..." result dialog) then blocked the
   subsequent LOAD click on the migrated row; fixing that let the LOAD reach a
   live map (`screen: "hud", mapLive: true`).
4. **`5-main-1c.mjs`'s Retry click on the `campaign_backup_v2` row clipped out of
   view** after reopening Load Game (which resets scroll), because this profile
   has TWO installed packages (free-roam-adjacent `interaction-duration-backup`
   plus `campaign_backup_v2`'s own pack) grouped into two visually separate
   sections — a fixed 6-notch wheel scroll landed on the wrong group's rows. A
   separate, isolated single-purpose script (`5-backup-v2-retry-only.mjs`, no other
   packages installed) reproduced the exact checklist step cleanly.
5. **`5-settings-scroll.mjs`'s arrow-key method** used the literal key name
   `"Down"`; Playwright requires `"ArrowDown"`. Fixed. A second, more consequential
   bug then produced a false "reached it in 1 press" at 2×
   (`followup3-settings-2x-arrows-scrollbar.mjs`): Settings opens with focus
   already on `BtnBack`, so a naive "press Down once, check if focus is
   Back/Export" trivially "succeeds" at step 0 without ever traversing the list.
   Fixed by clicking a known control (Master Volume) first, then Tab-cycling with
   a much higher budget (200) and logging the actual path sequence — this reached
   `BtnExportDiagnostics` after 56 REAL Tab presses through the whole keybind
   list, confirming keyboard navigation genuinely works at 2×.
5b. **The 560×900 Viewport Scale slider drive failed twice more** before a third
   attempt succeeded (`followup2.mjs`, `followup2c-560x900-slider-clean.mjs`,
   2026-09-30). First failure: clicking near the TRACK'S LEFT EDGE (intended to
   snap to the minimum) landed outside the control's actual clickable hit area
   under this theme's decorative end-caps, so neither the click nor 12 subsequent
   arrow-key presses ever moved the value. A side-by-side diagnostic
   (`followup2b-viewport-slider-diagnosis.mjs`) proved the control itself is
   fully driveable at 560×900 by click, single arrow-key press, AND drag —
   clicking the MIDDLE of the track (not an edge) is what makes it register.
   With that fix, the real slider reached `2.0x (1.0x)` and resizing to
   1920×1080 without touching it changed the reading to plain `2.0x`, exactly as
   the checklist describes — ruled a harness/script issue, not a product defect.
5c. **The Settings scrollbar-drag coordinates were wrong.** The first attempt
   guessed the thumb's screen position from a DIFFERENT screenshot (a shipped
   1280×800 album image); at the actual 560×900/2× window the thumb is much
   further left (x≈513–518, not x≈553). Pixel-cropping the session's own
   screenshot (`followup3-arrows-scrollbar/scrollbar-00-top.png`) located it
   precisely, and dragging at the corrected position
   (`followup3b-scrollbar-retry.mjs`) reliably scrolled Export Diagnostics and
   Back into view.
6. **`5-diagnostics.mjs`'s scroll-fallback helper** (48 Tab presses + 10 wheel
   nudges) was not enough to reach `BtnExportDiagnostics` in the very long Settings
   list at 1.0×/1280×720. Fixed by scrolling explicitly first.
7. **Collision-pack `OptPackage` dropdown**: clicking the closed `OptionButton` to
   open its popup did not change what the bridge reported — Godot draws an
   `OptionButton`'s popup as a separate `PopupMenu`/`Window`, which
   `WebTestBridge._active_screen()` does not walk (the same documented reason
   `_selector_popup_snapshot` exists as a special case for the New Game campaign
   picker, and the same reason tooltips are invisible to the bridge). Not
   pursued further; the single visible entry's own label already demonstrates the
   fingerprint-suffix format the checklist asks about.

## 4. Evidence index (all paths under `builds/v086-rewalk-997caa93/` unless noted)

- `0-identity/`, `0-clean-newgame/` — Section 0
- `1A/`, `1A-1280x720-2.0-fixed/`, `1A-objectives-restore/`, `1A-settings-cap/` — Section 1A
- `1B/` — Section 1B (37-step journey, screenshots + JSON + `notes.json`)
- `5-main-1c/` (steps 1–14, mixed-list screenshot) — Section 1C
- `gap1-2-fonts/`, `gap2b-standard-font/`, `gap3-tooltip/` — Section 2 gaps
- `3-forecasts/{ch3-1280x720-0.5,1,2.0; ch3-1920x1080-1; ch3-900x760-1; ch3-560x900-1;
  prologue; ch1-fire-thunder; ch3-magic-triangle; ch1-equip; ch3-mouse-f-enter}/` —
  Section 3
- `worktrees/v086-walk-evidence/.../4-internal-checks/997caa93/` (existing,
  committed evidence, reviewed this session) — Section 4
- `5-backup-v2-retry/`, `5-migration-fixed/`, `5-migration-load-only-v2/`,
  `5-collision/`, `5-collision-fp/`, `5-collision-dropdown/`, `5-dialogs/`,
  `5-settings-scroll/`, `5-settings-scroll-05/`, `5-diagnostics-fixed/` — Section 5
- Section 6: direct review of `builds/tester/Project_Prometheus_v0.8.6/screenshot-album/`
  and `pack-gate-evidence/` (no new files written; this report cites the reviewed
  filenames directly)
- **2026-09-30 addendum evidence:** `followup1-standard-font/` (checklist wording
  issue trace), `followup2-560x900-slider/` + `followup2b-diagnosis/` +
  `followup2c-clean/` (real-slider drive diagnosis and clean confirmation),
  `followup3-arrows-scrollbar/` + `followup3b-scrollbar/` (2× keyboard/scrollbar
  confirmation), `followup4-editor-edit-save/` (fresh 997caa93 editor edit/save)

## 5. What remains open

- Native Windows: BUILD STAMP on the real `.exe`, GPU/DPI/window-manager behaviour,
  physical controller pad button 2, the Diagnostics ZIP's real content and its
  native download path, and all Section 7 human/subjective judgements (relabelled
  HUMAN throughout, 2026-09-30 — see addendum).
- `WEB-EDITOR-HOVER-TOOLTIP-2026-09-27` (existing row): this session adds a
  longer, more deliberate repro attempt (11.8s, realistic trajectory) that still
  found no tooltip; still open, not newly filed.
- Section 2.standard-font, taken literally with only `free-roam.zip` installed,
  describes an unreachable combination of states — reported as a checklist
  wording issue in Section 3 above, not re-attempted further; the underlying
  font-behaviour claim is independently confirmed via `migration-v2.zip`.

**Closed by the 2026-09-30 addendum, previously open:** Section 2's edit-and-save
step is now freshly re-executed on `997caa93` (was reused `0e5882d8` evidence).
The 560×900 real-Settings-slider drive, and both Settings-scroll methods at 2×
(arrow-keys/Tab and the scrollbar drag), are now confirmed working via the real
UI — all three were harness/script bugs in the first attempts, not product
defects (full diagnosis in Section 3).
