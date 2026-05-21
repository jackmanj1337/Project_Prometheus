# Code Review — 2026-05-16 (b)

Reviewer: Claude
Codebase: ~7,361 lines GDScript, 30 source files + 11 test suites, Godot 4 turn-based
tactics RPG (Fire Emblem-like).
Scope: all `scripts/` source (autoloads, core, resources, units, items, skills, ui,
shared). Tests run green (11 suites, 241 tests) and were read for coverage but not
line-audited. Tool scripts excluded. Skill `.tres` data inspected where relevant.

This is a follow-up to `code_review_2026-05-16.md`. The four High/Medium findings from
that pass — counter-kill EXP, the Retry inventory deep-copy, the `load()` null-checks,
and `assert` → `push_error` for startup validators — have all been correctly fixed and
verified in this read. This review covers what is still open or newly visible.

---

## 1. Executive Summary

**Overall quality: 7.5 / 10.**

The codebase remains well-structured, unusually well-commented, and well-tested, and the
team has shown strong follow-through on the previous review. The biggest concern this
pass is a real correctness bug in the combat *preview*: it restores unit state before
computing the numbers it displays, so any skill that works through stat modifiers
(Resolve, shipped and implemented) makes the preview lie to the player. Beyond that, the
issues are a cluster of "declared but unenforced" data fields and a missing weapon-type
gate that lets staves be used as attack weapons. None crash; the test suite is green.

---

## 2. Issues Found

### [SEVERITY: High]
- **File & Line:** `scripts/core/CombatResolver.gd:385-425` (`preview_combat`),
  restore calls at `:391-392`.
- **Problem:** `preview_combat` snapshots attacker/defender state, runs
  `_collect_combat_modifiers()` (which fires `on_combat_start` skills), then **restores
  unit state immediately at `:391-392`** — *before* it computes the displayed damage,
  hit, crit, and follow-up numbers at `:396-422`. Skills that work through
  `context["atk_mod"]`/`def_mod` (Wrath, Faire, Breaker, S-rank Mastery) survive the
  restore because those dicts are not snapshotted. But **Resolve** applies its +50%
  STR/MAG/SKL/SPD through `Unit.add_modifier()` — i.e. `data.active_modifiers`, which
  *is* snapshotted and restored. So for a unit at ≤50% HP with Resolve:
  - `compute_damage()` reads `get_effective_stat("strength")` *after* the restore →
    preview shows base damage, actual combat deals boosted damage.
  - `get_follow_up_attacker()` at `:396` reads `battle_speed()` *after* the restore →
    preview can miss a follow-up that the real fight will perform.
  - `compute_hit_pct()` reads SKL after the restore → preview understates accuracy.
  The combat forecast is the player's primary decision tool; for a low-HP Resolve unit
  it is simply wrong, and `resolve_combat()` (which keeps the modifiers applied through
  the whole fight) will diverge from it.
- **Root Cause:** The restore was placed to satisfy "preview must leave no trace on live
  state," but it was placed *too early*. The invariant should be "apply modifiers →
  compute → restore," not "apply → restore → compute."
- **Recommended Fix:** Move the two `_restore_unit_state` calls to the end of the
  function, after every `compute_*` / `get_follow_up_attacker` call. Build the result
  into a local, restore, then return it:
  ```gdscript
  _collect_combat_modifiers(context)
  # ... compute aw, dw, follow_up, all the hit/damage/crit values into locals ...
  var result := { ... }            # same dict as today, built from the locals
  _restore_unit_state(attacker, atk_snap)   # restore AFTER the math
  _restore_unit_state(defender, def_snap)
  return result
  ```
  The preview still leaves no lasting trace (restore happens before return), but now the
  numbers reflect the same modifier state `resolve_combat()` will use.
- **Tradeoffs:** None. Add a regression test: a unit at ≤50% HP with Resolve →
  `preview_combat` `attacker_damage` matches the boosted figure, and a borderline-SPD
  case shows the follow-up. `test_combat.gd` already exercises Resolve in `resolve`.

