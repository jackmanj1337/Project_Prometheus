---
Role: dated
---

# Code Review — 2026-05-16 (c)

Reviewer: Claude
Codebase: ~5,260 lines of GDScript source (30 files) + 11 test suites, Godot 4
turn-based tactics RPG (Fire Emblem-like).
Scope: all `scripts/` source — autoloads, core, resources, units, items, skills, ui,
shared. Skill/unit `.tres` data inspected where it affects correctness. Test suites
were read for coverage but not line-audited and not re-run (last session reported
11 suites / 245 tests green). Tool scripts (`tools/`, `scripts/tools/`) excluded.

This is a follow-up to `code_review_2026-05-16b.md`. **All twelve findings from that
review (1 High, 4 Medium, 6 Low + the deferred items the user approved) have been
correctly implemented and verified in this read** — see Positive Observations §1.
This pass covers what is still open or newly visible after those fixes.

---

## 1. Executive Summary

**Overall quality: 7.5 / 10.**

The codebase stays well-structured, unusually well-commented, and well-tested, and the
team's follow-through on the previous review was complete and accurate. The headline
concern this pass is a genuine, *shipped* skill-ordering bug: a unit defending with the
**Nihil** skill cannot actually negate the attacker's combat skills, because the
attacker's `on_combat_start` skills are applied before the defender's Nihil runs. The
map's boss (`e8_knight_boss`) carries Nihil, and players will most often *attack* the
boss — exactly the broken case. Beyond that the issues are a cluster of latent
inconsistencies: staff-vs-attack-weapon gating is now done two different ways in two
files, and combat skill triggers fire during pure simulation for exchanges that a
weapon break later discards. None crash; the suite is green.

---

## 2. Issues Found

### [SEVERITY: High]
- **File & Line:** `scripts/core/CombatResolver.gd:109-112` (`_collect_combat_modifiers`);
  `scripts/skills/SkillHandler.gd:163-168` (`_apply_nihil`).
- **Problem:** `_collect_combat_modifiers` applies `on_combat_start` skills in a fixed
  order — **attacker first (`:110`), then defender (`:112`)**:
  ```gdscript
  context = sh.apply_trigger(attacker, "on_combat_start", context, preview)
  if not context.get("defender_skills_blocked", false):
      context = sh.apply_trigger(defender, "on_combat_start", context, preview)
  ```
  Nihil is an `on_combat_start` skill: `_apply_nihil` sets `defender_skills_blocked`
  when its bearer is the attacker, or `attacker_skills_blocked` when its bearer is the
  defender. The attacker-side case works — the attacker's Nihil runs at `:110` and the
  guard at `:111` then skips the defender's skills entirely. **The defender-side case is
  broken:** when the *defender* carries Nihil, its `_apply_nihil` runs at `:112` and
  sets `attacker_skills_blocked` — but the attacker's `on_combat_start` skills already
  ran at `:110`. Resolve, Wrath, Faire, Breaker, and S-rank Mastery have all already
  written their bonuses into `context["atk_mod"]` by then. `attacker_skills_blocked` is
  only re-checked later in `_resolve_single_attack` for the `on_attack`/`on_hit`/
  `on_kill` triggers — and no shipped skill uses those. **Net effect: a defender's Nihil
  negates nothing.**
  This is not theoretical. `data/maps/map_001_rout/enemies/e8_knight_boss.tres` has
  `skills = ["nihil", "resolve", "lancefaire"]`, and `unit_02_mercenary` ships with
  `["vantage", "swordfaire"]`. When the player mercenary attacks the boss, the
  mercenary's Swordfaire applies its +5 damage at `:110` and the boss's Nihil at `:112`
  is too late to stop it. The boss's signature skill is roughly half-functional.
- **Root Cause:** Nihil is a skill that must run *before* the opposing side's skills,
  but it is dispatched in the same undifferentiated `on_combat_start` pass as the
  skills it is meant to suppress. Ordering within the pass is attacker-then-defender,
  so only the attacker's Nihil gets to act first.
