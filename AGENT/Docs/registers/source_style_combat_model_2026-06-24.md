---
Type: register
Status: RESOLVED 2026-06-25
Last verified: 2026-06-25
Register: STY-1..17
Resolved-in: 2026-06-24j / 2026-06-24k / 2026-06-24l / 2026-06-24m / 2026-06-24n / 2026-06-25k (STY-11 → [BAT])
---

# Source + Style — Unified Combat-Action Model (combat arts · gambits · capture)

**Started:** 2026-06-24 (session 2026-06-24j, the A1 "walk the idea" pass).
**Status:** OPEN — **STY-1..8 RESOLVED 2026-06-24j**; **STY-12..15 RESOLVED 2026-06-24k** (staves fold
in + full F5 pulled forward); **STY-16 RESOLVED 2026-06-24l** (multi-effect combos); **STY-9 + STY-17
RESOLVED 2026-06-24m** (AoE/multi-target vocab + friendly fire + directed faction relationship matrix);
**STY-10 RESOLVED 2026-06-24n** (combined-preview UX — **A1 design complete**); **STY-11 RESOLVED
2026-06-25k** (full battalion entity → the **attached-augment** pattern, register `[BAT-1..13]`) —
**register now fully RESOLVED**. Player flow + authoring surface walked in
`design/source_style_player_and_authoring_2026-06-24.md`.
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
**kind** (`strike` by default; or `heal`/`teleport`/`fetch`/`repair`/`cure`/`inflict`/`bolster`/
`displace`), a
payload, a per-effect **`target_filter`**, and a **gate** (`always`/`on_hit`/`on_kill`). A style may
**add or override** effects (`[STY-14]`); all effects resolve together on one use. So "Attack" is just a
`strike` effect + hostile targeting, and staves are the same pipeline. **Targeting** = a per-effect
`shape`/`origin` (`[STY-9]`) whose footprint units are filtered by each effect's `target_filter`,
resolved against the **faction relationship matrix** (`[STY-17]`).

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
list reuses `[SKL-3] requires_equip`, deferred like `[CEX-7]` — **RESOLVED 2026-06-27d → `[LDC-1..7]`**:
separate author-configurable `max_styles` cap; swap freely in prep; weapon-granted styles are a separate
per-weapon override, not a cap slot.)

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
**Counters carry NO style:** styles are player-initiated (`[STY-2]` `player_activated`), so an
enemy-phase counterattack is always `equipped_source` + *null style* — the fallback (`[CEX-22]`) only
ever needs a usable **source**, never a style.

### [STY-13] Staves fold in via an `effects` set + `target_filter`  **[RESOLVED 2026-06-24k; effects-set per `[STY-16]`]**
Staves are already `[CEX-20]` sources (`combat_family == "staff"`), and the code already dispatches by
effect (`is_healing_staff()` → heal resolver; offensive staves → damage resolver) — and
`WeaponData.effect_tags` is **already an `Array[String]`** (its comment anticipates `poison_on_hit`).
**Formalize** that so "use a source" is the one pipeline (attack = a `strike` effect + hostile target):
- **`effects`** (a **set** — generalizes `effect_tags`, see `[STY-16]`): each effect has a **kind** —
  `strike | heal | teleport (Warp) | fetch (Rescue staff) | repair (Hammerne) | cure (Restore) |
  inflict (debuff) | bolster (buff) | displace (shove/swap/pivot — added by [DSP-7], A2)` —
  extensible, with a payload + per-effect `target_filter` + gate.
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
utility-`effect` sources + their `target_filter`. (Today `ActionMenu` already has Attack + Staff,
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

### [STY-17] Faction relationship matrix — the "aggression matrix" `target_filter` resolves against  **[RESOLVED 2026-06-24m]**
`target_filter` is **relative to the actor** and resolves against faction relationships. Today
`GameState.are_hostile(a, b)` is **binary + symmetric** (hostile iff different `alliance_group`).
**Upgrade to an author-defined, DIRECTED, 3-state relationship matrix** (designer call; mirrors the
`[CEX-11]` triangle matrix):
- **`relationship(from, to) ∈ { hostile | neutral | allied }`** — **directed** (A→B may differ from
  B→A), enabling **neutral NPCs/villagers** and **one-way aggression** (passive-until-provoked).
- **Default derives from today's alliance groups** (same group → `allied`, different → `hostile`; no
  `neutral` by default) so existing maps are **non-breaking**.