### [SEVERITY: Medium]
- **File & Line:** `scripts/core/GridManager.gd:329` (`get_attackable_enemies_from_tile`),
  `:276` (`_get_weapon_range`); `scripts/core/CombatResolver.gd:252` (`can_counterattack`);
  `scripts/ui/ActionMenu.gd:28-37` (`show_for`).
- **Problem:** Nothing excludes `weapon_type == "staff"` from attack logic. A staff is an
  `InventoryEntry` of type `"weapon"`, so `Unit.get_equipped_weapon()` returns it, and:
  - `ActionMenu.show_for` enables **Attack** whenever an enemy is within the staff's
    range (`has_weapon and attackable.size() > 0`).
  - Confirming the attack runs `resolve_combat` with the staff: `compute_damage` uses
    `mt = 0` but still adds STR, so the staff deals chip damage; `compute_hit_pct` uses
    `SKL*2+LUK` and is quite accurate. The staff also loses a use (`"staff"` is in
    `_ALWAYS_USE_DURABILITY`).
  - `can_counterattack` returns true for a staff-wielding defender, so staves
    counterattack too.
  - `show_enemy_danger_zone` paints staff range as a threat ring.
  A "basic"-profile enemy carrying a staff will attack with it instead of healing.
- **Root Cause:** Staff vs. attack-weapon is distinguished only at the *menu action*
  level (Attack vs. Staff buttons), never in the range/targeting helpers themselves.
- **Recommended Fix:** Add a single predicate — e.g. `WeaponData.is_staff()` returning
  `weapon_type == "staff"` — and filter on it in `_get_weapon_range`/
  `get_attackable_enemies_from_tile` (return no attack range / no targets for a staff)
  and in `can_counterattack` (a staff cannot counter). `ActionMenu` then naturally
  disables Attack for a staff-only unit. Keep the staff's range available to
  `get_healable_allies` via a separate path or a `for_healing` flag.
- **Tradeoffs:** If a future design *wants* offensive staves (e.g. Flux-type), this
  becomes a per-weapon flag instead of a blanket type check — but for MVP a staff that
  can chip-attack is a bug, not a feature.

### [SEVERITY: Medium]
- **File & Line:** `scripts/core/TurnManager.gd:169-206` (`check_victory_conditions`,
  `_map_over`), `:208-212` (`_apply_victory_rewards`); `scripts/ui/GameOverScreen.gd:42-46`.
- **Problem:** On victory, `_apply_victory_rewards` adds `reward_gold`/`reward_items` to
  `GameState.party_gold` / `party_items`. The `GameOverScreen` shows a **Retry** button
  on victory as well as defeat; pressing it calls `restore_map_snapshot()` and reloads
  the scene. But `take_map_snapshot()` only snapshots per-unit `UnitData` — it does *not*
  snapshot `party_gold`/`party_items`, and `_map_over` is per-`TurnManager` instance, so
  it resets to `false` on the scene reload. Win → Retry → win again → **rewards are
  granted a second time**. Gold and item drops duplicate on every replay.
- **Root Cause:** `party_gold`/`party_items` live on the persistent `GameState` autoload
  but are outside the Retry snapshot, and victory is an idempotent-looking action that
  isn't idempotent.
- **Recommended Fix:** Two parts. (a) Include `party_gold` and `party_items` in the
  snapshot/restore (snapshot them in `take_map_snapshot`, restore in
  `restore_map_snapshot`) so a Retry rolls the economy back. (b) Reconsider showing
  **Retry** on the victory screen at all — after a win the player wants to *advance*, not
  replay. For the single-map MVP, relabel it or hide it on victory; either removes the
  duplication path.
- **Tradeoffs:** None for (a). (b) is a small UI decision; flag it for the milestone
  tracker rather than guessing intent.

