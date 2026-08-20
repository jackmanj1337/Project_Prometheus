---
Type: handoff
Status: Active — audit findings; `B3-REQ-F16` returned to `in_progress`, not closed
Last verified: 2026-08-20
Tracker: B3-REQ-F16-BUILD-2026-08-18-2026-08-19
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

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

### `[6]` `has_trait` is a silent alias of `in_group`

`_eval_has_trait()` calls `_eval_in_group()` verbatim, so traits and groups are one
namespace. Two vocabulary entries collapse into one, and because the registration keeps
distinct text keys (`req.has_trait` vs `req.in_group`), a **group** check renders a
player-facing reason that says *trait*. Either is defensible as a decision; neither is
recorded as one.

### `[7]` `sub` and `div` silently drop operands past the second

Spec permits up to 32 operands per variadic arithmetic node. Measured:
`sub(10, 3, 2)` returns `7.0` — the `2` is discarded with no error. `div(10, 3, 2)`
likewise. A silent wrong answer rather than a validation failure.

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

## 5. Recommended disposition

1. **Row → `in_progress`** with these findings attached. Do not close.
2. **Fix `[1]`–`[4]` first** — they are cheap relative to their blast radius, and each
   comes with a spec-named test that is currently missing. Add the tests with the fixes so
   the exit criteria and the suite converge.
3. **`[5]` `has_item` is the schedule-relevant one.** Convoy, shop and `[CVS-S2]` all need
   it; `PREP-V1-S01` should not be planned as though it exists.
4. **`[3]` should be flagged to the announcement-channel work** — `[ANN-2]` assumes a gate
   presentation the producer does not yet supply.
5. **Record `[6]` and the §3 divergences as decisions** (honour or waive), so the next
   audit does not re-derive them.

`PREP-V1-S01` remains blocked on this row. That is the correct state, not a bookkeeping
artifact.