- **Recommended Fix:** Give Nihil (and any future "negate" skill) a pre-pass before
  the normal `on_combat_start` dispatch. Concretely, in `_collect_combat_modifiers`,
  resolve the blocked-flags first, then run the modifier skills:
  ```gdscript
  # Pre-pass: let either side's Nihil set the *_skills_blocked flags before any
  # modifier skill runs, so a defending Nihil bearer can still negate the attacker.
  if sh:
      context = sh.apply_trigger(attacker, "on_combat_start_negate", context, preview)
      context = sh.apply_trigger(defender, "on_combat_start_negate", context, preview)
  # Normal pass: modifier skills, each guarded by the now-final blocked flags.
  if sh:
      if not context.get("attacker_skills_blocked", false):
          context = sh.apply_trigger(attacker, "on_combat_start", context, preview)
      if not context.get("defender_skills_blocked", false):
          context = sh.apply_trigger(defender, "on_combat_start", context, preview)
  ```
  This needs `nihil.tres` re-tagged to the new `on_combat_start_negate` trigger, and
  `_apply_nihil` left as-is. A lighter-touch alternative — sort the skill list inside
  `apply_trigger` so negate-class effects dispatch first, and run *both* sides'
  `on_combat_start` unconditionally with the attacker's modifier skills guarded by a
  flag re-checked per skill — is more fragile because it still interleaves the two
  units' passes. The two-trigger split is the clean fix.
- **Tradeoffs:** Adds one trigger name and one extra `apply_trigger` round. Add a
  regression test: a defender with Nihil vs an attacker with Swordfaire/Resolve →
  `preview_combat` / `resolve_combat` show *no* skill bonus on the attacker.
- **Assumption flagged:** I assume Nihil is intended to work symmetrically (negate the
  opponent whether its bearer attacks or defends), which is standard FE behavior and is
  what `_apply_nihil` itself is written to do. If Nihil is deliberately attacker-only,
  this drops to a documentation fix — but `_apply_nihil`'s defender branch shows that
  was not the intent.

### [SEVERITY: Medium]
- **File & Line:** `scripts/ui/ActionMenu.gd:40-43` (`show_for`);
  `scripts/core/EnemyAI.gd:167-168` (`_try_staff_heal`).
- **Problem:** Session E's staff fix introduced `WeaponData.is_healing_staff()` (keys
  off the `heal_10_plus_mag` tag) and routed `GridManager` and
  `CombatResolver.can_counterattack` through it — explicitly so future offensive/debuff
  staves (M8) stay attack-capable. But two call sites were missed and still gate on the
  raw `weapon_type == "staff"`:
  - `ActionMenu.show_for:41` — `if staff_weapon and staff_weapon.weapon_type == "staff"`
    decides whether to enable the **Staff** (heal) button.
  - `EnemyAI._try_staff_heal:168` — `if weapon == null or weapon.weapon_type != "staff"`
    decides whether an enemy heals.
  Today every staff *is* a healing staff, so behavior is correct. The moment an M8
  offensive staff lands (`weapon_type == "staff"`, no heal tag), it will be **both** an
  attack weapon (correct — `is_healing_staff()` is false everywhere else) **and** offer
  the heal action via these two stale checks: a unit could "heal" with an offensive
  staff via `perform_staff_heal` (10 + MAG HP), and an enemy AI would try to heal with
  it. The codebase would then be internally inconsistent — the same weapon classified
  two different ways depending on which file you ask.
- **Root Cause:** The Session E fix updated the range/targeting helpers but not the two
  UI/AI consumers; the `is_healing_staff()` predicate was meant to be the single source
  of truth and isn't yet.
- **Recommended Fix:** Replace both raw checks with `is_healing_staff()`:
  - `ActionMenu.gd:41` → `if staff_weapon and staff_weapon.is_healing_staff():`
  - `EnemyAI.gd:168` → `if weapon == null or not weapon.is_healing_staff():`
