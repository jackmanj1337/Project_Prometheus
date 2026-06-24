---
Type: register
Status: OPEN
Last verified: 2026-06-24
Register: STY-1..12
Resolved-in: 2026-06-24j
---

# Source + Style — Unified Combat-Action Model (combat arts · gambits · capture)

**Started:** 2026-06-24 (session 2026-06-24j, the A1 "walk the idea" pass).
**Status:** OPEN — **STY-1..8 RESOLVED 2026-06-24j**; STY-9..12 deferred to the build / later clusters.
Absorbs the deferred **`[CEX-23]`** maneuver layer and is the A1 design for **combat arts (#15)** and
the **gambit attack-side of Battalions (#16)**. **Pattern:** mirrors `[CEX]`/`[RCR]`. Legend:
**[OPEN]** / **[RESOLVED]**.

---

## The model in one line
**Every combat-like action = a `source` + an optional `style`.** *Source* = the `WeaponData` from the
`[CEX-20]` inventory+granted union (weapon / spell / natural weapon / **battalion gambit**); answers
*what* you attack with. *Style* = a modifier layer; answers *how*. **Plain attack = the null style.**
Combat arts, gambits, and non-lethal **capture** are all just styles. One pipeline serves all of them:
**select source → select style → combined preview → re-derived targeting → pay combo cost → resolve.**

| Action | Source | Style |
|---|---|---|
| Normal attack | weapon | *(null)* |
| Combat art | weapon (type-gated) | single-target art |
| Gambit | battalion gambit | AoE |
| Capture | weapon | non-lethal |

---

## Resolved decisions

### [STY-1] The unification — attack = source + style  **[RESOLVED]**
Adopt the **source + style** decomposition above as the single combat-action pattern; it **absorbs
`[CEX-23]`** (the deferred "maneuver"). Building this *is* building CEX-23. Designing arts and gambits
separately would fork the select→preview→target UI per feature (the explicit A1 anti-goal). The style
half is **open-ended** by design so future combat verbs (e.g. staff modes) can join the same pipeline.

### [STY-2] Style data model — own lightweight `StyleDef` resource  **[RESOLVED]**
A style is its **own small resource** (`StyleDef`), referenced like a skill and **fired via the
existing `player_activated` trigger** (no new trigger — F11 discipline), but carrying attack-shaping
fields a plain skill lacks: stat-mods, range override, targeting/AoE shape, cost set, lethality. Keeps
"skill" from being overloaded with attack-shaping semantics.

### [STY-3] Style availability / binding  **[RESOLVED]**
A style is offered for a given (unit, equipped source) when:
`(style ∈ unit's learned/equipped styles  AND  the equipped source's weapon-type satisfies the style's
type-gate)`  **∪**  `(the equipped weapon GRANTS the style)` — the **per-weapon override**: a weapon may
confer a style while equipped, optionally gated on **the wielder matching requirements**. So a unit can
carry a list of learned/equipped styles, and a weapon can also lend one. (Loadout cap on the learned
list reuses `[SKL-3] requires_equip`, deferred like `[CEX-7]`.)

### [STY-4] What a style may modify  **[RESOLVED]**
**Stat-mods (Mt/Hit/Crit/…) + range override + AoE/targeting shape** ship in A1. **Status-effect
application rides the F5 `ConditionManager`** (currently a stub) — same split as the `[CEX-10]`
triangle-conditions slice: stat/range/AoE without F5, status with F5.

### [STY-5] Cost model — composable, multi-resource (supersedes the `[CEX-6]` XOR)  **[RESOLVED]**
A *source* keeps one storage backend (`[CEX-6]`: how its "ammo" is stored — durability / counter / pool
/ infinite). A *style* declares its **own cost SET** — a list of `{backend, amount}` components — and the
**combo cost = source per-use cost + the style's cost set**, all charged on commit. **Not XOR.** E.g. a
Smash art = 2 weapon-uses **and** 3 stamina; a gambit = 1 battalion charge **and** a pool spend.
Generalizes `[CEX-4]` ("may cost from multiple pools") to the whole combo.

### [STY-6] Capture as a non-lethal style  **[RESOLVED]**
A **non-lethal** style **cannot reduce the target below 1 HP**; a hit that would otherwise be **lethal
instead applies the `sleep` condition**. The sleeping unit is the **capture-enabling state** for the A2
carry/jail. Splits cleanly: the **damage cap ships in A1**; `sleep` is a **condition → rides F5** (a
strong candidate for the *first* F5 condition built); the **physical carry/jail stays A2** (`[RCR-5]`).
This adds a **combat-capture path** alongside the `[RCR]` talk-recruit path (note added to `[RCR]`).

### [STY-7] Battalions — slice for A1 vs A2  **[RESOLVED]**
Scope target = **full 3H battalions** (attached unit with level / endurance / passive bonuses /
gambit). The **A1 slice is only the gambit-as-style**: an AoE *source* (a `WeaponData` granted by the
battalion, provenance `battalion` on the `[CEX-20]` granted-list) with per-map **charges**. The
**battalion *entity*** — assignment UI, passive `StatContributions`, endurance, leveling — is the **A2
side** (`#16 ⇄ A2`) / its own build. So "full battalions" does **not** bloat A1.

### [STY-8] Action economy — a style is the attack  **[RESOLVED (lean; battalion edge-cases → A2)]**
Choosing a style **is** the unit's attack and **costs its one combat action** (matches 3H: arts and
gambits both consume the combat action). It is **not** an extra action. Finer battalion action-economy
edge-cases (e.g. gambit-then-move ordering, who spends the charge) are settled on the **A2** side.

---

## Deferred / build-time (still OPEN)

### [STY-9] AoE targeting vocabulary + friendly-fire rules  **[OPEN]**
Shape vocabulary (line / blast / cone / N-tile radius), origin rules, and whether an AoE style can hit
allies (friendly fire) or filters by faction. Design at the A1 build. **Resolution:** _[OPEN]_

### [STY-10] Combined-preview UX  **[OPEN]**
The `[CEX-23]` UI detail: how the forecast renders the *combined* source+style effect (deltas, range
highlight, AoE footprint, total combo cost) before commit. Design at the A1 build. **Resolution:** _[OPEN]_

### [STY-11] Full battalion entity spec  **[OPEN — A2]**
Attached-unit data model, assignment/prep UI, endurance & how it depletes, passive bonus aggregation,
battalion EXP/leveling, adjutant/pair-up variant. Owned by the **A2** cluster. **Resolution:** _[OPEN]_

### [STY-12] F5 pull-forward decision for capture/status  **[OPEN]**
`[STY-4]` status + `[STY-6]` `sleep` both need F5 `ConditionManager`. Decide whether capture/status
justify **building F5 (or just the `sleep` condition) earlier**, or whether the status slice waits for
the scheduled F5 build. **Resolution:** _[OPEN]_

---

## F1 schema implications (reserve at the Phase-B lock)
- **`unit.learned_styles` / `unit.equipped_styles`** (the `[STY-3]` lists; cap via `requires_equip` later).
- **`style_id`** as the optional second half of the committed-attack reference (the `[CEX-23]`/`[CEX-21]`
  "optional maneuver id").
- **Per-style charge state** (the `[STY-5]` style cost components that use counters/pools), alongside the
  `[CEX-6]`/`[CEX-20]` per-source charge state.
- **Captured/`sleep` state** reserve coordinates with `[RCR]` (roster) + F5 (condition) + A2 (carry).

## Notes
- **DoD:** when this graduates to a build, it gets GDD owner updates (GDD_02 combat exchange, GDD_05
  skills/`StyleDef`, GDD_04 weapons type-gate) + the `StyleDef` `.tres` + tests, **with the build**.
- **Cross-refs:** `[CEX-20]` source enum · `[CEX-21]` equipped reference · `[CEX-6]` per-source charge
  (extended here) · `[CEX-23]` (absorbed) · `[SKL-3]` `requires_equip` cap · `[RCR-5]` capture-carry
  (A2) · F5 `ConditionManager` · F7 pools.
