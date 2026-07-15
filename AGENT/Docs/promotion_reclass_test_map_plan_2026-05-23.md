# Plan — Promotion / Reclass Validation Map

**Date:** 2026-05-23
**Scope:** Unblock the "Class / Skill Live Playtest" checklist in
`AGENT/GDD/GDD_Manual_Tasks.md`.
**Status:** Planning only.

---

## 1. Goal

Build a dedicated test map that lets one or two short playtest runs exercise
every promotion and Second Seal case currently in the manual-task checklist.
No campaign content needs to change to unblock the checklist — the existing
default roster starts at level 1 with no promotion items, and `map_001`'s
8 low-level enemies do not award enough EXP to reach the promotion gate.

The map is purpose-built for regression testing. It will be removed (or
re-tagged) once a real campaign with proper item progression replaces it.

---

## 2. Deliverables

1. **Validation map** — `map_950_promotion_validation` with a fixed test roster.
2. **Fixed test roster** — `data/roster/test/map_950_promotion_validation/`
   containing units at the levels and inventories needed for the coverage
   matrix below.
3. **Registry entry** — new line in `data/maps/map_registry.json`. Per
   2026-05-23 user decision, NOT flagged `is_dev_only` — it will simply be
   removed before release when actual campaign content lands.
4. **Manual playtest pass** — run the existing `Class / Skill Live Playtest`
   checklist in `GDD_Manual_Tasks.md` against this map and mark items done.

---

## 3. Map Design

### Recommended map id
- `map_950_promotion_validation`

`map_900_*` is the hotseat slot; `map_950_*` keeps a clear name-spaced gap
for promotion/reclass regression maps.

### Faction / turn model
- `factions: [blue]` plus a small `red` for the EXP-grind step.
- `turn_order = ["blue", "red"]`, `activation_mode = "WHOLE_PHASE"`.

No green / yellow needed — promotion / reclass is single-faction territory.

### Layout
- Small map, roughly **14×10**.
- Open center so the player can move every test unit into combat range quickly.
- Player starts west, enemies east.
- A `fort` tile near the center for healing if a unit takes a bad hit during
  EXP grinding (so a single bad roll does not derail the whole playtest).

### Objective
- `victory_conditions = {"allies": [rout()]}` is sufficient — the playtest
  ends naturally once the test roster has used every seal it needs to.

---

## 4. Test Roster

One unit per promotable base class plus three already-promoted units to
cover the Second Seal demote / lateral reclass cases. Every promotion-item-
holding unit starts at the level where one more kill triggers the promotion
gate, so the playtest does not become a grind.

Units are sized for a single playtest sitting:

| File suffix | unit_id | Class | Level | Inventory (besides weapon) | Notes |
|---|---|---|---|---|---|
| `01_cavalier` | `m950_cavalier`   | cavalier   | 9 | `master_seal` ×1, `second_seal` ×1 | 2-path promote (paladin / vanguard) |
| `02_mercenary` | `m950_mercenary` | mercenary  | 9 | `master_seal` ×1, `second_seal` ×1 | 3-path promote (hero / sentinel / bow_knight) |
| `03_archer`  | `m950_archer`     | archer     | 9 | `master_seal` ×1, `orion_bolt` ×1, `second_seal` ×1 | Class-restricted item path (orion_bolt) |
| `04_mage`    | `m950_mage`       | mage       | 9 | `master_seal` ×1, `guiding_ring` ×1, `second_seal` ×1 | Class-group-restricted item path (guiding_ring → mystic) |
| `05_cleric`  | `m950_cleric`     | cleric     | 9 | `master_seal` ×1, `guiding_ring` ×1, `second_seal` ×1 | Second mystic; verify guiding_ring works on both classes in the group |
| `06_knight`  | `m950_knight`     | knight     | 9 | `master_seal` ×1, `second_seal` ×1 | 2-path promote (general / great_knight) |
| `07_paladin` | `m950_paladin`    | paladin    | 4 | `second_seal` ×1 | Promoted, below 10 — Second Seal should offer **demotions only** |
| `08_sniper`  | `m950_sniper`     | sniper     | 14 | `second_seal` ×1 | Promoted, 10+ — Second Seal should offer lateral tier-2 reclass options from the archer line |
| `09_bow_knight` | `m950_bow_knight` | bow_knight | 14 | `second_seal` ×1 | Shared promotion (mercenary + archer can both promote here); verify the `class_line_id` carried by the unit is respected when reclassing |
| `10_general` | `m950_general`    | general    | 20 | `second_seal` ×1 | Promoted at max — Second Seal on current class should **self-reset to level 1** without stat changes |
| `11_war_monk` | `m950_war_monk`  | war_monk   | 5  | _none_ | Promoted unit for the "promoted level 15 skill unlock" check after EXP grinding (combine with `force_levelup` debug aid if a single playtest is desired) |

