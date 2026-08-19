# Session Note - 2026-08-18 — the convoy/shop residue packet, walked

## Branch context

- Branch: `agent/integration`
- Base branch: `agent/integration`
- Base SHA: `3f43a4c5`
- Coordination Work ID: `CONVOY-SHOP-PACKET-WALK-2026-08-18-2026-08-18`

## What was done

Authored, precedence-checked and walked `CVS-1..10` in one sitting — the convoy/shop packet the
schedule has been calling "next session" since 2026-08-14 — and closed it with ten rulings,
`[CVS-S1]`–`[CVS-S10]`.

### The finding that reframed the session before a question was written

**The sitting had already happened.** The control plane records that `DSX-1..28`, walked and closed
2026-08-15, **is** `S5`+`S6` — *"widened by the owner from convoy + shop to every surface that moves
a limited thing onto a holder"*. Three scheduling documents never learned that: the sequencing
plan's Stage C, the `UBS-6` agenda section, and the tracker.

So the packet became the **residue of the widening** rather than the sitting itself, and the
`UBS-6` agenda turned out to be the wrong agenda. Two of its five must-settle items no longer
exist — `[DSX-S10]`/`[DSX-S11]` settled the Compact selector, and `[DSX-S7]` removed the
reserved-but-uncommitted state itself, so asking how to display it would have manufactured a state
the corpus deleted. Meanwhile the half-line it gave "refresh cadence" became four questions. The
generalisation worth keeping: **a shell walk asks how a number is drawn, never what the number
counts**, and the counting is what was left.

### The ten rulings

Convoy — `[CVS-S1]` capacity counts **instances**, not stack rows, so a row reading `×5` and a cap
figure reading five agree and `[DSX-S20]`'s projection stays computable (stack-counting would let
one item *use* split a stack and move a cap figure with no action in the surface). `[CVS-S2]`
key-ness stops being a class: the four ratified behaviours become **independent per-instance
properties**, "key item" is the authoring preset that sets them together, and the Key Items view
becomes a `[DSX-S23]` pool facet — **amending `[CEX-16]`**, which predates `[DSX-S1]` by nine weeks.
`[CVS-S3]` over-capacity is a legal state, spilling to the pending tray at next prep entry, tray
durable in the save. `[CVS-S4]` see below.

Stock and cadence — `[CVS-S5]` stock is a seventh `[DSX-S19]` cap with the projection required only
when finite. `[CVS-S6]` the restock cadence reference lives on the stock **entity** with a per-entry
override; a tick **resets** by default, **increments to a ceiling** where the author selects it, and
**re-roll is out of v1** because a randomized offer pulls in `RNG` policy, seeded runs and
determinism. `[CVS-S7]` restock disclosure is author-declared per shop, default off, and phrasable
only for the counter families — a predicate-keyed shop just reads "Sold out". `[CVS-S8]` selling is
final in v1.

Both halves — `[CVS-S9]` the quantity stepper clamps to the minimum of affordability, stock and
destination capacity and names the binding limit. `[CVS-S10]` sell is symmetric with buy under
`[EPUX-17]`, with unsellable rows gated rather than hidden.

### `[CVS-S4]`, and the miss that produced it

`CVS-4` asked what battlefield convoy access costs a unit. **The precedence check missed the
`[CNV-5]` amendment of 2026-07-27**, which already rules it — the FE7 partial-action preset, with
`[DRC-30]`'s open registry making cost, session limit, post-action movement and provider range
author-tunable. The question was asked at the wrong altitude, and the owner's answer ("work like
Trade, author-overridable") landed on the ratified default.

What the owner **added** is genuinely absent from the corpus: cost is overridable **per source**,
and when several sources cover one unit — the `EPUX` convoy-access aura, `[CNV-5]`'s designated
provider, a campaign rule — the **most permissive wins**. Order-independent, like the cadence
engine's OR-composed triggers, and it obliges `[DRC-30]`'s registry to *rank* permissiveness rather
than judge it case by case.

Worth recording as a pattern: the citation-based precedence method is blind to amendments appended
to a register whose questions are already marked `[RESOLVED]`. That is the third distinct shape of
this failure in the programme, after `R1`'s two.

