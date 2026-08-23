---
Role: dated
Type: design
Status: Active framing / driver
Last verified: 2026-06-24
---

# Source + Style — Player Flow & Authoring Surface

**Started:** 2026-06-24 (session 2026-06-24n).
**Status:** Active framing / driver — the **player-facing flow** and the **designer-authoring surface**
for the `[STY]` source+style combat model. **Navigation/illustration, NOT a second spec** (per DOC-005
the authoritative decisions live in `registers/source_style_combat_model_2026-06-24.md` `[STY-1..17]`
and the owning GDD chapters at build). Grounded in the live UI/data as of this session.

---

## A. How a player uses it

The action loop after a unit moves (or acts in place), built on the live `ActionMenu`
(**Attack / Staff / Item / Equip / Wait …**):

1. **Action framing** — **Attack** (`strike` / hostile) or **Staff/Use** (utility). Both feed the
   *one* pipeline (`[STY-15]`); the split is just which targets/sources are offered.
2. **Pick the source** — `WeaponMenu`, fed by the **CEX-20 union** of inventory + granted sources
   (weapons, spells, natural weapons, battalion gambits). Visibility keys off the *union* size.
3. **Pick the style** — *plain* vs any available art/gambit/non-lethal; offered per the `[STY-3]`
   binding `(learned/equipped ∩ weapon-type gate) ∪ weapon-granted`. **Skipped when only plain is
   available**, so a normal attack stays a single confirm.
4. **Target** — single (cursor, as today) or **place an AoE footprint** (`[STY-9]` shape + direction;
   `self_centered` / `targeted_tile` / `targeted_unit`).
5. **Combined preview** (`[STY-10]`) → **confirm** → resolve every effect.

**Key player-feel guarantees**
- A vanilla attack is unchanged: `Attack → target → confirm` (steps 3–4 collapse when there's one
  source, no styles, single target).
- **Attack stays distinct from Equip** (`[CEX-21]`) — re-targeting never forces re-selecting a weapon.
- The preview is **one generalized "effect forecast" panel** (`[STY-10]`):
  - **1v1 `strike`** = today's two-box `AttackPreview` (Dmg×hits / Hit% / Crit% / Effective) — back-compat.
  - **Utility/no-counter** (heal/warp/repair/cure) = a **single-sided** readout (heal amount, "Warp →",
    "Repair +N", "→ Sleep (3)").
  - **AoE/multi-target** = **footprint highlight + a focused-target forecast you cycle** through
    affected units.
  - Always lists **all `[STY-16]` effects** with their gate ("+ Poison (3t) **on hit**", self-heal) and
    the **total multi-resource combo cost** (`[STY-5]`). More-Info links retained.

### Illustration — an AoE art preview
```
Map:  [#][#][#]
      [#][E][#]    # = footprint, E = focused (cycle < >)

┌ Forecast: Knight (1 of 3) ──────┐
│ You  →  Knight    (no counter)  │
│ Dmg 14x1   Hit 92%   Crit 5%    │
│ + Poison (3t) on hit            │
│ Cost: 2 dur + 3 stamina         │
└──────────────────────────────────┘
```

## B. How a designer builds it

| You want… | You author… |
|---|---|
| A special attack (combat art) | a **`StyleDef`** `.tres` |
| A gambit | a `StyleDef` with an AoE `shape` + a battalion-granted source (provenance `battalion`) |
| Capture | a `StyleDef` with `lethality = non_lethal` (→ caps at 1 HP, applies `sleep`) |
| A poison weapon / Nosferatu | put the **effects on the source** (`WeaponData.effects[]`) — no style needed |
| A staff (heal/warp/debuff/buff) | a staff source whose `effects[]` use the right `kind` + `target_filter` |
| Who is hostile/neutral/allied | **`FactionData`** relationship-stance overrides (`[STY-17]`) |
| A battalion (the entity) | **deferred to A2** (`[STY-11]`) |

**`StyleDef` (illustrative shape — authoritative fields firmed at build):**
```
id, display
weapon_type_gate          # which source families may use it (∪ per-weapon grant)
binding                   # learned / class_innate / weapon-granted (+ wielder requirements)
effects: [ EffectSpec ]   # { kind, payload, target_filter, gate(always|on_hit|on_kill) }
shape / origin / range / direction   # [STY-9]; omit for single-target
cost: { override_source_cost: bool, components: [ {backend, amount} ] }   # [STY-5]
lethality                 # normal | non_lethal
```

**`EffectSpec` `kind`s** (`[STY-13]`/`[STY-16]`): `strike | heal | teleport | fetch | repair | cure |
inflict | bolster`. A combo's effect set = **source effects ∪ style effects** (`[STY-14]`: add or
override), resolved in order, each gated; **per-effect `target_filter`** lets one use hit different
targets (Nosferatu = `strike`(enemy) + `heal`(self)).

**Authoring-time validation** (`DataManager.validate`, at build) — warn on:
- a `StyleDef` whose `weapon_type_gate` matches **no** known family;
- an `inflict`/`cure` effect naming a **condition F5 doesn't define**;
- an AoE effect with **no `target_filter`**, or a `rectangle` with non-positive `W`/`L`;
- a `non_lethal` style on a source that **can't reduce HP** (no `strike`);
- (carries the same spirit as the `[CEX-19]` key-item-loss warning.)

## Cross-refs
`[STY-1..17]` (the decisions) · `[CEX-20/21]` source union + equipped reference · `[CEX-6]` charge ·
`[RCR-5]` capture-carry (A2) · F5 `ConditionManager` · F7 pools · M14 faction model (`[STY-17]`).