Every unit also carries a single basic weapon for its class so it can land at
least one hit on a red unit for EXP. HP is full at start.

### Enemy roster (red)
- 4–6 weak `soldier`-tier enemies, level 3, scattered so each test unit can
  walk up and land a finishing blow for the EXP push to level 10 or 15.
- 1 slightly tougher enemy to absorb extra hits if needed.

Enemies use the existing `e1_soldier.tres` shape as a template.

---

## 5. Coverage Matrix

Each row maps a checklist item in `GDD_Manual_Tasks.md → Class / Skill Live
Playtest` to the unit that proves it.

| Checklist item | Unit |
|---|---|
| Level-1 class skill present in live UI | any starter (`01`–`06`) |
| Base-class level-10 skill unlock in live play | `01`–`06` (one kill from gate) |
| `earned_skills` retains skills beyond equipped slots | any unit who reaches level 10 with skill slots already full |
| Auto Promote prompt fires when enabled | `01` cavalier with Auto Promote toggled On at New Game |
| Auto Promote does NOT fire when disabled | repeat playthrough with Auto Promote Off |
| Master Seal on a capped unit | `01` cavalier after reaching level 10 |
| Cancel promotion-item prompt → item not consumed | `02` mercenary (3-path) — cancel first attempt |
| Class-restricted item gate (orion_bolt) | `03` archer (legal) + try on `04` mage (illegal) |
| Class-group item gate (guiding_ring) | `04` mage or `05` cleric (legal mystic) + try on `02` mercenary (illegal) |
| Multi-option promotion families | `01` cavalier (2 options), `02` mercenary (3 options), `03` archer (3), `04` mage (3), `05` cleric (4), `06` knight (2) |
| Weapon proficiencies after promotion: new ranks at E, old ranks preserved | `04` mage promoting to mage_knight (gains lance E, keeps tome rank) |
| Promoted level 5 class skill | `07` paladin (starts at promoted level 4 — one kill gets the unlock) |
| Promoted level 15 class skill | `11` war_monk (needs more grinding OR use `debug_force_levelup`) |
| Second Seal: tier-1 below 10 → not usable | any starter before they hit level 10 |
| Second Seal: tier-1 at 10 — tier-1 reclass options only | `06` knight after reaching level 10 |
| Second Seal: promoted below 10 → demotions only | `07` paladin |
| Second Seal: promoted 10+ → lateral tier-2 reclass | `08` sniper |
| Reclass shared promoted class respects `class_line_id` | `09` bow_knight (came from either archer or mercenary line — confirm reclass options match the unit's stored line) |
| Self-reset at max level via Second Seal | `10` general at level 20 → pick same class → level reverts to 1, stats unchanged |
| New class level-1 skill granted after reclass | any unit who reclasses into a class with a level-1 skill |
| Retry snapshot after promotion / reclass restores cleanly | promote `01` cavalier, take damage, die or fail map, Retry |

---

## 6. Suggested Playtest Beats

A single sitting should cover most items in this order:

1. **Open with the level-1 check** — confirm every starter has its class
   level-1 skill in the unit-details panel.
2. **Try a class-restricted misuse first** — use Orion Bolt on the mage
   (`04`); confirm it is rejected. Same with Guiding Ring on a non-mystic.
3. **Walk one starter into killing range** (e.g. `06` knight) and land the
   level-10 hit. Confirm the level-up screen shows the class level-10 skill
   unlock.
4. **Master Seal the same unit** — confirm modal opens, pick a promotion
   path, confirm stats apply and item is consumed.
5. **Cancel a Master Seal modal once** on `02` mercenary — confirm item is
   NOT consumed, then re-open and confirm.
6. **Reclass paths via Second Seal**:
   - Use Second Seal on `07` paladin (promoted < 10): confirm demote-only
     options.
   - Grind `08` sniper one or two kills to level 10+; Second Seal → confirm
     lateral options from the archer line.
   - On `09` bow_knight, Second Seal → confirm reclass options respect
     the unit's `class_line_id`.
   - On `10` general at level 20, Second Seal → confirm self-reset back to
     level 1 with stats unchanged.
7. **Promoted skill-unlock check** — push `07` paladin one kill to promoted
   level 5; confirm class skill appears. Either grind `11` war_monk to
   promoted level 15 OR flip `debug_force_levelup` for that single test.
8. **Retry round-trip** — after one promotion is done, take fatal damage and
   Retry. Confirm post-promotion class, level, stats, skills, and weapon
   ranks all come back exactly via snapshot restore.
9. **Replay with Auto Promote On vs Off** in two short re-runs — the only
   New Game switch flip needed.

---

## 7. Suggested Build Order

1. Author the test roster `.tres` files in
   `data/roster/test/map_950_promotion_validation/` (11 units).
2. Author the map data: `data/maps/map_950_promotion_validation/`
   - `map_950_promotion_validation_data.tres`
   - 4–6 enemy `.tres` files (or reuse / symlink from `map_001_rout/enemies/`
     if the spawn layout permits — simplest is to author fresh ones).
3. Add the registry entry to `data/maps/map_registry.json`:
   ```json
   {
     "id": "map_950_promotion_validation",
     "label": "Map 950 - Promotion Validation",
     "map_data_path": "res://data/maps/map_950_promotion_validation/map_950_promotion_validation_data.tres",
     "roster_policy": "fixed_test_roster",
     "roster_source": "res://data/roster/test/map_950_promotion_validation/",
     "description": "Test roster pre-staged for every promotion / reclass case.",
     "is_dev_only": false,
     "tags": ["class_test", "promotion_test", "reclass_test"]
   }
   ```
4. Smoke test: launch the map from `NewGameScreen` and confirm all 11 units
   spawn at the expected tiles with the expected inventories.
5. Run the playtest sequence above. Mark each checked item in
   `AGENT/GDD/GDD_Manual_Tasks.md` as completed.

---

## 8. Out of Scope

- **Soldier promotions** — `soldier.tres` has `promotes_to = []`; no test
  unit needed for it.
- **Balance tuning** of promoted classes' stats — placeholder values stay.
- **Sprite / portrait art** for the new test units — placeholder generation
  via the existing tool is fine; no manual art needed.
- **Save-system round-trip beyond the in-session Retry path** — until a
  proper suspend / resume lands, only Retry needs to round-trip.
- **Combining with Pair Up regression** — Pair Up `map_001` playtest items
  remain on `map_001`; the two playtests are intentionally separate.

---

## 9. Removal Plan (when campaign content lands)

When a real campaign with item progression replaces this stand-in:

1. Delete `data/maps/map_950_promotion_validation/`.
2. Delete `data/roster/test/map_950_promotion_validation/`.
3. Remove the `map_950_promotion_validation` entry from
   `data/maps/map_registry.json`.
4. Move the corresponding checklist items in `GDD_Manual_Tasks.md` from
   "Pending" to "Completed" (or rewrite them against the campaign maps if
   the coverage matrix changes).
