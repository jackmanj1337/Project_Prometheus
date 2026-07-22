---
Type: playtest
Status: Active - triage review, fix decisions pending
Last verified: 2026-07-22
---

# v0.5.3 Playtest Results — Triage Review (2026-07-22)

Code-review-style triage of the returned v0.5.3 Windows playtest. Every issue
the tester raised has been traced to a root cause in source where possible;
each finding lists its evidence, the responsible code, a proposed fix, and any
decision the maintainer must make before the fix is implemented.

## Return package

- Location: `AGENT/v0.5.3 playtest results/` (returned there instead of
  `AGENT/Incoming/v0.5.3/`; contents are complete)
- Build verified: BUILD STAMP `0.5.3 / 4ddd54c / 2026-07-21T06:34:15Z` in all
  three logs matches `playtest_build_v0.5.3.md`
- Evidence: completed `playtest_checklist_v0.5.3.md`, `godot.log` +
  2 rotated logs, 6 screenshots, `resume_battle.json` (mid-map suspend save,
  node_03_boss, turn 2)
- Tester environment: Windows 11 (10.0.26200), Intel Arc integrated,
  GL Compatibility, 1280x720 windowed/maximized. No controller available —
  all controller checks are NOT RUN, not passed.

## Findings index (severity order)

| ID | Sev | Finding | Root cause found |
|---|---|---|---|
| V053-01 | Critical | Continue from a mid-battle suspend orphans the map from the campaign: the eventual victory/defeat is ignored, Results shows "next battle is unavailable" → Return to Menu, and the win is lost | Yes |
| V053-02 | Critical | Retry after a defeat on a resumed map reloads an empty board: no units on either side, no objective HUD | Yes |
| V053-03 | High | Casual-mode fallen units re-enter the next map at 0 HP ("walking dead"); any combat removes them instantly | Yes |
| V053-04 | High | Manual Prep saves refuse "randomly"; the Replace flow also fails once the save-slot class is full; UI only says "Save failed." | Yes |
| V053-05 | Medium | Edit HUD Layout: WASD still drives the settings screen / map cursor underneath the editor | Yes |
| V053-06 | Medium | Edit HUD Layout toolbar buttons glow on hover but reportedly do nothing when clicked | Partial |
| V053-07 | Low | Checklist item "passing turn 8 does not lose map_005" is untestable — the map's survive target is 6 | Yes (checklist defect) |
| V053-08 | Low | Every Continue logs `campaign_restored` twice — triage noise | Yes |
| V053-09 | Low | Results screen's data-error exit leaves the campaign active in memory | Yes |
| V053-10 | Note | Tester requests: Rewind-selector scrollbar visibility; §6 checklist comment is cut off mid-sentence | — |

---

## V053-01 — Mid-battle Continue orphans the live map from the campaign (Critical)

**Symptom (tester).** "Losing Unit_01 … causes the victory screen to route to
main menu." Two victory screenshots show `Save: next battle is unavailable`
with only a `Return to Menu` button — once on Proving Grounds map 1, once on
the map 3 boss kill. The two-map skirmish's River Pass hit the same wall.

**Evidence (logs).** The identical four-line pattern appears in every affected
run, always after the app was relaunched and the mid-battle suspend was
continued:

```text
PLAYTEST CONTEXT {"active_node_id":"", ... "event":"campaign_restored", ...}
PLAYTEST CONTEXT {"active_node_id":"", ... "event":"campaign_restored", ...}
WARNING: CampaignManager: map result ignored because the active campaign has no launched node
ERROR: Campaign Data Error: campaign='' node='' successors=[]
```

Occurrences: node_01_rout (02:10→02:18Z), node_03_boss (01:55→01:58Z),
node_02_seize defeat (01:38→01:51Z, feeds V053-02), river_pass (02:34→02:35Z).
It is not tied to the unit death — that was coincidental; the trigger is
*resuming a suspended battle*.

