---
Type: register
Status: OPEN
Last verified: 2026-06-24
Register: STY-1..16
Resolved-in: 2026-06-24j / 2026-06-24k / 2026-06-24l
---

# Source + Style — Unified Combat-Action Model (combat arts · gambits · capture)

**Started:** 2026-06-24 (session 2026-06-24j, the A1 "walk the idea" pass).
**Status:** OPEN — **STY-1..8 RESOLVED 2026-06-24j**; **STY-12..15 RESOLVED 2026-06-24k** (staves fold
in + full F5 pulled forward); **STY-16 RESOLVED 2026-06-24l** (multi-effect combos); **STY-9..11 still
OPEN** (AoE targeting / preview UX / battalion entity).
Absorbs the deferred **`[CEX-23]`** maneuver layer and is the A1 design for **combat arts (#15)**, the
**gambit attack-side of Battalions (#16)**, and **utility + buff/debuff staves (#10)**. **Pattern:**
mirrors `[CEX]`/`[RCR]`. Legend: **[OPEN]** / **[RESOLVED]**.

---

## The model in one line
**Every combat-like action = a `source` + an optional `style`.** *Source* = the `WeaponData` from the
`[CEX-20]` inventory+granted union (weapon / spell / natural weapon / **battalion gambit**); answers
*what* you attack with. *Style* = a modifier layer; answers *how*. **Plain attack = the null style.**
Combat arts, gambits, and non-lethal **capture** are all just styles. One pipeline serves all of them:
**select source → select style → combined preview → re-derived targeting → pay combo cost → resolve.**

A source + style carries a **SET of effects** (`[STY-13]`/`[STY-16]`), each an `EffectSpec` with a
**kind** (`strike` by default; or `heal`/`teleport`/`fetch`/`repair`/`cure`/`inflict`/`bolster`), a
payload, a per-effect **`target_filter`**, and a **gate** (`always`/`on_hit`/`on_kill`). A style may
**add or override** effects (`[STY-14]`); all effects resolve together on one use. So "Attack" is just a
`strike` effect + hostile targeting, and staves are the same pipeline.

| Action | Source | Effect set (kinds) | Style |
|---|---|---|---|
| Normal attack | weapon | `strike` | *(null)* |
| Combat art | weapon (type-gated) | `strike` | single-target art |
| Gambit | battalion gambit | `strike` | AoE |
| Capture | weapon | `strike` (non-lethal → `sleep` on would-be-kill) | non-lethal |
| **Poison dagger** | weapon | `strike` **+** `inflict: poison` (on_hit) | *(null)* |
| **Nosferatu / Sol** | weapon | `strike`(enemy) **+** `heal: self`(=dmg, on_hit) | *(null)* |
| Heal staff | staff | `heal` | *(null)*; AoE-heal style optional |
| Warp / Rescue staff | staff | `teleport` / `fetch` | *(null)* |
| Hammerne / Restore | staff | `repair` / `cure` | *(null)* |
| **Legendary staff** | staff | `heal` **+** `bolster` **+** `cure` | *(null)* |
| Debuff / buff staff | staff | `inflict` / `bolster` (rides F5) | *(null)* |

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
**Override (refinement 2026-06-24k):** a style may also **OVERRIDE the base source cost** (not just add
to it) — `style.cost = { override_source_cost: bool, components: [...] }`. So a style can say "this use
spends **0** weapon durability, only 5 pool," replacing the source's normal per-use cost. Default
(`override_source_cost = false`) = additive as above.

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

### [STY-13] Staves fold in via an `effects` set + `target_filter`  **[RESOLVED 2026-06-24k; effects-set per `[STY-16]`]**
Staves are already `[CEX-20]` sources (`combat_family == "staff"`), and the code already dispatches by
effect (`is_healing_staff()` → heal resolver; offensive staves → damage resolver) — and
`WeaponData.effect_tags` is **already an `Array[String]`** (its comment anticipates `poison_on_hit`).
**Formalize** that so "use a source" is the one pipeline (attack = a `strike` effect + hostile target):
- **`effects`** (a **set** — generalizes `effect_tags`, see `[STY-16]`): each effect has a **kind** —
  `strike | heal | teleport (Warp) | fetch (Rescue staff) | repair (Hammerne) | cure (Restore) |
  inflict (debuff) | bolster (buff)` — extensible, with a payload + per-effect `target_filter` + gate.
- **`target_filter`**: `enemy | ally | self | empty_tile | weapon_holder | …` (per effect).
The resolver runs **each** effect; targeting derives from the effects' filters. **Most staves =
source + null style** (the verbs are intrinsic to the source); styles still *may* layer (AoE-heal style
over a Heal staff). **Disambiguation:** the **Rescue *staff*** (`fetch`, teleport an ally
adjacent) is distinct from the **Rescue *carry* system** (#6/H3, physical carry/drop, A2). **Hammerne**
(`repair`, `target = weapon_holder`) is the `[CEX-19]` story-item repair path; **Restore** (`cure`)
calls `ConditionManager.remove_condition`.

### [STY-14] A source may expose both aggressive AND beneficial styles; a style may add/override effects  **[RESOLVED 2026-06-24k; effects-set per `[STY-16]`]**
The source's `effects`/`target_filter` are the **default**, but a **style may ADD effects to the set
OR OVERRIDE them** — so one source can offer both **aggressive and beneficial** styles (designer
refinement). A style is no longer only a "strike modifier": it may contribute its own effects (e.g. a
beneficial style on an otherwise-offensive source, or an offensive style on a staff). This + buff/debuff
staves means the **status payloads ride F5** (`[STY-12]` — now a full build): `inflict` → apply
condition (sleep/silence/berserk), `bolster` → timed positive modifier. **`sleep` is shared by capture
(`[STY-6]`) and the Sleep staff** — one condition, two features.

### [STY-15] Action-menu framing for utility vs hostile  **[RESOLVED 2026-06-24k]**
Keep **Attack** (`strike` / hostile framing) and **Staff/Use** (utility framing) as **two menu entries
over the one pipeline** — Attack filters to `strike` sources + hostile targets; Staff/Use filters to
utility-`effect_kind` sources + their `target_filter`. (Today `ActionMenu` already has Attack + Staff,
gated by `is_healing_staff()`; offensive staves currently route through Attack, which is fine — they are
`strike`-ish with a status payload.) Extends the `[CEX-21]` menu vocabulary; no separate pipeline.

### [STY-16] A source+style combo carries MULTIPLE effects, resolved together  **[RESOLVED 2026-06-24l]**
**A single use applies a *set* of effects, not one** (designer refinement; also matches the existing
`WeaponData.effect_tags: Array[String]`, whose comment already anticipates `poison_on_hit`). Each effect
is an **`EffectSpec`**:
```
{ kind,                 # strike | heal | inflict | bolster | cure | teleport | fetch | repair | …
  payload,              # e.g. Mt source / heal formula / condition id+duration / stat-mod set
  target_filter,        # per-effect: enemy | ally | self | … (effects in one combo may differ)
  gate }                # when it fires: always | on_hit | on_kill  (reuses the F11 combat context)
```
The committed combo's effect set = **source effects ∪ style effects** (`[STY-14]`: a style may add or
override). On commit they resolve **in listed order**, each gated by `gate`. Examples:
- **Poison dagger** = `strike` (always) **+** `inflict: poison` (**gate `on_hit`**) → same enemy target.
- **Legendary staff** = `heal` **+** `bolster: +stats` **+** `cure` → same ally target.
- **Nosferatu / Sol (drain)** = `strike` (target `enemy`) **+** `heal: self` (target `self`,
  payload = damage dealt, gate `on_hit`) — **per-effect `target_filter` differs within one use.**
**Implications:** generalizes/replaces the single-`effect_kind` framing of `[STY-13]`; the
combined-preview (`[STY-10]`) must show **all** effects (damage **and** "inflicts poison" **and** heal);
cost (`[STY-5]`) is still per-*combo*, not per-effect; `inflict`/`bolster`/`cure` effects route through
the full **F5** (`[STY-12]`). Reuses `effect_tags` as the storage seam (extended with payload+target+gate).

---

## Deferred / build-time (still OPEN)

### [STY-9] AoE targeting vocabulary + friendly-fire rules  **[OPEN]**
Shape vocabulary (line / blast / cone / N-tile radius), origin rules, and whether an AoE style can hit
allies (friendly fire) or filters by faction. Design at the A1 build. **Resolution:** _[OPEN]_

### [STY-10] Combined-preview UX  **[OPEN]**
The `[CEX-23]` UI detail: how the forecast renders the *combined* source+style effect (deltas, range
highlight, AoE footprint, total combo cost) before commit — and **all `[STY-16]` effects in the set**
(e.g. damage **and** "inflicts poison" **and** self-heal), each with its gate. Design at the A1 build.
**Resolution:** _[OPEN]_

### [STY-11] Full battalion entity spec  **[OPEN — A2]**
Attached-unit data model, assignment/prep UI, endurance & how it depletes, passive bonus aggregation,
battalion EXP/leveling, adjutant/pair-up variant. Owned by the **A2** cluster. **Resolution:** _[OPEN]_

### [STY-12] F5 pull-forward decision for capture/status  **[RESOLVED 2026-06-24k]**
`[STY-4]` style-status + `[STY-6]` capture `sleep` + `[STY-14]` buff/debuff staves **all** need
conditions, and `sleep` is shared by capture and the Sleep staff. **Resolution: build the FULL F5
`ConditionManager` now**, pulled onto A1's critical path (designer call). F5 graduates from stub to a
real foundation build (`scripts/autoloads/ConditionManager.gd` already declares `sleep`/`silence`/
`berserk` and the `apply`/`remove`/`tick`/`has`/`clear` surface). Scope = the full condition framework
(types, durations, ticking, immunities, stacking), not just `sleep`. This unblocks capture + style
status + buff/debuff staves together. Also resolves the `[CEX-10]` triangle-condition slice deferral.

---

## F1 schema implications (reserve at the Phase-B lock)
- **`unit.learned_styles` / `unit.equipped_styles`** (the `[STY-3]` lists; cap via `requires_equip` later).
- **`style_id`** as the optional second half of the committed-attack reference (the `[CEX-23]`/`[CEX-21]`
  "optional maneuver id").
- **Per-style charge state** (the `[STY-5]` style cost components that use counters/pools), alongside the
  `[CEX-6]`/`[CEX-20]` per-source charge state.
- **Captured/`sleep` state** reserve coordinates with `[RCR]` (roster) + F5 (condition) + A2 (carry).
- **Active-conditions state per unit** (type + remaining duration) — owned by the **full F5
  `ConditionManager`** (`[STY-12]`); reserve at the lock (capture, style status, buff/debuff staves).
- (`effect_kind` / `target_filter` are *source data-def*, not save state.)

## Notes
- **DoD:** when this graduates to a build, it gets GDD owner updates (GDD_02 combat exchange, GDD_05
  skills/`StyleDef` + F5/conditions, GDD_04 weapons type-gate, **GDD_07-ish staff `effect_kind`**) +
  the `StyleDef` `.tres` + tests, **with the build**.
- **Cross-refs:** `[CEX-20]` source enum · `[CEX-21]` equipped reference · `[CEX-6]` per-source charge
  (extended here) · `[CEX-23]` (absorbed) · `[SKL-3]` `requires_equip` cap · `[RCR-5]` capture-carry
  (A2) · F5 `ConditionManager` · F7 pools.
