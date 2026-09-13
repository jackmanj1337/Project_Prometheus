# Session Note — 2026-08-13-18-32-29Z — `DRC-1..33` closed (Groups A–E)

## Branch context

- Branch: `agent/integration` (docs line; register walks land here directly)
- Base branch: `agent/integration`
- Base SHA: `9533e9f37bee3450d3f2a0a87bf68d92af0cd20a`
- Coordination Work ID: `DISCUSS-RECRUIT-CAPTURE-UX-2026-07-23`

## What was done

**Closed `DRC-1..33` entirely.** The session ran in two halves: first Group A (`DRC-19..24`, the
state-model spine), then Groups B–E (`DRC-25..33`, capture, custody, Trade and observation). Each
half got its own mandatory precedence check first, and both checks changed the questions before the
owner saw them. The register is now **RESOLVED**.

The Group A half is recorded immediately below; Groups B–E follow in their own section.

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

## Groups B–E — capture, custody, Trade, observation

The second precedence check (`design/drc_groups_bcde_precedence_diff_2026-08-13.md`) **dropped two
questions before they reached the owner**: `[DRC-26]` was answered by `[RCV-4]` in June
(*"trigger-agnostic — runnable from any MET trigger"*) and closed a second time by the morning's
service ruling, and `[DRC-33]`'s option choice **is** that service ruling, made hours earlier. Three
more — `DRC-25`, `DRC-27`, `DRC-28` — shrank to residue once `[REQ]`, `[EPUX-02]` and the
open-registry principle were applied.

**The duplicate-state shape appeared three times in one day**, which is the session's real pattern.
It retired `[RCR-2]`'s `recruited:<id>` flag in the morning; it decided `[DRC-29]` (a carried
captive would have been represented once as `CarryRegistry` state and once as `custody_status`, so
**`custody_status` is authoritative and carry is derived**); and it decided `[DRC-33]`'s record
(embedding inventory transactions would duplicate the item-instance ledger `[DRC-30]` already owns,
so the record **references** ledger entries). `[DRC-25]`'s rejected third option — a unit default
with an opportunity override — was the same shape a fourth time.

Also ruled: `[DRC-27]` registers capture methods with **`non_lethal_carry` plus a first-class
`take_custody`**, so story capture stops faking a sleep status it does not mean; the method is a
**field group on the existing `[DRC-13]` interaction entry**, not a second registry; `[DRC-28]`
ships one `incapacitated_and_carryable` profile built from existing `REQ` terms with the size term
deferred; `[DRC-25]`'s transition attaches to the **opportunity**, with no `recruitable` truth flag
on the unit; Trade **commits per swap** and takes its captive permission from `[DRC-12]`'s
descriptor rather than a controller fiction; and `[DRC-32]`'s automatic map-end disposition **emits
`execution` without confirming** — the tag makes permanent removal record one way, but there is no
decision point to confirm in automatic resolution.

Two findings were resolutions of things nobody had noticed were ambiguous. **`[DRC-31]`'s map-end
sweep takes `[EPUX-11]`'s pending-items tray, not fail-before-commit** — it is an *unavoidable*
acquisition, and the wrong reading would halt map-end resolution on a full convoy. And **"staging"
now means two different things**: `TSV`'s *"no staging"* forbids a user-visible cart, while the
two-primitive ruling's *staged transaction* is the internal atomic commit. Both are recorded in the
register so neither is later read as overriding the other.

One question was **derived rather than asked**: an open conversation does not count against
`[EPUX-06]`'s at-most-one-gated-activity invariant, because that invariant bounds *snapshot* cost
and a conversation is a *stage*. The other reading would forbid a conversation inside a gated
activity, which would break Prison outright.

## Commits

Ownership is in `CLAIMS.tsv`. Group A: seven commits from `007741b2` to `97a7baed` — the precedence
diff and its control-plane registration, one commit per ruling, then the confirmations and debts.
Groups B–E: `8f291fe5` (precedence diff), `c5472c2a` (`DRC-29`/`27`/`28` + registry shape),
`43decd13` (`DRC-25`/`30`/`31`/`32`/`33`, closing the register).
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

**`DRC-PLAN-REDERIVATION-2026-08-13` is now unblocked and is the next action.** It was sequenced
explicitly behind this walk — *"walk first, re-derive second; doing it the other way means doing it
twice"* — and the walk is done. The integrated implementation plan is marked **Needs revision**, and
**thirteen tracker rows derive from it by name and slice number** (`DRC-V1-S00..S11` and
`EPIC-DIALOGUE-CUSTODY-V1`), all still gated and not to be picked up for build until it lands.

The re-derivation now has to absorb the whole packet, not just Group A. The heaviest changes are the
five-dimension sparse transition (which replaces `[RCV-4]`'s `recruit(unit)` contract outright), the
unit-state service owning every dimension write, `custody_status` as the authoritative custody
representation with carry derived, capture as registered methods on the existing interaction entry,
Trade's per-swap commit over `[EPUX-24]`'s core, and the transition record referencing the ledger.

**A process note worth keeping.** Both precedence checks this session changed the questions before
the owner saw them, and the Group A check found that the *previous* session's check was itself
partly wrong — propagated at the register-banner level but not the item level. Two consecutive
sessions, three checks, three times the check earned its cost. Treat it as load-bearing, not
ceremony.

**Debts this walk recorded** (none blocking, all for the re-derivation): `[RCR-4]` owes `[REQ]` a
banner — `REQ` absorbed recruit eligibility in June and `RCR-4` records none of it, which matters
because `REQ`'s display path supplies the reason string `[DRC-11]`'s fifth-surface ruling needs;
`[RCR-7]`/`[RCV-6]` save reservations predate the five-dimension model; `[REQ-13(b)]`'s
`is_captured` should read `custody_status`; and `[RCV-4]`/`[RCR-3]`/`[RCR-2]` need their amendment
banners.
