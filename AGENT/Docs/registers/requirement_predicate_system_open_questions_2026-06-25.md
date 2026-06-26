---
Type: register
Status: RESOLVED 2026-06-25r
Last verified: 2026-06-26
Register: REQ-1..14
Resolved-in: 2026-06-25r (REQ-1..8) / 2026-06-26 (REQ-9 compare, REQ-10 chance, REQ-11 item-property, REQ-12 unit/pool/availability sources, REQ-13 spatial/state/relationship/aggregate families, REQ-14 condition potency/duration); author-extension registry rides F4, condition-potency a forward-req on F5
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
Requirement **data is authoring** (not saved). Predicates **read** already-reserved or runtime state
(F6 flags, unit stats/level/skills/inventory/HP/pools, convoy, F5 conditions, `[REL]` ranks, grid
position, turn/pair/carry state) — **no new save surface** introduced by F16 itself. **One exception:**
the **REQ-10 `chance` latch** is persisted state, but it **rides** the `[DLG-11]` `visited_trail` /
`[F6]` (no new top-level field).
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
- **Value term** = `{ source }` resolving to a scalar. v1 sources:
  - **unit attributes** `{subject (REQ-3), attr}` — `level` · `stat:<name>` (`get_effective_stat`,
    string-keyed → F14) · `proficiency:<track>` (rank or wexp) · `item_count:{item_id, location}` ·
    `skill_count` · `gold`;
  - **item properties** `{item_ref, property}` — a property of an **equipped / held / targeted** item
    (REQ-11): numeric (`mt`/`hit`/`crit`/`wt`/`uses_remaining`/`cost`/`range`/`required_rank`-ordinal/…)
    or scalar-string (`combat_family`/`triangle_family`/`item_type`);
  - a **literal** constant.
  Author-extensible (same F4-style registry).
- **`compare`** predicate = `{ lhs: <term>, op, rhs: <term> }` — **both sides dynamic**, each side may
  name a **different subject/item** (the point of cross-subject/cross-item compare). Ordering ops
  (`< <= >= >`) are **numeric**; `==`/`!=` work on any **scalar** (number OR string, e.g. weapon
  `combat_family == "sword"`). Deterministic / pure read.
