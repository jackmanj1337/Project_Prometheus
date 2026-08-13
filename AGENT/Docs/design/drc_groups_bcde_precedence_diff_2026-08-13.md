---
Type: design
Status: OPEN — precedence diff written before the `DRC-25..33` owner walk
Last verified: 2026-08-13
Tracker: DISCUSS-RECRUIT-CAPTURE-UX-2026-07-23
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# `DRC-25..33` (Groups B–E) — Precedence Diff Before the Owner Walk

Third `DOC-014` check in this packet, after
[`skf_drc_precedence_diff_2026-08-13.md`](skf_drc_precedence_diff_2026-08-13.md) (`DRC-1..18`) and
[`drc_group_a_precedence_diff_2026-08-13.md`](drc_group_a_precedence_diff_2026-08-13.md)
(`DRC-19..24`). Covers the nine remaining questions: **B** authoring and sources (`DRC-25`,
`DRC-26`), **C** capture and custody (`DRC-27..29`, `DRC-31`, `DRC-32`), **D** the captive's
inventory (`DRC-30`), **E** observation (`DRC-33`).

**Sources diffed.** `EPUX-02/06/07/11/12/21/24/25/28`, the `TSV` outcome, `REQ-1..16`, `DSP`
(displacement/carry), `STY-6`, `DLUX` §7.3, `CAU-4` as amended 2026-08-13, and **all of Group A's
rulings from earlier today** — the five-dimension sparse patch, the unit-state service owning reads
and writes, `target_activation`, the five-dimensions-only patch scope, and the retired
`recruited:<id>` flag.

## Bottom line

**Two questions are already answered and should not be put to the owner.** `DRC-26` was settled by
`[RCV-4]` in June and again by this morning's service ruling; `DRC-33`'s *option choice* is
literally the transition-ownership ruling made hours ago, leaving only the record's contents live.

**Three more have their mechanism settled and only residue live** — `DRC-25`, `DRC-27` and `DRC-28`
each reduce to a much smaller question once `REQ`, `EPUX-02` and the open-registry architecture
principle are applied.

**The real work is four conflicts**, one of which is the same duplicate-state shape the retired
`recruited:<id>` flag turned out to be, and one of which is a **word collision** that will be read
as a contradiction by anyone who does not know both rulings.

---

## 1. Closed by precedence — do not ask these

### 1.1 `DRC-26` — "which sources may recruit" was answered in June

`DRC-26` asks whether Talk alone, any registered event action, or bespoke paths may recruit, and
recommends B. **`[RCV-4]` already ruled it:** the `recruit` action is *"trigger-agnostic —
runnable from **any** MET trigger (`talk`, village `Visit`, `turn_reached`, `flag`)"*. This
morning's ruling closes it a second way: one unit-state service owns `apply(transition)`, so every
source necessarily converges on the same path. There is nothing left to decide.

### 1.2 `DRC-33`'s option choice is this morning's ruling

`DRC-33` option B is *"one authoritative unit-transition service emits a structured before/after
record and applies it transactionally; objectives, turn order, AI, UI, roster, dialogue facts,
ledger, and saves consume the same result."* That is the transition-ownership ruling, already made.
Options A and C are foreclosed with it.

What remains live is only the **record's contents** — `DRC-33` recommends cause, actor, target,
old/new affiliation, controller, roster/custody/activation states, inventory transactions,
duration/expiry, and emitted facts — plus the pack-schema-version rejection rule. The milestone
vocabulary (`incapacitate`, `capture`, `extract`) and the extraction lifecycle were ruled in July
and stand.

---

## 2. Mechanism settled, residue only

### 2.1 `DRC-25` — predicates, disclosure and selectors all already have owners

Three of the four things `DRC-25` option C bundles are decided elsewhere:

- **Authoritative predicates** → `[REQ]`. It named `[RCR-4]` recruit eligibility explicitly and
  ruled *"one evaluator + one display path"*.
- **Disclosure** → `[EPUX-02]`'s **two-value** vocabulary and its per-entry authoring property
  (`visible-disabled-with-reason` default, or `hidden-until-met`), which `[DRC-11]` extended to
  the tactical map as a fifth surface this month. `DRC-25` must not invent a third disclosure
  vocabulary — that is the argument `DRC-11` already lost.
