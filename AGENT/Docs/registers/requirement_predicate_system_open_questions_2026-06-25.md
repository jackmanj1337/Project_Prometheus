---
Type: register
Status: RESOLVED 2026-06-25r
Last verified: 2026-06-25
Register: REQ-1..8
Resolved-in: 2026-06-25r (author-extension registry detail rides F4 / the define-all sweep)
---

# Shared Requirement / Predicate System (Foundation F16) — Player-Facing Design + Open Questions

**Started:** 2026-06-25r (surfaced by the dialogue branch-gating question — the listed conditions are
not dialogue-specific).
**Status:** **[REQ-1..8] RESOLVED 2026-06-25r** (design firmed; the author-extension *registry*
mechanism rides the F4 profile pattern / the define-all sweep). Foundation **F16**.
**The insight:** the conditions an author wants on a dialogue branch (campaign/map flags · speaking/
participating unit ids · class level · proficiency level · stat level · skill/trait possession · items
held/equipped/in-convoy …) are the **same predicate set** that **MET triggers** (`[MET-4]` condition),
the **`[VIL-6]` tile-action "required characteristics"**, **`[RCR-4]` recruit eligibility**, **`[IEQ]`
accessory `req_flags`**, and **objective conditions** all want. So define **ONE shared, author-
extensible requirement-predicate vocabulary** they all evaluate against — not N parallel condition
languages.

**Method (owner pref `feedback_feature_walk_end_shape_first`):** end-shape via questions first. Owner
calls (2026-06-25r): **one shared predicate foundation** (not dialogue-local); subject = **author's
choice (participant-relative AND named/party)**; gating granularity = **option + segment + whole
conversation**; gated-out UX = **author's choice per option** (hidden secret | shown-disabled-with-
requirement, mirroring `[VIL-6]`/`[VIL-7]`).

**Code grounding (every predicate is a thin read over an existing accessor):** `UnitData.level:int`,
`UnitData.skills:Array[String]`, `UnitData.inventory`, `Unit.get_effective_stat(name)` (string-keyed —
covers F14 `extra_stats` for free), the `weapon_rank_for_wexp` proficiency helpers, the `[CNV]` convoy
store, the `[F6]` flag store, and the `[CEX-15]` "party/unit holds item X" predicate already pinned in
MET. The objective system's **AND/OR per-group** evaluation is the composition precedent.

---

## Verdict

> **One author-extensible Requirement = a boolean tree (AND/OR/NOT) of typed predicates, each a ~1-line
> adapter over existing data, evaluated against a named subject.** It is **net-simplifying** — it
> replaces the scattered ad-hoc condition code (MET flag-only `[MET-4]`, `req_flags`, the `[VIL-6]`
> requirement text, `[RCR-4]` eligibility) with one evaluator + one display path. Dialogue branches
> (`[DLG-14]`) are just another consumer.

---

## Register

### [REQ-1] One shared predicate system = foundation **F16**  **[RESOLVED]**
A **`Requirement`** is a data structure evaluated to `bool` against game state: a boolean tree
(`all`/`any`/`not`) of **typed predicates**. **Consumers (unified):** dialogue branch/segment/
conversation gating (`[DLG-14]`), MET `condition` (generalizes `[MET-4]`), `[VIL-6]` tile-action
requirement, `[RCR-4]` recruit eligibility, `[IEQ]` accessory `req_flags`, and objective preconditions.
- **Resolution:** RESOLVED 2026-06-25r — one shared `Requirement` evaluator (F16); consumers above.

### [REQ-2] Predicate vocabulary v1 — thin adapters over existing accessors  **[RESOLVED]**
Each predicate = `{ type, subject (REQ-3), …params, op? }`. v1 types (each a 1-line read):
- **`flag`** `{scope: map|campaign, name}` → `[F6]`.
- **`unit_is` / `unit_present`** `{subject, unit_id}` → identity / on-map presence.
- **`class_level`** `{subject, class_id?, op, n}` → `UnitData.level` (+ class id).
- **`proficiency`** `{subject, track, op, rank}` → `weapon_rank_for_wexp(proficiency_xp)`.
- **`stat`** `{subject, name, op, n}` → `get_effective_stat(name)` (string-keyed → F14 stats too).
- **`has_skill` / `has_trait`** `{subject, id}` → `UnitData.skills`.
- **`has_item`** `{subject, item_id, location: held|equipped|convoy}` → `inventory` + `[CNV]` convoy.
- **Author-extensible:** new predicate types register without an engine change (the **F4 profile-style
  registry**); each is a named evaluator. (The registry mechanism rides F4 / the sweep.)
