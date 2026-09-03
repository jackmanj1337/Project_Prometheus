---
Role: dated
Type: register
Status: RESOLVED 2026-06-27
Last verified: 2026-06-27
Register: DTH-1..12
Resolved-in: 2026-06-27d
---

# Death-Inventory Disposition Rule Set (A5 keystone) — Player-Facing Design + Open Questions

> **Reconciled 2026-08-29 by DRC Slice 0:** map-end prisoner disposition is part of the one
> staged map-end transaction and references the inventory-transfer ledger rather than copying it.
> Residual equipment moves item by item after filtering protected/key items; capacity overflow goes
> to the pending-items tray and must not abort otherwise-valid map-end resolution.

**Started:** 2026-06-27 (session 2026-06-27d). **First and keystone sub-cluster of A5 —
Campaign meta-rules & EXP/economy** (the last design cluster before the F1 schema-lock, Phase B).
Walked end-shape-first per the feature-walk method. Branch `docs-reorg-2026-06-23`.

**Thesis.** When a unit dies, *something* must happen to its carried + equipped inventory. This
register firms an **optional `CampaignRules` profile** governing that, routed through **one
disposition step that every death cause funnels through** — so combat death, condition/poison ticks
(F5), hazard terrain, the `[DSP-14]` `force_onto_invalid` ring-out, and scripted/event death all share
a single, testable path rather than each growing its own inventory handling. Design-capture only;
nothing built (the convoy `[CNV]` this leans on is itself designed-but-unbuilt). Legend: **[OPEN]** /
**[ASKED]** / **[RESOLVED]**.

---

## Substrate reality (verified in code this session)

- **`Unit.handle_death()` (`scripts/units/Unit.gd:488`) has NO inventory step today.** It flags
  `data.is_incapacitated` if permadeath is on, releases pair-up support, unregisters from `GameState`,
  emits `unit_died`, and `queue_free()`s the node. The `data.inventory` simply dies with the unit
  (preserved on `data` only when permadeath is off). **Disposition is greenfield — A5 *adds* the step.**
- **Convoy does not exist in code yet** (`[CNV-1..7]` is design-firmed 2026-06-23k, unbuilt). Every
  "no item loss" mode reserves a build-time dependency on the convoy build (Phase C ordering note).
- **The snapshot-then-resolve shape already exists in miniature.** `CombatResolver` applies all
  exchange HP, *then* derives deaths from final HP, *then* calls `handle_death` **defender-first so kill
  credit stays with the attacker** (`scripts/core/CombatResolver.gd:779–807`). DTH-8 generalizes this
  existing pattern; it is not a new invention.

---

## The model (the spine all items hang on)

**Disposition = an author-ordered fall-through CHAIN of links, walked per-item.** Each item the dead
unit carried independently walks the chain; the **first link that can accept it wins**. Link types:

| Kind | Links | Resolves to | Can fail? |
|---|---|---|---|
| **Recipient** | `transfer_to_killer` · `nearest_ally` · `main_character` | a unit (with inventory space) | yes → next link |
| **Placement** | `to_convoy` · `drop_on_tile` | the store / the death tile | no (always succeeds) |
| **Terminal** | `lost` | destroyed | no (always "succeeds") |

A well-formed chain ends in a placement or terminal link. Recipient links are **"place what fits"** —
overflow continues down the chain per-item (DTH-4). Ties in recipient selection break by **roster
order** (DTH-4). "Ally" = **same faction as the deceased** (a dead enemy's `nearest_ally` = nearest
enemy; `main_character` is meaningless on the enemy side and falls through).

---

## [DTH-1] Scope — disposition always runs; revived units return EMPTY (no restore) — **RESOLVED (revised 2026-06-27d)**
**Owner:** the disposition step runs **unconditionally for every death via the same chain** — there is
**no inventory hand-back branch**. Permanent death → unit gone, items dispersed per the faction chain.
**Revivable death (Phoenix #12)** → the unit's items **disperse through the normal chain too** (to convoy
by default), and the **revived unit returns with an EMPTY inventory**; the player re-equips from convoy.
- **No at-death loadout snapshot / restore (owner, revising the earlier snapshot-and-restore call).**
  Deliberately *not* re-handing items whose state may have **diverged since death** — durability spent,
  weapon broken, item sold/traded out of convoy. Tracking "give back exactly what it held" against a
  store that has since changed is the complexity this avoids.