- **Eligible actor/target selectors** → `[DRC-12]`'s authored **interaction descriptor**, which
  already carries direction, a range predicate, allowed phases, and which side may initiate, and
  which ships in `[DRC-13]`'s registry.

`DRC-25`'s intent to remove *"a potentially misleading `recruitable` truth flag"* also converges
with this morning's retirement of `[RCR-2]`'s `recruited:<id>` flag — the same reasoning, reached
independently.

**Residue, and it is the whole question:** where does the `[DRC-20]` transition itself attach — to
the recruitable unit, or to the opportunity?

### 2.2 `DRC-27` — the architecture principle forces option C

*"Registered capture methods"* versus a fixed one- or two-path rule is the closed-enum smell this
project rejects by standing principle: author-facing vocabularies that grow with content are
data-driven registries, never engine `match` statements. `[STY-6]`'s non-lethal sleep path is then
simply the first registered method.

**Residue:** which methods ship in v1, and whether `take_custody` is a first-class action.
**Watch for a third registry** — `[DRC-13]` already places Talk, recruit and capture *interaction
policy* presets in one registry, and `[DRC-12]` puts the interaction descriptor there too. A
capture **method** (how custody is established) is a different axis from capture **cost/range**
(how the interaction behaves), so the walk should say plainly whether these are one registry with
two field groups or two registries.

### 2.3 `DRC-28` — `REQ` again, plus an already-ruled reason path

Option C's *"registered requirement predicate per capture method, with shared selectors"* is
`[REQ]`. Its listed selectors map onto ruled families: status and carry state to `[REQ-13(b)]`
(`is_carried`/`is_rescuing` from `CarryRegistry`/`[DSP]`, `is_captured`/`asleep` from `[STY-6]`),
relation to `[REQ-13(c)]`, HP and equipment to `[REQ-12]`. Size/carry capacity is the one term
that may not exist yet, and `REQ-12` is author-extensible by ruling, so adding it needs no new
mechanism.

Option C's stated con — *"UI must explain failures"* — is `[EPUX-07]`'s unified reason contract
delivered through `[DRC-11]`'s fifth surface. Already solved.

**Residue:** the standard `incapacitated_and_carryable` profile, and whether a size/carry-capacity
value term is in v1.

---

## 3. The live conflicts

### 3.1 `DRC-29`: custody may end up represented twice — the `recruited:<id>` shape again

`DRC-29` offers `carried` (cargo on a carrier, the `[DSP]`/`CarryRegistry` substrate),
`restrained_on_tile`, and `removed_to_custody`, *"each backed by one custody record."*

Group A ruled **`custody_status` a typed dimension** this morning but deliberately did not
enumerate its values. So a carried captive is now potentially represented **twice**: once as
`CarryRegistry` carry state, and once as `custody_status = carried`. Two sources of truth for one
fact, which can disagree, and which is **exactly** the duplicate-state finding that retired
`[RCR-2]`'s flag a few hours ago — there the flag duplicated `roster_status`; here carry state
duplicates `custody_status`.

**This is the first question the walk should put**, because `DRC-31` and `DRC-32` both describe
transitions between these representations and cannot be checked for completeness until the value
set exists.

### 3.2 `DRC-31` step 2 must name `[EPUX-11]`'s pending-items tray — and takes the *other* branch

`DRC-31`'s ruled map-end sweep transfers residual captives' items to the convoy and says overflow
*"must use the campaign's normal safe destination/failure policy."* That policy is `[EPUX-11]`,
by name, and `EPUX-11` has **two** branches:

- **player-initiated** buys and transfers **fail before commit** with a "destination full" reason;
- **unavoidable acquisitions** (battle drops, story grants) go to the **pending-items tray**,
  resolved before leaving prep, default hold-pending.

A residual-captive sweep at map end is **not player-initiated** — it fires automatically after the
event runner. So it takes the **pending-items tray** branch. `DRC-31` never says which, and the
wrong reading (fail-before-commit) would halt map-end resolution on a full convoy.

`[EPUX-12]`'s Send All to Convoy also supplies the shape for the sweep itself: one item at a time
in order, non-transferable instances filtered up front rather than halting — which is already what
`DRC-31` says about bound and protected/key equipment.

### 3.3 `DRC-31` and `EPUX-06`: two narrow nesting questions the two-primitive ruling did not reach