### [SEVERITY: Medium]
- **File & Line:** `scripts/resources/SkillData.gd:22` (`max_uses_per_combat`),
  `scripts/skills/SkillHandler.gd:47-78` (`apply_trigger`).
- **Problem:** `SkillData.max_uses_per_combat` is declared, exported, persisted in
  `.tres`, and documented ("Counter cleared after each combat resolves") — but **no code
  reads it**. `apply_trigger` enforces only `max_uses_per_map`. A skill authored with a
  per-combat cap (e.g. "Astra: once per combat") would fire unlimited times within a
  single fight. This is a silent correctness hole that will surface the moment a
  per-combat skill is added in M9.
- **Root Cause:** The field was defined ahead of the enforcement code (same pattern as
  the inert-settings finding in the prior review).
- **Recommended Fix:** Either implement it now or document it as not-yet-enforced. To
  implement: track a per-combat counter dict that `CombatResolver` resets at the start of
  each `resolve_combat`/`preview_combat` and that `apply_trigger` checks and increments
  alongside the existing `max_uses_per_map` logic. Until then, add a `# NOT ENFORCED —
  M9` comment on the field so it isn't assumed live.
- **Tradeoffs:** A per-combat counter needs a clear reset point; `resolve_combat` start
  is the natural one. Preview must not increment it (or must restore it, like
  `skill_use_counters`).

### [SEVERITY: Medium]
- **File & Line:** `scripts/ui/SettingsScreen.gd` (whole file), `scripts/ui/MainMenu.gd`,
  `scripts/ui/MapMenu.gd`.
- **Problem:** `SettingsScreen` is complete and functional (audio sliders, gameplay
  toggles, back signal, `combat_animations` correctly hidden) but **still has no entry
  point**. `MainMenu` exposes only New Game / Quit; `MapMenu` exposes only End Turn /
  Close. There is no button anywhere that calls `SettingsScreen.open()`. The screen, its
  `.tscn`, and the `SettingsManager` write-through it drives are unreachable by the
  player. This was raised in the prior review; `PhaseBanner` now honors `phase_banner`
  and `combat_animations` is hidden, but the screen itself was never wired up.
- **Root Cause:** Screen built before its navigation entry; the prior review's
  "wire it up OR hide the inert option" was resolved by doing the second half only.
- **Recommended Fix:** Add a "Settings" button to `MainMenu` (next to New Game) that
  calls `_settings_screen.open()` and connects `back_pressed` — the exact pattern
  `MainMenu` already uses for `NewGameScreen`. Optionally add one to `MapMenu` too. If
  deferral is intentional, record it in the milestone tracker so the screen is not
  assumed live.
- **Tradeoffs:** None — a few lines, mirroring existing `NewGameScreen` wiring.

### [SEVERITY: Low]
- **File & Line:** `scripts/skills/SkillHandler.gd:74-77` (`apply_trigger`).
- **Problem:** `apply_trigger` rolls activation, runs `_execute_skill`, then increments
  `skill_use_counters` **unconditionally** if the skill is use-limited. But a skill can
  proc its activation roll and then no-op inside its handler: `_apply_miracle` returns
  the context unchanged when the hit is non-lethal (`:161 dmg < sim_hp`). If Miracle ever
  gets a `max_uses_per_map`, a successful luck-roll on a *non-lethal* hit would burn a
  use without saving anyone. Today `miracle.tres` sets no per-map limit, so this is
  latent — but Miracle is exactly the skill shape that would expose it.
- **Root Cause:** "Activation succeeded" and "effect actually did something" are
  conflated; the counter is tied to the former.
- **Recommended Fix:** Let the handler signal whether it consumed a use — e.g. have
  `_execute_skill` return a result and only count the use when the effect applied, or
  have `_apply_miracle` itself decrement only on a real save. Simplest: don't count the
  use until the effect commits. Defer until a use-limited conditional skill exists, but
  note it.