- *Net:* strictly simpler than snapshot-and-restore, and the path becomes **fully** uniform (revivable
  = the same disposition; the unit merely respawns empty — no internal inventory branch at all).
- **Scope note:** the owner called this out for **Phoenix**; the same rationale applies to **Casual
  (#12)** — recommend the identical empty-on-revive rule; **PvP/skirmish (#7)** is moot (fresh loadout
  per match). **Confirm the Casual/PvP scope in the imminent #12 walk.**

## [DTH-2] Disposition = author-ordered fall-through chain, per-item walk — **RESOLVED**
See **The model** above. Chosen over a single-mode profile because the owner's recipient additions
(DTH-4) only compose cleanly as a prioritized list. Per-item resolution keeps overflow and key-item
exceptions uniform. Author-time validation: a chain must end in a placement/terminal link.

## [DTH-3] Override granularity = campaign default + per-faction — **RESOLVED**
**Owner: campaign default + per-faction split.** `CampaignRules` gains a **player default chain** and an
**enemy default chain** (the Key-Item lock, DTH-5, is the one built-in *per-item* exception).
- **Player default = `[to_convoy]`** (no item loss; only the unit is lost) — the kindest sensible
  default. *Hard build-time dependency on the unbuilt `[CNV]` convoy.*
- **Enemy default = `[lost]`**, with **droppable-flagged items on a separate chain** (the classic FE
  loot model; edge case (8) the "droppable-item enemy"). The droppable chain is authored (e.g.
  `[drop_on_tile]` or `[transfer_to_killer, to_convoy]`).

