---
Type: design
Status: Ratified — owner decisions 2026-08-01; implementation Target design
Last verified: 2026-08-01
Tracker: DESIGN-MOVEMENT-PATH-PASS-THROUGH-2026-08-01
---

# Position-Change Model — Movement Interrupts, Crossings, and Displacement

**Held:** 2026-08-01, directly after the terrain authoring discussion, once `[TER-7]`
revealed that terrain was the third claimant on a seam two other ratified features
already needed. The owner pulled the displacement primitive (Warp/Rescue staves,
shove/knockback) into the same conversation.

**Scope.** How a unit's position changes, what may observe it mid-change, and what
interrupts it. Supersedes nothing; it *reconciles* `[FOW-4]`, `[PER-8]`, `[TER-7]` and
the `[DSP]` contract, which had grown into each other's territory while all four were
unbuilt.

---

## The organising split

Every position change is one of two shapes, and almost every disagreement between the
four sources came from treating them as one:

| | **Continuous** | **Discrete** |
|---|---|---|
| What | An ordinary pathed move | A displacement |
| Examples | Walking, `[SMV]` second window | Warp, Rescue staff, shove, swap, pivot, knockback, blink |
| Intermediate tiles | **Yes** — the path crosses them | **No** by default — one destination is computed |
| Needs the crossing seam | Yes | Only when the source declares traversal (`[PCM-4]`) |
| Governing contract | This document | `[DSP-1..17]`, unchanged |

