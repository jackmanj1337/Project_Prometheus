---
Type: design
Status: Ratified — owner decisions 2026-08-01; implementation Target design
Last verified: 2026-08-01
Tracker: DESIGN-TERRAIN-AUTHORING-2026-08-01
---

# Terrain Authoring — Owner Decisions

**Held:** 2026-08-01, immediately after the Tier-2 terrain family landed and the
zero-content families branch merged forward onto the docs line.

**Why then.** Three of the questions below would change the terrain schema that had
just shipped. Answering them after another family landed would have meant editing a
closed vertical.

This document records decisions and the measured state behind them. It authorizes no
implementation by itself; each decision names the track that builds it.

---

## The frame that changed the discussion

The discussion opened on "should terrain define behaviours" and split almost
immediately, because **behaviour** turned out to be two unrelated things:

- **Player-initiated ACTIONS** — a menu entry the player selects (Seize, Visit, Shop,
  Activate). Authority here was already settled, twice, and terrain is not it.
- **Passive and triggered EFFECTS** — things that happen to a unit because of where it
  is standing (healing, defence, poison, a stat boost). Terrain already owns this
  category; `heal_fraction` is the proof.

Conflating them is what made the original question look like one decision. It is two,
and they resolve in opposite directions.

---

## Measured state (2026-08-01, survey — verify before relying on any line)

### Rendering is a four-way lock

`scripts/tools/generate_tilesets.gd` writes one `TileSetAtlasSource` per terrain with
`source_id == terrain index`, stamping a `terrain_type` custom-data string on each.
`GameMap._paint_terrain` resolves grid char → terrain id → `tile_source_id` →
`set_cell`. `GridManager.get_terrain_at` then reads the terrain **back off the painted
tile's custom data** — not off the grid char.

So grid char, terrain id, tile source and stat block are one indivisible thing, and
runtime identity round-trips through the tileset. This is the constraint every
rendering decision below has to clear.

### Labelling does not reach the player

`HUD._update_terrain` sets the panel title with `terrain.capitalize()` — the **id**.
`TerrainRegistry` stores a `display_name`, admits it as an authorable field, and has
**no accessor for it**; nothing reads it. A pack retuning `display_name: "Deep Wood"`
gets a tile labelled "Forest". The family's own test asserts the retune reaches the
registry, which is true and is also the entire distance it travels.

### A seventh table survived the consolidation

The terrain family folded six baked engine tables into `TerrainRegistry`.
`MoreInfoContent.TERRAIN` is a seventh: a hardcoded description dictionary keyed by
terrain id, which describes `village`, `throne` and `river` — none of them registered
terrains. It is stale and closed.

### The one existing effect beyond def/avoid/move is invisible

`heal_fraction` appears nowhere in the HUD. The only thing that ever tells a player a
fort heals is a hand-written sentence in that seventh table — "slow HP recovery each
turn" — which is prose, not derived from the number. Retune fort's healing and the
sentence does not change; give a shrine healing and nothing is said at all.

**This is the finding that shaped the effects decisions.** Adding bogs and stat boosts
on the same pattern would have made them invisible the same way.

### Seize and escape are not terrain-gated, and never have been

`TurnManager.can_seize` is a three-way gate: the map's objective condition names an
explicit `tile`, the unit's alliance group must match the condition's group, **and**
`unit.data.can_seize` must be true. Terrain is not consulted at any point.
`can_escape` additionally requires the condition to name `unit_ids`; an escape
condition with an empty unit list can never surface the button.

A throne tile grants Seize because the map named that coordinate — not because it is a
throne. Moving this onto terrain would relocate authority, not expose something that
already exists, and it would break the legitimate case of a seize point on ordinary
ground.

### The action authority was already ratified twice

- `[DCH-2]` (2026-06-21, owner override) — ONE unified `MapData.map_objects` model
  holds doors, chests, levers and stationary weapons.
- `[SAC-1]` (2026-06-27) — generalised it: shops, villages, panel triggers and arenas
  are `map_objects` with an `activate` behaviour. *"No parallel system."*
- `[VIL-1]` — a village is not a system; it is a destructible `map_object` carrying a
  Visit trigger.
- `B4-MAP-OBJECTS` step 4 already plans to *replace* the placeholder `TileActions`
  shop/visit/activate path with component-provided action records.

So `TileActions.gd`'s closed `match` is not waiting on a terrain decision. It is
already scheduled for replacement by the map-object component model.

### Movement has no per-step model