**Root cause.** `CampaignManager.restore_campaign_state()` ends with
`_active_node_id = ""` (`scripts/autoloads/CampaignManager.gd:788`) under the
comment "nothing is on a map yet". That is correct for a between-map restore,
which goes on to call `launch_current_node()` (it re-sets `_active_node_id` at
line 303). But a mid-battle suspend resume
(`GameState.configure_suspend_resume`, `scripts/autoloads/GameState.gd:367-424`)
restores the envelope and then boots **directly into the live GameMap** —
nothing ever re-marks the node as launched. When the map later resolves,
`_record_result()` bails at `CampaignManager.gd:523` ("no launched node"), so:

- `_pending_result` stays empty → `get_pending_successor_options()` returns
  `[]` → `MapResultsScreen._refresh_result()` takes the campaign-data-error
  branch (`scripts/ui/MapResultsScreen.gd:132-149`): "Return to Menu" +
  "Save: next battle is unavailable" + the `Campaign Data Error` log line with
  empty ids.
- The win is **lost**: the position never advances, no autosave fires, and the
  `resume_battle` slot was already deleted when the result presented
  (`MapResultsScreen._delete_mid_map_slot_after_resolution`). The player
  replays from the previous between-map save.
- A defeat is equally ignored, which cascades into V053-02.

**Proposed fix.** After the campaign envelope is successfully restored inside
`configure_suspend_resume()`, re-mark the launched node — e.g. a new
`CampaignManager.resume_launched_node()` that sets
`_active_node_id = current_node_id` (guarded on an active campaign and a
non-empty node), and logs a distinct playtest event (`node_resumed`). The
mid-map save always carries `campaign_id` + `node_id` (verified in
`resume_battle.json`), so the data is there. Between-map restores
(`configure_campaign_resume`) keep the existing clearing behavior.

