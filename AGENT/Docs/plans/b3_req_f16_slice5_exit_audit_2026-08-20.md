---
Type: handoff
Status: Active — findings `[1]`–`[7]` REMEDIATED 2026-08-20 (`975b38bd`, merged `92a5ff4e`); §3 divergences DISPOSITIONED 2026-08-20 (§6)
Last verified: 2026-08-20
Tracker: B3-REQ-F16-BUILD-2026-08-18-2026-08-19
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

> **REMEDIATED 2026-08-20**, same day, on
> `agent/from-integration/b3-req-slice5-remediation` (`975b38bd`), merged to
> `agent/integration` at `92a5ff4e`. Every finding in §2 is fixed and pinned by the
> spec-named test that was missing. Suites went **5 → 24** (formula) and **5 → 34**
> (requirement); the full 144-suite run is green. **A sixth defect surfaced while writing
> the tests** — see §2.8. What remains open is §3, which is a set of decisions to take
> rather than defects to fix.

# `B3-REQ` / F16 — Slice 5 Exit-Criteria Audit (2026-08-20)

The `B3-REQ-F16-BUILD-2026-08-18-2026-08-19` row was set to `in_review` rather than
`completed` because *"this session did not author the work and did not audit it against
Slice 5's exit criteria item by item; a reviewer should confirm the B3-TEXT text-key seam
half and close it."*

This is that audit.

**Verdict: do not close. Returned to `in_progress`.** The build is a real and largely
sound vertical slice, but it does not meet Slice 5's exit criteria, and three of the gaps
produce **silently wrong answers in the system that gates content**.

