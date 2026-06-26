---
Type: register
Status: RESOLVED 2026-06-25r
Last verified: 2026-06-26
Register: REQ-1..10
Resolved-in: 2026-06-25r (REQ-1..8) / 2026-06-26 (REQ-9 value-term compare, REQ-10 chance gate); author-extension registry detail rides F4 / the define-all sweep
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
- *(The `class_level`/`stat`/`proficiency` constant comparisons generalize to **REQ-9** value-term
  `compare(term op term)`; **REQ-10** adds a `chance` gate. These are the literal-rhs / probabilistic
  cases of the same family.)*
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
unit stats/level/skills/inventory, convoy) — **no new save surface** introduced by F16 itself. **One
exception:** the **REQ-10 `chance` latch** is persisted state, but it **rides** the `[DLG-11]`
`visited_trail` / `[F6]` (no new top-level field).
- **Resolution:** RESOLVED 2026-06-25r — authoring data; reads reserved state; adds nothing to the lock
  except the REQ-10 chance latch, which rides `visited_trail`/`[F6]`.

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

### [REQ-9] Value terms + deterministic two-value `compare` (owner add 2026-06-26)  **[RESOLVED]**
Generalize the constant-comparison predicates (REQ-2 `class_level`/`stat`/`proficiency`) to compare
**two dynamic values**, e.g. "is my level > yours", "is my STR > your DEF", "do I have more sword skill
than you".
- **Value term** = `{ subject (REQ-3), source }` resolving to a number. v1 sources mirror REQ-2
  attributes: `level` · `stat:<name>` (`get_effective_stat`, string-keyed → F14) · `proficiency:<track>`
  (rank or wexp) · `item_count:{item_id, location}` · `skill_count` · `gold` · a **literal** constant.
  Author-extensible (same F4-style registry as predicate types).
- **`compare`** predicate = `{ lhs: <term>, op: < | <= | == | != | >= | >, rhs: <term> }` — **both sides
  dynamic**, and each side may name a **different subject** (the whole point of cross-subject compare).
  Deterministic / pure read.
- **Generalizes REQ-2:** `stat(subject,name,op,n)` is sugar for `compare(term(subject,stat:name) op
  literal(n))`; the constant predicates are the literal-`rhs` special case. Examples: my level > yours =
  `compare(term(speaker,level) > term(participant:other,level))`; sword edge =
  `compare(term(speaker,proficiency:sword) > term(participant:other,proficiency:sword))`.
- **Resolution:** RESOLVED 2026-06-26 — reusable value terms (subject + source, incl. literal) + a
  `compare(term op term)` predicate; REQ-2 constants are the literal-rhs case.

### [REQ-10] Chance gate — a comparison-skewed probabilistic predicate (owner add 2026-06-26)  **[RESOLVED]**
A **`chance`** predicate: a gate that succeeds by a random roll whose odds are **skewed by a comparison
of two value terms** (REQ-9). The **one stateful/impure predicate** — all others are pure reads.
- **Shape:** `{ base, skew?: { lhs:<term>, rhs:<term>, operand: difference|ratio, profile:<skew-profile>
  }, latch: once(default)|re_rollable }`. `success% = skew_profile.apply(base, operand(lhs, rhs))`,
  clamped by the profile. With no `skew`, it's a flat `base%` gate.
- **Skew profile = a CampaignRules (F4) profile** (owner call): `linear {k, floor, ceil}` (default) ·
  `sigmoid {steepness, midpoint}` · `table` · author-custom; selected **per gate**. Reuses the F4
  generic profile mechanism — no bespoke curve code.
- **Operand = author's choice per gate:** `difference (lhs − rhs)` (default, FE-additive feel) ·
  `ratio (lhs / rhs)`.
- **RNG discipline (hard requirement):** routes through **`RngService` / Package A** (`[PKGA]`) —
  seeded, **canonical roll order, rewind-safe**; **never** engine RNG (respects the `check_rng_usage`
  guard). A `chance` predicate is **not built until Package A lands** (it is the L0 RNG foundation).
- **Latching (owner call — roll once + latch):** rolls **once** on first evaluation and **latches** the
  outcome into the conversation `visited_trail` (`[DLG-11]`) and/or an **`[F6]` result key** (for
  cross-context reads), so **save→reload, rewind, or re-evaluation returns the same answer** — no
  save-scum, consistent with Package A's anti-reroll discipline. Author may set **`re_rollable`** for
  intentional retries (does not latch / clears the latch).
- **Display vs commit (REQ-5 interplay):** a `chance` gate **displays its odds** ("65%") rather than a
  boolean; **evaluation IS the roll** — so it is evaluated **on commit** (the choice is taken), not for
  passive preview. Pure predicates may be previewed freely; `chance` may not.
- **General primitive (reuse):** comparison-skewed-chance also serves persuade/steal/intimidate, status
  infliction, etc. — a shared "contest/check" gate, mirroring combat hit math; surfaced here, not
  dialogue-only.
- **Save note (amends REQ-7):** the **latched roll outcome** is new state, but it **rides existing
  reserved surfaces** — the `visited_trail` (`[DLG-11]` `conversation_resume`) for in-conversation gates
  and `[F6]` for persistent results — **no new top-level save field.**
- **Resolution:** RESOLVED 2026-06-26 — `chance` = base + F4 skew-profile over a difference|ratio of two
  terms, rolled via RngService/Package A, **roll-once-and-latch** (author `re_rollable`); the one impure
  predicate; latch rides `visited_trail`/`[F6]`.

---

## Cross-references
- **Foundation F16.** Consumed by: `[DLG-14]` (dialogue gating), MET `[MET-4]`, `[VIL-6]`, `[RCR-4]`,
  `[IEQ]` `req_flags`, objectives.
- Reads (does not own): `[F6]` flags, unit data (`level`/`skills`/`get_effective_stat`/`proficiency`/
  `inventory`), `[CNV]` convoy, F5 status (via `has_condition`), the `[PRV]`/`[STY-17]` relationship
  (via a `relationship` predicate).
- Composition precedent: the objective AND/OR-group evaluator.
- **REQ-10 `chance`** depends on **`RngService` / Package A (`[PKGA]`)** (seeded, rewind-safe) and a
  **CampaignRules (F4) skew profile** (`linear`/`sigmoid`/`table`); latch rides `[DLG-11]`/`[F6]`.
