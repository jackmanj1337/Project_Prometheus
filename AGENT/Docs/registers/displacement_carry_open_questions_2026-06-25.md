---
Type: register
Status: RESOLVED 2026-06-28
Last verified: 2026-06-28
Register: DSP-1..17
Resolved-in: 2026-06-25e (DSP-1..5,7) / 2026-06-25f (DSP-12..16) / 2026-06-25g (DSP-17 campaign-default+override; relationship gate; Capture-victory pin) / 2026-06-27d (DSP-6/9/11 leans firmed — register CLOSED)
---

# Displacement & Carry — Shared Spatial Primitive (rescue · capture-carry · shove/swap/pivot)

**Started:** 2026-06-25 (session 2026-06-25e). First sub-cluster of **A2 — Map action-economy &
movement assists** (owner call 2026-06-25e: *displacement primitive first*, mirroring A1's
foundation-first split). Branch `docs-reorg-2026-06-23`.

**Thesis.** Three A2 agenda items — **Rescue (#6/H3)**, **Capture carry/jail/release (`[RCR-5]`)**, and
**Movement assists (#17: shove/swap/pivot/smite)** — are all *relocate-a-unit* operations. They share
**one occupancy-mutation primitive** and either the **carry** state (rescue, capture) or the **push**
displacement rule (shove/swap/pivot/smite). This register firms that shared foundation so the three
features do not each grow their own occupancy/displacement code. The remaining A2 sub-clusters
(**action-grant / Dancer**, **battalion entity `[STY-11]`**) are separate passes.

**Code-grounded substrate.** Pair-Up already solves "two units, one tile": `PairUpRegistry` stores a
`unit_id -> {partner_id, role}` map and sets the support unit's `tile_position` to a negative-coord
`OFF_MAP_TILE (-1,-1)` sentinel while paired, so only the lead occupies a real cell; it is snapshotted
with `GameState._map_start_snapshot` so Retry rewinds it. `GridManager.get_unit_at(tile)` is the single
occupancy lookup (tile-position equality), and pathfinding already respects occupants. Carry is the
same shape — the carried unit goes off-map, attached to the carrier — so DSP mirrors the proven Pair-Up
plumbing rather than inventing new occupancy state.

**Pattern:** mirrors `[CEX]`/`[STY]`/`[RCR]`/`[SMV]`. Legend: **[OPEN]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)
- **Not implemented.** No `rescue`, `carry`, `shove`, `displace`, or `grant_extra_turn` in `scripts/`
  (grep clean). Pair-Up **is** built (`PairUpRegistry`, `PairUpBonusResolver`) and provides the off-map
  attach + snapshot convention DSP reuses.
- **F10 Secondary Movement** (`[SMV-1..11]`, firmed 2026-06-24a) is the post-move action window
  carry-pickup/drop and the push actions open/close; it is a parameterized **skill**, not built yet.
- **A1 `[STY]`** (design complete 2026-06-24n) provides the **`EffectSpec{kind,payload,target_filter,
  gate}`** axis and the **source `effects` set**; DSP-7 adds a **`displace`** effect kind onto it.

## 2. What this pass produced
**Session 2026-06-25e** — the shared occupancy primitive (DSP-1/2), the rescue/pair-up relationship +
carry gating (DSP-3/4), the capture-carry deltas (DSP-5), and the push family as a `displace` **effect
kind** layerable into sources/styles **and** exposed as standalone skill-actions (DSP-7), plus detail
leans (DSP-6/9/11).
**Session 2026-06-25f** — the **cross-cutting non-standard-movement ruleset** (DSP-12..16) that *all*
position-changes-outside-the-move-action obey: off-turn/reactive timing (DSP-12), the composable
resistance pipeline (DSP-13), the author-selectable invalid-destination outcome set (DSP-14), the six
framework invariants (DSP-15), and the preview/RNG surface (DSP-16). This generalized the old DSP-8/10
leans (now subsumed). Player flow + author levers illustrated in
`design/nonstandard_movement_and_displacement_2026-06-25.md`.
**Session 2026-06-25g** — made the ruleset **campaign-default + per-source override for every rule**
(DSP-17), added the **harmful-consequence relationship gate** (`[DSP-14]` — can't ring-out a non-hostile
unit), and **forward-pinned a "Capture" victory type** (`escape with prisoner`) + the `captured:<id>`
story/bonus-chapter flag.

---

## 3. Resolved decisions

### [DSP-1] Single occupancy-mutation primitive — **RESOLVED**
One `DisplacementService.relocate(unit, dest_tile)` (autoload/service) is the **only** path that moves a
unit between cells outside ordinary pathed movement. It validates terrain passability + occupancy
(`GridManager.get_unit_at`), writes `tile_position`, and emits the unit-moved signal. **Both** carry-drop
placement (DSP-6) and every `displace` effect (DSP-7) call it, so occupancy invariants live in one place.

### [DSP-2] Carry attach = reuse the Pair-Up off-map sentinel — **RESOLVED**
A carried unit's `tile_position` is set to the Pair-Up **`OFF_MAP_TILE (-1,-1)`** sentinel (so no tile
query returns it and it cannot be targeted/acted), with a `carrier_id ⇄ carried_id` pointer pair stored
in a **`CarryRegistry`** that mirrors `PairUpRegistry` (separate registry per DSP-3, same off-map +
snapshot convention). Snapshotted with the `GameState` map-start snapshot so Retry rewinds carries, same
as pairings.