- **Tradeoffs:** None — this is the exact consolidation Session E intended; it just
  finishes it. Worth a grep for any other `weapon_type == "staff"` literal.

### [SEVERITY: Medium]
- **File & Line:** `scripts/core/CombatResolver.gd:294-366` (`_resolve_single_attack`),
  `:443-529` (`resolve_combat`), `:535-602` (`apply_combat_result`).
- **Problem:** `resolve_combat` simulates the *full* strike count for every unit and
  ignores weapon durability entirely. `apply_combat_result` then decrements durability
  per exchange and, when a weapon breaks mid-combat, **skips every later exchange that
  used that weapon** (`:553-554`, the `broken` dict). The HP/death/EXP recompute at
  `:577-583` correctly accounts for the skipped hits. *But the skill triggers in
  `_resolve_single_attack` already fired during simulation* — `on_attack` (`:303`),
  `on_hit` (`:330`), `on_damaged` (`:346`), `on_kill` (`:351`). So an exchange that
  `apply_combat_result` discards because the weapon broke has *already* run its trigger
  side effects: an `on_damaged` skill on the target (Miracle is exactly this shape) can
  consume an activation and reduce a damage figure for a blow that never lands; an
  `on_kill` skill fires for a kill that never happens. No shipped skill uses
  `on_attack`/`on_hit`/`on_kill`, and Miracle currently has no use cap, so this is
  **latent** — but it is a real divergence between "what was simulated" and "what is
  applied," and M9 skills on those triggers will expose it.
- **Root Cause:** Durability is modelled only in the apply phase, bolted on after the
  fact, while the simulation phase (which fires triggers) assumes infinite uses. The
  two phases disagree about how many attacks actually occur.
- **Recommended Fix:** Move durability into the simulation. Track a per-weapon
  remaining-use count inside `resolve_combat` (seeded from the equipped
  `InventoryEntry.uses_remaining`), and stop generating exchanges for a unit once its
  weapon would be exhausted — the same `broken`-style bookkeeping that
  `apply_combat_result` already does, just one layer up. `apply_combat_result` then
  only *applies* exchanges and never has to skip any, and triggers fire only for
  attacks that genuinely happen. This also makes `resolve_combat`'s returned
  `exchanges`/death prediction accurate on its own rather than needing the `:577-583`
  recompute as a correction.
- **Tradeoffs:** Non-trivial — it shifts logic between two functions and the
  recompute-after-the-fact guard would become redundant (a simplification, but a
  behavior-visible one that needs its own test coverage). If deferred, at minimum add a
  comment on `_resolve_single_attack` noting that triggers may fire for exchanges the
  apply phase later discards, so M9 skill authors are warned.

### [SEVERITY: Medium]
- **File & Line:** `scripts/core/GridManager.gd:361-366` (`can_attack_from_tile`),
  `:308-324` (`get_attack_range_from_tiles`); `scripts/core/EnemyAI.gd:134-160`
  (`_choose_move_tile`).
- **Problem:** `get_attackable_enemies_from_tile` (`:342`) and
  `get_attack_range_from_tiles` (`:311`) both correctly call `_equipped_can_attack` and
  return nothing for a healing-staff user. **`can_attack_from_tile` (`:361`) does not** —
  it goes straight to a range/distance check. `EnemyAI._choose_move_tile` drives enemy
  positioning off `can_attack_from_tile`, so a `basic`-profile enemy holding a healing
  staff is treated as able to "attack" any tile within staff range: it will path toward
  players to get them into that range, then `get_attackable_enemies_from_tile` returns
  `[]` and it does nothing offensive (it falls back to `_try_staff_heal`). The enemy
  positions itself as an attacker when it can only heal. Today the shipped healers use
  the `healer` AI profile, so this is a near-miss rather than an active bug — but the
  two predicates disagreeing about the same weapon is the same class of latent
  inconsistency as the previous finding.
- **Root Cause:** The healing-staff gate was added to two of the three attack-range
  helpers; `can_attack_from_tile` was missed.
