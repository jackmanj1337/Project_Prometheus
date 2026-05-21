# Code Review — 2026-05-21

**Scope:** The C3 faction changeset — commits `cca788d..8ea7429` (faction-driven
AI phase flow). Files: `EnemyAI.gd`, `TurnManager.gd`, `GameMap.gd`, `MapData.gd`,
`HUD.gd`, `PhaseBanner.gd`, `Unit.gd`, the new `map_001_c3_factions_data.tres`,
and their tests.

**Assumption:** I scoped this to the unreviewed delta since `code_review_2026-05-20.md`.
Say so if you wanted the whole codebase instead.

## 1. Executive Summary

**Overall quality: 8/10.** Solid, well-tested work. The N-faction model is
genuinely faction-blind — adding a faction is data-only, exactly as the design
intends — and the new behaviour is backed by targeted tests (hostility model,
the stage-4 dispatch loop, HUD/banner labels, unit tint). All 23 suites pass
(484 checks green).

Biggest concerns are not bugs in current content but latent gaps: the
`start_enemy_phase` loop only terminates because `"blue"` happens to be in every
map's turn order, and faction label/colour lookup logic is now duplicated across
three UI scripts.

## 2. Issues Found

### [SEVERITY: Medium] `start_enemy_phase` loop has no hard termination guard
- **File & Line:** `scripts/core/TurnManager.gd:288`
- **Problem:** The new dispatch loop is `while active_faction() != "blue" and
  active_faction() != "":`. It only exits when the scheduler lands back on
  `"blue"`. `_advance_faction()` always wraps and `active_faction()` never
  returns `""` while `_turn_order` is non-empty — so a map whose `turn_order`
  omits `"blue"` (a data error, but an easy one) hangs the game in an infinite
  loop with no error.
- **Root Cause:** Termination was tied to a magic string rather than to a
  bounded iteration count. It works today only because every authored map
  includes `blue`.
- **Recommended Fix:** Cap iterations at the number of factions:
  ```gdscript
  var guard: int = _turn_order.size() + 1
  while active_faction() != "blue" and active_faction() != "" and guard > 0:
      guard -= 1
      ...
  if guard <= 0:
      push_error("TurnManager: enemy-phase loop did not return to blue — check turn_order")
  ```
- **Tradeoffs:** None meaningful — a few lines, and it converts a hang into a
  loud error.

### [SEVERITY: Medium] Non-blue, non-AI factions are silently skipped in WHOLE_PHASE
- **File & Line:** `scripts/core/TurnManager.gd:288` (loop body) / `:332` (`_is_ai_controlled`)
- **Problem:** Inside the loop, `if _is_ai_controlled(active_faction()) and ai:`
  guards the AI call. A non-blue faction with `controller = "HOTSEAT"`/`"HUMAN"`
  gets its `_begin_phase` run (units refreshed, fort healing, start-of-turn
  skills fire) and is then immediately advanced past — nobody ever acts for it.
  Current C3 content is safe because every non-blue faction is `"AI"`, but the
  next hotseat/second-player map will lose a whole faction's turn with no
  warning.
- **Root Cause:** Stage 4 deliberately ships AI-only dispatch (the comment says
  so), but the loop still *runs the phase-begin side effects* for factions it
  cannot drive.
- **Recommended Fix:** When `_is_ai_controlled` is false for a non-blue faction
  in WHOLE_PHASE, either skip `_begin_phase` for it too, or `push_warning` and
  `break` so the gap is visible rather than silent. Pick the explicit break
  until stage 5 plumbs the hotseat controller.
- **Tradeoffs:** A break changes behaviour for any half-authored hotseat map —
  but that map is already broken; failing loudly is better.