**Tests.** Headless: capture a mid-map save on a campaign node →
`configure_suspend_resume` → emit `map_victory`/`map_resolved` → assert
`get_pending_result()` names the node and its successor; same for defeat.
This closes the checklist §8 gap ("Return to Menu … Report it if you hit
this") for the resume path specifically.

## V053-02 — Retry after defeat on a resumed map wipes the board (Critical)

**Symptom (tester).** "After losing … and hitting retry, all the units from
both sides disappeared and the victory condition hud disappeared." Screenshot
shows GameMap at Turn 1, terrain painted, zero units, no Objectives panel.
(The prose says the boss map; the log and the screenshot filename place it on
map_002_seize — mechanism is map-independent.)

**Evidence (log, 01:38 run).**

```text
WARNING: CampaignManager: map result ignored because the active campaign has no launched node
ERROR: GameMap: launch roster not explicitly prepared for policy 'suspend_resume' (source 'encounter_map_002_seize')
```

**Root cause chain.**

1. The map was itself a suspend resume. `GameMap._apply_suspend_resume()` ends
   with `gs.call("clear_suspend_resume")` (`scripts/core/GameMap.gd:374`) —
   the payload is consumed, but `GameState.next_map_roster_policy` is left as
   `"suspend_resume"` (set at `GameState.gd:413`; nothing resets it).
2. Defeat → `GameOverScreen._on_retry()` (`scripts/ui/GameOverScreen.gd:167`):
   `route_retry_to_prep()` returns false — because of V053-01,
   `_active_node_id == ""` (`CampaignManager.gd:384`) — so it falls back to
   `reload_current_scene()`.
3. On reload, the resume payload is empty, so `_spawn_units()` takes the
   normal branch and asks `is_roster_ready_for_launch()`
   (`GameMap.gd:231`); for policy `"suspend_resume"` that is
   `not next_map_suspend_payload.is_empty()` (`GameState.gd:544-545`) →
   false → `push_error`, spawn aborted, `TurnManager.start_map` never runs.
   Result: empty board, no objective HUD, dead scene.

**Proposed fix.** When a resume payload is successfully applied to the live
map, normalize the launch config so a later reload is self-consistent: set
`next_map_roster_policy = "keep_current_roster"` (the roster was rebuilt from
the payload at `GameState.gd:407`) as part of consuming the payload. Note the
V053-01 fix alone would make Retry route to prep instead — and then
`begin_prepared_battle` hits the *same* stale-policy wall — so both halves are
needed: fix the orphaned node (V053-01) *and* normalize the policy (this).
Retry semantics stay "ledger round 0 = map start", matching the non-resumed
path.

**Tests.** Headless: configure a resume → apply → assert
`is_roster_ready_for_launch()` still true after payload consumption; retry
flow restores round 0 and relaunches with units.

## V053-03 — Casual fallen units return at 0 HP next map (High)

**Symptom (tester).** "The unit is restored next map, but placed on the map
with zero health, but engaging in combat removed the unit. Unit could be moved
or healed." Screenshot: chapter 2, `Unit_02 … HP 0 / 18` standing on a tile.

**Root cause.** With Permadeath off, `DeathLifecycle.handle_death()`
(`scripts/autoloads/DeathLifecycle.gd:22-25`) only sets `is_incapacitated`
when `permadeath_enabled` — correct — but the shared `UnitData` in
`GameState.player_roster` keeps `hp = 0`. The next launch keeps the roster
(`keep_current_roster`) and `GameMap._spawn_units()` filters **only**
`is_incapacitated` (`scripts/core/GameMap.gd:259`). No between-map heal
exists anywhere: `Unit.reset_map_state()` (`scripts/units/Unit.gd:393-396`)
clears modifiers/counters but never touches `hp`. So every casual casualty is
a 0-HP unit next map, and any combat kills it again instantly.

**Nasty interaction:** later nodes carry `Protect: unit_01_cavalier` lose
conditions — a 0-HP protected unit makes defeat nearly unavoidable.

**Decision needed — between-map HP policy** (see Questions):

- (a) **Full heal for everyone at map launch** — FE-series convention;
  simplest; also erases attrition carry, which today is implicit (surviving
  units currently carry damage between maps too — probably unintended).
- (b) Heal only 0-HP (retreated) units to full; others keep carried damage.
- (c) Revive retreated units at 1 HP; others carry damage (attrition design).

Recommendation: (a) — matches genre expectation and removes the whole class of
carried-HP surprises. Implemented at campaign next-map launch (not on suspend
resume, which must preserve mid-map HP exactly).

## V053-04 — Manual Prep saves refused; Replace fails when class is full (High)

**Symptom (tester).** "Campaigns seem to randomly not allow save. Not likely
actually random, perhaps being limited by allowed save count. Should" *(the
comment ends mid-sentence — see V053-10)*.

**Evidence.** ~20 paired log lines across the session:

```text
ERROR: SaveManager: manual 'between_map' slot class is full
ERROR: CampaignManager: failed to write campaign slot 'node-01-rout-prep-...'
```

**Root causes (three, stacked).**

1. **The cap itself**: the default policy is `SavePolicy.classic_gba()` —
   **3** manual `between_map` slots (`scripts/save/SavePolicy.gd:10-14`), and
   the budget is **global across all campaigns and single-map runs** — the
   picker counts every manual between-map row
   (`SaveManager._manual_write_allowed`, `scripts/autoloads/SaveManager.gd:382-407`).
   Three prep saves anywhere = every later prep save refused. Hence
   "random": it depends on save history, not the campaign being played.
2. **Replace is broken exactly when it matters**: `PrepScreen` replaces by
   writing the NEW timestamped slot id first and deleting the old one only on
   success (`scripts/ui/PrepScreen.gd:234-245`). At the cap,
   `_manual_write_allowed` still counts the old row → the new write is
   refused → "Save failed." even though the player confirmed "Replace Save?".
3. **No diagnosis in the UI**: the only feedback is the literal string
   `"Save failed."`; the class-full reason lives only in the log.

**Proposed fixes.**

- Replace should reuse the existing slot id (SaveManager already allows a
  manual overwrite of an existing manual slot, `SaveManager.gd:383-388`) —
  no headroom needed, atomic, no orphan on failure. The label stays the
  chapter label, so nothing user-visible changes.
- When the class is full and there is no same-label slot to replace, say so:
  "All 3 campaign save slots are in use — delete one from Load Game" (and
  verify Load Game actually offers delete; add it if not).
