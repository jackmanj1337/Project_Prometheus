# Plan — Hotseat Validation Map + Map Selector

> **Historical** — M15 Part A foundations landed 2026-05-21. Manual validation
> checklist migrated to `AGENT/Docs/manual_test_playbook.md`. Retained for the
> original design rationale.

**Date:** 2026-05-21
**Scope:** Finish M15 Part A's remaining content and manual verification work.
**Status:** Planning only.

---

## 1. Goal

Create a fast, purpose-built map that validates the new hotseat flow in live play,
and add a lightweight map selector so this and future regression maps can be launched
without editing `GameMap.tscn` or changing `GameMap.map_data_path` by hand.

---

## 2. Deliverables

1. **Hotseat validation map** — a small WHOLE_PHASE authored map that exercises the
   new M15 Part A behavior in one short run.
2. **Map selector** — a minimal launch path for choosing among authored maps from
   the UI, so future playtests do not depend on scene edits.
3. **Manual playtest pass** — a repeatable checklist run against the validation map
   and at least one all-AI comparison map.

---

## 3. Map Design

### Recommended map id

- `map_900_hotseat_validation`

Using a high-numbered test id keeps it clearly separate from campaign content.

### Scenario goals

The map should let one short session confirm:

- Blue still behaves like the normal player phase.
- Green can be manually controlled through the shared `MapCursor`.
- Red AI still runs after green.
- Yellow AI still runs after red.
- Green can target hostiles correctly across multiple factions.
- Green can interact with allies correctly (same alliance group as blue).
- Ending a hotseat phase works both by manual End Turn and by "all units done".
- A map can resolve cleanly during a hotseat phase without hanging the controller.

### Recommended faction setup

- `blue` — human, allied group `allies`
- `green` — `HOTSEAT`, allied group `allies`
- `red` — `AI`, allied group `foes`
- `yellow` — `AI`, allied group `rogues`

### Recommended authored turn model

- `turn_order = ["blue", "green", "red", "yellow"]`
- `activation_mode = "WHOLE_PHASE"`

### Recommended roster shape

- **Blue:** 2 units
  - 1 front-line unit starting slightly injured
  - 1 second unit positioned so blue can either act normally or be left unacted to
    trigger the End Turn confirmation path
- **Green:** 2 units
  - 1 combat unit that can immediately attack either red or yellow
  - 1 cleric/staff unit that can heal a green ally or the injured blue ally
- **Red:** 2 units
  - 1 fragile unit positioned to be killed by green during hotseat play
  - 1 second unit that survives long enough to show the red AI phase still runs
- **Yellow:** 1 unit
  - Positioned so yellow remains a hostile for both green and red and gets a real AI
    turn instead of being trapped or irrelevant

### Recommended terrain/layout

- Small map, roughly **12×10 to 16×12**
- Mostly open center so movement/pathing is obvious
- One **fort** near the center to keep terrain bonuses visible during playtest
- A few walls or forest tiles for readable pathing, but no maze or long travel time
- Blue starts southwest, green central-west, red east, yellow southeast or northeast

### Recommended objective

- `victory_conditions = {"allies": [rout()]}` is sufficient

This keeps the test focused on controller flow instead of new objective authoring.
The final hostile should be reachable by green during a hotseat phase so the map can
end **before** End Turn is pressed.

---

## 4. Intended Playtest Beats

The validation map should naturally support this sequence:

1. **Blue phase sanity check**
   - Move or wait with one blue unit.
   - Leave one blue unit unacted and press End Turn once to confirm the warning
     prompt still appears.
   - Confirm End Turn and advance.
2. **Green hotseat phase**
   - Verify the cursor is unlocked and only green units are selectable.
   - Attack a red or yellow unit with the green fighter.
   - Heal a green or blue ally with the green staff user to confirm alliance-group
     ally targeting.
3. **AI follow-through**
   - Watch red act after green.
   - Watch yellow act after red.
   - Confirm neither AI phase hangs or gets skipped.
4. **Return to blue**
   - Confirm the camera and control handoff back to blue feels normal.
5. **Mid-hotseat map end**
   - On a later green phase, kill the last hostile during green's action.
   - Confirm the map ends immediately without waiting for End Turn and without
     leaving the cursor stuck in a live hotseat phase.

---

## 5. Map Selector Plan

### Why do this now

Right now map testing depends on direct scene loads or editing
`GameMap.map_data_path`. That does not scale once we have:

- campaign maps
- faction regression maps
- hotseat validation maps
- future AI/objective/condition test maps