- **Recommended Fix:** Add the same guard to `can_attack_from_tile`:
  ```gdscript
  func can_attack_from_tile(attacker: Node, at_tile: Vector2i, target: Node) -> bool:
      if attacker == null or target == null:
          return false
      if not _equipped_can_attack(attacker):
          return false
      var wrange := _get_weapon_range(attacker)
      ...
  ```
- **Tradeoffs:** None. `_choose_heal_move_tile` already routes healers correctly via
  `get_healable_allies`, so this only corrects the stray `basic`-with-staff case.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/TurnManager.gd:106-118` (`start_enemy_phase`) vs
  `:72-92` (`start_player_phase`).
- **Problem:** `start_player_phase` runs `_apply_start_of_turn_skills` for living
  player units (`:86`); `start_enemy_phase` ticks enemy modifiers and applies fort
  healing but **never calls `_apply_start_of_turn_skills` for enemies**. An enemy with
  a `start_of_turn` skill (Renewal is the only one implemented) would silently never
  trigger it. Today no enemy `.tres` carries a `start_of_turn` skill (the boss has
  `nihil`/`resolve`/`lancefaire`, all `on_combat_start`), so this is latent — but it is
  an undocumented asymmetry between the two phases.
- **Root Cause:** `start_of_turn` skill dispatch was added to the player path only.
- **Recommended Fix:** Either call `_apply_start_of_turn_skills(gs.get_living_enemy_units())`
  in `start_enemy_phase` for symmetry, or add a comment stating enemy `start_of_turn`
  skills are intentionally unsupported in MVP. Symmetry is the smaller surprise.
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/ui/HUD.gd:21` (`_displayed_unit`), `:79-81`
  (`_on_unit_hp_changed`).
- **Problem:** `_displayed_unit` caches the unit currently shown in the info panel.
  When that unit dies, `Unit.handle_death` calls `queue_free()` but `_displayed_unit`
  is not cleared. The panel keeps showing the dead unit's last state until the next
  `cursor_moved`/`unit_selected` event overwrites it. `_on_unit_hp_changed` guards with
  `unit == _displayed_unit`, and `take_damage` won't fire again on a freed node, so
  this does not crash — but it is a stale reference and a stale panel.
- **Root Cause:** No `unit_died` listener in `HUD`; the cache is only refreshed on
  cursor/selection events.
- **Recommended Fix:** Connect `EventBus.unit_died` in `HUD._ready` and, if the dead
  unit is `_displayed_unit`, call `_show_unit(null)` to hide the panel.
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/CombatResolver.gd:35-36` (context schema header).
- **Problem:** The combat-context schema comment documents
  `"attacker_skills_blocked" bool — nihil (unused): prevent attacker's skills`. The
  `(unused)` annotation is wrong: `_apply_nihil` *does* set this key for a defending
  Nihil bearer (`SkillHandler.gd:167`) and `_resolve_single_attack` *does* read it
  (`:300`, `:340`). The comment understates how live this path is — and, combined with
  the High finding above, masks that the key is set but set too late to matter.
- **Root Cause:** Comment written before the defender branch of `_apply_nihil` landed
  and not updated.