Everything below was **measured by execution** against `agent/integration` `6085e354` on
Godot 4.6.3, not read off the source. Spec source:
[`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](band3_core_authoring_foundations_implementation_plan_2026-06-30.md)
§Slice 5.

---

## 1. What the row asked about, and what it is: **confirmed good**

The B3-TEXT text-key seam — the specific half the row asked a reviewer to confirm —
**works**. `test_requirement.gd` builds a real `TextDB`, and
`render_reason(reason, db)` renders `req.flag` + `{name: "missing"}` into
`"Requires missing"`. `REQ-5`'s render-to-text path is genuinely present, which is what
let `ENGINE-PREDICATE-UNMET-REASON-2026-07-26` close by precedence.

Also verified working:

| Slice 5 requirement | State |
|---|---|
| Map-free evaluation (`RequirementContext` as a plain dictionary) | ✓ |
| Open predicate/value-source registration, no engine edit to add one | ✓ |
| `not` over an absent subject evaluates **true** (the subtle clause) | ✓ |
| Structured `{met, reasons, trace, errors}` with predicate path | ✓ |
| `REQ-8` objective bridge (`evaluate_objective_condition`) | ✓ |
| `0^0 = 1` (fixed-point `1000`) | ✓ |
| `div` missing `on_zero` is a **validate** error | ✓ |
| `on_zero: to_max` clamps to `+MAX_FIXED` | ✓ |
| Hard ceilings exist; a pack may lower but never raise (`mini(budget, MAX)`) | ✓ |
| First production consumer beyond tests (`CadenceEngine` predicate triggers) | ✓ |

The architecture is right. The gaps below are completeness and hardening, not a rewrite.

---

## 2. Blocking findings

Ordered by severity. `[1]`–`[3]` are the ones that matter most, because this is the
**gating** system: a wrong answer here silently opens or closes content.

### `[1]` Integer overflow before the clamp — `pow` returns a **negative** result for a positive base

Spec: *"Fixed-point ×1000, 64-bit, every node clamped"*, and the test list names
**"clamp on overflow"** explicitly. Measured:

| Expression | Returned | Should be |
|---|---|---|
| `mul(9e12, 9e12)` | `5404116273116218` | clamp to `MAX_FIXED` = `9000000000000000` |
| `pow(9e12, 3)` | **`-7525728660033044`** | clamp to `MAX_FIXED` |

`_clamp()` is applied to the *result* of a multiply that has already wrapped: in
`_evaluate_node`, `pow` computes `answer * values[0]` and `mul` computes
`product * value` where **both factors can already be `MAX_FIXED` = 9e15**, so the product
reaches ~8.1e31 against an int64 ceiling of ~9.22e18. The wrap happens first; the clamp
then tidies a number that is already garbage. **No error, no `available: false` — just a
wrong number, sign included.**

*Fix shape:* clamp the operands or detect overflow **before** multiplying (compare against
`MAX_FIXED / operand`), not after.

### `[2]` An empty `all` gate silently **passes**

Spec: *"`all`/`any` have at least one [child]"*. Not enforced. Measured:

```
{"op": "all", "children": []}   validate -> []   evaluate -> met = true
{"op": "any", "children": []}   validate -> []   evaluate -> met = false
```

An authoring typo that produces an empty `all` is **vacuously satisfied**, so the gate
opens. In a system whose entire job is deciding whether content is available, the failure
direction is the wrong one, and validation accepts it without comment.

### `[3]` `presentation.gate` is entirely unimplemented

Spec: *"`presentation.gate` is `visible_disabled` by default or `hidden_until_met`; hidden
presentation suppresses player display, not diagnostics"* — and the test list requires
*"Hidden versus visible-disabled changes presentation only"*. Measured:

- `gate` is **never read** — `_reason()` consumes only `presentation.override_text_key`.
- `gate` is **never surfaced** in the reason dictionary, so no consumer can act on it.
- `{"presentation": {"gate": "NOT_A_GATE"}}` **passes validation** with zero errors.

This is directly load-bearing beyond Slice 5: `[EPUX-02]`'s per-entry gate presentation and
`[EPUX-04]`'s hidden-vs-disabled shell decision both consume it, and it is the same
property the freshly-ruled `[ANN-2]` announcement mapping will need. **Whoever builds
`SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL` should know this producer half does not exist
yet.**

### `[4]` Seven operators crash on input `validate()` has just accepted

`validate()` never checks operator **arity**. Measured — each of these validates clean,
then throws `Out of bounds get index '0'` (or a `Nil`→`int` conversion error) and returns
an empty `{}`:

`abs` · `neg` · `not` · `truthy` · `sub` · `min` · `max`, each with `operands: []`.

Only `div` degrades gracefully (`"div requires two operands"`). Same class one level up:
`{"op": "all"}` with **no `children` key at all** validates clean and then crashes in
`_evaluate_node` on `node.children`.

Validated-then-crashes is precisely what a validation pass exists to prevent, and packs
are the untrusted input here.

### `[5]` Four of the eleven v1 predicates are missing

Spec step 2 names the v1 vocabulary. Measured registrations:

| Registered | Missing |
|---|---|
| `flag`, `unit_is`, `unit_present`, `has_skill`, `has_trait`, `in_group`, `compare`, `campaign_var` (extra) | **`class_level`**, **`proficiency`**, **`stat`**, **`has_item`** |

`has_item {held\|equipped\|convoy}` is the conspicuous one: it is the predicate used in
**Slice 5's own canonical JSON example**, and it is what `[CVS-S2]` key-item properties,
convoy and shop all need. `stat` is required by `compare`'s intended use.

### `[6]` `has_trait` is a silent alias of `in_group` — **partly withdrawn**

`_eval_has_trait()` calls `_eval_in_group()` verbatim, so traits and groups are one
namespace.

> **CORRECTION 2026-08-20.** The audit filed this as an undocumented conflation. Reading
> `[REQ-2]` to recover the ratified param shapes for `[5]` showed it is **ratified
> behaviour**: the `[TCV-3]` note embedded under `[REQ-2]` (2026-06-27d) says
> group-membership *"reuses this family — a `has_trait`/`in_group` read over an
> author-assignable per-unit `groups`/tags field"*. So the alias is correct and the finding
> is withdrawn.
>
> What survives is small: the two registrations keep **distinct text keys**
> (`req.has_trait` vs `req.in_group`), so a group check still renders a player-facing
> reason that says *trait*. Worth a text-key decision, not a code change.

This is the same failure shape the corpus keeps producing — a reading of the code without
the register beside it. The register was two greps away.

### `[7]` `sub` and `div` silently drop operands past the second

Spec permits up to 32 operands per variadic arithmetic node. Measured:
`sub(10, 3, 2)` returns `7.0` — the `2` is discarded with no error. `div(10, 3, 2)`
likewise. A silent wrong answer rather than a validation failure.

---

### `[8]` Found during remediation, not by the audit: `on_zero: {to_value}` **threw on every divide by zero**

The audit probed `to_max` and stopped. Writing the missing coverage for the *other* two
ratified `REQ-16` policies exposed a sixth defect:

```
SCRIPT ERROR: Invalid operands 'Dictionary' and 'String' in operator '=='.
    at: _zero_result (FormulaEvaluator.gd:206)
```

`_zero_result` compared the policy against `"to_max"` **before** checking its type, and
comparing a Dictionary to a String is a hard runtime error in GDScript — so the
`{"to_value": <term>}` form, one of the three policies the owner ratified in 2026-07-30's
Option A, crashed every time it was reached. Fixed by type-checking first; an unknown
policy is now a **validate** error rather than a runtime surprise.

**The lesson is about the audit, not the code:** probing one enum value and generalising is
how a defect hides behind a passing check. The remediation now covers all three policies.

---

## 3. Non-blocking divergences worth recording

- **The runtime evaluators are recursive, and the spec bolds the opposite.** Step 3:
  *"The evaluator is **iterative (explicit stack)**"*, and §Complexity budgets:
  *"Runtime evaluators remain iterative"*. `FormulaEvaluator._evaluate_node` and
  `RequirementSystem._evaluate_node` both recurse. In practice the depth ceiling (32) and
  the shared step budget make a stack overflow unreachable, so this is a divergence rather
  than a defect — but it is an explicit, bolded requirement and should be either honoured
  or consciously waived in writing. `validate()` in both files *is* correctly iterative.
- **`RegistryManager` has no `predicate_type` / `value_source` families.** Slice 5 lists
  the file under "files to create or touch" and states it again under "Registry
  obligations". `RequirementSystem` keeps private dictionaries instead. The open-registry
  *principle* is satisfied; the stated registry *home* is not.
- **Requirement depth default (16) is unenforced.** Only the hard ceiling (32) applies;
  `CampaignRules` exposes node budgets but no depth budget, and `Formula.validate` is
  called with a hardcoded `16`. A pack cannot lower depth as the spec allows.
- **DoD#2 purity check is absent** — no purity flag on registration, so "no impure
  predicate reachable from inside a value term" cannot be checked. Reasonably deferred
  **with** `chance` (correctly not built until `B1-PKGA`), but it should be deferred
  explicitly rather than by omission.
- **`Requirement.gd`, `Predicate.gd` and `ValueTerm.gd` are byte-identical do-nothing
  wrappers** (12 lines each: hold a Dictionary, return a copy). All real behaviour lives in
  `RequirementSystem` and `FormulaEvaluator`. They are exported `class_name` globals that
  look like the API and are not it — either give them the behaviour Slice 5 assigns them or
  delete them.
- **`any` reports `results[0].reasons`**, i.e. the first child; spec asks for *"the most
  actionable child reason"*. `all` has no display cap. Both minor.

---

## 4. Why the suites did not catch any of this

They are honest but thin: **5 assertions each**, all happy-path.

`test_formula_evaluator.gd` covers addition, one `on_zero` policy, missing `on_zero`,
`0^0`, and canonical booleans. Slice 5's test list additionally requires **clamp on
overflow** (finding `[1]`), `floor`/`ceil` rounding, *each* `on_zero` policy, and budget
overflow at load — none present. The single most load-bearing missing test is the one that
would have caught the negative `pow`.

`test_requirement.gd` covers composition, not-over-absent-subject, the structured reason,
text-key rendering, and open registration — a good five, and it is why §1's list is as
strong as it is. Absent: per-type truth tables, golden JSON round-trip, budget limits,
hidden-vs-visible-disabled, and the P0/P1 FE-fixture parity the spec requires.

**A full green suite here means "the paths we wrote tests for work", not "Slice 5 is
met".** The 144-suite gate passing is not evidence against this audit.

---

## 5. Disposition — what was done, and what is left

**Done 2026-08-20** (`975b38bd`, merged `92a5ff4e`):

| Finding | Fix |
|---|---|
| `[1]` overflow | `_mul_fixed` bounds the product **before** multiplying, so `mul`/`pow` saturate at `MAX_FIXED`. `pow` of a positive base is now positive. |
| `[2]` empty composition | Empty or missing `children` is a validate error; `_evaluate_node` also degrades instead of throwing. |
| `[3]` `presentation.gate` | Validated against the two ratified values, defaulted to `visible_disabled`, and **surfaced in the reason** so a consumer can act on it. |
| `[4]` operator arity | `OPERATOR_ARITY` validates every operator; the seven crashers are now validate errors. |
| `[5]` missing predicates | `class_level`, `proficiency`, `stat`, `has_item` registered with the **ratified** `[REQ-2]` param shapes. |
| `[7]` dropped operands | `sub`/`div`/`pow` are strictly binary; a third operand is an error, not a silent discard. |
| `[8]` `to_value` crash | Type-checked before comparison; an unknown policy is a validate error. |

Tests went **5 → 24** and **5 → 34**, each new assertion tied to a Slice 5 line that had
no coverage. Full 144-suite run green.

**Still open — decisions, not defects.** Everything in §3: the recursive evaluators against
a bolded "iterative" requirement, the missing `RegistryManager` families, the unenforced
depth default, the deferred purity check, the three do-nothing wrapper classes, and
`any`'s first-child-not-most-actionable reason. Each needs to be **honoured or waived in
writing** so the next audit does not re-derive them. The `[6]` text-key question belongs
here too.

**Closing this row is now a judgement about §3, not about defects.** `PREP-V1-S01`'s other
three blockers are untouched by this work.

> **Superseded 2026-08-20 by §6**, which takes every §3 decision. Three findings the
> audit did not reach are recorded in §6.8.

> **Carry to the announcement channel:** `[3]` is fixed, so `[ANN-2]`'s mapping now has the
> gate presentation it assumed. `RequirementSystem.gate_for(node)` returns it, and every
> reason dictionary carries a `gate` key.

---

## 6. §3 dispositions — taken 2026-08-20

Every §3 item is now honoured or waived **in writing**, which is what the tracker row
was holding `in_review` for. Two resolved to code (`ad4ba215`, merged to
`agent/integration`); four are waivers with a stated reason; one is withdrawn because
the audit's claim did not survive a check against the code.

Each waiver records **what would make it wrong**, so a future audit can re-open it on
evidence instead of re-deriving the question.

| §3 item | Disposition |
|---|---|
| Recursive evaluators vs bolded "iterative" | **Waived, conditionally** |
| `RegistryManager` predicate/value-source families | **Waived** |
| Requirement depth default unenforced | **Honoured** — `ad4ba215` |
| DoD#2 purity check absent | **Waived, deferred to `B1-PKGA`** |
| Three do-nothing wrapper classes | **Honoured by deletion** — `ad4ba215` |
| `any` reports the first child's reason | **Waived** |
| `[6]` `has_trait` / `in_group` text key | **Withdrawn — the audit's claim is false** |

### 6.1 Recursive evaluators — waived, and the condition is load-bearing

Slice 5 bolds *"The evaluator is **iterative (explicit stack)**"*. Both runtime
evaluators recurse. Waived, because the recursion is **bounded before it starts**:

- `FormulaEvaluator.evaluate()` runs `validate()` (iterative) first **and**
  `_evaluate_node` carries its own `depth > HARD_MAX_DEPTH` guard. Two independent bounds.
- `RequirementSystem.evaluate()` runs `validate()` (iterative, depth-capped) first, but
  `_evaluate_node` takes **no depth parameter at all** and has no runtime guard. Its only
  bound is the validate gate.

That asymmetry is the whole content of this waiver. The requirement evaluator is safe
**because `evaluate()` validates on every call** — so the validate-first ordering is not
an implementation detail that a later optimisation may drop. Anyone who makes validation
conditional (a cached-validation fast path, a "trusted content" bypass, a caller reaching
`_evaluate_node` directly) **reintroduces unbounded recursion over author-supplied
content**, which is what the spec's "iterative" requirement was protecting against.

**Re-open this if** validation stops running unconditionally before evaluation, or if a
depth ceiling above the stack's tolerance is ever wanted. The cheap alternative to
rewriting the evaluator is to give `_evaluate_node` the same depth parameter
`FormulaEvaluator._evaluate_node` already has.

### 6.2 `RegistryManager` families — waived, wrong home

Slice 5 lists `RegistryManager` under "files to create or touch" and states a registry
obligation for `predicate_type` / `value_source`. Waived because the two registries are
not the same kind of thing:

`RegistryManager` is a **content** registry. It loads authored `RegistryEntry` resources
from `registries/<family>/` directories under a content source, validates them against
`REQUIRED_FAMILIES`, and answers `has_entry` / `entry` / `ids` by family and id. Its
entries are data on disk.

Predicate types and value sources are **code** — `Callable`s registered at `_ready()` by
`RequirementSystem.register_predicate` / `register_value_source`, and by any consumer
that wants to extend the vocabulary. There is no disk representation to catalogue.

Putting them in `RegistryManager` would mean either storing `Callable`s in a resource
catalogue or building a second, parallel mechanism inside the same class. The
**open-registry principle** the spec cares about is satisfied — the vocabulary grows by
registration, not by editing a `match` — and only the stated file location differs.

**Re-open this if** predicate types ever acquire an authored, data-driven form (a pack
declaring a predicate without code), because that form *would* belong in the content
registry.

### 6.3 Depth budget — honoured

`CampaignRules` now carries `requirement_depth_budget` and `value_term_depth_budget`
(default 16, `@export_range(1, 32)`) alongside the existing node budgets. Both are
pack-lowerable and capped by the engine ceilings, which a pack may lower but never raise.
`RequirementSystem.validate` applies `mini(rules.requirement_depth_budget, MAX_DEPTH)`
instead of `MAX_DEPTH` alone, and passes `rules.value_term_depth_budget` to
`Formula.validate` in place of the literal `16` that was there.

Pinned by three assertions in `test_requirement.gd`, each negative-checked: with the
change reverted, the first two fail on the requirement tree and the third on the value
term. A budget that is not *observably* lower than the ceiling is not a budget.

### 6.4 Purity check — waived, deferred explicitly

DoD#2's "no impure predicate reachable from inside a value term" cannot be checked
because registration carries no purity flag. Deferred **with `chance`**, the impure
predicate that motivates it, which is correctly unbuilt until `B1-PKGA`. Recorded here
rather than left as an omission, which is the whole point of the §3 item.

**Re-open this when** the first impure predicate is registered — that is the moment the
check stops being theoretical, and it should land in the same change.

### 6.5 The three wrapper classes — honoured by deletion

`Requirement.gd`, `Predicate.gd` and `ValueTerm.gd` were byte-identical twelve-line
`class_name` globals: hold a `Dictionary`, return a copy. A project-wide search found
**zero references** — not in `scripts/`, not in scenes or resources, not even in
`test_requirement.gd`, the suite named after one of them. The only trace was the
generated `global_script_class_cache.cfg`.

The audit offered "give them the behaviour Slice 5 assigns them **or** delete them".
Deleted: an exported global that looks like the public API and is not it is a worse
failure than an absent one, and the real API (`RequirementSystem`, `FormulaEvaluator`)
is already coherent without them.

### 6.6 `any`'s reason selection — waived, unimplementable as specified

The spec asks `any` to report *"the most actionable child reason"*; the code reports
`results[0].reasons`. Waived because **"most actionable" has no referent in this
engine**: the CEUI walk established that no severity model exists anywhere in the
corpus, so there is no ranking by which one unmet reason outranks another. Implementing
this today means inventing a severity model inside a requirement evaluator — precisely
the kind of feature-aware decision that belongs in a shell ruling, not here.

Note that when `any` reports, **every** child failed, so `results[0]` is always a real
reason rather than a placeholder. The defect is ordering, not correctness.

**Re-open this when** a severity or ordering model is ratified. `all`'s missing display
cap belongs with it — both are presentation questions about a list of reasons, and they
should be answered together by whichever ruling defines reason presentation.

### 6.7 `[6]`'s text-key residue — withdrawn, not deferred

§2.6 withdrew the `has_trait`/`in_group` conflation and left "only the distinct-text-key
question survives (a group check renders a reason saying 'trait')". **That surviving
claim is false.** `RequirementSystem._ready()` registers:

```gdscript
register_predicate("has_trait", _eval_has_trait, "req.has_trait", "req.has_trait.inverse")
register_predicate("in_group",  _eval_in_group,  "req.in_group",  "req.in_group.inverse")
```

The two predicates share an *evaluator* and have **distinct text keys**. A node authored
as `in_group` renders `req.in_group`; only a node authored as `has_trait` says "trait",
which is what its author wrote. Finding `[6]` is therefore withdrawn in full.

### 6.8 Three findings outside §3, raised by this pass

Checking §3 against the code surfaced three things the audit did not reach. None of them
block the §3 dispositions; all three are larger than this row.

1. **`RequirementSystem` has no production callers.** A search of `scripts/` excluding
   `scripts/tests/` returns nothing. The stated reason for building `B3-REQ` was that
   `RequirementFormulaRegistry` had *"no production callers, only
   `test_formula_registries.gd`"* — its replacement is now in the identical state. The
   first real consumer is the cadence engine, which reached `agent/integration` on
   2026-08-20.
2. **Two evaluators shipped.** `scripts/registries/RequirementFormulaRegistry.gd` still
   exists next to `scripts/req/FormulaEvaluator.gd`. The row's own instruction was *"grow
   it or replace it, but do not ship two"*. Its only reference is
   `test_formula_registries.gd`.
3. **Unmet reasons cannot render player-facing text.** No `req.*` key exists in any
   content file, and `TextDB` is **not an autoload** — `project.godot`'s `[autoload]`
   block has no entry for it, so no production caller can pass a `text_db` to
   `render_reason`, which then returns the raw key. A player would read `req.has_item`.
   The announcement-channel session note flagged the fallback as a hazard; the measurement
   here is that the fallback is currently the *only* path. This lands on `PREP-V1-S01`
   (gated prep entries need reason text) and on
   `SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19`.
