# Session Note — 2026-08-13-18-32-29Z — `DRC` Group A, the state-model spine

## Branch context

- Branch: `agent/integration` (docs line; register walks land here directly)
- Base branch: `agent/integration`
- Base SHA: `9533e9f37bee3450d3f2a0a87bf68d92af0cd20a`
- Coordination Work ID: `DISCUSS-RECRUIT-CAPTURE-UX-2026-07-23`

## What was done

Walked **`DRC-19..24`** — Group A of the recruitment/capture half, the state-model spine — to
completion. Six questions ruled, the three July provisional rulings confirmed, four propagation
debts recorded. `DRC-25..33` (groups B–E) remain.

**The precedence check came first**, per `DOC-014`, and its headline was a correction to the
*previous* precedence diff. That document's §3 stated the `RCR`/`RCV` reopening *"is already
propagated … no action needed."* True at the **register banner** level; false at the **item** level.
`RCR-1` and `RCR-5` carry supersession banners; `RCR-2`, `RCR-3`, `RCR-4` and `RCR-7` carry none,
and `RCV-4` still named `[RCR-1]`'s superseded faction flip **by name** as the contract its
`recruit` action calls. A banner on a register header does not reconcile the items underneath it.
Recorded in `design/drc_group_a_precedence_diff_2026-08-13.md`.

**Two questions were foreclosed before the owner saw them.** `DRC-20` option A (target faction only)
cannot represent `[DRC-21]`'s already-ruled `map_end` duration with a mandatory expiry outcome, and
`DRC-20` option C (arbitrary action list) gives `[DRC-17]`'s blocking recruit/capture-compatibility
validation nothing typed to check. A third — `DRC-22`'s middle position — **collapsed on
inspection**: `preserve` already lets an unacted unit act, so `refresh` differs from it *only* for a
unit that has already acted, which is the double-turn case itself. There is no "allow refresh but
block the exploit" option; the choice is binary.

### The rulings

- **Activation ownership — split by subject.** `[DRC-13]`'s interaction-policy registry owns the
  **actor's** cost; the transition owns the **target's** arrival activation, as `target_activation`
  (renamed from `DRC-20`'s ambiguous `activation_policy`). They cannot contradict each other because
  they describe **different units**. Decided by `[RCV-4]`'s trigger-agnostic ruling — a
  `turn_reached` recruitment has no actor and no interaction, so a target-activation policy living
  on the interaction registry would be unreachable there. Absorbs `[DRC-21]`'s *"expiry never grants
  a bonus action"*, which had been a fourth location for the same concept.
- **`[DRC-20]` — a sparse patch over all five dimensions**, unset meaning unchanged. The written
  field list covered **three** of `[DRC-19]`'s five ruled dimensions: it matched `DRC-19`'s
  *pre-ruling* option B, and the ruling added `tactical_side_id` the same day without the list being
  updated. Since that dimension owns turn group and hostility, a transition unable to set it leaves
  a recruited enemy **in the enemy turn group**.
- **`[DRC-22]` — `preserve` default; `refresh` permitted with a `[DLUX-10]` author-time warning.**
- **`[DRC-23]` — the transition patches the five dimensions and nothing else.** Owner narrowed this
  past the recommendation: the diff proposed an allow-list admitting `[AIP]` profile and scripted
  orders, and the owner moved **behaviour changes to the effect system**, bundled into the
  recruitment presets. One mechanism for "recruitment also changes X" instead of two. The
  consequence is stated deliberately in the register — a hand-built bare transition leaves old
  orders running, and the presets are what keep that off the common path.
- **Transition ownership — one unit-state service owns reads *and* writes**, unwinding `[RCR-3]`'s
  inversion (the roster held an API writing four dimensions it does not own — the same shape amended
  in `[DRC-33]` the previous sitting). Gives `[DRC-17]` validation, the `[CAU-4]` tags and staged-
  transaction participation a single home.
- **`[RCR-2]`'s `recruited:<id>` flag retired.** `[DRC-21]`'s `map_end` guest is a recruitment
  producing no membership — a case `RCR-2` never anticipated — and *every* answer to "does a guest
  set the flag" was defensible, which is the tell that the flag duplicated state the dimensions
  already hold. Branching moves to `[REQ-13(b)]` runtime unit-state predicates, an already-ruled
  author-extensible family. Removes the leak hazard too: a flag written outside `[DRC-9]`'s staged
  transaction would have reintroduced what `DRC-9` closed by construction.

### Confirmed and unchanged

`[DRC-19]` (no longer provisional; writes now go through the same authoritative service),
`[DRC-24]` (now structural — membership stages and commits atomically by construction), and
`[DRC-21]`, whose *"ride the normal save/Rewind ledger"* sentence was **re-expressed** in the
two-primitive vocabulary (transitions commit through a staged transaction; `MapLedger` is a snapshot
consumer). Intent unchanged.

## Commits

Ownership is in `CLAIMS.tsv`. Seven commits from `007741b2` to `97a7baed`: the precedence diff and
its control-plane registration, then one commit per ruling, then the confirmations and debts.
`7182b971` needed a retry — the first attempt aborted in the Godot import prepare step (exit 134),
transient; the retry was clean and the docs-only path skipped the suite as expected.

## Gates

- `python3 AGENT/Docs/check_docs.py` — **PASS**, all 44 checks, run after every register edit.
- `python3 AGENT/Docs/gen_docs_index.py` — regenerated and committed alongside.
- `python3 scripts/ci/check_session_commit_claims.py --fix` — **PASS**, 739+ commits audited.
- Pre-commit hooks green throughout (analyzer tests 12/12, scene integrity 23 scripts, GDScript
  style 320 files, RNG guard).
- One check caught a real omission mid-session: the `session-claims` hook refused `DRC-20`'s commit
  because `756a8e12` was unclaimed. Claim as you go, not at the end.

## Next

**`DRC-25..33`, groups B–E**, in the order the register's scope block sets: B authoring and sources
(`DRC-25`, `DRC-26`), C capture and custody (`DRC-27..29`, `DRC-31`, `DRC-32`), D the captive's
inventory (`DRC-30`), E observation (`DRC-33`). Group A's custody dimension is now settled, which is
what C and D were waiting on. **Each group owes its own precedence check** — this session is the
second consecutive one where the check changed the answer before the owner saw the question, and
where the *previous* check turned out to be partly wrong.

The live findings for those groups are §3 of `skf_drc_precedence_diff_2026-08-13.md`, and the
`DRC-30` work is the heaviest: Trade must consume `[EPUX-24]`'s shared transaction core and
`[EPUX-11]`'s pending-items tray **by name**, and its multi-swap session is consistent with the
`TSV` outcome only if each swap is its own committed transaction.

**Then, not before: `DRC-PLAN-REDERIVATION-2026-08-13`.** Group A changed the plan's spine —
`DRC-20/22/23`, transition ownership and the retired flag are all decision sources it derives from —
so the thirteen gated build rows (`DRC-V1-S00..S11`, `EPIC-DIALOGUE-CUSTODY-V1`) stay gated.

**Debts this walk recorded** (none blocking, all for the re-derivation): `[RCR-4]` owes `[REQ]` a
banner — `REQ` absorbed recruit eligibility in June and `RCR-4` records none of it, which matters
because `REQ`'s display path supplies the reason string `[DRC-11]`'s fifth-surface ruling needs;
`[RCR-7]`/`[RCV-6]` save reservations predate the five-dimension model; `[REQ-13(b)]`'s
`is_captured` should read `custody_status`; and `[RCV-4]`/`[RCR-3]`/`[RCR-2]` need their amendment
banners.
