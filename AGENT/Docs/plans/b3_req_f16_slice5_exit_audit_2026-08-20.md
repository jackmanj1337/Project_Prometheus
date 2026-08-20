---
Type: handoff
Status: Active — findings `[1]`–`[7]` REMEDIATED 2026-08-20 (`975b38bd`, merged `92a5ff4e`); §3 divergences still open
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

> **Carry to the announcement channel:** `[3]` is fixed, so `[ANN-2]`'s mapping now has the
> gate presentation it assumed. `RequirementSystem.gate_for(node)` returns it, and every
> reason dictionary carries a `gate` key.
