---
Type: handoff
Status: Executed 2026-07-30 — verdict `ready with amendments` in [`package_contract_plan_review_2026-07-30.md`](../../Code%20Reviews/package_contract_plan_review_2026-07-30.md)
Last verified: 2026-07-30
Tracker: REVIEW-PACKAGE-CONTRACT-PLANS-2026-07-30
---

# Package Contract Plans — Next-Session Review Handoff

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
zero-content and B3-REQ rows; canonical execution status remains in the workspace
tracker.

## Review outcome

Perform a read-only implementation-readiness review of the package and predicate
contracts merged to `agent/integration` at `8cfcf2410e0b`. Confirm that an implementer
can build Z0, the canonical Godot validator, and the B3-REQ registry without inventing
missing policy. Produce findings first; do not implement fixes during the review pass.

## Read in this order

1. [`zero_content_engine_implementation_plan_2026-07-23.md`](zero_content_engine_implementation_plan_2026-07-23.md),
   especially **Target package contract**, **Canonical content fingerprint**,
   **Import and media authoring flow**, and **Validation phases and diagnostics**.
2. [`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](band3_core_authoring_foundations_implementation_plan_2026-06-30.md),
   Slice 5 sections **Canonical v1 serialization**, **Context bindings and unavailable
   subjects**, and **Complexity budgets and purity**.
3. [`campaign_data_ownership_research_findings_2026-07-23.md`](campaign_data_ownership_research_findings_2026-07-23.md),
   R3 entity/provenance obligations.
4. Private fixture evidence on Campaign Pack FE branch
   `agent/from-main/zero-content-predicate-fixture-plan` at `ad3e59f`:
   `planning/reviews/zero_content_predicate_fixture_questions.md`,
   `planning/zero_content_predicate_fixture_plan.md`, and
   `tests/test_zero_content_fixtures.py`.
5. The resolved source design in
   [`requirement_predicate_system_open_questions_2026-06-25.md`](../registers/requirement_predicate_system_open_questions_2026-06-25.md).

## Review questions

### A. Package lifecycle and identity

- Are `authoring_status`, structural validity, playability, effective enablement, and
  target-specific distribution eligibility independent everywhere, with no old
  “complete means playable” assumption remaining?
- Is a stable UUID plus SemVer plus snapshot fingerprint sufficient for saves,
  duplicate imports, forks, updates, and same-id/version conflicts?
- Are package-local entity ids used consistently, with no accidental requirement for
  authors to qualify references or for the engine to perform global raw-id lookup?

### B. Fingerprint reproducibility

- Can Godot and a generated CLI client produce identical `pp-pack-sha256-v1` bytes on
  Windows and Linux?
- Are path normalization, manifest projection, length encoding, file closure, sort
  order, and receipt exclusion fully specified and non-circular?
- Does the algorithm distinguish a faithful content snapshot without allowing editor
  timestamps, caches, or expected-error metadata into the hash?

### C. Provenance and distribution rights

- Are the rights status, licence identity, distribution scope, attribution obligation,
  verification date, and optional author notes independently representable?
- Can drafts always be backed up and privately transferred even when they are invalid
  or rights are unresolved, while unsafe content remains non-executable?
- Does public-release eligibility fail closed without misrepresenting attribution as a
  cure for content that has no redistribution grant?

### D. Import and media UX

- Is file/folder import atomic, deterministic, and sufficiently explicit about ID
  generation, duplicates, collisions, reimport, rollback, and finalized-package edits?
- Are integrity fields entirely tool-generated, leaving authors only exceptional
  prompts and optional notes?
- Is excluding SVG from the v1 production allow-list sufficient until sanitization and
  external-reference rules are designed?

### E. Validation and fixture parity

- Do the five validation phases suppress only dependent checks and still yield every
  safely discoverable error in the stated stable order?
- Can structured diagnostics carry package/document/field/source context and an
  actionable fix without relying on parsed free-form notes?
- Is the external `tests/expected_errors/<fixture-id>.json` convention enough to pair
  public synthetic fixtures with private compatibility fixtures while keeping package
  roots byte-realistic?
- Is the transition from temporary Python checks to the canonical Godot validator
  explicit enough to prevent two authorities?

### F. B3-REQ implementation readiness

- Does the exact JSON projection preserve every resolved REQ-1..16 capability without
  adding a consumer-specific predicate language?
- Are subject objects, context bindings, absent-runtime-subject behavior, unavailable
  values, composed unmet reasons, and hidden-versus-disabled presentation unambiguous?
- Are the default and hard depth/node/aggregate/operand budgets coherent, enforceable
  before activation, and bounded against nested aggregate multiplication?
- Can pure preview statically reject `chance`, while committed chance declares one RNG
  stream/order key, draws exactly once, and persists before downstream effects?

## Required output

Write `AGENT/Code Reviews/package_contract_plan_review_2026-07-30.md` (or the actual
review date if later) containing:

1. overall verdict: `ready`, `ready with amendments`, or `not ready`;
2. findings ordered by severity, each with exact plan section, consequence, and
   proposed wording or test;
3. a contract-coverage table mapping Z0, Z1, P0, and P1 exits to their owning public
   plan section;
4. explicit answers to review questions A–F;
5. amendments required before Z0 or B3-REQ implementation; and
6. items deliberately deferred, especially SVG production admission and P3 chance
   execution.

Do not reopen ZFQ-01 through ZFQ-08 merely because another option is aesthetically
preferable. Reopen only a demonstrated contradiction, unsafe behavior, impossible
implementation, or missing use case, and show the evidence.

## Current evidence

- Project full suite: all 111 suites green at the merged plan tree.
- Documentation checks: all 43 green.
- Private FE fixture suite: 18 tests green at `ad3e59f`.
- Tracker validation: 200 tasks, no claim conflicts after the amendment closeout.

## Gate after review

- If `ready`, start Z0 canonical-validator implementation from current
  `agent/integration` and pair it with the private Z0/Z1 receipts.
- If `ready with amendments`, land the bounded plan/test amendments first.
- If `not ready`, create tracker rows for each blocking contract; do not begin Z2 or
  P0 to work around the gaps privately.