- **Generalizes REQ-2:** `stat(subject,name,op,n)` is sugar for `compare(term(subject,stat:name) op
  literal(n))`. Examples: my level > yours = `compare(term(speaker,level) > term(participant:other,
  level))`; **my weapon's Mt > yours** = `compare(item_property(equipped(speaker),mt) >
  item_property(equipped(participant:other),mt))`; **targeted item worth ≥ 5000** =
  `compare(item_property(targeted,cost) >= literal(5000))`.
- **Resolution:** RESOLVED 2026-06-26 — value terms span **unit attributes AND item properties**
  (equipped/held/targeted, REQ-11) plus literals; `compare` does numeric ordering + scalar (num/string)
  equality; REQ-2 constants are the literal-rhs case.

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

### [REQ-11] Item references + item-property terms & set predicates (owner add 2026-06-26)  **[RESOLVED]**
Let value terms (REQ-9) and predicates read **properties of a referenced item**, so authors can gate/
compare on equipped/held/targeted item stats — "is my weapon's Mt higher than yours", "does the held
relic have the armorslayer tag", "is the targeted item a sword".
- **Item reference (`item_ref`)** — identifies *which* item, relative to a subject or the action context:
  - **`equipped(subject)`** → the unit's equipped weapon/source (`get_equipped_weapon()` / the `[CEX-21]`
    equipped-source pointer).
  - **`held(subject, item_id | slot_index)`** → a specific inventory `InventoryEntry` / its `ItemDef`.
  - **`targeted`** → the item the current action targets (steal / forge-repair / break-item event /
    trade). **Context-resolved** (like `speaker`/`participant`): defined only where the consuming
    context supplies a targeted item; elsewhere the predicate is **false/undefined** (never errors).
- **Property vocabulary (grounded in the `[IEQ]` item model; author-extensible):**
  - **numeric** → `mt` · `hit` · `crit` · `wt` · `uses` / `uses_remaining` · `cost`(worth) · `range` ·
    `required_rank` (as an ordinal) · `strikes_per_attack` · `forged_mods.<k>` · equip-mods
    (`accuracy`/`damage`/`crit`/`dodge`) — usable in `compare` (REQ-9).
  - **scalar-string** → `combat_family` · `triangle_family` · `item_type` · `effect_id` ·
    `required_rank` (as a rank letter) — usable in `compare` `==`/`!=`.
  - **boolean** → `is_natural_weapon` · `uses_mag` — a bare predicate or `compare ==`.
  - **set** → `effect_tags` (Array) — **not** a scalar, so a dedicated **`item_has_tag(item_ref, tag)`**
    (and `item_has_effect(item_ref, effect_id)`) membership predicate; plus **`item_is(item_ref,
    item_id)`** (the referenced item is a specific id).
- **Subject reuse:** an `item_ref`'s owning unit uses the REQ-3 subject selector
  (`speaker`/`participant`/`unit:<id>`/`party`), so cross-subject item compares work
  (`equipped(speaker)` vs `equipped(participant:other)`).
- **Resolution:** RESOLVED 2026-06-26 — `item_ref` = `equipped|held|targeted` (targeted is
  context-resolved); item properties (numeric/string via `compare`, sets via `item_has_tag`/
  `item_has_effect`, identity via `item_is`); property vocab grounded in `[IEQ]`, author-extensible.

### [REQ-12] Additional unit / resource / availability value-term sources (owner add 2026-06-26)  **[RESOLVED]**
More value-term sources (all thin reads; usable in `compare`/`chance`):
- **HP:** `hp_current` · `hp_max` (`UnitData.hp` / `max_hp`) · **`hp_pct`** (= current/max×100). The
  **`pct` derived pattern generalizes** to any pool.
- **Resource pools (F7, `[CEX-1..4]`):** `pool:<id>.current` · `pool:<id>.max` · `pool:<id>.pct`.
- **Per-map ability availability:** `ability_uses_remaining:<skill/source id>` · `ability_available:<id>`
  (bool) · `usable_ability_count` — over `skill_use_counters` / `map_uses_remaining` (`[CEX-13]`) /
  charges (`[AGT §5]`, `[BAT-15]`); all `reset_map_state`-scoped.
- **Attack styles / sources (`[STY]`):** `style_available:<id>` · `source_available:<id>` (bool) ·
  `style_count` · `source_count` (total currently available, respecting the `[CEX-7]`/`[STY-3]` cap).
- **Identity / class:** `class_id` · `movement_type` · `promoted` (bool) · `is_main_character` (`[MCH]`)
  — via `compare ==` / a bare bool.
- **Resolution:** RESOLVED 2026-06-26 — HP (+`pct`), F7 pools (+`pct`), per-map ability availability,
  STY style/source availability+count, identity/class sources; author-extensible.

### [REQ-13] Gap predicate families — spatial · runtime-state · relationship-rank · aggregate (owner: all four 2026-06-26)  **[RESOLVED]**
Four families that **cannot** be expressed by combining the prior predicates; the owner folded **all
four** into the v1 vocabulary (each an independent family; **build as a consumer needs it**):
- **(a) Spatial / positional** — `adjacent(subjectA, subjectB)` · `distance(subjectA, subjectB) op N`
  (grid **Manhattan** metric, the movement/`[DSP]` default) · `on_terrain(subject, terrain)` ·
  `in_region(subject, region/zone)`. Reads `GridManager` + `MapData`. Subject(s) per REQ-3; a tile may
  be named directly.
- **(b) Runtime unit-state** — `has_acted` / `has_moved` / `can_act` (`TurnManager` `READY/MOVED/DONE`) ·
  `is_deployed` · `is_paired` (`PairUpRegistry`) · `is_carried` / `is_rescuing` (`CarryRegistry`/`[DSP]`)
  · `is_captured`/`asleep` (`[STY-6]`). Thin runtime reads.
- **(c) Relationship / support rank** — `relationship_rank(a, b) op <rank>` reading the **`[REL]`**
  pair-graph (ordinal → `compare`-able). Natural for dialogue ("if your bond with X ≥ A"). A pair-keyed
  term, not a unit attribute.
- **(d) Aggregate / count** — `count(<subject-set>, <Requirement>) op N` over a set (`party` · `faction`
  · `in_region(...)` · `participants`): "≥3 units have skill X", "<2 fliers deployed". **Generalizes
  REQ-3** any/all (`any` = count≥1, `all` = count==size). The one family that composes a sub-Requirement.
- **Resolution:** RESOLVED 2026-06-26 — all four families in the v1 design; each reads existing runtime
  state (grid / turn / pair-carry / `[REL]` / a party loop); build per-consumer; author-extensible.

### [REQ-14] Active-condition potency & duration (owner Q 2026-06-26)  **[RESOLVED — potency = forward-req on F5]**
`has_condition` (REQ-6) only tests **presence**. Add value-term sources reading **F5 active-condition
state** so authors can gate on magnitude/time:
- **`condition_potency:{subject, condition_id}`** — the stack/magnitude ("poison stack ≥ 3").
- **`condition_duration:{subject, condition_id}`** — turns remaining ("sleep wears off next turn ≤ 1").
- **`condition_count:{subject}`** — number of active conditions.
- Used via `compare`. **Dependency:** `condition_duration`/`count` read F5's already-reserved
  active-condition state (type + duration, `[STY-12]`); **`condition_potency` is a forward-requirement
  on the F5 status model** — F5 must model a magnitude/stack dimension for potency to exist. Flagged for
  the F5 build (degrades gracefully: if F5 has no potency, the term is unavailable, not an error).
- **Resolution:** RESOLVED 2026-06-26 — `condition_potency`/`duration`/`count` value terms over F5
  state; potency pins a **forward-requirement on the F5 status model**.

---

## Cross-references
- **Foundation F16.** Consumed by: `[DLG-14]` (dialogue gating), MET `[MET-4]`, `[VIL-6]`, `[RCR-4]`,
  `[IEQ]` `req_flags`, objectives.
- Reads (does not own): `[F6]` flags, unit data (`level`/`skills`/`get_effective_stat`/`proficiency`/
  `inventory`/`hp`/`max_hp`), F7 pools (`[CEX-1..4]`), per-map counters (`skill_use_counters`/
  `map_uses_remaining`/charges), `[STY]` styles/sources, `[CNV]` convoy, **item properties** (`[REQ-11]`
  via `[IEQ]`/`[CEX-21]`), **F5 conditions** (presence + `[REQ-14]` potency/duration), the
  `[PRV]`/`[STY-17]` relationship, **`[REL]` support ranks** (`[REQ-13c]`), and **grid/turn/pair-carry
  runtime state** (`GridManager`/`MapData`, `TurnManager`, `PairUpRegistry`/`CarryRegistry` — `[REQ-13a/b]`).
- **Forward-requirement:** `[REQ-14]` `condition_potency` needs the **F5 status model to carry a
  magnitude/stack dimension** (degrades gracefully if absent).
- Composition precedent: the objective AND/OR-group evaluator.
- **REQ-10 `chance`** depends on **`RngService` / Package A (`[PKGA]`)** (seeded, rewind-safe) and a
  **CampaignRules (F4) skew profile** (`linear`/`sigmoid`/`table`); latch rides `[DLG-11]`/`[F6]`.