### Propagation, applied rather than deferred

Every consequence the register listed was swept in the same change, per the `CEUI` lesson that a
ruling which defers a sentence must be applied before the register is called closed: `[CEX-16]`
amended in place; `band4_convoy` capacity accounting and over-capacity; `band4_shop_economy`'s
restock semantics; `prep_economy` `S03` and `S05`. The `S03` edit records that per-instance key
properties make that slice's **stable instance id load-bearing**, since the properties must survive
save/load and `[EPUX-10]` regrouping.

### Spun out and recorded elsewhere

- **`BACKLOG-SHOP-BUYBACK-2026-08-18-2026-08-18`** + `B8-SHOP-BUYBACK` in Band 8 — owner wants
  stores to keep what you sell them, post-v1. Additive over every `CVS` ruling.
- **An owner ruling on `DESIGN-OVERWORLD-CADENCE-2026-07-25`, taken in this session:** the
  **overworld-map traversal surface is in v1**. Nothing builds it today — the prep/economy plan
  mentions the optional map twice and no slice or row owns it, while `CampaignNode.next_node_ids`
  and `CampaignManager`'s successor-choice API already carry the graph, so what is missing is the
  surface and free revisit, not the data.

### Two things found while checking, left for their owners

- The cadence row's "fold into implementation planning" is **half discharged**: the plan folds in
  the cadence half at summary level, with no trigger descriptor schema, no evaluation points, no
  binding format for the reference `[CVS-S6]` has now defined, no durable-state shape and no clock
  seam — and the traversal half needs a slice. It is also parked at `S13` in the sequencing plan
  while `PREP-V1-S01` depends on it: the first prep/economy build slice is blocked by a row
  scheduled last.
- **The shared condition/predicate registry the cadence model assumes does not exist in campaign
  scope.** `ObjectiveConditionRegistry.evaluate()` is battle-scoped (`for_group`,
  `game_state: Node`), and `RequirementFormulaRegistry` — fact-dictionary, campaign-shaped — has no
  production callers, only tests. **Corrected while writing the handoff:** that is true of the
  **code** and false of the **design** — `REQ-1..16` is `RESOLVED` and Band 3 Slice 5 specifies the
  build. The real finding is that `B3-REQ` owns it and **had no tracker row**, so
  `PREP-V1-S01`'s only predicate edge pointed at a closed design row. See
  [`cadence_and_predicate_prerequisites_handoff_2026-08-18.md`](../Docs/plans/cadence_and_predicate_prerequisites_handoff_2026-08-18.md).

## Commits

Ownership is in `CLAIMS.tsv`. Four documentation commits: the packet plus its precedence check and
control-plane entry; the convoy rulings; the stock/cadence rulings with the Band 8 parking; and the
closing two rulings with the whole propagation sweep. They are split by walk block rather than by
file, because each block is the unit a reader would want to review.

## Gates

- `python3 AGENT/Docs/check_docs.py` — **PASS**, 46 checks, run before each commit. Two rejections
  were fixed rather than bypassed: a missing control-plane ownership entry for the new design doc,
  and two `PREP-V1-S05` references in the Band 8 row that are tracker ids, not control-plane Track
  IDs.
- `python3 AGENT/Docs/gen_docs_index.py` — regenerated in the same commits; `REGISTERS.md` catalogues
  `CVS-1..10` correctly (checked by reading the diff, not by trusting the PASS).
- `python3 scripts/ci/check_session_commit_claims.py --fix` — ledger green at each step.
- Godot suite skipped — documentation-only change.

## Next

1. **`DESIGN-OVERWORLD-CADENCE`** is now the sharpest-edged row: it blocks `PREP-V1-S01`, it is
   scheduled at `S13`, its fold is half done, and it just gained a v1 build obligation.
2. The two stale scheduling documents, through `RESEARCH-SEQUENCING-2026-08-13-2026-08-13`.
3. `R2` — UI corpus and album release review. Unaffected by anything here; `CVS` changes no album,
   though `[CVS-S5]`'s stock figure and `[CVS-S7]`'s reason string are candidates for a re-bake of
   `shop_transaction_album.src.html` if they reach a drawn frame.
