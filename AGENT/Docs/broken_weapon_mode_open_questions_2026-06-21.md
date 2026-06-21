# OPEN-5 — Broken-Weapon Degraded Mode (§3) — Draft Plan + Open Questions

**Started:** 2026-06-21d
**Status:** Planning draft — register OPEN. Small optional-rule design + a `CampaignRules`
toggle. Slots cleanly into §2's rule consolidation ([CST-4]).
**Source:** `planning_backlog_2026-06-20.md` §3; `GDD_10` Open Items Register OPEN-5
(lines 911–913); session note 2026-06-21c Tier 2 #9.
**Authority on landing:** `GDD_04 §Inventory Management`. **Code:**
`scripts/resources/CampaignRules.gd`, `scripts/resources/InventoryEntry.gd`,
`scripts/core/CombatResolver.gd`, `scripts/items/ItemHandler.gd`.
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)

- **The rule is already specified in the roadmap** (OPEN-5): "a 0-use weapon stays usable
  with a stat penalty and infinite uses while broken, repairable at special shops/items.
  Likely a `CampaignRules` toggle."
- **`InventoryEntry.uses_remaining`** is the use counter: `-1` = infinite, `0` =
  empty/exhausted, `>0` = finite. Today **0 = unusable** (`has_uses()` returns false). The
  degraded mode reinterprets the `0` state as "usable-but-broken" *when the rule is on*.
- **`CampaignRules` is the toggle home** — it already holds `permadeath_enabled`,
  `leveling_method`, etc., and §2/[CST-4] is consolidating all rule access to
  `gs.campaign_rules.*`. A `broken_weapon_degraded: bool` field drops in there.
- **Combat reads the equipped weapon's `mt`/`hit`/`crit`.** A degraded penalty is applied
  in `CombatResolver` when the equipped weapon is broken — a scoped stat modifier, not new
  combat flow.
- **Repair has no model** — no shop (deferred §2b/E) and no repair item/effect exist yet.

## 2. Draft plan (classic FE convention)

This is a **non-classic** optional rule (FE normally *destroys* a 0-use weapon). The OPEN-5
design borrows the "weapons degrade instead of break" idea (e.g. some FE-likes / Three
Houses durability-off variants):
- When `broken_weapon_degraded` is ON: a weapon hitting 0 uses is **not destroyed**; it
  becomes **Broken** — infinite uses, but a **stat penalty** (reduced Mt/Hit, maybe Crit)
  until repaired.
- When OFF (default): existing behavior — 0 uses = exhausted/unusable (classic FE).
- **Repair** restores the weapon to positive uses via a special shop or item.

Core: reinterpret the `uses_remaining == 0` state under the rule; apply a penalty in combat;
add a `repair` item effect. The toggle keeps the default (classic) path untouched.

## 3. Open questions register

### [BWN-1] "Broken" state representation  **[OPEN]**
- **A — Reuse `uses_remaining == 0` as "broken" when the rule is on** (no new field). A
  broken weapon is just a 0-use weapon that the rule keeps usable. `has_uses()` /
  equip-legality consult the rule.
- **B — Add an explicit `is_broken: bool` to `InventoryEntry`** (clearer, but a new
  serialized field + snapshot coverage).
- **Rec: A** — the `0` state already means "out of uses"; the rule just changes what `0`
  *does* (broken-usable vs exhausted). No new field, no snapshot change — the penalty is
  derived from `uses_remaining == 0 && rule_on`. Minimal surface, and the rule is the single
  switch ([CST-4]-friendly).
- **Resolution:** _[OPEN]_

### [BWN-2] Penalty magnitude + which stats  **[OPEN]**
- **A — Flat global penalty in `GameConstants`** (e.g. Mt −X, Hit −Y; Crit unaffected).
  One tunable, applies to every broken weapon.
- **B — Per-weapon `broken_penalty` fields** on `WeaponData`. Granular, more authoring.
- **C — Percentage reduction** (e.g. Mt/Hit at 50%).
- **Rec: A** — one global tunable (`BROKEN_WEAPON_MT_PENALTY`, `..._HIT_PENALTY`) is enough
  for an optional rule; it's easy to balance and test, and avoids touching every `WeaponData`.
  Promote to B only if a specific weapon needs a bespoke degraded profile later. Default
  values flagged as tune-live (non-blocking).
- **Resolution:** _[OPEN]_

### [BWN-3] Repair mechanism — ship with the rule or defer?  **[OPEN]**
Repair needs a shop (deferred §2b/E) or a repair item.
- **A — Repair item only, ship now** (`ItemData` `effect_id "repair"` restoring N uses;
  `ItemHandler` already has the effect-id dispatch + `IMPLEMENTED_EFFECT_IDS` validation).
  No shop dependency.
- **B — Defer repair to the §2b/E shop** (broken weapons stay broken until the economy
  lands). The degraded rule still *works* (you fight with broken weapons), just no repair.
- **Rec: A** — a repair *item* is self-contained (one new `ItemHandler` effect, validated at
  boot) and completes the loop without waiting on the deferred shop. The shop later just
  sells repair services/items. Ship the item; note the shop-repair as a §2b/E follow-up.
- **Resolution:** _[OPEN]_

### [BWN-4] Combat penalty application point  **[OPEN]**
- **A — In `CombatResolver`** at stat assembly: if the equipped weapon is broken + rule on,
  subtract the penalty from Mt/Hit. Single chokepoint; the forecast/preview reflects it
  automatically (preview reads the same path).
- **B — As an `active_modifiers` entry** on the unit. Wrong owner (the penalty is the
  weapon's, not a timed unit buff) and pollutes the modifier list.
- **Rec: A** — apply at the combat-stat assembly so the forecast and the resolution agree
  (the player sees the degraded numbers in the preview). Keep it out of `active_modifiers`
  (those are timed buffs/debuffs, per the `UnitData` modifier schema).
- **Resolution:** _[OPEN]_

### [BWN-5] Interaction with the default (rule-off) path + tests  **[OPEN]**
- **A — Rule OFF is the existing behavior, fully untouched** (0 uses = destroyed/unusable).
  The rule strictly *adds* the degraded branch.
- **Rec: A (no alternative)** — the toggle must not change the default game. Test both:
  rule-off → a 0-use weapon is unusable/removed as today; rule-on → a 0-use weapon is usable
  with the penalty, and the forecast shows reduced Mt/Hit; a repair item restores uses.
- **Resolution:** _[OPEN]_

## 4. Slice sketch (provisional)
1. `CampaignRules.broken_weapon_degraded: bool = false` (lands with / after §2 [CST-4]
   consolidation so it's wired the same way as the other rules). DoD#2: the rule is a bool,
   no vocab guard needed.
2. Reinterpret `uses_remaining == 0` under the rule ([BWN-1]) at equip/usability gates.
3. Combat Mt/Hit penalty in `CombatResolver` ([BWN-2]/[BWN-4]) — preview + resolve.
4. `repair` item effect in `ItemHandler` (+ `IMPLEMENTED_EFFECT_IDS`) ([BWN-3]).

## 5. Test notes
- `test_combat`: rule-on broken weapon deals reduced Mt + reduced Hit; rule-off behaves as
  today. `test_skill_item_handler`: repair item restores uses + clears broken state.
- Sequencing: cleanest **after** §2's `CampaignRules` consolidation lands (so the field is
  added in the consolidated shape, not the loose-field shape).