### [DSP-3] Rescue is DISTINCT from Pair-Up, sharing the attach substrate — **RESOLVED**
(owner 2026-06-25e) Rescue is its own mechanic — **no combat bonus** (unlike a Pair-Up support's stat
contribution), **carried unit inert** (off-map, can't act/be targeted), **droppable** — but reuses the
DSP-2 off-map-attach + snapshot plumbing. **Exclusivity prior:** a unit may **not** simultaneously be in
a Pair-Up and carrying/being-carried; the two registries cross-check on entry (build-time guard). Rescue
≈ FE-classic Rescue alongside Awakening-style Pair-Up.

### [DSP-4] Carry gating = an F4 author-profile rule — **RESOLVED**
(owner 2026-06-25e) Whether A can carry B is governed by an **`CampaignRules` "carry" profile** (F4), not
hardcoded: a **capacity stat** (default Con/Aid à la FE), **weight = the carried unit's Con**, and
author-set **while-carrying penalties** (default lean: carrier cannot act and takes a move penalty while
carrying). Data-driven, matching how the flexible triangle (`[CEX-9..12]`) and pools (`[CEX-1..4]`) were
firmed. The concrete default formula is an authoring default, overridable per campaign.

### [DSP-5] Capture-carry = the rescue substrate + deltas — **RESOLVED**
(owner 2026-06-25e; settles `[RCR-5]`'s A2 hand-off) Capture reuses the **same** carry plumbing (DSP-2,
DSP-6, DSP-4 gating) with deltas: the carried unit is an **enemy** under the `[STY-6]` **`sleep`**
condition; it is **freed if the carrier is defeated** (dropped to an adjacent valid tile, then subject to
the normal `sleep` wake/tick rules via F5); and it is **delivered to the roster/jail** on map-clear via
the `[RCR]` recruited-state path. One carry engine; capture is a flavored case, not a parallel system.

### [DSP-7] Push family = a `displace` EFFECT KIND, usable as skill-actions AND layered into sources/styles — **RESOLVED**
(owner 2026-06-25e) Shove/swap/pivot/smite are **not** a separate action family. They are a new
**`displace`** kind on the A1 `[STY]` **`EffectSpec`** axis (`EffectSpec{kind:"displace", payload, …}`),
resolved by `DisplacementService` (DSP-1). It is surfaced **two ways**:
1. **Standalone skill-granted actions** — preset `SkillData` (`effect_id` carrying a `displace`
   EffectSpec), granted via the skill-grant mechanisms exactly like `[SMV]`. Player-facing presets:
   **shove** (push target 1 away), **smite** (same directional rule, **higher potency** — push 2),
   **swap** (exchange the actor's and target's tiles), **pivot** (actor relocates relative to the
   target). Smite is *shove with a distance/potency param*, not a distinct mechanic.
2. **Layered into an attack** — a `displace` EffectSpec may sit in a source's `effects` set or be added
   by a **style**, so a weapon can `strike + displace` (knockback) or a style can bolt a shove onto an
   attack. This rides the existing `[STY]` `select → combined preview → re-derived targeting → resolve`
   pipeline and the **effect-forecast preview** (`[STY-10]`); `target_filter` (`[STY-17]` matrix) picks
   ally-shove vs enemy-knockback.
- **`payload`** carries the displacement **mode** (`push | pull | swap | to_side`), **distance/potency**,
  and **direction source** (away-from-actor / actor-facing — 4-way v1, matching `[STY-9]`).
- **Cross-cutting:** this **extends A1's `EffectSpec.kind`** with `displace` (the same kind of
  deliberate A1 touch as the F5 pull-forward). Recorded as an A1→A2 amendment (see Notes).

