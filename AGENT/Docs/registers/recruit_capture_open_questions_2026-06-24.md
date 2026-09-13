---
Role: dated
Type: register
Status: RESOLVED 2026-06-24
Last verified: 2026-06-24
Register: RCR-1..7
Resolved-in: 2026-06-24h
---

# Recruit / Capture (#4) — Roster-Side Design + Open Questions

> **Amended 2026-07-27 by `[DRC-19..33]`:** recruitment is no longer a faction-flip synonym and
> capture is no longer a recruited-state path. Use the five independent unit-state dimensions and the
> authoritative transition service. V1 recruitment may be permanent or map-end temporary with an
> explicit expiry; capture establishes custody independently of recruitability; residual captives
> route through authored end-map disposition and Explore/Prison.

**Started:** 2026-06-24 (session 2026-06-24h) — third and last branch of sync-cluster **A3** (roster
identity & relationships), after Relationship `[REL]` and Main Character / Avatar `[MCH]`.
**Status:** RESOLVED 2026-06-24h **for the roster-facing side**. Recruit/Capture **straddles three
clusters**: roster-state (A3, firmed here), the **conversation/trigger** side (A4 — MET `talk`/
`recruit`/`dialogue` actions), and **capture's physical carry/jail** mechanic (A2 — rescue/carry/
displacement). This pass firms the **shared recruited-state + the talk-recruit path** and writes the
**MET-action contract** A4 will build against; capture's carry mechanic is deferred to A2.
**Pattern:** mirrors `[IEQ]`/`[PXP]`/`[REL]`/`[MCH]`. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded — verified 2026-06-24h)
- **Faction model exists.** `Unit.team` is a faction id (`blue`=player, `red`=enemy; green/yellow
  planned), with `MapData.factions` / `FactionData`. So recruitment = a **faction flip** to the
  player faction on an on-map unit. No recruit/capture/talk code otherwise — clean slate.
- **Conversation side is MET's (A4).** The MET framework (F8, firmed) owns triggers + actions; it has
  a planned **`dialogue`** and **`flag`** action but **no `talk`/`recruit`/`capture` action yet**
  ("land with their seams"). REL-6 already added an `unlock_conversation` on-crossing verb.
- **F6 flag store** (decided, unbuilt) carries recruit *conditions* and recruited-*state* flags.

---

## 2. Resolved decisions

### [RCR-1] Recruitment model — **RESOLVED: faction flip → persistent roster member**
**Superseded by `[DRC-19..24]`.** Retained as the historical reason the five-dimensional model is
required; do not implement the coupled faction/roster mutation below.
Recruiting an on-map unit **flips its `team` to the player faction** AND promotes it into the
**persistent campaign roster** (survives map end). Reuses the existing faction/`FactionData` model;
no new allegiance concept.

### [RCR-2] Recruited-state persistence — **RESOLVED: roster membership + auto-set F6 flag**
> **The flag is RETIRED (2026-08-13, `DRC` Group A walk).** The auto-set `recruited:<unit_id>` F6 flag
> is dropped; story branching asks a **`[REQ-13(b)]` runtime unit-state predicate** about
> `roster_status` or recruitment history instead. The setter question disappeared rather than being
> answered — `[DRC-21]`'s `map_end` guest is a recruitment producing no membership, a case this item
> never anticipated, and every answer to "does a guest set the flag" was defensible, which is the sign
> the flag duplicated state the dimensions already hold. Retiring it also removes a leak hazard: a flag
> written outside `[DRC-9]`'s staged transaction would reintroduce exactly what `DRC-9` closed by
> construction. **The distinction below survives** — `roster_status` and recruitment history stay
> separately queryable.

A recruited unit becomes a **first-class persistent roster member**, AND recruiting **auto-sets an F6
flag** (`recruited:<unit_id>`) so story/branching can react. Both reserved in the F1 lock (RCR-7).
Roster membership answers "is X in my army"; the flag answers "did the player recruit X" for
branching — kept distinct.

### [RCR-3] A3/A4 seam — **RESOLVED: roster = state + API; MET (A4) = trigger + action**
> **Amended 2026-08-13 (`DRC` Group A, transition ownership): the roster does not own the API.** This
> item inverted the dependency — it gave the roster a `recruit()`/`capture()` API writing four
> dimensions the roster does not own. **One unit-state service owns reads and writes both**, and
> `apply(transition)` (a `[DRC-20]` sparse patch) is the only path that mutates the five dimensions;
> the roster is a **consumer** reacting to `roster_status`. That single path is where `[DRC-17]`'s
> blocking validation, the `[CAU-4]` tags and staged-transaction participation attach. **The hand-off
> contract below survives re-expressed, not discarded** — MET still supplies the trigger and the
> action; what changes is which service the action calls.