`[DSP]`'s pipeline computes **one** destination tile (`mode: push/pull/swap/to_side/
blink`, plus `distance`) and calls `DisplacementService.relocate(target, dest)`. There
is no traversal in it today. That is why warp and rescue never needed the seam, and why
the contradiction below was never really about them.

## The contradiction, and what it actually was

`[PER-8]` `on_cross` — a unit crossing a masked unit's tile springing a reactive
trigger, the register's own *"bait into traps"* case — instructs that it reuse
`[DSP-12]` and the reaction-family surface, ***"not a bespoke movement hook."*** But
`[DSP]` invariant 1 says a non-standard position change *"happens between actions,
**never mid-path**."* `[PER-8]` asks `[DSP]` to do the one thing `[DSP]` excludes.

**An earlier draft of this analysis (same day) claimed a broader three-way
contradiction, citing `[DSP-12]` as "non-interrupting" against `[FOW-4]`'s ambush
interrupt. That was wrong and is retracted.** `[DSP-12]`'s exact scope is that off-turn
displacement *"never interrupts an **in-progress exchange** … never cancelling an attack
or denying a counter mid-exchange (the combat exchange stays atomic)."* It governs
combat exchanges, not movement paths. `[FOW-4]` and `[TER-7]` were never in conflict
with anything — they both need a capability that does not exist. That is a gap, not a
disagreement, and separating the two is what made this tractable.

---

## Decisions

### [PCM-1] One crossing resolver serves every continuous position change — **RESOLVED**

There is exactly one mechanism that detects "a unit entered/crossed tile T mid-move"
and runs whatever is registered against it. `[FOW-4]`'s ambush reveal, `[TER-7]`'s
pass-through terrain triggers, `[PER-8]`'s `on_cross`, and a traversing displacement
(`[PCM-4]`) are all **consumers** of that one resolver.

Whoever builds first owns it; nobody builds a second. In practice that means fog
Slice 3, which is the first scheduled work that would create it — and which is
consequently larger than its plan estimates.

### [PCM-2] `on_cross` lives on the crossing resolver; `[DSP]` stays the consequence — **RESOLVED**

The **trigger** moves to the crossing resolver, where the crossing actually happens.
The **resulting displacement** still resolves through `DisplacementService` exactly as
`[PER-8]` intended.

This honours what `[PER-8]` was actually protecting — *no bespoke collision code, no
parallel system* — without asking `[DSP]` to fire mid-path. `[DSP]` invariant 1 stays
intact and unamended: the displacement it performs is still atomic, discrete and
instant. Only its *trigger* is upstream.

`[PER-8]`'s "not a bespoke movement hook" is therefore honoured in substance: the
resolver is not bespoke to perception, it is the shared seam three other features use.

### [PCM-3] The crossing resolver is logical, not animation-driven — **RESOLVED (forced)**

Not really a choice — three separate constraints force it:

- `Unit.move_along_path` assigns `tile_position = path[-1]` **before** animating, so the
  tween loop commits no logical state per step;
- at Instant movement speed (`_get_per_tile_seconds() <= 0`) the function calls
  `snap_to_tile` and **the loop never executes**, so anything hung off the tween would
  silently not fire for those players;
- AI moves and replay/determinism must resolve identically to animated player moves.

So crossing detection resolves over the **path as data**, before or independently of
animation, and the tween becomes a presentation of an already-resolved sequence. Any
design that hooks the tween is wrong for at least one of the three reasons above.

**This is the single largest piece of work in the model**, and it is what `[FOW-4]`'s
plan under-estimated.

### [PCM-4] Displacement traversal is author-declared, and REQUIRED — **RESOLVED**

A `displace` source declares `traversal: traverse | teleport`. There is **no default**;
omitting it is a validation error.

- `teleport` — the current pipeline: compute one destination, relocate, on-entry effects
  at the destination only. A 3-tile knockback across a bog does not touch the bog.
- `traverse` — the displacement resolves through the `[PCM-1]` crossing resolver, so
  each crossed tile's triggers fire and `[PCM-5]`/`[PCM-6]` apply.

**Why "required" rather than a default.** Nothing authors a displacement yet — warp,
rescue and shove are entirely unbuilt (a grep finds only a `MoreInfoContent` string
mentioning rescue). So making it mandatory costs nothing now, and it is the one moment
where that is true. A default would be inherited silently by every source authored
later, and the two behaviours differ enough to be a real bug when wrong (a "drag"
effect that should scrape its victim across hazards vs a "blink" that should not).

Consistent with `[DSP-17]`'s source-override philosophy, but stricter: this one is not
merely overridable, it must be stated.

### [PCM-5] A crossing trigger declares `interrupt: halt | continue`; halt is the default — **RESOLVED**

- `halt` — the move ends on the triggering tile. `[FOW-4]`'s ambush **requires** this.
- `continue` — the effect resolves and the unit keeps moving (a bog that damages as you
  wade through).

**Halt is the default** because the failure mode matters: a trigger that forgets to
declare stops the unit visibly rather than silently applying an effect the player never
saw. In a system whose legibility is already deferred to `B3-REFERENCE-MODEL`
(`[TER-8]`), the safe default is the one that cannot hide.

### [PCM-6] The trigger also declares whether a halt ends the activation — **RESOLVED**

A second, independent axis: a halted unit may still act, or may be done. An ambush
reveal and a bear trap are different events and should not be forced to agree.

Both axes belong to the trigger, so `[PCM-5]` and `[PCM-6]` compose:
`{interrupt: halt, ends_activation: false}` is the FE ambush; `{interrupt: halt,
ends_activation: true}` is a disabling trap; `{interrupt: continue}` is a hazard toll.

### [PCM-7] A fired mid-path effect makes the movement permanent; Rewind is unaffected — **RESOLVED**

Three separate things, deliberately separated:

1. **Pre-confirm undo** — the moment a crossing trigger resolves an effect, the movement
   is **permanent**. It cannot be taken back with the free pre-confirm undo. This is
   what stops undo becoming a zero-cost scouting tool for hidden traps and ambush
   positions, and it means no crossing effect has to be invertible.
2. **Rewind** — unchanged and unrestricted. **Rewind charges can rewind anything**,
   including this. The permanence above is a property of *free* undo, not of the
   charge-based persistence model, which already prices what it re-lives.
3. **The action** — decided by the trigger, per `[PCM-6]`, not by the fact that an
   effect fired.

**Secondary movement may still trigger.** A halted unit with `[SMV]` gets its second
window normally. This composes better than expected with `[SMV-2]`'s `"remaining"` mode,
whose budget is `move_stat − path_cost_spent_to_reach_the_action_tile`: because a halt
stops the unit *early*, the spent cost is lower, so the remainder is larger. A unit
ambushed two tiles into a six-tile move keeps four tiles of second-window movement. That
falls out of the June design without amendment.

**Perception-pathing closure (owner 2026-08-30, `[PER-16]`).** A discovered tile or object
may explicitly grant that `"remaining"` secondary-movement window as a temporary effect.
This is the forgiving alternative to rolling movement back: the discovery, traversed cost,
position, and any resolved effect remain permanent under this rule, while the player chooses
a fresh route from the resolved tile. The grant rides the open `[SMV]` effect seam rather
than adding a perception-specific crossing type. It does not apply if the outcome ended the
activation or left the unit dead or unable to move; a tile the unit was forbidden to enter
does not count toward spent movement.

Note this also makes `undo_move`'s current behaviour — snap back to `_original_tiles`,
unwind nothing — **correct as far as it goes**, provided it is prevented from running at
all once an effect has fired. The bug would be leaving it available.

---

## Consequences to carry into implementation

**Derived, not separately decided:**

- **A re-crossed trigger re-fires according to `[TER-4]`.** If a `[SMV]` second window
  re-crosses a tile whose trigger already fired: a **terrain** trigger is type-level and
  stateless, so it fires again (wading back through the bog hurts again); a **one-shot
  map_object** trap carries per-instance sprung state, so it does not. The
  terrain/`map_object` boundary produces the right answer without a new rule — good
  evidence for `[TER-4]`.
- **`[DSP]` invariant 4 already covers the discrete case.** *"Forced entry == normal
  entry for tile consequences … on-entry terrain effects apply; action-gated objectives
  (Seize/Escape) never fire from being placed."* A warp onto a hazard triggers it; a
  warp onto an Escape tile does not auto-escape. Unchanged by anything here.
- **The displacement design doc already assumed hazard tiles exist** — *"Shoving a foe
  into a fire tile burns them — a real tactic"* — written in June, when terrain had no
  effect surface at all. `[TER-6]` is what makes that worked example true.

**Still open, and deliberately not decided here:**

- **Preview for a traversing displacement (`[DSP-16]`).** The effect-forecast preview
  shows a destination today. A `traverse` source needs to preview a *path*, and to show
  which crossed tiles would trigger. Not decided.
- **`chain_push` and AoE ordering under traversal (`[DSP-15]` clause 7).** Multi-unit
  displacement resolves farthest-from-origin first so destinations vacate in order. With
  traversal, each unit's crossing sequence must interleave with that ordering. Not
  decided.
- **Whether a halted displacement (a `traverse` knockback stopped by `[PCM-5]`) counts
  as `fail` for `[DSP-14]`'s destination handling**, or as a successful partial move.
  Not decided.

## What this does not change

`[DSP]` invariants 1–6 are all intact and unamended. `[DSP-12]` keeps its exact scope
(in-progress combat exchanges). `[FOW-4]` A-full is unchanged and now has a defined seam
to build against. `[PER-8]`'s intent is preserved; only the location of its trigger
moves.