- **Tradeoffs:** Slightly more plumbing through the dispatch return value.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/CombatResolver.gd:385-392` (`preview_combat` →
  `_collect_combat_modifiers` → `SkillHandler.apply_trigger`).
- **Problem:** `preview_combat` is documented "no RNG, no side effects," but
  `_collect_combat_modifiers` calls `apply_trigger`, which rolls `randi()` for any skill
  with `activation_chance_stat` set (`SkillHandler.gd:69-72`). Today the only such skill
  is Miracle (`on_damaged`, not fired during preview), so the contract holds *by
  accident*. The moment an `on_combat_start` skill with an activation roll is authored,
  the preview will roll RNG and can diverge from `resolve_combat`.
- **Root Cause:** The "no RNG" guarantee is a comment, not an enforced code path.
- **Recommended Fix:** Pass a `preview: bool` flag down to `apply_trigger` (or set a
  context flag) so that during preview a chance-based skill is treated deterministically
  — e.g. assumed-on for the bearer's own buffs, assumed-off for opponent debuffs, or
  shown as a range. Decide the convention when the first such skill lands; for now add a
  comment so the contract is explicit.
- **Tradeoffs:** None immediate; this is a guardrail against a future regression.

### [SEVERITY: Low]
- **File & Line:** `scripts/autoloads/GameState.gd:16-17` (`max_skills`, `max_inventory`).
- **Problem:** `max_skills` and `max_inventory` are declared on `GameState` and
  referenced in a `UnitData` comment ("counts against max_skills"), but no code reads
  either. Nothing caps how many skills a unit equips or how many inventory slots it
  fills. Dead config that implies an enforced rule which does not exist.
- **Root Cause:** Fields defined ahead of the equip/inventory-management UI.
- **Recommended Fix:** Either enforce them at the (future) skill-equip and trade UIs, or
  drop them until that UI exists. At minimum, change the `UnitData.gd:32` comment so it
  doesn't claim an enforced limit.
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/MapCursor.gd:415-424` (`_enter_targeting`).
- **Problem:** `_enter_targeting` snaps the cursor with `current_tile = tiles[0]` and a
  direct `position` assignment, bypassing `_set_tile()`. As a result, entering targeting
  does not emit `cursor_moved`, so the HUD info panel does not update to show the unit
  under the new cursor tile, and `_scroll_camera_if_needed()` is not called, so a target
  off the current view does not pull the camera. `_cycle_target`/`_handle_targeting_mouse_motion`
  both correctly go through `_set_tile`; only the initial snap is inconsistent.
- **Root Cause:** Direct assignment used to avoid re-clamping, but it skips the side
  effects `_set_tile` exists to centralize.
- **Recommended Fix:** Call `_set_tile(tiles[0])` instead of the manual assignment.
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/units/Unit.gd:334-339` (`perform_staff_heal`).
- **Problem:** Staff heal amount is `STAFF_HEAL_BASE + data.magic` — it reads
  `data.magic` directly rather than `get_effective_stat("magic")`. Every combat formula
  (`compute_damage`, dynamic weapon range) goes through `get_effective_stat` so temporary
  MAG modifiers apply; staff healing silently ignores them. A MAG-buffed healer heals as
  if unbuffed.
- **Root Cause:** Direct field read where the modifier-aware accessor was intended.
- **Recommended Fix:** `var heal_amount := GameConstants.STAFF_HEAL_BASE +
  get_effective_stat("magic")`.
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/GridManager.gd:183-213` (`get_movement_range`),
  `:218-270` (`get_movement_path`).
- **Problem:** Both Dijkstra passes use a plain `Array` frontier: a relaxed tile is
  `append`ed again without removing the stale copy, and each pop is an O(n) linear
  min-scan. Correct, but O(n²)-ish on the frontier. Carry-over from the prior review.