---

## 4. Detail leans (firm at build unless a fork emerges)

### [DSP-6] Drop / Give-Take handoff through the F10 window — **RESOLVED 2026-06-27d**
Drop places the carried unit on a **valid tile within an author-configurable `drop_range`** (via DSP-1),
inside the **F10 post-move window** so a carrier can move-then-drop. **Owner: `drop_range` is authorable**
(default **1 = adjacent**, **includes the carrier's vacated origin tile**), so an author may allow
longer-range "throws" — consistent with the open-registry/author-extensibility principle. **Give/Take**
handoff between two adjacent carriers is supported (FE Rescue→Take→Drop chain). Target tiles obey the
DSP-1 valid-tile rules; a drop onto a normally-invalid tile is the `[DSP-14]` `force_onto_invalid` path
only if authored.

### [DSP-8] Push collision — **[SUPERSEDED by `[DSP-14]`]**
The "blocked, no chain" lean is **subsumed** by the author-composable destination-handling set in
`[DSP-14]`: `fail` is the v1 default (matches the old lean), with `collision_damage` / `chain_push` /
`force_onto_invalid` reserved as opt-in author outcomes.

### [DSP-9] Action economy × F10 — **RESOLVED 2026-06-27d (lean confirmed)**
A standalone carry-pickup, a drop, and a standalone push skill **each cost the unit's action** (like an
attack). When `displace` is an **attack effect** it rides the parent attack's action (**no extra cost**),
consistent with `[STY-8]` "a style is the attack." The F10 second-move window opens per the acting
skill's `secondary_move_actions` config — same rule as `[SMV]`. (Owner-confirmed, FE-standard.)

### [DSP-10] Forced-move landing effects — **[SUBSUMED by `[DSP-15]` inv. 4]**
Landing-tile terrain/trap effects apply to a displaced/dropped unit — generalized by the **"forced
entry == normal entry"** invariant (`[DSP-15]` #4): a unit arriving by force obeys exactly the tile
rules a walking unit would, including that **action-gated objectives (Seize/Escape) do NOT auto-fire**.
**ZoC / attack-of-opportunity** on forced movement stays **deferred** (no ZoC in the engine yet; when
built, forced movement ignores ZoC).

## 5. Cross-cutting non-standard-movement ruleset (DSP-12..16) — **RESOLVED 2026-06-25f**
These rulings govern **every** position change outside the regular move action — DSP `displace`/carry,
the `[STY]` `teleport`/`fetch` staff effects, and environmental/event movers — so they share one
framework. Player-facing flow + worked edge cases + the author-lever catalog are illustrated in
`design/nonstandard_movement_and_displacement_2026-06-25.md` (navigation, not a second spec).

### [DSP-12] Off-turn / reactive displacement — **RESOLVED**
(owner 2026-06-25f) Displacement **may fire on any phase** — an enemy gambit shoves you on enemy phase;
an on-hit knockback fires even on a counter; a reaction skill may shove the attacker. But it **never
interrupts an in-progress exchange**: off-turn displace resolves as a **post-resolution consequence**,
never cancelling an attack or denying a counter mid-exchange (the combat exchange stays atomic).
Eligibility to fire off-turn is an **author flag per source/skill**. Consistent with `displace` being a
source on-hit effect (`[DSP-7]`).

### [DSP-13] Resistance pipeline — composable, staged — **RESOLVED**
(owner 2026-06-25f) Whether a target is moved runs through up to **three author-composable stages**
(any subset; none → always moves):
1. **`immobile` tag** (immune) + a per-effect **`ignores_immobile`** bypass — binary, deterministic.
2. **Static stat contest** — `potency` vs the target's weight/Con; deterministic. May **block** or
   (build-option) **reduce distance** (a heavy unit gets shoved 1 instead of 2).
3. **To-hit accuracy** — an optional displacement **accuracy %** that can miss like an attack; the
   **only stochastic stage** → rides **`RngService`** + reuses the combat hit calc.
**Build staging:** v1 ships **stage 1 only** (binary, deterministic); stages 2–3 reserved as author
levers (stage 3 is the only one that adds an RNG path). Rides **F5** for the `immobile` condition/tag.