The two-primitive ruling settled the general nesting — a conversation **stages** inside an activity
that is **snapshot** — but `EPUX-06`'s specifics leave two open:

1. **Does a completed prison conversation's commit stay reversible through the exit receipt?**
   `EPUX-28` ruled *"the exit review receipt is the undo window — permanent means permanent after
   acceptance,"* so a recruitment committed inside a prison visit is reversible until the receipt
   is accepted. That may or may not be intended for recruitment specifically.
2. **Does an open conversation count as "a gated activity open"** under `EPUX-06`'s **at most one
   exit-gated activity open at a time** invariant?

`EPUX-06`'s warning against RNG-bearing activities lands here only if a campaign makes prison
recruitment random; `DRC-31` already forbids a built-in persuasion score, so the exposure is
authored-only.

### 3.4 "Staging" now means two different things — say so before it reads as a contradiction

The `TSV` outcome ruled the transaction model has **"no cart, no staging, no holds, no per-receipt
undo, no partial commits; re-quote every commit."** The two-primitive ruling then named a **staged
transaction** (overlay + commit/discard) as the primitive Trade consumes.

These do not conflict, and the walk must record why: `TSV`'s "no staging" forbids a **user-visible
cart** that accumulates intent across selections; the staged transaction is the **internal atomic
commit mechanism** for a single operation. Left unstated, a future reader will find `TSV` and the
two-primitive ruling and conclude one overrode the other.

The related `TSV` obligation is real and unstated in `DRC-30`: a Trade session performing multiple
slot swaps is consistent with *no partial commits* **only if each swap is its own committed
transaction**. `DRC-30` implies this and never says it.

### 3.5 `DRC-30`'s Trade-permission hack should be a descriptor predicate, not a Trade special case

`DRC-30`'s July ruling treats an on-map captive as an eligible Trade target *"as though both units
had the same controller for Trade permission only,"* explicitly not mutating `controller_id`,
tactical side, or custody.

That instinct is right and is now expressible properly: after this morning's ruling the unit-state
service is the **only** path that mutates dimensions, so a permission fiction must not look like a
dimension write at all. It belongs in `[DRC-12]`'s interaction descriptor as an authored
**permission predicate** — the descriptor already owns which side may initiate and against whom —
rather than as a bespoke exception inside Trade. Otherwise it is precisely the kind of one-off
structure the standing optimization-pass row exists to find.

Trade must also consume `[EPUX-24]`'s shared atomic quote/commit/rollback core and `[EPUX-21]`'s
shared quantity primitive **by name**, so it does not become a third transaction implementation
beside shop and forge. `DRC-30`'s own note that Trade target discovery should reuse a shared
spatial query from `GridManager` is the same instinct, and it converges with `[DRC-12]`'s range
predicate — one geometry seam, several callers.

### 3.6 `DRC-32` versus `CAU-4`'s new `execution` tag

`DRC-32`'s ruled map-end disposition may *"count as that unit's death and may consequently turn an
apparent victory into defeat."* `CAU-4` gained an **`execution`** tag (permanent unit removal) only
yesterday, together with `recruitment` and `custody_change`, under the split-by-origin confirmation
ruling.

So: does an authored disposition that kills a residual captive emit `execution`, and is it
confirmable? It is authored, fires automatically at map end, and may invert the map result — the
strongest possible case for a confirmation, and also a case where a confirmation prompt during
automatic end-of-map resolution may be unwanted. `DRC-32` predates the tag and cannot have
considered it.

---

## 4. Suggested walk order

1. **`DRC-29` first** — the `custody_status` value set (§3.1). `DRC-31` and `DRC-32` both describe
   movement between these representations and cannot be checked until it exists.
2. **`DRC-27`, then `DRC-28`** — the capture-method registry and its eligibility profile, including
   the one-registry-or-two question in §2.2.
3. **`DRC-25`** — where the transition attaches (§2.1). Small, once the rest is stripped away.
4. **`DRC-30`** — the heaviest: §3.4's word collision and per-swap commit, §3.5's permission
   predicate, and the `EPUX-24`/`EPUX-21` consumption.
5. **`DRC-31`/`DRC-32` residue** — §3.2's tray branch, §3.3's two nesting questions, §3.6's
   `execution` tag.
6. **`DRC-33`** — the record's contents only; the option choice is already made.
7. **Skip `DRC-26` entirely.**
