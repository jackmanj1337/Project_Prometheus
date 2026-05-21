# M6 — Promotion System Plan (handoff, 2026-05-21)

Detailed implementation plan for the promotion milestone of the class & skill
rebuild. Builds on M1–M5 (see `class_skill_rebuild_plan_2026-05-21.md`). Branch:
`class-skill-rebuild`.

## Scope

A Tier-1 unit that reaches its class maximum level can **promote** into one of
its class's Tier-2 options, chosen by the player. Promotion applies a stat-bonus
delta, switches the unit to the promoted class's caps / growth tables / skill
unlocks, grants new weapon proficiencies, and resets the level counter while
`effective_level` keeps accumulating.

**In scope:** promotion flow, promoted-class data, promotion items, the
auto-promote campaign rule, the branch-choice UI, skill-cap handling.
**Out of scope:** reclassing / Second Seal (analysed at the end), demotion,
the battle-prep skill-swap UI (noted as a dependency, built separately).

## Locked decisions (user, 2026-05-21)

1. **Auto-promotion at max level is a per-campaign rule**, modelled like
   `permadeath_enabled` — a per-save flag set on the New Game screen.
2. **Promotion items** also exist: an item that triggers promotion on an
   eligible unit regardless of the campaign rule.
3. **`MAX_LEVEL` moves out of `GameConstants`** and becomes a per-class
   `ClassData.max_level` field (default 20).
4. **Stat model:** promotion = current stats **+** `promotion_stat_bonuses`;
   the unit then adopts the promoted class's `stat_caps` and growth tables.
   Tier-2 `base_*` fields are unused (kept 0, documented).
5. **Skills:** the unit keeps its base-class skills; promoted-class skills
   unlock at **level 5 and 15**. The 4-skill cap is enforced — but the cap is a
   **variable** (`GameState.max_skills`, already exists), not a constant.
6. **A future battle-prep skill-swap option** will let the player exchange
   equipped skills for previously-earned ones. M6 must keep every earned skill
   recorded even when it can't be equipped (see "Skill cap handling").
7. **New weapon proficiencies gained at promotion start at E rank.**

## Schema changes

### `ClassData.gd`
| Field | Change |
|-------|--------|
| `max_level: int = 20` | **new** — replaces `GameConstants.MAX_LEVEL` |
| `promotes_from: Array[String] = []` | **new** — inverse of `promotes_to`, for validation/UI |
| `promotion_stat_bonuses` | already exists (M1) — populated for Tier-2 classes |
| `tier` | already exists — Tier-2 classes set `tier = 2` |

`GameConstants.MAX_LEVEL` is **removed**; `Unit.add_exp` reads
`class_data.max_level` instead (two call sites, Unit.gd:520 / 526).

### `UnitData.gd`
| Field | Change |
|-------|--------|
| `earned_skills: Array[String]` | **new** — every skill the unit has ever learned, never trimmed. `skills` stays the *equipped* subset (≤ `max_skills`). The battle-prep swap UI (decision 6) draws from `earned_skills`. |

Snapshot/allowlist: add `earned_skills` to the static allowlist in
`test_data_layer.gd` and `test_snapshot_coverage.gd` (it is identity-ish,
written only at level-up/promotion).

### `GameState.gd`
| Field | Change |
|-------|--------|
| `auto_promote_at_max_level: bool = false` | **new** per-save rule, beside `permadeath_enabled` |
| `max_skills` | already exists (currently inert) — M6 makes it live |

### New item effect
A promotion item is an `ItemData` with `effect_id = "promote"` (handled by
`ItemHandler`). Using it on an eligible unit opens the promotion-choice UI.
Create at least one resource, e.g. `data/items/master_seal.tres`.

## Engine changes

### Promotion eligibility
`Unit.can_promote() -> bool`: true when `not data.is_promoted` **and**
`data.level >= class_data.max_level` **and** `class_data.promotes_to` is
non-empty. (Assumption A1 — see below — same gate for both the auto rule and
items.)

### Promotion flow — `Unit.promote(target_class_id: String)`
1. Validate `target_class_id` is in `class_data.promotes_to`.
2. Apply `promoted_class.promotion_stat_bonuses` to each stat (HP bonus raises
   `max_hp` and `hp`); clamp each result to the **promoted** class's `stat_caps`.
3. `data.class_id = target_class_id`; `data.is_promoted = true`.
4. `data.level = 1`; `effective_level` is left untouched (it already counts
   total levels — it kept incrementing through Tier-1 and continues from here).
