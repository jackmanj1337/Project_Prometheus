---
Type: code review
Status: Complete — verdict: ready with amendments
Last verified: 2026-07-30
Tracker: REVIEW-PACKAGE-CONTRACT-PLANS-2026-07-30
---

# Package Contract Plans — Implementation-Readiness Review (2026-07-30)

Read-only review defined by
[`package_contract_plan_review_handoff_2026-07-30.md`](../Docs/plans/package_contract_plan_review_handoff_2026-07-30.md).
No plan text was changed during this pass; findings first.

## Scope and evidence

Reviewed at `agent/integration` `e36b255a` (contracts merged at `8cfcf2410e0b`):

- `AGENT/Docs/plans/zero_content_engine_implementation_plan_2026-07-23.md`
  (target package contract, fingerprint, import/media flow, validation phases);
- `AGENT/Docs/plans/band3_core_authoring_foundations_implementation_plan_2026-06-30.md`
  Slice 5 (canonical v1 serialization, context bindings, budgets/purity);
- `AGENT/Docs/plans/campaign_data_ownership_research_findings_2026-07-23.md` (R3);
- `AGENT/Docs/registers/requirement_predicate_system_open_questions_2026-06-25.md`
  (REQ-1..16);
- Campaign Pack FE branch `agent/from-main/zero-content-predicate-fixture-plan` at
  `ad3e59f`: `planning/zero_content_predicate_fixture_plan.md`,
  `planning/reviews/zero_content_predicate_fixture_questions.md`,
  `tests/test_zero_content_fixtures.py`, and the eleven `fixtures/zero_content/*`
  roots plus their `tests/expected_errors/` corpus.

## Verdict

**Ready with amendments.**

The lifecycle/identity, provenance/rights, import, and validation-phase contracts
are implementable as written. Two defects must be amended before their consuming
implementation starts: the B3-REQ `on_zero` vocabulary contradicts the ratified
REQ-16 register (blocks B3-REQ), and the fingerprint's manifest projection is not
specified tightly enough for two independent clients to produce identical bytes
(blocks the Z0 fingerprint/conflict contract). One ownership gap (the
diagnostic-code vocabulary) should be closed in the same amendment because the
expected-error corpus already pins exact code strings. No ZFQ-01..08 decision needs
reopening; finding 1 is a demonstrated contradiction, the category the handoff
explicitly admits.

## Findings (most severe first)

### 1. `on_zero` vocabulary contradicts ratified REQ-16 — blocks B3-REQ

**Where:** band3 plan, Slice 5 → *Canonical v1 serialization*, compound value-term
shape (`"on_zero": "error|zero|min|max"`) versus the register's REQ-16 resolution
(`on_zero`: `to_max` · `to_zero` · `to_value:<term>`).

**Defect:** the canonical serialization enumerates a different policy set than the
owner-resolved register. It drops the `to_value:<term>` fallback (a resolved
capability), adds `min` and `error` (neither in the register), and leaves `min|max`
clamp semantics undefined. `error` also collides with the register's explicit "no
undefined propagation — the number domain stays total/closed" rule unless it is
defined as producing the amended plan's `unavailable` value-term result, which no
sentence states.

**Consequence:** the implementer cannot know which vocabulary to build, and the
golden JSON fixtures written in the first B3-REQ slice would freeze whichever guess
they make. Question F's "preserve every resolved REQ-1..16 capability" fails as
written because `to_value:<term>` is unrepresentable.

**Proposed amendment:** record one owner decision in the plan: either (a) restore
the register vocabulary (`to_max|to_zero|to_value`), or (b) keep the new set and
add: `min`/`max` clamp to ∓/±MAX_FIXED, `error` yields the value-term `unavailable`
result (consuming comparison false with a structured reason), and `to_value:<term>`
is deliberately dropped/deferred. Whichever way, add a supersession pointer next to
REQ-16 in the register so the two texts cannot disagree silently, and add a
`test_formula_evaluator.gd` case per admitted policy.

### 2. Fingerprint manifest projection underspecified for cross-tool parity — blocks the Z0 fingerprint contract

**Where:** zero-content plan → *Canonical content fingerprint*, steps 3–4, and the
receipt paragraph.