- **Recommended Fix:** Drop `(unused)`; if the High finding is fixed, note that the
  flag is resolved in a pre-pass before modifier skills.
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/CombatResolver.gd:393-438` (`preview_combat`).
- **Problem:** `preview_combat` reports `attacker_attacks` / `defender_attacks` counts
  correctly, but does not surface **Vantage** ordering. When the defender has Vantage,
  `resolve_combat` makes the defender strike first (`:463-471`), which materially
  changes who might die before landing a blow — yet the preview the player sees is
  identical to a non-Vantage fight. The displayed numbers are not *wrong*, but the
  forecast omits a combat-deciding fact.
- **Root Cause:** The preview models hit/damage/crit/strike-count but not exchange
  order.
- **Recommended Fix:** Add a `defender_vantage: bool` (or `attacker_strikes_first`) key
  to the `preview_combat` result, read from `context["flags"]["vantage"]`, and let
  `AttackPreview` show a small "Vantage" marker. Low effort; meaningful clarity.
- **Tradeoffs:** Minor UI work; needs an `AttackPreview` label.

### [SEVERITY: Low]
- **File & Line:** `scripts/units/Unit.gd:540-551` (`_increment_stat`).
- **Problem:** Level-up stat gains have no upper cap — `_increment_stat` increments the
  stat unconditionally. ClassData almost certainly defines per-stat maxima (standard FE
  design); nothing reads them, so a high-growth unit can exceed class caps. This is a
  missing feature rather than a defect, but `_level_up_random`/`_level_up_fixed` will
  silently over-grant once cap data exists.
- **Root Cause:** Stat caps are a deferred feature; the leveling code predates them.
- **Recommended Fix:** When class stat-cap data lands, clamp in `_increment_stat`
  (`data.strength = mini(data.strength + 1, cap)` etc.). Until then, add a
  `# NOT ENFORCED — stat caps` marker so the gap is visible.
- **Tradeoffs:** None now; flagged so it isn't assumed handled.

---

## 3. Positive Observations

1. **Complete, accurate follow-through on the previous review.** Every
   `code_review_2026-05-16b.md` finding is genuinely fixed and verified in this read:
   `preview_combat` now restores unit state *after* all `compute_*` calls
   (`CombatResolver.gd:435-437`); `WeaponData.is_healing_staff()` gates `GridManager`
   and `can_counterattack`; `party_gold`/`party_items` are in the Retry
   snapshot/restore (`GameState.gd:147-148`, `:158-159`); `max_uses_per_combat` is
   enforced via `_combat_skill_uses` + `reset_combat_uses()`; the `fired: bool` return
   threads through `apply_trigger` so declined effects don't burn a use; `SettingsScreen`
   is wired into `MainMenu` with an `open_settings` keybinding; `_enter_targeting` uses
   `_set_tile`; `perform_staff_heal` uses `get_effective_stat("magic")`;
   `damage_taken_this_map` counts clamped HP loss. The Resolve four-stat-source bug
   surfaced while writing the regression test was also fixed cleanly.
2. **The combat preview/resolve split is now self-consistent.** With the Session E
   restore-ordering fix, `preview_combat` applies deterministic modifier skills,
   computes every displayed figure, and only then restores — so the forecast and
   `resolve_combat` finally agree for Resolve-active units. The `preview` flag that
   excludes random-activation skills from the forecast is a clean, explicit contract.
3. **Comments explain *why*, consistently.** The combat-context schema, the
   "capture the weapon before the durability decrement" note in `MapCursorTargeting`,
   the distinct-source rationale in `_apply_resolve`, the headless autoload-ordering
   notes, and the snapshot deep-copy reasoning all document decisions, not mechanics.
4. **Data-driven content with fail-fast loading.** Classes/weapons/items/skills/maps
   are all `.tres`; `DataManager` validates cross-references and stat names at boot;
   `SkillHandler`'s dispatch table turns an unknown `effect_id` into a startup
   `push_error` instead of a silent no-op.
5. **Test-aware architecture holds up.** `is_inside_tree()` guards, the
   `GridManager._terrain_fallback`, and the dependency-injected `MapCursorTargeting`
   (a plain `RefCounted`) keep core logic exercisable headlessly without autoloads or a
   SceneTree.

---

## 4. Architectural Observations

- **Trigger dispatch has no notion of skill priority.** The High finding is a symptom:
  Nihil must run before the skills it suppresses, but `apply_trigger` fires a unit's
  skills in list order and `_collect_combat_modifiers` fires the two units in fixed
  attacker-then-defender order. As more skills land in M9 (especially anything that
  *modifies how other skills resolve* — Nihil, and aura debuffs), a single
  undifferentiated `on_combat_start` pass will keep producing order-dependent bugs.
  Consider either an explicit per-skill priority field or a small set of ordered
  sub-phases (negate → buff → aura), resolved before the modifier pass reads its
  results.