5. Reset `data.exp = 0` and `data.growth_accumulators = {}` (fresh carry for the
   new growth table).
6. Add each weapon type in the promoted class's `proficiencies` not already
   present to `data.proficiencies` at **E rank** (`{"rank": "E", "wexp": 0}`).
7. Grant any `skill_unlocks` whose level ≤ 1 (none, by the 5/15 convention) —
   i.e. no skills at promotion itself; they come at promoted levels 5 and 15 via
   the existing `_grant_level_skills` path.
8. Emit a new `EventBus.unit_promoted(unit, old_class_id, new_class_id)` signal.

### Level-up after promotion
`_grant_level_skills` already keys off `data.level`; with the level reset to 1
it naturally grants the promoted class's level-5 / level-15 skills. No change
needed beyond authoring the data.

### Auto-promote hook
In `Unit.add_exp`, when `data.level` reaches `class_data.max_level` and
`GameState.auto_promote_at_max_level` is true and `can_promote()`, emit
`EventBus.promotion_available(unit)` instead of silently discarding EXP. The
promotion UI listens for this and opens the choice screen. When the rule is
off, EXP is discarded at cap as today until a promotion item is used.

### Skill cap handling
- `earned_skills` always gets the new id appended (level-up grant and promotion).
- `skills` (equipped) gets it appended **only if** `skills.size() < GameState.max_skills`.
- If the cap is full, the skill is still in `earned_skills`; the level-up screen
  shows "Learned X! (skill slots full — equip from battle prep)".
- `_grant_level_skills` returns ids added to `earned_skills`; the screen
  distinguishes equipped vs. stored.

## UI changes

### Promotion-choice screen (new) — `scenes/ui/PromotionScreen.tscn` + script
- Opens on `EventBus.promotion_available` (auto rule) or on a promotion item.
- Lists the unit's `promotes_to` options; each row shows the promoted class
  name, the stat-bonus deltas, and the two skills it will learn.
