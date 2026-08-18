# Session Note - 2026-08-17-22-34-04Z

## Branch context

- Branch: `agent/integration` (documentation-only change; the docs-guard refuses
  `AGENT/Docs/plans/**` on a feature branch, so no feature branch was created)
- Base branch: `agent/integration`
- Base SHA: `c31e79ee`
- Coordination Work ID: `PREP-ECONOMY-IMPLEMENTATION-PLAN-2026-08-17`

## What was done

Wrote `AGENT/Docs/plans/prep_economy_implementation_plan.md`, the second item in `R1`'s walk order
and the document `R1` instance (b) discovered did not exist. It is derived against `EPUX-1..28`
(the decision source), `TSV-1..24`, `SHC-1..8`, `CUR-1..7`, `DSX-1..29` and `RPD-1..18`, and it
supersedes §6 of `recent_research_implementation_portfolio_review_2026-07-27.md` as the decision
source for `PREP-V1-S01..S08`.

Two findings the plan produces rather than merely records:

1. **A fourth producer/consumer inversion, inside the prep line.** `R1`'s §4.5 table marked
   `[EPUX-06]`'s activity-entry snapshot as the one primitive whose edge was already right, because
   it checked only the `DRC` consumer at `DRC-V1-S10`. The shop needs the receipt too — `[TSV-19]`'s
   confirm/revert-on-exit *is* the shop's exit behaviour, and `[DSX-S26]`'s no-receipt disclosure is
   a shop obligation — and the shop is `PREP-V1-S05`, one slice **before** the `S06` that currently
   builds it. The plan moves the producer to `S05`, beside the transaction core whose commits it
   reviews. `DRC-V1-S10`'s edge survives.
2. **Two shared primitives that no plan builds.** `[DSX-S1]`'s distribution shell (holder · pool ·
   detail, shell-owned verb slot, N registered adapters across nine consumers) and `[DSX-S4..S9]`'s
   dependent-choice layer. A corpus-wide search finds **no document citing `[DSX-S1]`** outside the
   `DSX` register itself. Convoy, shop and forge are three of the nine consumers, so left
   unassigned this line acquires the separate selectors `UBS-2` exists to prevent. The plan homes
   the shell in `PREP-V1-S02`; the layer needs an owner call, because `[DSX-S9]` requires it to
   *absorb* `RPD`'s select-then-select gesture while `B4-PREP-MAP-DEPLOYMENT` ships that gesture for
   **v0.8.0**, ahead of every `PREP-V1` slice.

Code state was verified against the tree rather than assumed, and §3 records what it found:
`InventoryEntry` has **no stable instance id** anywhere (four ratified rulings require one, and it
gates convoy, shop, forge and Trade); the convoy is a save schema with `GameState.party_items:
Array[String]` as its whole runtime; `ResourceLedger` is a wallet, not the transaction core
`[TSV-3]` needs; `ResourceLedger.reserve()` and `CostSpec.allow_partial` both have **zero callers**
and both are contradicted by ratified rulings, so the plan deletes them; `ResponsiveLayout` derives
its class from width alone and has no landscape predicate for `[SHC-4]`; `MapMenu.gd:75-79` is
confirmed as the whole gold-assumption migration; and `CampaignManager.gd:67`'s autosave-trigger
list is the exact insertion point for `[EPUX-06]`'s activity-entry trigger.

## Commits

`ff371ca4` adds the plan, gives §6 of the portfolio review a superseded banner pointing at it, adds
the ownership-map row in `doc_role_manifest_2026-06-29.md`, and regenerates `INDEX.md`. `64e150ff`
claims it in the ledger.

## Gates

- `python3 AGENT/Docs/check_docs.py` — **PASS**, all 46 checks green (including `[45]` Doc Type
  taxonomy and `[46]` Uncatalogued registers, both added by `R1` the same day).
- `python3 AGENT/Docs/gen_docs_index.py` regenerated and the new filename was grepped out of
  `INDEX.md:275` rather than trusting the PASS.
- Pre-commit: contract suite 12/12, scene integrity 23 scripts, session claims 864 commits,
  evidence matrices, GDScript style 321 files. Godot suite skipped — docs-only change.

## Owner rulings, 2026-08-18 — all three approved and applied

1. **`B4-PREP-MAP-DEPLOYMENT` builds the `[DSX-S4..S9]` dependent-choice layer**, deployment
   placement as consumer 1. The handoff gains a new §3.1 spelling out what that adds to slice 2b —
   one state machine with the *kind* selecting only how rows render, the first pick as focus rather
   than a reservation with the vocabulary fixed as `pinned`, the empty slot as an entry in the set,
   no confirmation of its own, and the pinned pick surviving a step back. **Boundary held
   explicitly:** `B4` builds the *layer*, not the *shell* — `[DSX-S1]`'s holder/pool/detail
   composition stays at `PREP-V1-S02`, because Map Preview is a canvas and placement needs the state
   machine without the regions. If that splits badly in build, widen `S02`; never grow a second
   shell in `B4`.
2. **Primitive 4 moved `PREP-V1-S06` → `PREP-V1-S05`**, beside the transaction core whose commits
   it reviews. `DRC-V1-S10`'s edge survives through `S10 → S06 → S05`.
3. **The distribution shell is a consumer of `UIREC-V1`'s primitives, not a peer**, with the
   escalation path recorded: widen layer 1 rather than fork a second shell.

**Nine rows edited**, all through `agent-update-task.sh` with `--append-reference` so no build prose
was discarded (`PREP-V1-S01` carries a must-carry v0.7.0 finding that a `--reference` assignment
would have thrown away). One edit was **not** on the pre-ruling list and was added deliberately:
`DRC-V1-S05` also gains the `B4` edge, because `[DSX-S9]` names Trade as a consumer of the layer
and leaving a *named* consumer unordered is the exact defect this plan exists to fix.

**Verified after applying, over the whole 434-row graph rather than by inspection:** still acyclic,
and **all six primitives now sort producer-before-consumer**. Putting primitive 6 at
`B4-PREP-MAP-DEPLOYMENT` introduced no back-edge — that row depends only on `B3-PHB-REGISTRY`
(closed) and `R1`, neither downstream of any `PREP-V1` row.

## Next

`R1` continues at walk-order item 3 — `B4-PREP-MAP-DEPLOYMENT` against `RPD`, already re-derived on
2026-08-17 and now carrying the widened scope above. It is a v0.8.0 dependency, and it is also the
producer of a primitive four other rows consume, so it is the first place the new build spine gets
tested rather than asserted. Walk-order item 4 (the unified UI programme) follows.
