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

## Next

Three owner calls in §11, in order of cost:

1. **Where the dependent-choice layer is built.** Recommendation: `B4-PREP-MAP-DEPLOYMENT` builds
   it with deployment placement as consumer 1 — it builds the state machine either way, and the
   alternative is the consumer-before-producer shape `R1` found three times in one graph. It widens
   a v0.8.0 row's scope, hence the call.
2. **Confirm moving the snapshot/receipt primitive from `PREP-V1-S06` to `PREP-V1-S05`.** Derived,
   not a design question, but recorded so it is not applied silently.
3. **Confirm the layering in §4.1** — that the distribution shell is a *consumer* of `UIREC-V1`'s
   record-screen primitives rather than a peer. Neither register says so, because `DSX` never cites
   `UIREC`.

Once ruled, apply the tracker edits listed at the end of §11 with `track.py update` (never a
hand-edit), then `R1` continues at walk-order item 3 — `B4-PREP-MAP-DEPLOYMENT` against `RPD`,
already re-derived, and a v0.8.0 dependency.