- On confirm, calls `Unit.promote(chosen_id)`; blocks input while open
  (mirror `LevelUpScreen`'s `level_up_started` / `_finished` bracketing).
- For classes with a sub-choice (Bow Knight proficiency, Paladin "+1
  additional", Sage "+1 additional", War Monk vs War Cleric) — see A3.

### New Game screen — `NewGameScreen.gd`
Add an "Auto-promote at max level" Off/On `OptionButton`, wired to
`GameState.auto_promote_at_max_level` exactly like the permadeath option
(NewGameScreen.gd:63–65 / :79 / :100 are the pattern to copy).

### Level-up screen
Extend the learned-skill line to handle the "slots full" case (above).

## Promoted-class data

All values transcribed from `AGENT/GDD/Content Expansion/awakening_classes_and_skills.md`.
Each Tier-2 `ClassData` sets `tier = 2`, `max_level = 20`, `base_* = 0`,
`promotion_stat_bonuses`, `stat_caps`, `player_growth_rates`,
`enemy_growth_rates`, `skill_unlocks = {5: <primary>, 15: <secondary>}`,
`proficiencies`, `special_qualities`, `promotes_from`.

Stat key order below: **HP STR MAG SKL SPD LUK DEF RES** (LUK growth always 0
for player tables; LUK cap shown).

### Archer → ranger, sniper, bow_knight

**ranger** (homebrew) — weapons: bow, sword
- bonuses: HP+8 STR+3 MAG+0 SKL+2 SPD+4 LUK+0 DEF+1 RES+2 (MOV+3)
- caps: 80 / 40 / 30 / 43 / 41 / 45 / 35 / 30
- player growth: 50 / 20 / 0 / 25 / 20 / 0 / 5 / 5
- enemy growth: 90 / 35 / 0 / 40 / 40 / 35 / 25 / 15
- skills: 5 → swiftfoot, 15 → multishot

**sniper** — weapons: bow
- bonuses: HP+4 STR+2 MAG+1 SKL+4 SPD+3 LUK+0 DEF+5 RES+3 (MOV+1)
- caps: 80 / 41 / 30 / 48 / 40 / 45 / 40 / 31
- player growth: 45 / 15 / 0 / 30 / 15 / 0 / 15 / 5
- enemy growth: 90 / 35 / 0 / 50 / 40 / 35 / 30 / 25
- skills: 5 → hawkeye, 15 → deadeye

**bow_knight** — weapons: sword, bow — type: mounted — `promotes_from`: archer, mercenary
- bonuses: HP+2 STR+3 MAG+0 SKL+3 SPD+2 LUK+0 DEF+2 RES+1 (MOV+2)
- caps: 80 / 40 / 30 / 43 / 41 / 45 / 35 / 30
- player growth: 50 / 20 / 0 / 25 / 20 / 0 / 5 / 5
- enemy growth: 90 / 35 / 0 / 40 / 40 / 35 / 25 / 15
- skills: 5 → bowfaire *(exists)*, 15 → rally_skill
- note: proficiency gained depends on origin (A3).

### Cavalier → paladin, vanguard

**paladin** — weapons: sword, lance (+1 at promotion, A3) — type: mounted
- bonuses: HP+7 STR+3 MAG+1 SKL+2 SPD+2 LUK+0 DEF+3 RES+6 (MOV+1)
- caps: 80 / 42 / 30 / 40 / 40 / 45 / 42 / 42
- player growth: 45 / 20 / 0 / 20 / 20 / 0 / 10 / 10
- enemy growth: 90 / 45 / 0 / 40 / 40 / 45 / 35 / 30
- skills: 5 → strike_true, 15 → challenge

**vanguard** (homebrew) — weapons: axe, lance, sword (as held) — type: mounted
- bonuses: HP+8 STR+5 MAG+0 SKL+1 SPD-1 LUK+0 DEF+7 RES+1 (MOV+0)
- caps: 80 / 48 / 20 / 34 / 37 / 45 / 48 / 30
- player growth: 50 / 25 / 0 / 15 / 15 / 0 / 15 / 5
- enemy growth: 95 / 45 / 0 / 30 / 30 / 40 / 35 / 15
- skills: 5 → counter *(needs resource)*, 15 → supremacy

### Cleric → bishop, paragon, war_monk, war_cleric

**bishop** (homebrew) — weapons: light, staff
- bonuses: HP+4 STR+1 MAG+4 SKL+3 SPD+3 LUK+0 DEF+3 RES-1 (MOV+1)
- caps: 80 / 30 / 46 / 43 / 42 / 45 / 31 / 40
- player growth: 35 / 0 / 20 / 20 / 20 / 0 / 5 / 10
- enemy growth: 70 / 0 / 40 / 40 / 40 / 40 / 20 / 35
- skills: 5 → blessing, 15 → holy_aura

**paragon** (homebrew) — weapons: light, lance, staff — type: mounted
- bonuses: HP+3 STR+0 MAG+2 SKL+2 SPD+4 LUK+0 DEF+2 RES+2 (MOV+3)
- caps: 80 / 30 / 42 / 38 / 43 / 45 / 30 / 45
- player growth: 35 / 0 / 20 / 10 / 20 / 0 / 5 / 15
- enemy growth: 70 / 0 / 40 / 30 / 50 / 50 / 20 / 45
- skills: 5 → boon, 15 → judgement

**war_monk** — weapons: axe, staff
**war_cleric** — weapons: bow, staff
- both share: bonuses HP+3 STR+4 MAG+0 SKL+1 SPD+1 LUK+0 DEF+2 RES+1 (MOV+1)
- caps: 80 / 40 / 40 / 38 / 41 / 45 / 38 / 43
- player growth: 45 / 15 / 15 / 10 / 15 / 0 / 10 / 10
- enemy growth: 90 / 40 / 35 / 30 / 45 / 45 / 30 / 40
- skills: 5 → sol; 15 → odd_rhythm (war_monk) / even_rhythm (war_cleric)
- note: modelled as two classes rather than one class with a choice (A3).

### Knight → general, great_knight

**general** — weapons: lance, axe — type: armoured
- bonuses: HP+10 STR+4 MAG+0 SKL+3 SPD+2 LUK+0 DEF+4 RES+3 (MOV+1)
- caps: 80 / 50 / 30 / 41 / 35 / 45 / 50 / 35
- player growth: 50 / 25 / 0 / 15 / 10 / 0 / 15 / 10
- enemy growth: 100 / 50 / 0 / 35 / 25 / 40 / 35 / 20
- skills: 5 → bastion, 15 → iron_wall

**great_knight** — weapons: sword, lance, axe — type: armoured, mounted
- bonuses: HP+8 STR+3 MAG+0 SKL+2 SPD+3 LUK+0 DEF+3 RES+1 (MOV+3)
- caps: 80 / 48 / 20 / 34 / 37 / 45 / 48 / 30
- player growth: 50 / 25 / 0 / 15 / 15 / 0 / 15 / 5
- enemy growth: 95 / 45 / 0 / 30 / 30 / 40 / 35 / 15
- skills: 5 → pavise *(needs resource)*, 15 → charge

### Mage → mage_knight, sage, dark_knight

**mage_knight** (homebrew) — weapons: anima (as held) — type: mounted
- bonuses: HP+9 STR+4 MAG+1 SKL+3 SPD+1 LUK+0 DEF+7 RES+2 (MOV+3)
- caps: 80 / 38 / 41 / 40 / 40 / 45 / 42 / 38
- player growth: 50 / 15 / 15 / 15 / 15 / 0 / 10 / 5
- enemy growth: 95 / 35 / 40 / 40 / 30 / 30 / 35 / 30
- skills: 5 → aegis, 15 → flare

**sage** — weapons: anima (as held) +1 additional (A3)
- bonuses: HP+4 STR+1 MAG+3 SKL+2 SPD+3 LUK+0 DEF+2 RES+2 (MOV+1)
- caps: 80 / 30 / 46 / 43 / 42 / 45 / 31 / 40
- player growth: 35 / 0 / 20 / 20 / 20 / 0 / 5 / 10
- enemy growth: 70 / 0 / 40 / 40 / 40 / 40 / 20 / 35
- skills: 5 → phasing, 15 → deeper_knowledge

**dark_knight** — weapons: sword, dark — type: mounted — `promotes_from`: mage, dark_mage
- bonuses: HP+7 STR+3 MAG+2 SKL+4 SPD+2 LUK+0 DEF+5 RES+1 (MOV+3)
- caps: 80 / 38 / 41 / 40 / 40 / 45 / 42 / 38
- player growth: 50 / 15 / 15 / 15 / 15 / 0 / 10 / 5
- enemy growth: 95 / 35 / 40 / 40 / 30 / 30 / 35 / 30
- skills: 5 → lifetaker, 15 → shadowgift
- note: needs a `dark` weapon type — confirm it exists in `GameConstants.VALID_WEAPON_TYPES`.

### Mercenary → hero, sentinel, bow_knight

**hero** — weapons: sword, axe
- bonuses: HP+4 STR+3 MAG+1 SKL+3 SPD+3 LUK+0 DEF+3 RES+3 (MOV+1)
- caps: 80 / 42 / 30 / 46 / 42 / 45 / 40 / 36
- player growth: 45 / 20 / 0 / 25 / 20 / 0 / 10 / 5
- enemy growth: 90 / 45 / 0 / 50 / 45 / 40 / 30 / 25
- skills: 5 → dash, 15 → disarm

**sentinel** (homebrew) — weapons: sword, lance
- bonuses: HP+4 STR+3 MAG+1 SKL+3 SPD+3 LUK+0 DEF+3 RES+3 (MOV+1)
- caps: 80 / 42 / 30 / 46 / 42 / 45 / 40 / 36
- player growth: 45 / 20 / 0 / 25 / 20 / 0 / 10 / 5
- enemy growth: 90 / 45 / 0 / 50 / 45 / 40 / 30 / 25
- skills: 5 → vigilance, 15 → diehard

**bow_knight** — see Archer section (shared class).

### `promotes_to` reconciliation
Update the Tier-1 `.tres` files to the full doc option lists:
- archer → `["ranger", "sniper", "bow_knight"]`
- cavalier → `["paladin", "vanguard"]`
- cleric → `["bishop", "paragon", "war_monk", "war_cleric"]`
- knight → `["general", "great_knight"]`
- mage → `["mage_knight", "sage", "dark_knight"]`
- mercenary → `["hero", "sentinel", "bow_knight"]`

## Skill resources needed

~28 new skill `.tres` (same approach as M4 — data now, effects with M9):
swiftfoot, multishot, hawkeye, deadeye, rally_skill, strike_true, challenge,
counter, supremacy, blessing, holy_aura, boon, judgement, sol, odd_rhythm,
even_rhythm, bastion, iron_wall, charge, aegis, flare, phasing,
deeper_knowledge, lifetaker, shadowgift, dash, disarm, vigilance, diehard.
(`bowfaire` already exists; `pavise` and `counter` are named in the doc's
"already in handbook" table but have **no `.tres`** yet — create them.)
Register each new `effect_id` in `SkillHandler._dispatch` pointing at
`_apply_unimplemented` until M9.

## Suggested commit breakdown

- **M6.1** — Schema: `ClassData.max_level` + `promotes_from`, remove
  `GameConstants.MAX_LEVEL`, `UnitData.earned_skills`,
  `GameState.auto_promote_at_max_level`; update validation + snapshot tests.
- **M6.2** — `Unit.can_promote()` / `promote()`, `EventBus` signals, auto-promote
  hook in `add_exp`; unit-level tests.
- **M6.3** — Skill-cap handling: `earned_skills` vs `skills`, level-up screen
  "slots full" line.
- **M6.4** — Promotion items: `ItemHandler` `promote` effect + `master_seal.tres`.
- **M6.5** — `PromotionScreen` UI + New Game screen auto-promote option.
- **M6.6** — Promoted-class skill resources (~28 `.tres` + dispatch stubs).
- **M6.7** — Promoted-class data (15 `.tres`); update Tier-1 `promotes_to`;
  `DataManager` validation of `promotes_to`/`promotes_from` (the deferred
  check noted at `DataManager.gd:50`).

## Tests
- `Unit.promote`: stat bonuses applied + clamped to new caps; class/level/flags
  updated; proficiencies added at E; `effective_level` preserved.
- `can_promote`: false when promoted, below max level, or no options.
- Auto-promote rule fires `promotion_available` only when the rule is on.
- Skill cap: a learned skill past `max_skills` lands in `earned_skills` only.
- Promoted skill unlocks fire at promoted level 5 / 15.
- `DataManager`: live catalogue validates clean; bad `promotes_to` id caught.

## Assumptions for review (M6)

- **A1 — Eligibility gate.** Both auto-promotion and promotion items require the
  unit to be at its class `max_level`. Early promotion (item usable from a lower
  level, FE:A-style) is left as a future knob, not built now.
- **A2 — `effective_level` is not reset** at promotion; `level` resets to 1.
  Promoted units re-cap at their own `max_level` (default 20 → 40 effective).
- **A3 — Sub-choices at promotion** (Bow Knight's origin-based proficiency,
  Paladin / Sage "+1 additional" weapon, War Monk vs War Cleric) are handled by
  modelling distinct classes where possible (war_monk / war_cleric) and by a
  second prompt in `PromotionScreen` for the "+1 weapon" cases. If that is too
  much UI for a first pass, fix the extra weapon per class instead.
- **A4 — Homebrew promoted classes** use the doc's stated analogue numbers
  as-is; no further tuning in M6.
- **A5 — Promotion items are consumed on use** and require an eligible target;
  using one on an ineligible unit is a no-op with feedback.

## Second Seal (reclassing) — effort estimate

**Question: how much harder is adding Second Seal to this plan?**

Short answer: **moderate — roughly 30–40% on top of M6**, because M6 already
builds the hard parts.

Reclassing reuses almost all of the promotion machinery:
- the class-switch routine (swap `class_id`, caps, growth tables, skill
  unlocks, proficiencies) — *shared*;
- the branch-choice UI — *shared* (a reclass picker is the same screen with a
  different option list);
- the item-triggered entry point — *shared* (`effect_id = "reclass"`).

The genuinely new work:
1. **Reclass target pools.** Unlike promotion (`promotes_to` is on the class),
   reclassing needs a per-unit or per-character allowed-class set. FE:A ties
   this to the character; this TTRPG's doc says Villager reclasses at "GM's
   discretion." → add `UnitData.reclass_options: Array[String]` (or a campaign
   rule "reclass freely"). **New data + a policy decision.**
2. **The lateral stat rule.** Promotion has clean additive bonuses; a sideways
   class change does not. Decide one of: (a) keep current stats, just swap
   caps/growths; (b) re-derive from class base-stat differences (FE:A's
   class-min approach). Option (a) is far simpler and recommended. **One rule,
   plus tests.**
3. **Tier & level behaviour.** Reclassing a *promoted* unit back to a Tier-1
   class (FE:A Second Seal) needs a level/tier decision: reset to level 1
   Tier-1, or keep tier? Recommend: reclass stays within the current tier for a
   first pass (Tier-1↔Tier-1, Tier-2↔Tier-2), which sidesteps the demotion
   question entirely.

**Recommendation:** do **not** build Second Seal in M6, but **factor M6's
class-switch code as a reusable `Unit._apply_class_change()` helper** that both
`promote()` and a future `reclass()` call. With (3) constrained to same-tier and
(2) using option (a), Second Seal then becomes a small follow-up milestone
(M7): the reclass item, the target-pool field, and the picker reusing
`PromotionScreen`. The expensive, shared 80% is paid once in M6.