`Unit.move_along_path` sets `tile_position = path[-1]` **before** animating, and emits
`unit_moved(origin, destination)` once at the end. Intermediate tiles are tween
segments and nothing else; at "Instant" movement speed there are no segments at all.
The path is an animation detail, not game state. `undo_move` snaps back to
`_original_tiles` and clears state, unwinding nothing else.

### Status conditions are a stub

`ConditionManager` names poison, sleep, silence, berserk and stun, and every method is
a no-op marked `[STUB — M8]`.

---

## Decisions

### [TER-1] Decorative variants — split art identity from stat identity — **RESOLVED**

A grid char maps to a **variant**; the variant names its `terrain_id` and carries its
own art and label. The stat block lives on the terrain, shared by construction rather
than by convention.

The tileset's `terrain_type` custom data keeps carrying the **terrain id**, so
`GridManager.get_terrain_at` and every id-matching consumer (AI scoring, tests, tags)
are unchanged — which is what makes this cheaper than the alternatives.

```
terrain "fort":              # the stat block
  def_bonus: 2, avoid_bonus: 30, heal_fraction: 0.1

variant "throne":
  terrain: "fort"            # shares the stats
  grid_char: "H"
  display_name: "Throne"
  tile_asset_id: "throne_tile"
```

**Rejected:** variant-inherits-from-base (`extends: "river"`), because each variant
would be a distinct `terrain_id` at runtime and every id-matching site would have to
resolve an inheritance chain. **Rejected:** no variant layer, because hand-synced
duplicate stat blocks are the drift the six-table consolidation just removed,
reintroduced one layer up.

**This answers `RULE-011` / `AWR-8`** (terrain ID mapping, open since 2026-06-13):
throne is a variant of fort, and the sea / wall-building variants resolve the same
way. The GDD's standing instruction — "resolved by a mapping pass, not name equality"
— is exactly what a variant layer implements. Close `RULE-011` when this builds, not
before.

### [TER-2] A pack may INTRODUCE terrain — **RESOLVED**

The v1 boundary (a pack retunes terrain but cannot introduce it) is lifted. `GameMap`
builds `TileSetAtlasSource`s from the pack's approved media at activation instead of
using only the pre-generated `terrain_tileset.tres`, stamping `terrain_type` custom
data per source.

**Gate:** this is a rendering change. Tile sizing and atlas regions are visual
correctness, so it requires a Windows visual pass, which the container cannot provide.
Do not mark it done on a headless green suite.

Note this is the same machinery `[TER-1]` needs — a variant requires its own tile
source — so the two build together rather than twice.

### [TER-3] Terrain does not own player-initiated actions — **RESOLVED**

`[DCH-2]` and `[SAC-1]` stand. Actions belong to `map_objects`. Terrain is not made a
third authority over them, and `TileActions`' closed `match` is converged by
`B4-MAP-OBJECTS`, not by terrain.

Seize and escape stay resolved against the map's objective conditions. A seize point
on ordinary ground remains legal.

### [TER-4] The terrain / map_object boundary is per-instance state — **RESOLVED**

> **Does it need per-tile state in the save?**
> **No** → terrain. Type-level and stateless: every tile of that type behaves
> identically, forever.
> **Yes** → `map_object`. Per-instance, individually addressable, owns a row in
> `map_objects_state`.

This is checkable rather than a matter of taste, and it already matches every ratified
case: doors (open/locked), chests (looted), villages (visited/razed) and ballistas
(ammo) all carry state; move cost and `heal_fraction` do not.

Its sharpest consequence: **a reusable hazard is terrain; a one-shot sprung trap is a
map_object.** The same fiction lands on either side depending on whether it remembers
what happened to it.

**Rejected:** passive-vs-player-initiated, because it puts a one-shot trap on terrain,
which then needs per-tile state terrain has no home for. **Rejected:** ground-vs-thing
-on-it, because it gives no verdict on a bog or a pit — the exact cases that prompted
the question.

### [TER-5] A map_object may override or modify terrain's passive stats — **RESOLVED**

The component contract already lets `passability_provider` do a terrain override for
movement. That is extended to passive stats through an explicit component, and it
carries **both** semantics:

- **override** — replace the terrain's value (a road is a flat 1 move cost);
- **modifier** — adjust it (a road is −1 move cost).

Both are needed: a road over varied terrain wants a flat cost, while a road that keeps
the terrain's character wants a delta. Precedence is declared once (object override >
object modifier applied to terrain > terrain) rather than inferred per call site.