- **Simulation and application disagree about durability.** `resolve_combat` simulates
  with infinite uses and fires triggers; `apply_combat_result` models breakage and
  discards exchanges; a recompute reconciles HP/EXP afterward. It works today only
  because no shipped skill uses the per-strike triggers (`on_attack`/`on_hit`/
  `on_kill`). Folding durability into the simulation (Medium finding §3) would make the
  `exchanges` list authoritative and remove the reconcile-after-the-fact pass.
- **"Single source of truth" predicates are still partially adopted.** Session E
  introduced `is_healing_staff()` as *the* staff classifier, but two call sites
  (`ActionMenu`, `EnemyAI._try_staff_heal`) and one helper (`can_attack_from_tile`)
  never moved onto it. A predicate is only a source of truth once every consumer uses
  it — worth a grep sweep whenever such a predicate is introduced.
- **Player/enemy phase logic is near-symmetric but not enforced to be.**
  `start_player_phase` and `start_enemy_phase` independently re-list the same steps
  (modifier ticks, fort healing, start-of-turn skills) and have already drifted (enemy
  start-of-turn skills are missing). A shared `_begin_phase(units)` helper taking the
  unit list would make the two paths provably consistent.
- **`MapCursor` remains a ~620-line FSM and the only core class without unit tests.**
  The D-1 targeting extraction landed cleanly; the `MapCursorInput` /
  `MapCursorSelection` slices are still pending. It owns input, selection, movement,
  menus, camera, and the end-turn dialog — the largest untested correctness surface.
  Continue the planned slicing before Phase 2 adds more actions. (Carry-over.)

---

## 5. Prioritized Action Plan

Ordered by impact-to-effort.

1. **Fix the Nihil ordering bug** (High): split negate-class skills into a pre-pass
   (`on_combat_start_negate`) that resolves the `*_skills_blocked` flags before any
   modifier skill runs, so a defending Nihil bearer — including the map's boss —
   actually negates the attacker. Add a defender-Nihil regression test.
2. **Finish the `is_healing_staff()` consolidation** (Medium): switch
   `ActionMenu.show_for` and `EnemyAI._try_staff_heal` off `weapon_type == "staff"`,
   and add the `_equipped_can_attack` guard to `GridManager.can_attack_from_tile`.
   Cheap, removes two latent M8 bugs and an AI inconsistency.
3. **Decide durability-in-simulation** (Medium): either move durability tracking into
   `resolve_combat` so triggers fire only for real exchanges, or add a comment warning
   M9 skill authors that per-strike triggers can fire for discarded exchanges.
4. **Low-effort polish, batched** (Low): enemy `start_of_turn` skills (or document the
   omission); clear `HUD._displayed_unit` on `unit_died`; correct the
   `attacker_skills_blocked (unused)` schema comment; surface Vantage in
   `preview_combat`; mark stat caps `NOT ENFORCED`.
5. **Architectural, when convenient**: introduce skill-priority/sub-phase ordering for
   trigger dispatch; factor a shared `_begin_phase` helper in `TurnManager`; continue
   the `MapCursor` slicing and give it unit tests.

---

## Assumptions Flagged

- I assume Nihil is meant to negate the opponent's combat skills whether its bearer is
  attacking or defending (standard FE behavior, and what `_apply_nihil`'s defender
  branch was written for). If Nihil is deliberately attacker-only, Finding 1 reduces to
  a documentation fix.
- I assume offensive/debuff staves are still planned for M8 (the `is_healing_staff()`
  comment says so explicitly). If staves will only ever heal, Finding 2 is cosmetic
  consistency rather than a latent bug.
- I assume per-class stat caps are intended (standard FE design) — Finding (stat caps)
  is a missing feature, not a defect, until that data exists.
- Test suites were read for coverage but not re-run; the green baseline (11 suites /
  245 tests) is taken from the Session E notes.