- **Decision needed** on the budget itself (see Questions): keep classic 3
  (fix replace + messaging only), raise it, or scope it per campaign.

## V053-05 — Edit HUD Layout does not block polled input (Medium)

**Symptom (tester).** "wasd controls are not being consumed or blocked in the
edit HUD layout mode and the cursor can be seen moving on the settings screen
while editing the HUD Layout." Screenshot confirms the Controls settings page
visibly focused/scrolled beneath the open editor.

**Root cause.** `HudLayoutEditor._input()` consumes non-mouse *events*
(`scripts/ui/HudLayoutEditor.gd:47-52`, the V021-02 fix) — but both consumers
underneath **poll the Input singleton every frame**, which
`set_input_as_handled()` cannot affect:

- `ModalScreen._process()` drives settings focus repeat via
  `_modal_repeat.poll(delta)` (`scripts/ui/ModalScreen.gd:132-153`) — this is
  what the tester watched moving.
- `MapCursor._process()` polls `poll_direction(delta)`
  (`scripts/core/MapCursor.gd:346-370`) — same hole when editing over a live
  map. MapCursor already honors the EventBus gameplay-modal lock
  (`_gameplay_modal_locked()`), but the editor never acquires it.

**Proposed fix.** Two small gates: (1) `HudLayoutEditor` acquires/releases the
EventBus gameplay modal exactly like `GameOverScreen` does
(`GameOverScreen.gd:322-337`) — that silences MapCursor; (2) `SettingsScreen`
pauses its focus repeat while the editor it spawned is open — it already owns
the editor's lifecycle (`_on_edit_hud_layout`, `SettingsScreen.gd:680-686`)
and the base class exposes the `_modal_focus_repeat_enabled()` opt-out, so
track open/closed via the editor's `closed` signal.

## V053-06 — Edit HUD toolbar buttons reportedly dead (Medium, partial)

**Symptom (tester).** "The edit HUD buttons also have the glow on hover with
the cursor, but clicking them does not appear to do anything."

**What code review confirms.**

- `Scale Panel −/+` silently no-op when no panel is selected
  (`HudLayoutEditor.gd:200-207` guards on `_selected_id == ""`). A tester who
  clicked them before clicking a panel frame sees exactly "nothing happens".
  They should be disabled (or show "select a panel first") until a selection
  exists.
- The drag frames are `MOUSE_FILTER_STOP` and are added **after** the toolbar
  (`_build_handles`, lines 107-127), so where a panel frame overlaps the
  toolbar the frame wins the click. The screenshot shows `phase_label`'s
  frame overlapping the title and part of "Scale Panel −". The toolbar has no
  background panel and no reserved band; frames should either be clipped out
  of the toolbar strip or the toolbar given a top strip the frames cannot
  enter.
- `Reset` on an already-default layout changes nothing visible — reads as
  "did nothing".

**Not yet reproduced:** a genuine dead `Done`/`Cancel` (both sit clear of any
frame in the screenshot and their `pressed` wiring is straightforward,
lines 100-104). Needs one live check after the V053-05/-06 fixes land; if
still dead, suspect input-stage interference from `SettingsScreen._input`.

## V053-07 — Checklist demanded an untestable turn-8 check on map_005 (Low)