### [DSP-14] Invalid-destination handling — non-exclusive author outcome set — **RESOLVED**
(owner 2026-06-25f) When a computed destination is occupied/impassable/off-map, the author selects a
**non-exclusive set** of outcomes for that displacement source:
- **`fail`** — no move (v1 default; supersedes the old `[DSP-8]` lean).
- **`collision_damage`** — damage scaled by target **terrain hardness / occupant**.
- **`chain_push`** — the blocking unit is displaced too (cascade).
- **`force_onto_invalid`** — place the unit on **normally-illegal terrain** (the sanctioned override of
  `[DSP-15]` inv. 3 — e.g. knock a foot unit into deep water → stranded + subject to that tile's
  on-entry effects). This is the deliberate environmental-kill / ring-out lever.
**Harmful-consequence relationship gate (owner 2026-06-25g):** the **harmful** outcomes —
`collision_damage` and `force_onto_invalid` — apply **only where the actor↔affected-unit relationship
permits aggression** (`[STY-17]`: the unit is `hostile` to the actor, or the effect explicitly enables
friendly fire). **Pure-positional** displacement onto a *valid* tile is relationship-agnostic (you may
reposition allies/neutrals). So an auto-succeed Shove may slide a `neutral`-faction unit one tile but
**cannot** route it off a cliff; a knockback sword targeting a `hostile` enemy can. See the worked
examples under `[DSP-17]`.
**Build staging:** v1 ships **`fail`** only; the other three reserved as opt-in author outcomes.