The roster side exposes a clean **`recruit(unit)` / `capture(unit)` transition API + recruited-state**;
it does **not** own a trigger. **MET (A4)** provides the **`talk` trigger** and the **`recruit` /
`dialogue` actions** that call the API. **Hand-off contract for A4:** add a MET `recruit` action
(calls `recruit(unit)`, optionally sets the flag + plays a `dialogue`) and a `talk` trigger
(unit-A-acts-on-unit-B). These are *not* yet in the MET vocab — A4 builds them against this contract.

### [RCR-4] Eligibility data split — **RESOLVED: identity/reward on the unit, firing-conditions on the MET trigger**
> **Absorbed by `[REQ-1..16]` (2026-06-25r / 2026-06-26); banner owed since then, paid 2026-08-13.**
> The firing-conditions half became ordinary `Requirement`s under `REQ`'s *"one evaluator + one display
> path"*, which names this item explicitly. This is load-bearing rather than housekeeping: **`REQ`'s
> display path supplies the reason string** `[DRC-11]`'s fifth-`EPUX-02`-surface ruling depends on,
> and `[RPD-10]`'s deploy eligibility depends on it too.
>
> **Also amended by `[DRC-25]` (2026-08-13):** the identity half loses its `recruitable` truth flag.
> The transition **opportunity** owns the `[REQ]` predicate, the `[DRC-20]` transition, the
> `[EPUX-02]` disclosure property and the selectors; the unit supplies identity and default hints only,
> so one unit may join several ways on different terms without duplicated unit data.

- **On the unit (A3):** what it *is* — `recruitable` + a recruitable-by hint + a join **reward**.
- **On the MET `talk` trigger (A4):** *when* it fires — recruiter present, required flags, "must not
  have attacked the recruiter," etc. (reuses MET's condition system + F6, no duplication).

### [RCR-5] Capture scope — **RESOLVED: talk-recruit + recruited-state now; capture-carry deferred to A2**
**Superseded by `[DRC-27..33]`.** Sleep/non-lethal remains one possible incapacitation method and carry
remains one custody representation, but neither implies recruitment.
Talk-recruit (the faction flip) and the shared recruited-state are firmed here. Capture's **roster
end-state** is defined: a captured enemy ends as **recruitable** (joins/recruited post-map or via the
RCR-3 API). Capture's **physical carry/jail/release mechanic is deferred to A2** (it shares
rescue/carry/displacement) — capture is a 3-way straddler, so its carry side firms with A2, not here.
> **Combat-capture path added (2026-06-24j, `[STY-6]`).** Beyond talk-recruit, a unit can be captured
> by a **non-lethal style**: it cannot drop below 1 HP and a would-be-lethal hit applies **`sleep`**
> instead; the sleeping unit is the capture-enabling state the A2 carry consumes. The non-lethal
> *attack* lands in A1 (`[STY]`); the **carry/jail/release stays A2** as above. Two capture paths now:
> talk-recruit (this register / A4) and combat non-lethal (`[STY]` / A1 + carry A2).

### [RCR-6] Main-character eligibility — **RESOLVED: a recruited unit may be a main character**
A recruited unit may carry the `[MCH]` main-character role; recruit conversations reuse the **F13**
text indirection + the REL-6 conversation hooks. No new mechanism.

### [RCR-7] Save / F1 schema — **RESOLVED: reserve the recruited-roster fields**
> **UNDERSIZED — re-derive the reservation (2026-08-13).** This predates the five-dimension model and
> reserves roster membership, the now-retired `recruited:<id>` flags, and eligibility/reward fields.
> Save-bearing state the reservation misses: the **five dimensions** (including `custody_status`),
> `[DRC-21]`'s duration/expiry data, `target_activation`, and the `[DRC-33]` transition record with its
> **references** to item-instance ledger entries. Size the schema from §4 of
> [`the integrated plan`](../plans/dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md),
> not from the list below. `[RCV-6]` carries the same defect.

Reserve in the F1 lock: the **roster-membership** entry for recruited units, the **`recruited:<id>`
flags**, and the unit **eligibility/reward** fields (RCR-4). Capture-carry state is reserved with the
A2 rescue/carry schema, not here.

---

## 3. Forward surfaces (deferred to their owning cluster)
- **Capture carry/jail/release** mechanic + UI — **A2** (rescue/carry/displacement).
- **MET `talk` trigger + `recruit`/`dialogue` actions** + "don't kill before recruiting" condition —
  **A4** (against the RCR-3 contract).
- Recruit **reward types** (gold/item/flag on join); green/yellow-faction recruitment; multiple
  eligible recruiters — authoring detail, ride RCR-4.

## 4. Notes
- **A3 complete:** with `[RCR]`, all three A3 branches (`[REL]` · `[MCH]`+F13 · `[RCR]`) have their
  **roster-facing side firmed** — the cluster's shared roster/save schema is defined for the F1 lock.
  **Next cluster: A1** (combat capabilities; finish the CEX cluster-B eval at its head).
- **DoD:** GDD section(s) + roadmap flip + `check_docs` checks land **with the build**, not at
  firming time.