This is what makes a bridge over a river read correctly instead of inheriting the
river's avoid bonus.

### [TER-6] Terrain's effect surface — design now, build behind the primitive convergence — **RESOLVED**

The shape is settled here; implementation is **deliberately not** scheduled yet.

Two generalisations are in scope when it builds:

1. **Phase effects.** `_begin_phase(units)` already does exactly three things: tick
   modifiers, `_apply_fort_healing`, fire start-of-turn skills. Healing is already
   generic. Replace the single `heal_fraction` field with a list of phase effects, so
   a poison bog is the same mechanism with the sign flipped rather than a new one.
2. **Stat contributions.** `terrain_bonuses_for` returns a hardcoded
   `{"def": …, "dodge": …}` with four consumers — the same closed-shape smell as the
   six tables, smaller. Terrain becomes a source in the existing stat-contribution
   pipeline, and def/avoid stop being special cases.

**Why it waits:** built now, terrain effects would become a **sixth** unconverged
dispatch table. `ARCH-ONE-PRIMITIVE-LIST-2026-08-01` (owner decision 2026-08-01, "one
list of primitives in the engine by v1") already names five, plus `SkillHandler`, and
is scheduled downstream of B5 Slice 4. Terrain effects register as primitives on that
substrate from day one instead of being converged later.

**Blocked separately:** an effect that *inflicts a condition* (a bog that poisons,
rather than one that merely damages) needs `ConditionManager`, which is a stub until
M8. A damaging bog does not.

### [TER-7] Traps split by trigger point — **RESOLVED**

- **Step-on (destination) triggers are in scope for the MET / `B4-MAP-OBJECTS` build.**
  `[MET-2]` resolved that further triggers arrive as "thin adapters over existing
  `EventBus` signals", and listed `unit_reached_tile` as a candidate. `unit_moved`
  already fires on arrival, so this genuinely is thin. It covers bogs, pressure plates
  and most traps.
- **Pass-through triggers are a separate tracked row**, because they are not thin.
  They require the movement path to become a resolved, interruptible sequence with
  explicit halt-versus-continue semantics; identical behaviour at Instant speed and
  under AI; and `undo_move` / Rewind unwinding effects that fired mid-path. That is a
  movement-model change and deserves its own decision rather than riding terrain.

#### The pass-through seam is shared with fog-of-war and perception — added 2026-08-01

Terrain is the **third** claimant on this seam, not the first. Three other ratified
sources already depend on it, and they do not agree with each other. Whoever builds
first owns the seam; nobody should build a second one.

1. **`[FOW-4]` — RESOLVED 2026-06-21j to "A-full": per-step mid-tween visibility
   recompute *with ambush interrupt*.** A move **halts on the exact step** that brings
   a previously-hidden enemy into view. `band6_fog_of_war_implementation_plan_2026-07-03.md`
   makes this **Slice 3**, names `scripts/units/Unit.gd` `move_along_path` as the file
   to touch, and calls it *"the one piece of real v1 complexity."*
2. **`[PER-8]` `on_cross` — RESOLVED.** A unit moving *across* a masked unit's tile may
   spring a reactive trigger; the register names the **"bait into traps" use-case
   explicitly**. Its instruction: reuse the reactive/off-turn displacement path
   (`[DSP-12]`) and the reaction-family event surface, ***"not a bespoke movement
   hook."***
3. **The `[DSP]` shared contract** — which `[PER-8]` routes `on_cross` into — states
   that every non-standard position change is *"**atomic & discrete** (between actions,
   **never mid-path**)"* (clause 1) and that off-turn invocation is
   *"**non-interrupting**"* (clause 5).

**The contradiction.** `[PER-8]` sends an inherently **mid-path** event into a
framework whose own contract says **never mid-path** and **non-interrupting**, while
`[FOW-4]` requires an **interrupt**. All three cannot hold. Reconciling them is the
substance of `DESIGN-MOVEMENT-PATH-PASS-THROUGH-2026-08-01`, and it should be settled
before FOW Slice 3 builds — not after, when one interpretation is already in code.

**Corroboration for `[TER-3]`/`[TER-4]` from an independent source.** `[DSP]` clause 4
says *"forced entry == normal entry for tile consequences (**on-entry terrain
applies**; **action-gated Seize/Escape never auto-fire**)."* That is the same
action/effect split reached here, ratified separately in June: terrain consequences are
automatic, actions stay gated. It is good evidence the split is the project's settled
model rather than this discussion's invention.