The cheapest stable fix is a **small selector now**, before more ad hoc test maps
accumulate.

### Recommended approach

Add a minimal **map registry + selector UI**, not a one-off hotseat toggle.

### Recommended data shape

Create one registry source that lists:

- `id`
- `label`
- `map_data_path`
- `roster_policy`
- `description`
- `is_dev_only`
- optional tags such as `campaign`, `faction_test`, `hotseat_test`

Best-practice recommendation: keep this registry in one authored data file so map
labels and paths are not duplicated across scripts.

### Recommended roster handling

The first selector build should be explicit and simple:

- **Phase 1 rule:** map selection changes only the map; every selectable map uses
  the current `load_default_roster()` path unless the registry says otherwise.
- Add `roster_policy` to each registry entry now, even if every initial entry is
  `"default_roster"`.
- Supported first-pass policies should be:
  - `default_roster` — call `GameState.load_default_roster()`
  - `keep_current_roster` — reserved for later reuse/testing flows; do not make it
    the default for New Game
- `fixed_test_roster` should be planned as the next extension for deterministic
  regression maps, but it does **not** need to ship in the first selector patch.

This avoids the current ambiguity: the selector should not silently inherit
whatever roster happens to be in memory unless the map entry explicitly opts in.

### Recommended UI scope

Keep the first selector intentionally small:

- Add a **Map** choice to `NewGameScreen`, or add a separate `MapSelectScreen`
  opened from `MainMenu`
- Show label + short description
- Include at least:
  - `map_001_data`
  - `map_001_c3_factions_data`
  - `map_900_hotseat_validation`

### Recommended runtime wiring

- Store the chosen `map_data_path` in `GameState` as the next map to load
- Store the chosen `roster_policy` alongside it in `GameState`
- `NewGameScreen` applies both selections before changing to `GameMap.tscn`
- `GameMap` reads that override first and falls back to its exported default only
  when no selection was supplied

This keeps direct scene boot usable for development while making normal testing
path-driven and repeatable.

### Selector acceptance criteria

- A tester can launch the hotseat validation map from the UI without editing scenes.
- A tester can switch back to the existing faction regression map from the same UI.
- Adding the next test map requires editing the registry, not wiring a new button.
- The selected map's roster behavior is explicit in the registry, not implied by
  whatever roster was last loaded in memory.

---

## 6. Suggested Build Order

1. Author the **map selector foundation** first.
2. Register existing maps in it (`map_001`, `map_001_c3_factions`).
3. Author `map_900_hotseat_validation`.
4. Add the validation map to the selector.
5. Run the manual checklist from `AGENT/GDD/GDD_Manual_Tasks.md`.
6. Mark the relevant M15 Part A roadmap boxes complete.

This order avoids creating a new test map that still has to be launched by hand.

---

## 7. Out of Scope

- ALTERNATING hotseat
- Per-phase custom keybindings
- Remote/LAN play
- New objective-system coverage beyond what the current rout objective already gives

---

## 8. Locked design decisions — 2026-05-25 review

The four M15 Part A open questions from
`AGENT/Session Notes/2026-05-25.md` were resolved before the manual-validation
pass starts. See `AGENT/Docs/campaign_rules_firming_notes_2026-05-25.md` and
`GDD_10_Roadmap.md` § Milestone 15 Part A.

- **Per-player keybindings — skipped for Part A.** All hotseat slots share the
  existing single `InputMap` action set. Per-player binding profiles defer to
  the same later backlog item that picks up split-controller / shared-couch
  co-op. (Already listed under §7 *Out of Scope*; restated here as a locked
  decision rather than a deferral.)
- **Hotseat assignment — per-map data + CLI/dev override.** Each map's `.tres`
  declares its factions' default controllers (`AI` or `HOTSEAT`). A CLI/dev
  flag (e.g. `--hotseat=red:human2,green:ai`) may override the defaults for
  testing and regression fixtures. **No pre-battle lobby UI lands in Part A.**
  The map selector planned in §4 is the only launch path; lobby UI arrives
  with the prep work later.
- **HUD phase banner shows `Faction — Controller` text.** The HUD label format
  is e.g. `Red — Player 2` or `Green — AI`. Faction-first matches the in-game
  identity; the controller half eliminates the "whose turn is it?" ambiguity
  for hotseat sessions. Icons may decorate but must not replace the text.
- **`ALTERNATING` hotseat — fully out of Part A.** Revisited only after the
  extra-turn / activation-scheduler work is settled. Already covered in §7.