### [DSP-15] Framework invariants — **RESOLVED**
The shared contract every non-standard position change obeys: (1) **atomic & discrete** (between
actions, never mid-path); (2) **action-economy neutral** (neither spends nor restores the moved unit's
action — the engine's *teleported-but-still-READY* state; carried unit costs nothing); (3) **destination
default-valid for the moved unit, author-overridable** only via `[DSP-14]` `force_onto_invalid`;
(4) **forced entry == normal entry** for tile consequences (on-entry terrain applies; action-gated
Seize/Escape never auto-fire); (5) **phase-agnostic mechanic**, off-turn invocation author-gated and
non-interrupting (`[DSP-12]`); (6) **undo parity** (own pre-confirm displacement undoes like a move; an
opponent's forced movement of your units does not).

### [DSP-16] Preview & RNG surface — **RESOLVED (lean)**
The **effect-forecast preview** (`[STY-10]`) shows a `displace`'s outcome like any effect: the
destination/footprint, plus — when configured — the **resistance result** (immune / stat-contest
outcome) and the **accuracy %** (`[DSP-13]` stage 3). Determinism: stages 1–2 are pure; only the
accuracy roll consumes `RngService`, so most displacement is replay-deterministic without an RNG draw.

### [DSP-17] Campaign-default rules + per-source overrides — **RESOLVED**
(owner 2026-06-25g) The **entire** displacement ruleset — every resistance stage (`[DSP-13]`), every
invalid-destination outcome (`[DSP-14]`), off-turn eligibility (`[DSP-12]`), and accuracy — is expressed
as **`CampaignRules` displacement defaults** that any **effect source may override per-rule**. An author
sets sane campaign-wide defaults once; individual sources opt into spicier behavior. **Resolution
order:** per-source `EffectSpec` override → `CampaignRules` displacement default → framework default
(`[DSP-15]`). Every rule is independently overridable (no all-or-nothing).
- **Worked example A — knockback sword (hostile target).** Authors `accuracy: weapon_hit`,
  `stat_contest: Str_vs_Con`, `on_invalid: [force_onto_invalid]`, `target_filter: enemy`. Result: when
  it **hits** and the wielder's **Str > defender's Con**, it can shove a `hostile` enemy **off a cliff**
  (lethal via the `[DSP-14]` gate — permitted, target is hostile).
- **Worked example B — Shove action (cooperative).** Authors `accuracy: auto`, `resistance: none`,
  `target_filter: ally|any`. It auto-succeeds positionally — but the **harmful** `force_onto_invalid`
  outcome is **gated by relationship** (`[DSP-14]`), so it **cannot** shove a **non-aggressive
  (`neutral`/`allied`) faction member off the same cliff**; it can only relocate them to a valid tile.
- The default set + per-source overrides are **data-def** (`CampaignRules` + `EffectSpec`), **not save
  state**.

### Forward-pinned — "Capture" victory type + `captured:<id>` story flag (owner 2026-06-25g)
Compose a new **`ObjectiveCondition.type` = `capture`** ("escape with prisoner"): like `escape`, but the
escaping unit(s) must be **carrying a captured prisoner** (the `[DSP-5]` carry state) — on satisfaction
the prisoners are extracted to the roster/jail. On each prisoner secured/extracted, set an **F6 flag
`captured:<unit_id>`** that **MET (A4)** story events and **bonus-chapter** unlock conditions branch on.
**Ownership:** composes `[DSP-5]` (carry) + the **objective system (M16, `ObjectiveCondition`/
`TurnManager.check_victory_conditions`)** + `[RCR]` (roster capture) + **F6** flags + **A4** (story
branching). **Pin:** firm the objective `type` with the objective-system build; firm the flag + story
hooks with **A4**. **Reserve the `captured:<id>` flag at the F1 lock** (see `[DSP-11]`).

### Forward-pinned — death-inventory disposition rule set (surfaced by `[DSP-14]`)
`[DSP-14]` `force_onto_invalid` can **kill a unit out of combat with no clear killer** (shoved into a
chasm), which raises: *what happens to its inventory / Key Items?* This is **not** a displacement
ruling — it is an **optional `CampaignRules` death-inventory profile** owned by **A5** (permadeath path;
modes `to_convoy`/`lost`/`drop_on_tile`/`transfer_to_killer`; Key-Item locks `[CEX-14..16]` override to
never-`lost`; a single `handle_death` disposition path for all death causes). **Now RESOLVED** as
`registers/death_inventory_disposition_open_questions_2026-06-27.md` `[DTH-1..12]`: the `[DSP-14]`
ring-out is a no-clear-killer death cause → the recipient link fails and the item walks to the next
chain link (`[DTH-7]`), resolved under snapshot-then-resolve ordering (`[DTH-8]`). **Full pin + edge-case
list** in `plans/feature_dependency_atlas_2026-06-23.md` (A5 bullet, 2026-06-25h).

## 6. Save / F1 reservations  *(reserve at the Phase-B lock)*
### [DSP-11] — **[RESERVE — confirmed 2026-06-27d, carried to the Phase B F1 lock]**
- **`carrier_id` / `carried_id` pointer pair** per unit (mirrors the Pair-Up partner pointer) + the
  `CarryRegistry` snapshot.
- **Captured/jail state** — coordinate the reserve with `[RCR]` (roster) + `[STY-6]` `sleep` + **F5**
  conditions + the `[STY-12]` active-conditions reserve (don't double-reserve `sleep`).
- **`captured:<unit_id>` F6 flag(s)** — set on prisoner extraction; consumed by **A4** story events +
  bonus-chapter unlocks (the "Capture" victory type, see `[DSP-17]` forward-pin). Reserve with the F6
  flag store; coordinate ownership with `[RCR]` + A4.
- The **`displace` EffectSpec** + the `[DSP-17]` campaign-default/override set are **source/style
  data-def, not save state** (like `[STY]` `effects`).

---

## Out of scope for DSP (other A2 sub-clusters)
- **Dancer / refresh (#8)** + the M10 `grant_extra_turn` substrate → the **A2 action-grant** pass.
- **Battalion entity (`[STY-11]`)** — data model, endurance, passive `StatContributions`, leveling,
  adjutant/pair-up variant → the **A2 battalion** pass.
- **A1 leans pointing at A2:** `[STY-8]` battalion action-economy edge-cases, `[STY-17]`
  counter-vs-stance → settle with the relevant A2 sub-cluster (battalion / action-grant).

## Notes
- **A1 amendment (DSP-7):** A1's `[STY]` `EffectSpec.kind` enum gains **`displace`**. Note it against
  `[STY-16]` (multi-effect combos) when DSP graduates, so the A1 build picks it up.
- **DoD (at build):** GDD_02 (combat/displacement) + GDD_05 (skills/`StyleDef`/effect kinds) + the
  carry/rescue UX, the `CampaignRules` carry profile (F4), `DisplacementService` + `CarryRegistry` +
  tests, and the GDD_10 roadmap status flip — all **with the build**.
- **Forward-ward (`[HEX-9]`, 2026-06-27):** shove/swap/pivot/carry directions must be **sourced from
  the geometry seam** (`GridManager`'s neighbour accessor), **not** a hard-coded 4-way `Vector2i`
  literal. Hex topology is a parked future option (`registers/grid_topology_hex_open_questions_2026-06-27.md`);
  a 4-way literal here would silently foreclose it. Costs nothing now, preserves the option.
- **Cross-refs:** `[RCR-5]` capture-carry (settled here) · `[STY-6]` `sleep` · `[STY-9]` AoE/direction
  vocab · `[STY-10]` effect-forecast preview · `[STY-16]` EffectSpec set · `[STY-17]` relationship
  matrix / `target_filter` · `[SMV]` F10 window · Pair-Up (`PairUpRegistry`, `OFF_MAP_TILE`) · F4
  `CampaignRules` · F5 `ConditionManager`.
