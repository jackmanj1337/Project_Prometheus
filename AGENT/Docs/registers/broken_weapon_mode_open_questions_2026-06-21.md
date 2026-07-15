---
Type: register
Status: RESOLVED 2026-06-22h
Last verified: 2026-06-23
Register: BWN-1..5
Resolved-in: 2026-06-22h
---

# OPEN-5 — Broken-Weapon Degraded Mode (§3) — Draft Plan + Open Questions

**Started:** 2026-06-21d
**Status:** **RESOLVED 2026-06-22h** — build-ready (after §2 [CST-4] for the campaign-default field).
**Owner reframed the feature (overrides the "single global toggle" framing):** break behavior is now
**per-weapon with a campaign default** ([BWN-1] override) — designers mark plot/special weapons to
**degrade** while common weapons **destroy**. Penalty = **global defaults + per-weapon overrides**
([BWN-2] = A+B hybrid). **Repair deferred to the §2b/E shop** ([BWN-3] = B) — degrading weapons stay
broken until the economy lands; **no repair item in v1**. Penalty applied at the `CombatResolver`
chokepoint **and surfaced on the character sheet in the debuff-red styling** ([BWN-4]); a **unified
weapon-stat-delta display** (shared with the future weapon-upgrade system) is reserved as a forward
item, not v1. Default break behavior = **destroy** (classic) so the default game is untouched
([BWN-5]). **Scope note:** this is now a `WeaponData` schema addition + `CampaignRules` default +
`DataManager` validation, not just one bool — larger surface than the original draft.
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
Houses durability-off variants). **Reframed 2026-06-22h to per-weapon authoring** (owner):

- Each weapon has a **break behavior** — `destroy` (classic; removed at 0 uses) or `degrade`
  (becomes **Broken**: stays usable at 0 uses with a **stat penalty** until repaired).
- The behavior is a **per-`WeaponData` field** with a **`CampaignRules` campaign-level default**
  (default `destroy`, so the default game is unchanged). Designers flip plot/special weapons to
  `degrade` while common weapons keep `destroy` — *that* is the "rule," not one global on/off bool.
- **Broken** is still the **derived** state `uses_remaining == 0 && effective_break_behavior ==
  degrade` — no new per-instance `InventoryEntry` field (see [BWN-1]).
- **Penalty** = global defaults (`GameConstants`) with optional per-weapon overrides ([BWN-2]).
- **Repair** is **deferred to the §2b/E shop** ([BWN-3]) — no v1 repair item; degrading weapons
  stay broken until the economy lands.

Core: a `WeaponData.break_behavior` field + `CampaignRules` default; reinterpret the
`uses_remaining == 0` removal path to consult it; apply the penalty at combat-stat assembly and
show it debuff-red on the character sheet. Default (`destroy`) path stays exactly as today.

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
- **Resolution: A's representation, but PER-WEAPON authoring — RESOLVED 2026-06-22h (owner reframe).**
  Keep rec A's *representation* (Broken = derived `uses_remaining == 0`, no new `InventoryEntry`
  field, no snapshot change). **But the switch is not a single global bool:** add a per-`WeaponData`
  **`break_behavior`** field (`destroy` | `degrade`, plus an "inherit campaign default" state) and a
  `CampaignRules` campaign-level default (default `destroy`). Effective behavior = weapon field,
  falling back to the campaign default. Broken = `uses_remaining == 0 && effective_break_behavior ==
  degrade`. **DoD#2:** if `break_behavior` is a string enum it is a string-keyed vocabulary → add the
  value-set guard to `check_docs.py` **with the code**; a bool (`degrades_on_break`) + a campaign
  default would dodge the guard but can't express "inherit" — build-time picks the encoding.

### [BWN-2] Penalty magnitude + which stats  **[OPEN]**
- **A — Flat global penalty in `GameConstants`** (e.g. Mt −X, Hit −Y; Crit unaffected).
  One tunable, applies to every broken weapon.
- **B — Per-weapon `broken_penalty` fields** on `WeaponData`. Granular, more authoring.
- **C — Percentage reduction** (e.g. Mt/Hit at 50%).
- **Rec: A** — one global tunable (`BROKEN_WEAPON_MT_PENALTY`, `..._HIT_PENALTY`) is enough
  for an optional rule; it's easy to balance and test, and avoids touching every `WeaponData`.
  Promote to B only if a specific weapon needs a bespoke degraded profile later. Default
  values flagged as tune-live (non-blocking).
- **Resolution: A + B hybrid — RESOLVED 2026-06-22h.** Global defaults in `GameConstants`
  (`BROKEN_WEAPON_MT_PENALTY` / `..._HIT_PENALTY`; Crit unaffected, tune-live) **plus optional
  per-`WeaponData` override fields** (e.g. `broken_mt` / `broken_hit`, unset → use the global
  default). Common weapons use the global defaults; bespoke degraded profiles are authorable where a
  weapon needs one. Pairs naturally with the per-weapon `break_behavior` from [BWN-1].

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
- **Resolution: B — RESOLVED 2026-06-22h (owner override of rec A).** Defer repair to the §2b/E
  shop/economy; **no v1 repair item**. **Consequence:** a `degrade` weapon that breaks stays at its
  degraded stats indefinitely until the economy lands — accepted (since common weapons `destroy`,
  only the rarer `degrade`-flagged weapons are affected). When §2b/E lands, repair restores positive
  uses (clearing the derived Broken state). No `repair` `effect_id` / `IMPLEMENTED_EFFECT_IDS` change
  in this slice.