- **Resolution:** RESOLVED 2026-06-25r — 7 v1 predicate types as accessor adapters + F4-style
  extensibility; `has_item` carries a `location` (held/equipped/convoy).

### [REQ-3] Subject selector — author's choice (participant-relative AND named/party)  **[RESOLVED]**
Each predicate names its **subject**: `speaker` · `participant:<role>` · `unit:<id>` · `active_unit` ·
`party(any|all)`. So "if the **speaker** is a Lord" and "if **anyone in the party** holds the relic" are
both expressible. Participant-relative subjects (`speaker`/`participant`) are resolved by the consuming
context (dialogue supplies its participants; a tile-action supplies the acting unit).
- **Resolution:** RESOLVED 2026-06-25r — both modes; per-predicate subject selector.

### [REQ-4] Composition — AND/OR/NOT boolean tree  **[RESOLVED]**
A `Requirement` composes predicates with `all` (AND) / `any` (OR) / `not`, nestable — reusing the
objective AND/OR-group precedent. A bare single predicate is the degenerate case.
- **Resolution:** RESOLVED 2026-06-25r — nestable all/any/not tree.

### [REQ-5] Display — render a Requirement to human-readable text  **[RESOLVED]**
A Requirement renders to text for the `[VIL-6]` "required characteristics" readout and the
shown-disabled choice UX ("[Requires: Lockpick]" / "Needs Charisma ≥ 10"). Each predicate type carries
a **display template (F13 key)**; the tree renders compositionally. Authors may override the rendered
string per use (a custom hint).
- **Resolution:** RESOLVED 2026-06-25r — per-type F13 display templates, compositional render,
  per-use override.

### [REQ-6] Boundaries — vs F5 status, F6 flags, and the relationship matrix  **[RESOLVED]**
Clean separations (do **not** merge):
- **`[F6]` flags** = **one predicate source** (the `flag` type), not the whole system.
- **F5 `ConditionData`** = status **effects** (a state a unit is *in*: poison/sleep) — **distinct** from
  predicates (a *test*). A `has_condition(subject, condition_id)` predicate may **query** F5 state, but
  F16 does not own status effects.
- **The faction-relationship matrix** (`[PRV]`/`[STY-17]`) is a **separate axis** (a `relationship`
  predicate may read it, but stance is not a Requirement). 
- **Resolution:** RESOLVED 2026-06-25r — F16 is the predicate/test layer; F6/F5/relationship are
  sources it can read, not things it absorbs.

### [REQ-7] F1 / save  **[RESOLVED]**
Requirement **data is authoring** (not saved). Predicates **read** already-reserved state (F6 flags,
unit stats/level/skills/inventory, convoy) — **no new save surface** introduced by F16 itself.
- **Resolution:** RESOLVED 2026-06-25r — authoring data; reads reserved state; adds nothing to the lock.

### [REQ-8] Consumer reconciliation (non-breaking; not relitigated)  **[RESOLVED]**
F16 **generalizes** existing condition notions; the owning registers **consume**, they are not
re-opened:
- **`[MET-4]`** flag predicate → a `Requirement` (a bare `flag` predicate is the non-breaking base; the
  full vocabulary is now available to MET triggers/guards).
- **`[VIL-6]`** tile-action `requirement` → a `Requirement` rendered via REQ-5.
- **`[RCR-4]`** recruit eligibility firing-conditions → `Requirement`s.
- **`[IEQ]` `req_flags`** → `Requirement`s (legality predicates).
- **Objectives** keep their AND/OR group evaluator but may **reference** REQ predicates.
- **Resolution:** RESOLVED 2026-06-25r — one vocabulary; consumers adopt it non-breakingly.

---

## Cross-references
- **Foundation F16.** Consumed by: `[DLG-14]` (dialogue gating), MET `[MET-4]`, `[VIL-6]`, `[RCR-4]`,
  `[IEQ]` `req_flags`, objectives.
- Reads (does not own): `[F6]` flags, unit data (`level`/`skills`/`get_effective_stat`/`proficiency`/
  `inventory`), `[CNV]` convoy, F5 status (via `has_condition`), the `[PRV]`/`[STY-17]` relationship
  (via a `relationship` predicate).
- Composition precedent: the objective AND/OR-group evaluator.
