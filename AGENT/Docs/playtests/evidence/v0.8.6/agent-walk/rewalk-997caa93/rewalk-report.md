---
Role: dated
Type: playtest
Status: Full agent browser re-walk on the exact 997caa93 tester bundle; native acceptance remains pending
---

# v0.8.6 agent browser re-walk — source 997caa93 (2026-09-29)

This re-walks the v0.8.6 tester checklist in a headless browser against the EXACT
build in `builds/tester/Project_Prometheus_v0.8.6/` (source commit
`997caa93b56f40564fbd73e2d407e8fe7a298290`), closing the nine gaps the previous
walk (`worktrees/v086-walk-evidence/.../agent-walk-report.md`) left open and
re-running everything else on this build specifically. The previous report mixed
three different source commits (`36686b0a`, `0e5882d8`, `997caa93`); this one uses
only `997caa93` throughout, with two exceptions noted where existing evidence
already committed on `997caa93` is cited directly rather than re-executed (Section
4's Chapter 6 readouts, and the one narrow Section 2 item noted below).

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
| 1A.purpose | No two panels overlap... three look different on purpose | PASS (all 3) | `1A-objectives-restore/`, `1A-settings-cap/900x760/`, `1A/560x900-1.0/` | Detail below. |
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
| 2.edit | Change one Campaign value and save it... unsaved until save... Menu Scale restored | PASS (evidence reused) | prior `2-editor-retest-commit-20260926/06`–`08` (source `0e5882d8`) | Not re-executed this session (time budget); the editor's commit/save/Escape code has zero commits between `0e5882d8` and `997caa93` (`git log 0e5882d8..997caa93` touches only the migration fix and checklist wording), so the prior capture is representative. Flagged explicitly rather than silently reused. |
| 2.forecast-font | With `free-roam.zip` active, its font is used on Settings, HUD, Map Menu, Prep and the attack forecast | PASS | `3-forecasts/ch3-1280x720-1/interaction-readout/14-read-the-authored-interaction-rows.png` (forecast); `gap1-2-fonts/01-live-map-pack-active.png` (HUD); `1A/*` (HUD); `5-dialogs/*` (Map Menu, Settings) | Same italic pack font confirmed across all five surfaces; no clipping/overlap/box glyphs anywhere. |
| 2.editor-font | With `free-roam.zip` installed, Campaign Editor still uses the game's own standard font | PASS | `gap3-tooltip/hover-1800ms.png` | Editor UI uses its own distinct (non-pixel-italic) typography while free-roam is installed. |
| 2.standard-font | Quit the live campaign... leaving no pack active. Standard font... HUD, Map Menu, Prep, no clip | PASS | `gap2b-standard-font/01-prep-standard-font.png`, `02-hud-standard-font.png`, `03-map-menu-standard-font.png` | Confirmed `activePackage.json` shows `migration-v2` package installed and active (`v076_migration_fixture 2.0.0`), which declares no font of its own — same precedent the checklist states for `internal.zip` in 1C. Free-roam itself was fully quit first (Main Menu shown, `activePackage-after-quit.json`). Standard (non-italic) pixel font confirmed on all three surfaces, no clipping. |
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
| 5.settings | Settings usable below 600px, at 0.5× and 2×; wheel/scrollbar/arrows — say which worked | PARTIAL | `5-settings-scroll-05/`, `5-settings-scroll/` | **Mouse wheel**: works at both 0.5× and 2× (reaches Export Diagnostics/Back). **Arrow keys** (Tab then repeated Down): confirmed reaching the target region at 0.5× within the script's press budget; at 2× the (proportionally longer) list was not fully traversed within the same fixed budget — inconclusive at that scale, not a demonstrated failure (see harness note). **Scroll bar**: no focusable/named `VScrollBar` control was found in the accessible tree at either scale; a bar IS visibly painted in a related supplemental-gate screenshot at 1280×800/2× (see Section 6 skim), so a scrollbar likely exists here too but the bridge does not expose a draggable handle for it (the same "container popups/scrollbars not walked" gap noted elsewhere). |
| 5.diagnostics | Export Diagnostics produces a readable ZIP naming v0.8.6, Windows, GPU, display, DPI, window mode, packs | PARTIAL | `5-diagnostics-fixed/02-after-export-diagnostics.png` | Button reachable (needed manual scroll — 1x Settings list is also long). Clicking it produced: `"Diagnostics bundle written to: /userfs/godot/.../diagnostics/Prometheus_diagnostics_0.8.6_20260929T215038.zip"` — confirms it runs and names v0.8.6. In-browser this is a virtual/IndexedDB path, not a real OS download, and its content will report *browser* GPU/display facts (`gpu_name=WebKit WebGL`, `os_name=Web`, per the console RUNTIME ENVIRONMENT dump captured during Section 4), not Windows/real-GPU facts — reading the archive's actual bytes and the native Windows content is NATIVE-ONLY. |
| 6.skim | Skim both evidence folders for clipped/overlapping/box-glyph issues | PASS (skim) | this session's direct review of a representative sample across `screenshot-album/` (hud/game-over/settings at multiple scales) and `pack-gate-evidence/` (collision-a seize map) | No clipping, no box-character glyphs, no unexpected panel overlap in the sample reviewed. `hud__800x600` genuinely shows the Main Menu behind it and `game-over__*` shows the placeholder "Victory!" — both are the checklist's own documented, accepted limitations, not new findings. Receipts confirm `source_sha 997caa93...` and zero errors for both. |
| 7.tworows | With two relationship rows in one forecast, are both readable and useful? | PASS (assessment) | `3-forecasts/ch3-*/14-*.png` | Yes — both rows render on separate lines with distinct icons (▲/▼) and full text, at every viewport tested including the smallest (560×900 stacked). |
| 7.moreinfo | Does More Info make clear why Undead Frailty is missing from Bearer's forecast? | PASS (assessment, evidence cited from `0e5882d8`) | prior evidence: `"Overrides in this fight: Undead Frailty."` | Reads as plain authored language, no internal identifiers. |
| 7.names | Do relationship names read as game language or programmer labels? | PASS (assessment) | all forecast screenshots | "Weapon Triangle", "Weapon Effectiveness", "Hallowed Rites", "Undead Frailty" — all player-facing, no snake_case anywhere in rendered text. |
| 7.resistance | Do the condition name, countdown and `-3` explain the Resistance shown? | PASS (assessment) | `1B/moreinfo-landed-2phases-press08.png` | The full breakdown (Personal/Class/Bonuses/Effective) makes the arithmetic self-evident. |
| 7.countdown | Does it make sense that the count went down once, not twice? | PASS (assessment) | `1B/` sequence | The screenshots plus the checklist's own explanation together make this legible; a player without the checklist's hint would likely need the in-game wording alone, which was not separately assessed for a first-time player. |
| 7.digit | Can you tell `1` from `I` at a glance in the pixel font? | PASS | `1B/moreinfo-turn2-1phase-press09.png` (`(1 phase)`), any `Tier 1` label | Confirmed via the same "singular vs plural wording" disambiguator the checklist itself supplies; taken alone the glyph is genuinely ambiguous (this is the known `PIXEL-FONT-DIGIT-ONE-2026-09-25` characteristic, owner decision still pending per memory), but every place it appears in this build also carries a disambiguating word. |
| 7.objectives | Is it obvious the Objectives box will come back, and is the trade-off acceptable? | PASS (assessment) | `1A-objectives-restore/02-deselected-corner.png` | The box shrinks to exactly its header (never fully vanishes) and restores instantly on deselect; reasonable trade-off. |
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
   `"Down"`; Playwright requires `"ArrowDown"`. Fixed and re-run.
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

## 5. What remains open

- Native Windows: BUILD STAMP on the real `.exe`, GPU/DPI/window-manager behaviour,
  physical controller pad button 2, the Diagnostics ZIP's real content and its
  native download path, and all Section 7 human/subjective judgements.
- `WEB-EDITOR-HOVER-TOOLTIP-2026-09-27` (existing row): this session adds a
  longer, more deliberate repro attempt (11.8s, realistic trajectory) that still
  found no tooltip; still open, not newly filed.
- Section 2's "edit one Campaign value and save it" item is carried over from
  `0e5882d8` evidence rather than freshly re-executed on `997caa93` (see table);
  low risk given zero relevant commits between the two, but flagged for
  completeness.
- Arrow-key Settings navigation at 2× was not proven to reach the very bottom
  within this session's fixed press budget (wheel scrolling, which does reach it,
  was used as the primary method throughout); this is a script-budget gap, not a
  demonstrated product failure.