### [BWN-4] Combat penalty application point  **[OPEN]**
- **A — In `CombatResolver`** at stat assembly: if the equipped weapon is broken + rule on,
  subtract the penalty from Mt/Hit. Single chokepoint; the forecast/preview reflects it
  automatically (preview reads the same path).
- **B — As an `active_modifiers` entry** on the unit. Wrong owner (the penalty is the
  weapon's, not a timed unit buff) and pollutes the modifier list.
- **Rec: A** — apply at the combat-stat assembly so the forecast and the resolution agree
  (the player sees the degraded numbers in the preview). Keep it out of `active_modifiers`
  (those are timed buffs/debuffs, per the `UnitData` modifier schema).
- **Resolution: A + character-sheet visibility — RESOLVED 2026-06-22h.** Apply the penalty at the
  `CombatResolver` stat-assembly chokepoint (NOT `active_modifiers`) so the forecast and resolution
  agree. **Plus a v1 UI requirement (owner):** the degraded stats must show on the **character-sheet
  view in the same red used for debuffed stats**, so the player can see a weapon is broken without
  entering combat. Because the penalty is weapon-derived (not an `active_modifiers` debuff), the
  sheet needs a path to render weapon-derived stat deltas in the debuff-red style. **Forward item
  (reserved, not v1):** a **unified weapon-stat-delta display system** shared with the future
  **weapon-upgrade** system (upgrades = + deltas, broken = − deltas, one display mechanism). v1 ships
  the broken-penalty red display narrowly; the unified system is evaluated when weapon-upgrades land.

### [BWN-5] Interaction with the default (rule-off) path + tests  **[OPEN]**
- **A — Rule OFF is the existing behavior, fully untouched** (0 uses = destroyed/unusable).
  The rule strictly *adds* the degraded branch.
- **Rec: A (no alternative)** — the toggle must not change the default game. Test both:
  rule-off → a 0-use weapon is unusable/removed as today; rule-on → a 0-use weapon is usable
  with the penalty, and the forecast shows reduced Mt/Hit; a repair item restores uses.
- **Resolution: A — RESOLVED 2026-06-22h.** Default break behavior = `destroy` (campaign default
  + unset weapons), so a weapon with no override behaves exactly as today (0 uses = removed). The
  `degrade` path is strictly additive. Tests: a `destroy` weapon at 0 uses is removed (as today); a
  `degrade` weapon at 0 uses stays usable with reduced Mt/Hit, the forecast reflects it, and the
  character sheet shows the stats debuff-red. (Repair test deferred with [BWN-3] to §2b/E.)

## 4. Slice sketch (RESOLVED 2026-06-22h — reflects the per-weapon reframe)
1. **Schema:** `WeaponData.break_behavior` (+ optional `broken_mt`/`broken_hit` overrides) and a
   `CampaignRules` campaign-level break-behavior default (default `destroy`). Lands with/after §2
   [CST-4] so the campaign field is wired in the consolidated shape. `DataManager` validation for
   the field. **DoD#2:** if `break_behavior` is a string enum, add its value-set guard to
   `check_docs.py` with this code (a bool encoding needs no guard).
2. **Break path:** at the 0-uses removal point, consult `effective_break_behavior` — `destroy` =
   today's removal; `degrade` = keep the entry at `uses_remaining == 0` (derived Broken, [BWN-1]).
3. **Combat penalty:** Mt/Hit penalty at `CombatResolver` stat assembly ([BWN-2] global default +
   per-weapon override; [BWN-4]) — forecast + resolve agree.
4. **Character-sheet display:** show the broken weapon's degraded stats in the debuff-red styling
   ([BWN-4]) via a weapon-derived stat-delta path (NOT `active_modifiers`).
5. **(Deferred — §2b/E)** repair restores positive uses (clears Broken). No v1 repair item ([BWN-3]).
   **(Forward, reserved)** unified weapon-stat-delta display shared with weapon-upgrades.

## 5. Test notes
- `test_combat`: a `degrade` weapon at 0 uses deals reduced Mt + reduced Hit (global default,
  and a per-weapon override when set); a `destroy` weapon at 0 uses is removed as today. Forecast
  reflects the degraded numbers (preview == resolve).
- `DataManager`/validation: per-weapon `break_behavior` + override fields round-trip; an unset
  weapon falls back to the campaign default (which defaults to `destroy`).
- Character-sheet: a broken weapon's stats render in the debuff-red style.
- Repair test **deferred** with [BWN-3] to §2b/E (no v1 repair item).
- Sequencing: cleanest **after** §2's `CampaignRules` consolidation lands (so the campaign-default
  field is added in the consolidated shape, not the loose-field shape).