Tester: "not able to be tested, ending turn 6 grants victory, but no time
limit listed." The authored objective is `survive`, `turns = 6`
(`data/maps/map_005_defend/map_005_defend_data.tres`), and there is no
turn-limit defeat condition — so the game is **correct**, and the checklist's
"passing turn 8 does not lose the map" can never be exercised because the map
ends in victory at 6. Fix the next checklist (assert "no defeat occurs on any
turn up to the survive target") or point the check at a fixture whose survive
target exceeds the old turn-8 phrasing.

## V053-08 — Double `campaign_restored` telemetry per Continue (Low)

Every resume logs the event twice: once when MainMenu/GameOverScreen calls
`configure_suspend_resume(...)` (`MainMenu.gd:121-122`,
`GameOverScreen.gd:238-239`) and again when `GameMap._ready()` re-stages the
same payload after `reset_map_state` (`GameMap.gd:71-73` → second
`restore_campaign_state`). Harmless at runtime but it cost real triage time
this round. Either tag the re-stage differently (`campaign_restaged`) or skip
the second log.

## V053-09 — Results data-error exit leaves campaign active (Low)

`MapResultsScreen._quit_to_menu()` (`MapResultsScreen.gd:250-255`) resets map
state but never calls `end_campaign()`, unlike `GameOverScreen._on_quit()`
(`GameOverScreen.gd:304-311`). After the V053-01 "Return to Menu", the dead
campaign stays active in memory at the main menu. Mostly moot once V053-01 is
fixed, but the two quit paths should behave identically.

## V053-10 — Tester requests / loose ends (Notes)

- **Rewind selector scrollbar** (§4 note) — **confirmed missing and fixed
  2026-07-22.** The row list was a bare `VBoxContainer`, so the panel simply
  grew with history length (matching the tester's "menu got larger than the
  default size"). Fix: rows now live in a `ScrollContainer`
  (`follow_focus = true`, horizontal scroll disabled) so the panel stays at
  its authored height and a vertical scrollbar appears on overflow
  (`scenes/ui/RewindSelector.tscn`, `scripts/ui/RewindSelector.gd`).
  Headless-verified with 30 rows (panel height held at 360, v-scrollbar
  visible); `test_rewind` / `test_map_menu` / `test_game_over_sequencing`
  suites green. **The v0.5.4 checklist must include**: open Rewind with more
  history than fits the panel and confirm the list scrolls (keyboard focus
  included) — the tester could not build enough history without debug
  controls, so a long-history path or fixture is needed.
- **§6 comment cut off**: "…perhaps being limited by allowed save count.
  Should" — superseded by the recorded decision: per-campaign cap of 3 plus
  explicit slots-full messaging.
- **Main menu direction (owner, 2026-07-22)**: eventually restructure the
  menu so each campaign has its own separated sub-menu. Registered as
  `MENU-CAMPAIGN-SUBMENUS-DESIGN` in `coordination/tasks.json` (design
  stage, unassigned).
- **Controller coverage NOT RUN** (§1): no controller was available, so all
  pad checks and the `PLAYTEST CONTROLLER` log lines remain unverified. The
  logs correctly contain no controller lines.
- **Checklist §9 (provenance) verified during triage** even though the tester
  left it blank: all three logs begin with BUILD STAMP + populated RUNTIME
  ENVIRONMENT; `PLAYTEST CONTEXT` fires at start/restore/launch with
  campaign, node, and package identity (the two-map-skirmish lines carry
  full package id/version/path). The telemetry work shipped in this build is
  what made this triage's root-causing possible.

## Fix sequencing (proposed)

1. **V053-01 + V053-02 together** (one branch — same resume seam, and 02's
   retry path only works once 01 marks the node): highest severity, loses
   player progress today.
2. **V053-04 replace-flow + messaging** (mechanical, no decision blocked) —
   the cap-size decision can follow separately.
3. **V053-03** once the HP policy is decided.
4. **V053-05/-06** HUD editor modal gate + toolbar hardening.
5. **V053-07/-08/-09/-10** batched as polish alongside whichever branch is
   open.

Per branch policy these are product fixes: base them on the release line
(sibling of `agent/playtest-release-v0.5.3-telemetry`) toward a v0.5.4
playtest build, and register rows in `coordination/tasks.json` when
implementation starts.

## Decisions (recorded 2026-07-22)

1. Between-map HP policy (V053-03): **full heal for everyone** at campaign
   next-map launch. Suspend resume still preserves exact mid-map HP.
2. Manual save budget (V053-04): **per-campaign cap of 3** between-map manual
   slots — saves in one campaign must not block saving in another. Replace
   flow and "slots full" messaging get fixed regardless; Load Game needs a
   delete affordance.
3. Implementation is **held pending discussion** of the proposed fixes —
   no code changes yet.