- **Root Cause:** Simplest-thing-that-works for MVP map sizes (acknowledged in comments).
- **Recommended Fix:** Not urgent. Note that `EnemyAI._flood_costs:228-251` already has
  the correct pattern — an insertion-sorted heap with stale-entry skipping. When map
  sizes grow, consolidate all three flood-fills onto that one shared helper rather than
  maintaining two algorithms.
- **Tradeoffs:** None beyond effort; flagged as a conscious deferral.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/CombatResolver.gd:555` (`apply_combat_result`).
- **Problem:** `def_unit.data.damage_taken_this_map += exchange["damage"]` adds the full
  computed damage, but `take_damage` (`Unit.gd:311`) clamps HP at 0 — so an overkill blow
  adds more to `damage_taken_this_map` than HP was actually lost. The field feeds the
  planned Vengeance skill (M9), which will then over-count on a killing hit.
- **Root Cause:** Counter incremented from the pre-clamp damage figure.
- **Recommended Fix:** Add the actually-applied amount: capture HP before/after
  `take_damage`, or `mini(exchange["damage"], hp_before)`. Trivial; do it before
  Vengeance is implemented.
- **Tradeoffs:** None.

---

## 3. Positive Observations

1. **Strong follow-through on the last review.** All four High/Medium findings from
   `code_review_2026-05-16.md` are genuinely fixed: the counter-kill EXP guard
   (`CombatResolver.gd:566`), per-`InventoryEntry` deep-copy on both snapshot and restore
   (`GameState.gd:157-159`, `:208-210`), `load()` null-checks before `.duplicate()` in
   both `GameState` and `GameMap`, and `assert` → `push_error` in the startup validators
   (`DataManager._validate_cross_references`, the `unit_id` checks). The fixes match the
   recommended approaches, comments included.
2. **Stateless, layered combat engine.** `preview_combat` / `resolve_combat` /
   `apply_combat_result` are cleanly separated, and `apply_combat_result` recomputes
   death and EXP from what *actually* landed rather than trusting the simulation — a
   deliberate guard against weapon-break divergence. (Finding 1 is a flaw in *where* the
   preview restore sits, not in the architecture.)
3. **Test-aware design that holds up.** 11 suites / 241 tests run green headlessly.
   `is_inside_tree()` guards, `GridManager._terrain_fallback`, and the dependency-injected
   `MapCursorTargeting` (a plain `RefCounted`) let core logic be exercised without
   autoloads or a SceneTree. The D-1 targeting extraction is a clean first slice.
4. **Comments explain *why*.** The combat-context schema atop `CombatResolver`, the
   "capture the weapon before the durability decrement" note in `_apply_staff_heal`, the
   headless autoload-ordering notes, and the snapshot deep-copy rationale all document
   decisions, not mechanics.
5. **Data-driven content with fail-fast loading.** Classes, weapons, items, skills, and
   maps are all `.tres`; `SkillHandler`'s dispatch table turns an unknown `effect_id`
   into a startup `push_error` instead of a silent no-op; `DataManager` validates
   cross-references at boot.

---

## 4. Architectural Observations

- **The preview snapshot boundary is the recurring hazard.** Findings 1 and 7 both stem
  from `preview_combat`'s snapshot/restore design. The intended invariant is "apply
  modifiers → compute displayed numbers → restore"; the code currently does "apply →
  restore → compute," and also rolls RNG inside the applied step. Worth making the
  invariant explicit (a short comment, and the reorder from Finding 1) because more
  modifier-applying skills are coming in M9. Note also that `_snapshot_unit_state` only
  covers the attacker and defender — a future `on_combat_apply_modifiers` aura skill that
  mutates a *third* unit's `data` would leak out of preview uncaught.
- **"Declared but unenforced" is a pattern.** `max_uses_per_combat`, `max_skills`,
  `max_inventory`, and (previously) `combat_animations` are all defined, persisted, and
  in some cases documented as rules — with no consumer. Each is a latent correctness gap
  the day a feature assumes it works. A lightweight habit — a `# NOT ENFORCED — M9`
  marker on any field defined ahead of its consumer — would keep these honest.