**Defect:** four gaps prevent a Godot client and a generated CLI client from
guaranteeing identical `pp-pack-sha256-v1` bytes:

- "any stored fingerprint/receipt fields omitted" never enumerates the exact
  manifest keys excluded from the projection;
- "sorted object keys, no insignificant whitespace, and LF" is not a complete
  canonical-JSON definition — string escaping (raw UTF-8 versus `\uXXXX`), number
  formatting, and whether a trailing LF byte exists are all unstated, and Godot's
  `JSON.stringify` and Python's `json.dumps` disagree on these by default;
- the receipt's storage location is unstated — a sidecar file inside the root
  would itself violate the unindexed-bytes closure rule;
- unknown-manifest-field handling is unstated, so an unrecognized field would be
  silently hashed by one client and possibly rejected by another. The
  algorithm-id "first length-delimited record" encoding should also be pinned as
  one `(uint64-BE length, UTF-8 bytes)` pair.

**Consequence:** two faithful implementations can emit different fingerprints for
the same snapshot, which manufactures false same-id/version conflicts — the exact
quarantine path the contract exists to make trustworthy.

**Proposed amendment:** enumerate the excluded keys (e.g. `content_fingerprint`,
`fingerprint_algorithm`); pin the projection encoding to RFC 8785 (JCS) or an
explicit equivalent (UTF-8, minimal escapes only, integer-only numbers in the
manifest, no trailing newline); state the receipt lives outside the package root in
library metadata (or names its exact manifest keys); state unknown manifest fields
are rejected before fingerprinting. Pair with a two-client parity test on a fixture
containing non-ASCII strings and every manifest field.

### 3. Diagnostic-code vocabulary has no public owner — needed at Z0

**Where:** zero-content plan → *Validation phases and diagnostics* (stable order
"…then diagnostic code"); FE `tests/expected_errors/*.json` pin exact strings such
as `unsupported_content_schema_version` and `casefolded_catalogue_id_collision`.

**Defect:** no public plan states who owns the closed set of diagnostic-code
strings. The private Python suite invented the current codes, and Z0/Z1 parity
consumes that corpus verbatim.

**Consequence:** either the Godot validator picks different strings and the entire
private expected-error corpus fails parity, or the engine adopts the private codes
silently — precisely the "private pack must not choose engine policy" failure the
fixture plan forbids.

**Proposed amendment:** one sentence in the validation section: the engine schema
registry owns the diagnostic-code registry; the current private corpus codes are
provisional inputs to be ratified or remapped in the Z0 parity slice, and a
parity-time code-mapping table is acceptable evidence.

### 4. Private Z0/Z1 fixture manifests diverge from the ratified manifest contract

**Where:** FE `fixtures/zero_content/*/manifest.json` at `ad3e59f` versus
zero-content plan → *Target package contract* v1 manifest fields.

**Defect:** fixture `package_id`s are dotted strings
(`internal.fixture.z0_complete_empty`), not the ratified stable lowercase RFC 4122
UUIDs; every fixture carries `internal_only: true`, a field absent from the v1
manifest list, and none carries the ratified
`distribution_policy: private_only | authorized_internal | public_candidate`.
`test_z0_lifecycle_states_are_explicit_and_disabled` asserts the non-contract
field.

**Consequence:** Z0/Z1 engine parity fails on the *valid* fixtures the moment the
canonical validator enforces the manifest schema, or pressures the engine into
accepting non-contract fields.

**Proposed amendment (FE side, before parity — does not block starting Z0 engine
code):** regenerate fixture manifests with UUID `package_id`s and
`distribution_policy: private_only`; update the lifecycle test accordingly. The
release-audit exit ("a release audit rejects every internal-only fixture") then
keys off `distribution_policy` + rights records instead of `internal_only`.

### 5. P0's required atom matrix exceeds the B3-REQ v1 build scope