## [DTH-4] Recipient links + tie-break + overflow — **RESOLVED**
**Owner additions:** beyond `transfer_to_killer`, the chain offers **`nearest_ally`** and
**`main_character`** (the #20 avatar, `[MCH]`) recipient links.
- **Tie-break = roster order** (equidistant `nearest_ally`; multiple avatars for `main_character`).
- **`nearest_ally` metric** = tile distance to the death tile via the **centralized `tile_distance`**
  (the `[HEX-9]` seam — do NOT inline Manhattan). "Ally" = same faction as the deceased.
- **`main_character`** with no avatar on map → link falls through.
- **Overflow** (recipient inventory full): **the unplaceable item continues down the chain per-item**
  (owner). Recipient links are "place what fits"; they never short-circuit the rest of the chain.

## [DTH-5] Key-Item chain (separate, `lost` banned) — **RESOLVED**
A Key Item (`[CEX-14..16]` locks) is **never `lost`** regardless of profile (edge case 3). Key Items
walk **their own chain** with **`lost` removed as a legal link** (author-validated). Default
`[to_convoy]`; **per-item override** allowed (a specific key item can pin its own chain, incl.
`[main_character, to_convoy]`). Applies symmetrically to a slain boss holding a plot item.

## [DTH-6] `drop_on_tile` parameterization — **RESOLVED**
`drop_on_tile` carries **`{pickup, on_map_end}`**:
- **`pickup`** = `auto_on_entry` (default — a unit moving onto / ending on the tile grabs it, overflow
  continues *its own* disposition chain) or `activate` (pickup costs the unit's action, reusing the A5
  `activate` config, `[SHP-4b]`/`[VIL-2]`).
- **`on_map_end`** = a **fall-through chain** re-walked for items still on the ground at map end.
  **Author-configurable: campaign default + per-drop-instance override; key-item drops get their own**
  (with `lost` banned). E.g. `[to_convoy]` (safe), `[lost]` (max tension — matches the mode's intent).
- Multiple items may stack on one tile.

## [DTH-7] No-killer / dead-killer fallback = the next chain link; credit ≠ transfer — **RESOLVED**
There is **no special no-killer case** — a recipient link that can't resolve (killed by hazard/condition
with no living source; the killer also died; a poison whose F5-stored source is gone) simply **fails and
the item tries the next link** (the author's configured fall-through). So "where do the items go" is
fully author-controlled by chain order; owner-offered links beyond convoy/lost/drop (`nearest_ally`,
`main_character`) cover the rich cases.
- **Credit ≠ item transfer.** EXP / objective **credit** still follows the **`[VAL]`/`[RDR-8]`
  credit-the-holder-even-if-dead** rule (a dead source is credited), but a **dead unit cannot *receive*
  items**, so a `transfer_to_killer` to a dead killer fails the recipient link → next link. Two separate
  resolutions over the same death.

## [DTH-8] Simultaneous death = snapshot-then-resolve (generalized) — **RESOLVED**
Generalizes the existing `CombatResolver` pattern (substrate note above) and the `[RDR-8]`/`[CVR-5]`
rule: **apply all HP → collect every unit now at 0 → resolve disposition for each in a deterministic
order = roster/registration order** (`GameState.get_living_units_of` order, the existing stable order;
single-exchange defender-before-attacker is a degenerate case). **Mutual kills both die.** A **dead
recipient** fails its recipient link → next chain link (DTH-7). A redirect/thorns kill **credits the
holder even if dead** for EXP/objectives (DTH-7, `[RDR-8]`).

## [DTH-9] Substrate seam — single funnel + a disposition resolver — **RESOLVED (design) / forward-req (build)**
- **`handle_death` gains an optional context** `ctx = {cause, killer}` (cause ∈ combat / condition /
  hazard / ring-out / scripted). Today only `CombatResolver` calls it (and knows the attacker); the
  other causes **must be routed through the same hook** when they're built — **do not invent a second
  death hook** (the same mandate `[BAT-16]` host-death and `[DSP-5]` death-while-carrying already make).
- **A new `DeathDisposition` resolver** (autoload or static helper) walks the chain for `ctx`. Keeps
  `Unit.gd` lean and gives one unit-testable place. `handle_death` invokes it before `queue_free()`.
- **Forward-req:** F5 condition ticks, hazard terrain, and the `[DSP-14]` ring-out are themselves
  unbuilt; each must funnel through `handle_death(ctx)` at build time (DoD#2 check candidate).

## [DTH-10] `key_item_removed_from_map` win/loss condition = a custody state machine — **RESOLVED (designed in full, owner call)**
A new **objective predicate** (owner pulled it into A5 from the death walk). Each tracked key item has a
**custody state ∈ `{player_held, in_convoy, enemy_held, on_tile, off_play}`**. The author keys
**victory and/or defeat** on entering specific states:
- *protect-it framing:* `defeat_if: [enemy_held, off_play]` (carrier safe in `in_convoy` is **not** a
  loss — this is why the binary on/off-map model was rejected: a `to_convoy` default would otherwise
  auto-trigger a loss).
- *seize-it framing:* `victory_if: [player_held, in_convoy]`.
- **Re-evaluated on every custody transition:** death-disposition (DTH), pickup (DTH-6), drop,
  unit-leaves-map (flee/escape/rescue-off), convoy recovery.
- **Composes** F16 (the predicate) + the **A4-pinned objective / win-loss system** (the wiring lives
  there; this register owns the **custody-state definition + transition triggers**). Needs an item
  **custody query** `key_item_custody(item_id) -> state`.

### Forward-pin — objective-system extensibility (the shared unlock; surfaced 2026-06-27d)
DTH-10 can't actually land until the win/loss system stops being closed. **Code reality:**
`ObjectiveCondition.type` is a **closed enum** (`rout/defeat_boss/seize/escape/survive/protect/
turn_limit`, `scripts/resources/ObjectiveCondition.gd`), evaluated by `TurnManager.
check_victory_conditions` (→ `EventBus.map_victory/defeat`) and **polled only at phase boundaries**;
there is **no flag/predicate/event-driven type** and **no F6 flag store** (only debug-aid flags on
`GameState`; `[MET]` is unbuilt and its v1 action set — `reveal_tiles`/`flag`/`spawn` — has no "end
map"). The **same closed enum blocks three converging needs:**
1. **A dialogue-driven victory/defeat** — a `[DLG]` `command` / `[MET]` action that ends the map or
   sets a win/lose flag (the side-check that surfaced this);
2. **this DTH-10 custody objective** (a new condition type);
3. **any flag/predicate-driven win/lose.**

**Two paths (to be chosen in the walk):** **(A) declarative** — migrate the objective enum toward
**F16 predicates** (or add a `flag_set`/predicate type) + build the **F6 flag store**; re-check on the
relevant event (flag/custody change) rather than only at phase boundaries. **(B) imperative** — a direct
**`end_map: victory|defeat`** DLG/MET action emitting `map_victory/defeat`. A + B are complementary
(declarative gate vs scripted beat). **Owner (2026-06-27d): this MUST be walked in the define-all sweep,
BEFORE the F1 schema-lock (Phase B) — and therefore before the Phase C evaluation/triage session.**
It is **schema-affecting** (objective conditions referencing predicates/flags; the F6 store), so it
cannot wait for the triage. Composes F16 + `[VIL-8]` + `[DLG]`/`[MET]`.
**RESOLVED in `[TCV-4]`** (the typed campaign-variable store walk, 2026-06-27d): the open enum gets a
**flag/predicate-driven `ObjectiveCondition` type** (the declarative path the custody objective needs) +
an imperative `end_map` action + event-driven re-check. The DTH-10 custody objective rides that new type.

## [DTH-11] Save / F1 schema reserve — **forward to Phase B (F1 lock)**
Reserve at the F1 schema-lock: **(a)** a **per-map dropped-item tile stash** *only if* `drop_on_tile` is
in play (tile → item list; persists mid-map); **(b)** **key-item custody tracking** (item → custody
state) for DTH-10; **(c)** ~~at-death loadout snapshot for revivable restore~~ — **removed (DTH-1 revised
2026-06-27d): revived units return empty, so no loadout snapshot/restore state is reserved.**
Otherwise no new state beyond convoy.

## [DTH-12] Build deps & definition-of-done — **forward**
- **Hard dep:** `to_convoy` (the player default, DTH-3) needs the **`[CNV]` convoy build** → Phase C
  ordering: this rule set can't ship its default until convoy lands.
- **`nearest_ally` uses the centralized `tile_distance`** (`[HEX-9]` seam), not inlined Manhattan.
- **DoD#1:** on build, update the affected GDD section(s) + flip `GDD_10_Roadmap` status in the same
  commit. **DoD#2:** a `check_docs.py` check that every death cause routes through `handle_death(ctx)`
  (guard against a second death hook) is a candidate when the non-combat death causes are built.

---

## Cross-refs (wired)
- **`[BAT-16]`** host-death disposition → funnels through this single `handle_death`/`DeathDisposition`
  path (a battalion is part of the host's loadout disposition); simultaneous host-deaths use DTH-8.
- **`[DSP-5]`** death-while-carrying (the carried unit drops per DSP, the carrier's own inventory
  follows this chain) and **`[DSP-14]`** ring-out (a no-clear-killer death cause → DTH-7) → this set.
- **`[RDR-8]`/`[CVR-5]`** simultaneous-death snapshot-then-resolve + credit-the-holder → DTH-7/DTH-8.
- **`[VIL-8]`** removal-disposition + the A4 objective system → DTH-10.
- **`[CEX-14..16]`** Key-Item locks → DTH-5. **`[IEQ]`/`[CNV]`** inventory/convoy → the placement links.
- **`[MCH]`** (#20 avatar) → the `main_character` recipient link (DTH-4). **#12** Casual/Phoenix, **#7**
  PvP → DTH-1 revivable branch.
- **`[VAL]`** forecast/credit model → the credit-the-holder rule (DTH-7).