### [SEVERITY: Medium] `run_enemy_phase` is dead code with a misleading rationale
- **File & Line:** `scripts/core/EnemyAI.gd:26`
- **Problem:** The legacy alias's comment says it is "kept so older tests/callers
  can still invoke the pre-C3 entry point," but `rg run_enemy_phase scripts/`
  finds no callers — not in production code, not in tests. It is dead code, and
  its behaviour also differs from the pre-C3 version (the old one called
  `turn.start_player_phase()`; this one does not), so it would not be a safe
  drop-in even if something did call it.
- **Root Cause:** Kept defensively during the rename without confirming a
  consumer exists.
- **Recommended Fix:** Delete `run_enemy_phase` and update the autoload
  reference accordingly, or — if you expect external/Codex callers — keep it but
  correct the comment to state it is a compatibility shim with *changed* phase-
  handoff semantics.
- **Tradeoffs:** Removing it is the cleaner call; re-add later if a real caller
  appears.

### [SEVERITY: Medium] Faction label/colour lookup duplicated across three scripts
- **File & Line:** `scripts/ui/HUD.gd:119,128`, `scripts/ui/PhaseBanner.gd:52,61`,
  `scripts/units/Unit.gd:60`
- **Problem:** Three scripts now independently do "loop `md.factions`, match by
  `id`, read `get_label()`/`color`." `_active_faction_id()` is byte-identical in
  HUD and PhaseBanner; the empty-id title-casing fallback re-implements
  `FactionData.get_label()` a third time. Every future faction-aware surface
  (results screen, unit details) will copy it again.
- **Root Cause:** No shared lookup helper exists, so each consumer rolled its own.
- **Recommended Fix:** Add one helper on `MapData`, e.g.
  `func get_faction(id: String) -> FactionData`, and let callers do
  `md.get_faction(id).get_label()` / `.color`. The `_active_faction_id()` path
  resolution can move to a small shared util or a `TurnManager` accessor.
- **Tradeoffs:** Slightly more indirection; offset by removing ~40 duplicated
  lines and a triplicated title-case rule.

### [SEVERITY: Low] UI scripts reach TurnManager by a hardcoded node path
- **File & Line:** `scripts/ui/HUD.gd:120`, `scripts/ui/PhaseBanner.gd:53`
- **Problem:** Both use `get_node_or_null("/root/GameMap/TurnManager")`. If the
  `GameMap` node is renamed or TurnManager is re-parented, the call silently
  returns null and the UI falls back to `"red"` — a wrong label with no error.
- **Root Cause:** No autoload/EventBus channel for "current active faction," so
  the UI walks the tree.
- **Recommended Fix:** Prefer surfacing the active faction id on an existing
  signal (e.g. include it in the `phase_changed` payload via EventBus) so the UI
  never needs the path. Short term, at least `push_warning` when the lookup fails
  instead of silently using `"red"`.
- **Tradeoffs:** Changing the signal payload touches every `phase_changed`
  listener; reasonable to defer, but log the miss now.

### [SEVERITY: Low] Stale comments in `TurnManager.start_enemy_phase`
- **File & Line:** `scripts/core/TurnManager.gd:274` and the comment block at `:272-278`
- **Problem:** Line 274 still reads "`EnemyAI.run_enemy_phase()` is awaited" —
  the code now awaits `run_ai_phase`. The block above also describes the
  "Stage 3 … single-AI path" that stage 4 has now replaced, so it documents
  behaviour the function no longer has.
- **Root Cause:** Comment not updated alongside the rename and loop rewrite.
- **Recommended Fix:** Rewrite the header to describe the current per-faction
  loop and the `run_ai_phase` call.
- **Tradeoffs:** None.

### [SEVERITY: Low] New comment lines un-indented inside `_spawn_units()`
- **File & Line:** `scripts/core/GameMap.gd:165-166`
- **Problem:** The two new `# Enemy/AI-controlled units…` comment lines sit at
  column 0 while the code around them is one tab in. GDScript tolerates it (the
  parser ignores comment-only lines), but it reads as if the block ended.