- **`MapCursor` is still a 620-line FSM.** D-1 slice 1 (targeting → `MapCursorTargeting`)
  landed cleanly, but the `MapCursorInput` / `MapCursorSelection` slices are still
  pending, and `MapCursor` still owns input, selection, movement, menus, camera, and the
  end-turn dialog. It remains the largest correctness surface and the only core class
  without unit tests. Continue the planned slicing before Phase 2 piles on more actions.
- **Autoload access is string-path coupling.** Nearly every cross-system call is
  `get_node_or_null("/root/SomeAutoload")` — a documented, deliberate workaround for the
  headless compile-ordering issue, but it converts compile-time errors into scattered
  runtime `null` checks. A thin typed accessor module would centralize both the lookups
  and the null handling. (Carry-over.)
- **The save/snapshot system is half-built — and Finding 3 is the proof.** The Retry
  snapshot covers per-unit `UnitData` but not party-level economy (`party_gold`,
  `party_items`), and `_map_over` is per-scene. The reward-duplication bug is the first
  concrete symptom of the snapshot's incomplete scope; the suspend-save milestone will
  need the economy in the snapshot regardless, so fixing it now is not throwaway work.

---

## 5. Prioritized Action Plan

Ordered by impact-to-effort.

1. **Fix the combat preview** (`CombatResolver.preview_combat`): move the two
   `_restore_unit_state` calls to *after* the `compute_*` / `get_follow_up_attacker`
   calls. Add a Resolve-active preview regression test. (High impact, low effort.)
2. **Gate staves out of attack logic**: add `WeaponData.is_staff()` and filter it in
   `_get_weapon_range` / `get_attackable_enemies_from_tile` / `can_counterattack`.
   (Medium impact, low-medium effort.)
3. **Stop Retry from re-granting rewards**: add `party_gold`/`party_items` to the
   snapshot/restore, and decide whether "Retry" belongs on the victory screen. (Medium
   impact, low effort — and needed for suspend-save anyway.)
4. **Decide `max_uses_per_combat`**: implement the per-combat counter in `SkillHandler`,
   or mark the field NOT ENFORCED until M9. (Medium impact, medium effort.)
5. **Wire up `SettingsScreen`**: add a Settings button to `MainMenu` mirroring the
   existing `NewGameScreen` wiring. (Medium impact, trivial effort.)
6. **Low-effort correctness polish, batched**: `_enter_targeting` → `_set_tile`;
   `perform_staff_heal` → `get_effective_stat("magic")`; `damage_taken_this_map` uses the
   clamped amount. (Low impact, low effort.)
7. **Deferred**: don't count a skill use until the effect commits (Finding 6); make the
   "no RNG in preview" contract explicit (Finding 7); drop or enforce
   `max_skills`/`max_inventory`; consolidate the three flood-fills onto the heap-based
   helper when map sizes grow.

---

## Assumptions Flagged

- I assumed the combat *preview* is meant to match `resolve_combat`'s modifier state. If
  the preview is intentionally a "base stats only" forecast, Finding 1 is reduced to a
  documentation issue — but the asymmetry (some skills show, Resolve doesn't) is far more
  consistent with a bug than a design choice.
- I assumed staves are not meant to be usable as attack weapons (standard FE behavior).
  If offensive staves are planned, Finding 2 becomes a per-weapon flag rather than a
  blanket type gate.
- I assumed the victory screen's "Retry" replays the same map and that map rewards are
  meant to be granted once. If Retry-after-victory is not a real path in the intended UX,
  Finding 3's severity drops to the missing-snapshot-coverage half only.
- `combat_animations` having no consumer is expected for MVP (no animation layer yet);
  it is correctly hidden in `SettingsScreen` and is not re-flagged here.