**Where:** FE fixture plan → *P0 — pure predicate atom matrix* (requires
item-property, adjacency/distance/terrain/region, runtime-state,
relationship-rank, aggregate, and condition potency/param/projection atoms) versus
band3 Slice 5 step 6 (REQ-11..15 families are built "per consumer demand, not all
up front") and REQ-14's F5 forward-requirement for potency.

**Consequence:** P0 as written cannot complete against the v1 engine; the pressure
resolves either as scope creep into B3-REQ or as private stubs inventing adapter
semantics.

**Proposed amendment:** stage P0 in the fixture plan — P0a covers the v1 vocabulary
(`flag`, `unit_is`/`unit_present`, `class_level`, `proficiency`, `stat`,
`has_skill`/`has_trait`/`in_group`, `has_item`, `compare` over unit-attribute and
literal sources, and the full arithmetic/rounding/budget cases); P0b tranches land
as each REQ-11..15 family registers. Alternatively, band3 explicitly promotes the
families P0 needs into the first B3-REQ slice — but staging is the smaller change
and matches the register's "build as a consumer needs it" resolution.

### 6. P0/P1 public–private parity has no owning public plan sentence

**Where:** zero-content plan → *Verification and documentation* names Z0/Z1 parity
explicitly; band3 Slice 5 tests cover the synthetic golden cases but never bind the
private P0/P1 truth tables ("public synthetic and private fixture truth tables
match exactly" exists only in the private plan).

**Consequence:** the coverage table below has no public owner for one P0 exit; the
parity obligation could silently drop out of the B3-REQ definition of done.

**Proposed amendment:** add one parity bullet to band3 Slice 5 tests mirroring the
zero-content Z0/Z1 bullet: P0/P1 parity consumes the private suite's truth tables
and expected-error corpus against the canonical evaluator, recording both commit
ids in the receipt.

### 7. Indexed-path grammar and Unicode normalization not pinned

**Where:** zero-content plan → *Canonical content fingerprint* step 1/step 4
("normalized POSIX relative paths", "unsafe paths") and *Player flows* rejection
list.

**Defect:** "unsafe" is never defined precisely (the private validator's working
rule: no backslash, not absolute, no `..`/`.` segments), and no Unicode
normalization (NFC/NFD) rule exists for path strings that feed UTF-8 byte-order
sorting and hashing.

**Proposed amendment:** define the admitted path grammar; a conservative v1
answer — segments matching `[a-z0-9_\-.]+`, `/` separators, no leading/trailing
separators — sidesteps normalization and case-folding entirely. Can be folded into
finding 2's amendment.

### 8. Absent-subject semantics under `not` are unstated and untested

**Where:** band3 Slice 5 → *Context bindings and unavailable subjects* (absent
subject ⇒ pure predicate `false` with a reason) composed with `not`.

**Defect:** the chosen two-valued model means `not(pred(absent_subject))`
evaluates `true` — e.g. "not carrying the relic" passes when the unit is not
deployed. That is deterministic and consistent, but author-visible, and neither the
plan nor the P1 case list pins it.

**Proposed amendment:** one sentence stating absent-subject `false` composes
normally through `all`/`any`/`not`, plus a P1/`test_requirement.gd` case asserting
the `true` result and its reason trace.

### 9. Stale wording left behind by the amendment pass

**Where:** three spots, all cosmetic but each is the residue question A asks about:

- FE fixture plan Z0 data list still says "one `complete`, disabled package"
  (ratified term: `finalized`; the fixtures themselves are already migrated);
- FE ZFQ-04 workaround paragraph still says expectations "remain inside each
  invalid fixture for now" although the corpus moved to `tests/expected_errors/`;
- band3 Slice 5 implementation step 2 still lists colon-encoded subject shorthand
  (`participant:<role>`, `unit:<id>`) two sections after the serialization ruled
  "objects, not colon-encoded strings".

**Proposed amendment:** wording sweep in the same amendment commit(s).

### 10. Fingerprint of unclosed draft roots is undefined

**Where:** zero-content plan → fingerprint step 1 (reject unsafe paths/unindexed
bytes) versus the backup guarantee ("private backup still preserves malformed or
incomplete bytes").

**Defect:** a faithful draft backup of a dirty or invalid root cannot have a
`pp-pack-sha256-v1`, and the plan does not say what identity such a backup carries.

**Proposed amendment:** state that `pp-pack-sha256-v1` is defined only for
structurally closed packs; draft backups carry an archive-level checksum with no
snapshot-identity or conflict-quarantine claims.

## Contract-coverage table

| Fixture exit | Owning public plan section |
|---|---|
| Z0: engine boots with no gameplay catalogue | zero-content §Outcome and boundary; Slice 1 `IMPL-ZERO-CONTENT-FOUNDATION` |
| Z0: New Game disabled with actionable reason | zero-content §Player flows ("No packs"); §Target package contract (playable ≠ valid/finalized) |
| Z0: failed activation preserves prior ContentSession byte-for-byte | zero-content §Target package contract (candidate `ContentSession` swap); §Player flows (activation fails before global state changes) |
| Z0: release audit rejects every internal-only fixture | zero-content §Class entity/provenance (public-release eligibility) + manifest `distribution_policy` — *caveat: finding 4, fixtures assert a non-contract field* |
| Z1: every invalid sibling returns the complete expected error set in stable order | zero-content §Validation phases and diagnostics — *caveat: finding 3, code vocabulary unowned* |
| Z1: draft launch waives only admitted occurrence coverage | zero-content §Class entity/provenance (editor-only draft launch waiver) |
| Z1: finalized load/export rejects every provenance gap | zero-content §Class entity/provenance (finalized load/public export rejection) |
| P0: evaluation is pure and deterministic | band3 Slice 5 §Complexity budgets and purity |
| P0: failures identify predicate id and exact JSON path | band3 Slice 5 §Context bindings (static validation errors); Slice 5 tests (exact paths) |
| P0: public synthetic and private truth tables match exactly | **no owning public sentence — finding 6** (nearest analogue: zero-content §Verification Z0/Z1 parity bullet) |
| P1: one Requirement document consumed by four consumers without translation | band3 Slice 5 §Context bindings table; Slice 5 tests ("Every consumer row…") |
| P1: rendered unmet reasons name subject/comparison/missing state | band3 Slice 5 §Context bindings (reason structure); step 4 (REQ-5 display) |
| P1: budgets fail at the exact over-budget node | band3 Slice 5 §Complexity budgets and purity; Slice 5 tests |
| P1: hidden vs visible-disabled changes presentation only | band3 Slice 5 §Canonical v1 serialization (`presentation.gate`); Slice 5 tests |

## Answers to review questions A–F

**A. Package lifecycle and identity — yes, with cosmetic residue.**
`authoring_status`, structural validity, playability, effective enablement, and
target-specific eligibility are independent everywhere in the public plans; the
empty-finalized-non-playable case is stated explicitly and New Game keys on a
playable campaign graph. The only "complete means playable"-era residue is stale
vocabulary in the private fixture plan (finding 9), not a semantic conflation.
UUID + SemVer + fingerprint covers saves (all three recorded), exact duplicates
(triple match), forks (different ids, identical fingerprints dedupe physically),
updates (SemVer), and same-id/version conflicts (quarantine, never overwrite).
Entity ids stay package-local; raw cross-pack lookup is prohibited; saves and
diagnostics carry package context rather than qualified author ids.

**B. Fingerprint reproducibility — not yet; findings 2 and 7.**
The closure, sort order, length encoding, and receipt-outside-payload structure
are right and non-circular in shape, and editor timestamps/caches/expected-error
metadata are correctly excluded (unindexed bytes reject; expectations live outside
roots). But identical bytes from Godot and a CLI client on Windows and Linux are
not yet guaranteed: the projection's excluded keys are unenumerated, the canonical
JSON encoding is incomplete, receipt location and unknown-field policy are
unstated, and the path grammar/normalization is not pinned.

**C. Provenance and distribution rights — yes.**
`rights_status`, `license_id` (required when verified), `distribution_scope`,
`attribution_required`, `verified_at`, and `author_notes` are independently
representable; notes never substitute for structured fields. Drafts are always
privately backupable/transferable even when invalid or rights-unresolved, while
execution stays gated on structural safety. Public release fails closed on
finalized status + structural validity + verified distributable rights + satisfied
attribution + allowed policy; attribution cannot cure a missing redistribution
grant because `rights_status`/`distribution_scope` gate independently of
`attribution_required`.

**D. Import and media UX — yes.**
File/folder import is atomic with whole-batch rollback; hash-match reuse and
rename/reuse/replace collision prompts are specified; reimport of a finalized
version always produces a dirty draft snapshot plus a new fingerprint, and
same-version replacement needs explicit confirmation. Integrity fields are
tool-generated and read-only; authors face only exceptional prompts and optional
notes. Excluding SVG from the v1 production allow-list is sufficient — the private
one-pixel SVG fixture is explicitly non-precedential — and the exact logical-id
generation rule is acceptably tool-internal since ids are durable once generated
and collisions always prompt.

**E. Validation and fixture parity — yes, with findings 3 and 6.**
The five phases (manifest → catalogue structure → document structure →
provenance/cross-reference → closure) with dependent-phase-only suppression and
document-path/field-path/code ordering match ZFQ-03 and support a complete
expected-error corpus. Structured diagnostics carry package, catalogue entry,
document path, field path, code, source/audit id, message, and suggested fix — no
free-form-note parsing. The external `tests/expected_errors/<fixture-id>.json`
convention keeps roots byte-realistic and pairs public/private fixtures adequately.
The Python-to-Godot transition is explicit and one-directional (ZFQ-08; "may not
define competing rules"). The gaps: nobody owns the code-string vocabulary the
corpus pins (finding 3), and P0/P1 parity lacks a public owner (finding 6).

**F. B3-REQ implementation readiness — yes except finding 1, plus staging findings 5/8.**
The projection covers composition, leaf, subject-object, presentation, and
value-term shapes without any consumer-specific language; REQ-11..15 stay reserved
per consumer demand, which preserves rather than drops them. Subject objects,
context bindings, absent-subject false-with-reason, `unavailable` value terms,
composed unmet reasons, and hidden-versus-disabled are unambiguous (one unstated
edge: `not` over an absent subject, finding 8). Default and hard budgets are
coherent, lower-only for packs/profiles, computed before activation with exact
over-budget paths, and the shared evaluation-step budget bounds nested aggregate
multiplication. Purity is statically checkable (pure-only consumers reject trees
containing `chance` before evaluation) and committed `chance` declares one RNG
stream/order key, draws once, and persists its latch before downstream effects.
The `on_zero` contradiction (finding 1) is the one blocker.

## Amendments required before Z0 or B3-REQ implementation

Blocking, in order:

1. **Before B3-REQ:** resolve the `on_zero` vocabulary contradiction and record
   the register supersession (finding 1).
2. **Before Z0:** pin the fingerprint projection — excluded keys, canonical JSON
   encoding, receipt location, unknown-manifest-field rejection, path grammar
   (findings 2 and 7).
3. **Before Z0 parity (may land with the Z0 slice):** declare engine ownership of
   the diagnostic-code vocabulary (finding 3).

Non-blocking but required before their gates:

4. **Before Z0/Z1 parity:** align FE fixture manifests with the ratified contract
   (finding 4, FE repository).
5. **Before P0 authoring:** stage P0 (finding 5) and add the P0/P1 parity bullet
   to band3 Slice 5 (finding 6).
6. **Anytime:** wording sweep (finding 9), absent-subject-under-`not` sentence and
   test (finding 8), draft-root fingerprint clarification (finding 10).

## Deliberately deferred — confirmed, not findings

- **SVG production admission** stays excluded until a separate contract defines
  active-feature sanitization, external-reference rejection, and canonical decode;
  the Z1 SVG fixture grants no admission.
- **P3 chance execution** stays behind the declared-RNG slice (`B1-PKGA`); every
  pure fixture proceeds without it.
- **REQ-11..15 predicate families** land per Band-4+ consumer demand (subject to
  the finding-5 staging so P0 does not silently force them).
- **`from_predicate` bridge and the string formula front-end** remain deferred per
  REQ-16; v1 uses the flag-upstream pattern.
- **Cross-package collision fixtures** wait for the outer session harness
  (ZFQ-07 workaround).
- **Z2/S0 fixture authoring** remains gated on the canonical engine schema
  projection landing in `IMPL-ZERO-CONTENT-FAMILIES`.

## Gate disposition

Per the handoff gate: verdict is `ready with amendments`, so the bounded plan/test
amendments above land first; Z0 canonical-validator implementation starts from
`agent/integration` once amendments 1–3 are in, pairing with the private Z0/Z1
receipts. Tracker rows for the amendment work accompany this review in
`coordination/tasks.json`.