- **Root Cause:** Comment pasted at column 0.
- **Recommended Fix:** Indent both lines one tab to match the `for` loop they
  describe.
- **Tradeoffs:** None.

### [SEVERITY: Low] `controller` value `"HUMAN"` not in the documented enum
- **File & Line:** `data/maps/map_001_rout/map_001_c3_factions_data.tres` (faction_blue)
  vs. `scripts/resources/FactionData.gd:32`
- **Problem:** The new `.tres` sets blue's `controller = "HUMAN"`, but
  `FactionData.gd`'s doc comment lists only `"AI"`, `"HOTSEAT"`, `"REMOTE"` plus
  "the implicit human-blue path." Nothing breaks (blue short-circuits before
  `controller` is read), but the data uses a value the schema doc doesn't name.
- **Root Cause:** The enum is intentionally open, but `"HUMAN"` was introduced in
  data without being recorded in the field's doc comment.
- **Recommended Fix:** Add `"HUMAN"` to the `controller` doc comment in
  `FactionData.gd`, or drop it from the `.tres` since blue ignores it anyway.
- **Tradeoffs:** None.

## 3. Positive Observations

1. **`set_ai_controller` test seam** (`TurnManager.gd:138`) is clean dependency
   injection — the stage-4 loop test drives a stub AI and asserts the exact call
   order (`["red", "yellow"]`) deterministically, no autoload juggling.
2. **`_living_hostiles_for_faction`** (`EnemyAI.gd:272`) implements targeting
   purely through the alliance-group model — no faction names hardcoded, so a
   5th faction needs zero AI changes. This matches the stated design rule in
   `FactionData.gd` exactly.
3. **Backward compatibility is deliberate and tested:** the `faction` placement
   key defaults to `"red"`, an empty `MapData.factions` falls back to the legacy
   blue/red tints, and the new `MapData.gd` comment documents the optional key.
   Pre-C3 maps keep working.
4. **Good test breadth for the changeset** — hostility model, the dispatch loop,
   HUD label, PhaseBanner, unit tint, and the ALTERNATING handoff each got a
   focused new check.

## 4. Architectural Observations

- **The faction-blind goal is being met.** The scheduler, AI, and hostility
  resolution all operate on string ids and alliance groups. The C3 `.tres`
  proves it: four factions, two alliance groups, an *allied AI* faction (green),
  and no enum edits.
- **Faction metadata resolution is spreading.** Three scripts now look up a
  `FactionData` by id (Issue 4). This is the moment to centralise it — one
  `MapData.get_faction()` accessor — before the results screen and unit-details
  panel copy the pattern a fourth and fifth time.
- **UI→game-state coupling.** HUD and PhaseBanner pull from `/root/GameState` and
  a hardcoded `/root/GameMap/TurnManager` path. As more UI becomes faction-aware,
  an EventBus signal carrying `(phase, faction_id)` would decouple them and kill
  the silent `"red"` fallback.
- **Stage boundaries are honest.** Comments mark what is deferred (ALTERNATING
  handoff, hotseat). The risk (Issue 2) is that a deferred path still runs
  half its side effects rather than failing fast.

## 5. Prioritized Action Plan

1. **Add the iteration guard to the `start_enemy_phase` loop** (Issue 1) — tiny,
   converts a potential hang into a clear error. Do this first.
2. **Make the non-AI non-blue WHOLE_PHASE case explicit** (Issue 2) —
   `push_warning` + `break` so the future hotseat gap is visible.
3. **Extract `MapData.get_faction()` and de-duplicate the UI lookups** (Issue 4)
   — best impact-vs-effort for maintainability; do it before more UI copies it.
4. **Delete or correctly document `run_enemy_phase`** (Issue 3).
5. **Fix the stale comments and comment indentation** (Issues 6, 7) and **record
   `"HUMAN"` in the `controller` doc** (Issue 8) — trivial cleanups, batch them.