**A measured correction to the FOW plan's premise.** Its Slice 3 says to build "against
the existing per-step movement loop" and cites `move_along_path` l.559-564 as "the
per-step tween loop". Measured 2026-08-01:

- the anchors have drifted (the function is now at l.561, the loop at l.575-579);
- `tile_position = path[-1]` is assigned **before** the loop, so the loop commits **no
  logical state per step** — there is no per-step point to hook, only tween segments;
- at Instant movement speed (`_get_per_tile_seconds() <= 0`) the function calls
  `snap_to_tile(path[-1])` and returns — **the loop never executes at all**.

So FOW Slice 3 is larger than "hook the existing loop", and as specified the ambush
interrupt would **silently not fire for any player using Instant movement speed** — a
settings-dependent behaviour difference in a ratified v1 slice. Flagged here because
this discussion is what measured it; the fix belongs to whoever builds the seam.

### [TER-8] Player-facing expression is owned by the generated reference model — **RESOLVED**

Terrain effects and tile actions do **not** get a bespoke per-effect display block.
Player-facing expression is handled by the semantic label / reference-fact generator
already planned in `B3-REFERENCE-MODEL`
(`generated_reference_model_implementation_plan_2026-07-30.md`), which already scopes
"terrain costs/bonuses/actions/restrictions" and "generate costs, bonuses,
requirements, consequences, and selected-unit availability from the same
terrain/action registries".

That plan's definition of done applies to terrain effects directly:

> Adding an author-extensible rule or effect is not done until its registered handler
> can validate its parameters and emit structured reference facts with safe provenance.

This is a stronger guarantee than a display block, because it binds the **handler**
rather than the data, and it is why `[TER-6]` does not invent a presentation surface.

**Scope boundary:** `MoreInfoContent.TERRAIN`'s deletion belongs to
`B3-REFERENCE-MODEL`, which gates it behind parity fixtures (plan line 298). Do not
delete it as part of a terrain change.

### [TER-9] Tile-action discovery is deferred to the map-object build — **RESOLVED**

`[VIL-6]` ratified the descriptor model — `TileActions` becomes
`{id, available, requirement, hidden}` and More-Info lists every non-hidden entry with
its requirement text ("Seize — requires Lord"). It is **not built**;
`TileActions.is_available() -> bool` is still exactly the shape VIL-6 described as the
"before".

Building it lands with `B4-MAP-OBJECTS`, which has to touch `TileActions` anyway to
replace the placeholder path with component-provided action records.

**Recorded so it is not lost:** the current readout is strictly worse than the
ratified target in three ways — `HUD._format_tile_actions` returns empty when no unit
is selected, lists only actions the selected unit can *already* perform, and shows no
requirement text. A throne the player is not eligible to seize displays nothing at
all.

### [TER-10] The `display_name` gap is fixed now, narrowly — **RESOLVED**

Add a `TerrainRegistry.display_name()` accessor and point `HUD._update_terrain` at it,
so the authored field reaches the player and `[TER-1]`'s variant labels have somewhere
to land.

**Explicitly out of scope:** the description strings and the retirement of
`MoreInfoContent.TERRAIN`, which `[TER-8]` assigns to `B3-REFERENCE-MODEL` behind its
parity fixtures.

---

## Consequences for the shipped terrain schema

`[TER-1]`, `[TER-2]` and `[TER-6]` all change the schema the terrain family shipped on
2026-08-01, which is why this discussion was held before the next family:

- `AUTHORABLE_FIELDS` gains a variant layer and, later, effect lists.
- `tile_source_id`'s exclusion (`"engine identity, not authored content"`) is
  **superseded** by `[TER-2]`: a pack that introduces terrain necessarily supplies its
  own source. The reason the field was excluded — an unpaintable terrain painting as
  `wall` with no diagnostic — still holds, so the replacement must fail validation
  when a terrain's media does not resolve, rather than silently falling back.
- `heal_fraction` becomes one entry in a phase-effect list rather than a field.

None of these are urgent. They are the reason the next terrain change should be
`[TER-1]` + `[TER-2]` together, rather than another family first.

## What was NOT decided

- Whether variants may differ in anything beyond art and label (they may not, today —
  that is what "shares the stat block" means, and widening it re-opens `[TER-1]`).
- The pass-through trap movement model (`[TER-7]`, tracked separately).
- Anything about fog, perception, or destructible terrain, which ride
  `map_objects` and are owned by their own registers.