- **Authoring home:** per-`FactionData` stance overrides (a faction declares its stance toward others),
  on `MapData` (factions are per-map), falling back to the group derivation.
- **`target_filter` resolution:** `enemy` = `relationship(actor, target) == hostile`; `ally` = `allied`;
  `neutral` = `neutral`; `any` = ignore relationship (friendly fire); `self`. **Cross-faction is free:**
  `enemy` spans *all* hostile factions (blue's AoE hits red **and** yellow if both are hostile, not green).
- **Consumers beyond targeting:** `EnemyAI` (target selection), EXP (`exp_gaining_factions`), objectives —
  this is a **faction-model (M14) extension**, surfaced here but shared. `are_hostile()` becomes a shim
  over `relationship() == hostile`.
- **Counterattack vs stance (lean):** being attacked triggers a counter **regardless** of the defender's
  stance (self-defense); a `neutral`/`allied` AI simply won't *initiate*. Keeps one-way aggression
  meaningful. (Firms with A2 alongside the other combat-economy leans.)
- **Dynamic "provoked" transitions — owned by A4 + AI (pinned 2026-06-25c):** the *trigger* mechanism
  (what flips a relationship at runtime) = a **`[MET]` event action that sets a faction relationship
  (A4)** + **AI provoke** (a `neutral` unit that is attacked becomes `hostile`, firming with the AI
  work). STY-17 owns the matrix + state; A4/AI own the transitions.
- **Save (F1):** the authored matrix is **data** (not saved). **Reserve a runtime
  faction-relationship-override store** for dynamic changes (provoked, `[MET]`-event-driven).

---

## Deferred / build-time items  *(status per item)*

### [STY-9] AoE / multi-target vocabulary + friendly-fire rules  **[RESOLVED 2026-06-24m]**
A style/effect declares **`shape` + `origin_mode` + `range` (+ `direction` for directional shapes)**.
Each shape is a **tile-template generator**; targeting derives the footprint, preview highlights it.

**Shape vocabulary (all defined now; build incrementally):**
- `single` — one tile/unit.
- `multi(N)` — up to **N discrete** single-tile picks within range.
- `blast(R)` — all tiles within distance **R** of the origin (**Manhattan/diamond default**; metric
  author-overridable per shape later).
- `line(L, width=1)` — straight line length **L** from origin along `direction`.
- `cone(L)` — a wedge expanding outward from the actor, depth **L**.
- `cross(R)` — the four cardinal arms of length **R** from the origin (a plus).
- `rectangle(W, L, anchor_side)` — **(designer-requested)** a **W×L** rectangle **anchored by the
  CENTER of a specified side**: that side's midpoint sits on the chosen tile and the rectangle extends
  **L** deep away along `direction` (W = breadth across the anchored side). Lets you aim a directional
  zone from the actor or a target tile.
- `all_matching` — every unit on the map matching the effect's `target_filter` (global; no origin/range).

**Origin mode:** `self_centered` (origin = actor) · `targeted_tile(range)` (pick a tile in range) ·
`targeted_unit(range)` (a targeted tile that must hold a unit). Directional shapes (`line`/`cone`/
`rectangle`) also take a **`direction`** — **4-way cardinal v1** (8-way later).

**Resolution rules:**
1. Gather units in the footprint.
2. **Each `[STY-16]` effect applies to footprint units matching ITS OWN `target_filter`** (resolved via
   the `[STY-17]` matrix). So one `strike + heal` blast can **damage enemies AND heal allies** in the
   same area — per-effect filtering is the whole point.
3. **Friendly fire = a broad `target_filter`** (`any`/includes allies) — **not a separate system.**
4. **Obstruction (lean):** v1 shapes are **pure geometric tile-templates, no line-of-sight blocking**
   (matches FE gambits/AoE staves); LoS-blocked shapes are a later growth.

**Friendly fire decision:** AoE damage **defaults to `target_filter: enemy` (no friendly fire)**; an
author opts in per style/effect by widening the filter to `any` (or adding `ally`). (`[STY-3 fork]`)

**Save (F1):** AoE adds **no** new save state (shapes are source/style data-def; selection is transient).

### [STY-10] Combined-preview UX  **[RESOLVED 2026-06-24n]**
The `[CEX-23]` UI detail: how the forecast renders the *combined* source+style effect before commit,
across all action types (1v1 strike, utility/no-counter, AoE/multi-target) and **all `[STY-16]`
effects** (damage **and** "inflicts poison" **and** self-heal), each with its gate. **Resolution
(designer forks):**
- **One generalized "effect forecast" panel** — evolve the existing `AttackPreview` (today: two
  Attacker/Defender boxes of `Dmg×hits / Hit% / Crit% / Effective`) into a single component:
  **1v1 `strike` = today's two-box view (back-compat); utility/no-counter = a single-sided readout;
  AoE = footprint + focused-target (below).** One code path, consistent look, More-Info links retained.
- **AoE/multi-target = footprint highlight + focused-target forecast (cycle).** Highlight the AoE
  tiles on the map; show one detailed forecast for the **currently-focused** affected unit; cycle focus
  through affected units. (Extends today's single forecast rather than replacing it.)
- The panel lists **every effect** of the combo with its gate (e.g. "+ Poison (3t) **on hit**",
  self-heal) and the **total combo cost** (the multi-resource `[STY-5]` set). Non-strike effects show
  their own readout (heal amount, "→ Sleep (3)", "Warp →", "Repair +N uses").
**Player flow + authoring surface** for the whole model are walked in the companion design doc
`design/source_style_player_and_authoring_2026-06-24.md` (this session). **Save (F1):** none (transient).

### [STY-11] Full battalion entity spec  **[RESOLVED 2026-06-25k → `[BAT-1..13]`]**
Attached-unit data model, assignment/prep UI, endurance & how it depletes, passive bonus aggregation,
battalion EXP/leveling, adjutant/pair-up variant. Owned by the **A2** cluster. **Resolution:** the
battalion is the canonical config of a generic **attached-augment entity** — a thin `BattalionData` +
`BattalionRegistry` over **reused** plumbing (Pair-Up attach pattern, the bonus-resolver pipeline, the
`[CEX-20]` granted-source union, the rank-threshold helpers), **not** merged into items and **not** fully
bespoke (`[BAT-1]`). Adjutant → Pair-Up (`[BAT-8]`); accessories/bond-rings → `[IEQ]` (`[BAT-9]`); Emblem
= the maximal config (`[BAT-7]`). Full spec in
`registers/battalion_attached_augment_open_questions_2026-06-25.md`.

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
- **Runtime faction-relationship overrides** (`[STY-17]`) — for dynamic provoked/`[MET]`-driven changes;
  the *authored* matrix is map data (not saved). AoE shapes (`[STY-9]`) add **no** save state.
- (`effects` / `target_filter` are *source/style data-def*, not save state.)

## Notes
- **DoD:** when this graduates to a build, it gets GDD owner updates (GDD_02 combat exchange, GDD_05
  skills/`StyleDef` + F5/conditions, GDD_04 weapons type-gate, **GDD_07-ish staff `effects`**) +
  the `StyleDef` `.tres` + tests, **with the build**.
- **Cross-refs:** `[CEX-20]` source enum · `[CEX-21]` equipped reference · `[CEX-6]` per-source charge
  (extended here) · `[CEX-23]` (absorbed) · `[SKL-3]` `requires_equip` cap · `[RCR-5]` capture-carry
  (A2) · F5 `ConditionManager` · F7 pools.
