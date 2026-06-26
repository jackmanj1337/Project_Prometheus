---
Type: register
Status: OPEN 2026-06-26
Last verified: 2026-06-26
Register: EXT-1..6
Resolved-in: 2026-06-26 (EXT-1 model = A "A-plus" / EXT-2 content-fit / EXT-3 validation / EXT-4 determinism + EXT-5 *mechanism* — ratified off the `[REQ-16]` worked example); **still OPEN:** EXT-5 *cadence/process* + EXT-6 per-vocabulary confirmation (DLG effects · F4 profiles · MET)
---

# Authoring Extensibility — What "Author-Extensible" Means Across the Vocabularies — Open Questions

**Started:** 2026-06-26 (parked by the F16/`[REQ]` sweep; owner: **dedicated session NEXT, before
A5**).
**Status (updated 2026-06-26):** **EXT-1, EXT-2, EXT-3, EXT-4 RESOLVED** and **EXT-5 *mechanism*
RESOLVED** — ratified directly off the `[REQ-16]` arithmetic-terms worked example (owner call: the
answers were obvious once the math case was walked). **Still OPEN:** **EXT-5 cadence/process** (the
release rhythm + triage for primitive requests) and **EXT-6 per-vocabulary confirmation** (an explicit
check that `[DLG-3]` effects, F4 profiles, and `[MET]` adopt the A model with no divergence). The
remaining walk is **much lighter than originally scoped** and likely **off the A5 critical path**.
**Why this exists:** the F16 `[REQ]` predicate vocabulary, the `[DLG-3]` effect taxonomy, and the F4
CampaignRules profiles have all been called **"author-extensible"** with the *mechanism* glossed as
"rides F4 / the sweep." That word makes a promise that is **not pinned**, and it matters because the
campaign content model is **self-contained packs of data + raw art with no code**
(`project_campaign_content_model`). "Author-extensible" therefore cannot naively mean "authors ship
evaluator logic." This register seeds the walk that settles what it *does* mean — **once, for all the
author vocabularies** (EXT-6).

**Candidate directions (surfaced 2026-06-26 — ✅ CHOSEN: A, as the "A-plus" hybrid, per EXT-1 below):**
- **A — Data-composition only. ✅ CHOSEN.** Authors parameterize + compose the engine-provided primitives and can
  define new **named** Requirements/effects as data compositions ("macros"). New **primitive** types
  are engine-added over releases. No code in packs — fits the content model. ("Extensible" = a
  growable named library, data-only.)
- **B — Author-defined primitives via a sandboxed expression layer.** Packs define genuinely new
  predicates/effects via a sandboxed formula/expression mini-language. More power; a real new subsystem
  (parser + sandbox + validation) and a bigger content-model commitment.
- **C — Engine-only; reword to "parameterizable."** Fixed vocabulary per release; authors only
  parameterize. Simplest/most honest; no author-defined compositions.

---

## Worked example so far (2026-06-26) — `[REQ-16]` arithmetic terms leaned **A**, ahead of the formal EXT-1 call
A focused walk of author math (`[REQ-16]`, in the F16 register) was settled **as an Option-A
data-composition** — a recursive *data tree* of engine-provided ops (`add/sub/mul/div/pow/min/max/abs/neg`
+ number-domain booleans), **not** an author-authored expression string. It is a concrete preview of
what each EXT question looks like in practice:
- **EXT-1/2 (model & content-model fit):** chose **A** — no code in packs; a parser/string front-end, if
  ever added, is **build-time sugar that emits the same validated tree** (runtime still evaluates data),
  so it stays A.
- **EXT-3 (validation):** structural — op∈set, arity, recursively-numeric operands, required `on_zero` on
  `div`, depth/node budget; fail-loud at load.
- **EXT-4 (determinism):** **fixed-point ×1000** for bit-determinism across desktop/web/lockstep; the
  REQ-10 `chance` skew input stays pure (only the roll routes through Package A).
- **EXT-5 (primitives & cadence):** comparisons (`gt/lt/eq…`) and `xor` ship as **named compositions**,
  not primitives; the **complexity budget is author-declared with full headroom**, and the guardrail is
  **social** — the guidebook tells authors to warn players, **request a new primitive, and consider
  joining the dev team to build it** (the primitive-request channel **doubles as a contributor on-ramp**).
- **EXT-6 (one model):** the **logic↔predicate bridge was DEFERRED** in favour of a **flag-upstream
  pattern** (a predicate writes `[F6]`; a term reads the flag as `0/1`) — keeping the two logic layers
  decoupled for now. The deferral **splits by purity**: a future `from_predicate` down-bridge would admit
  **deterministic/pure predicates only**; **chance-based (`[REQ-10]`) predicates are permanently excluded**
  from inlining (they reach a formula solely via their **latched** `0/1` outcome) — the same pure/impure
  line that governs the rest of F16, which is what makes the eventual bridge safe.

This does **not** pre-decide EXT-1 for the whole vocabulary (DLG effects, F4 profiles, MET) — it is one
data point that **A is sufficient and content-model-clean for the math case**.

## Open questions to walk

### [EXT-1] The core meaning — A (compose-only) vs B (expression layer) vs C (engine-only)  **[RESOLVED 2026-06-26]**
Pick the model. Drives everything below.
- **Resolution: A — data-composition only, run as the "A-plus" hybrid.** `[REQ-16]` proved A is
  sufficient **and** content-model-clean for the hardest case (live arithmetic), and the other
  vocabularies already behave as Option-A data-composition today (DLG effects = a parameterized 3-tier
  taxonomy; F4 profiles = `linear/sigmoid/table` + parameterize, where `table` already gives arbitrary
  author curves as *data*; MET = an engine action-list composed with `[REQ]` conditions). **B stays a
  narrow, evidence-gated future exception** (a single "expression-bodied" slot reusing A's eval tree),
  paid for only if a primitive-request backlog proves the ceiling is real. **C rejected** — A keeps the
  "extensible" promise honest without author code.

### [EXT-2] Content-model fit  **[RESOLVED 2026-06-26]**
Packs are **data + raw art, no code** (self-contained model). Does the chosen option preserve that? B
introduces author-authored logic (even sandboxed) — reconcile with "no code in packs," or scope it as a
deliberate exception.
- **Resolution: yes — A preserves "no code."** Compositions are **data trees**; the loader already
  enumerates them. The one subtlety `[REQ-16]` surfaced and settled: a **string front-end is build-time
  sugar that emits a validated tree** (the runtime evaluates data, never a string) → still no-code. Only
  a hypothetical *runtime-interpreted* B-expression would need a scoped carve-out, and that is **deferred**
  until evidence demands it.

### [EXT-3] Validation & safety  **[RESOLVED 2026-06-26]**
How is an author composition/expression **validated** at load (`DataManager.validate`)? Bad references
(unknown predicate type, missing subject, nonexistent stat/item), type errors (string vs numeric
`compare`), and unbounded/contradictory Requirements. Fail-loud at build vs degrade.
- **Resolution: structural load-validation against the engine primitive registry, fail-loud at build.**
  `[REQ-16]` is the concrete template: op ∈ known set, arity, recursively-typed operands, required params
  (e.g. `on_zero`), budget/depth bounds, **reject impure references**. Each vocabulary enumerates its own
  registry (predicate/effect/profile types), but the **validation shape is uniform** — bad refs/type
  errors/over-budget fail at load, not silently degrade.

### [EXT-4] Determinism & save-safety  **[RESOLVED 2026-06-26]**
Any author-defined logic must stay **deterministic** and **side-effect-free** for save/replay/rewind —
especially around the **REQ-10 `chance`** gate (RNG only via `RngService`/Package A) and the
`[DLG-11]` `visited_trail` latch. An expression layer must not be able to read wall-clock, re-roll, or
mutate state.
- **Resolution: author compositions are pure + side-effect-free; the only RNG is Package A's latched
  `chance`; fixed-point for cross-platform determinism.** Demonstrated end-to-end by `[REQ-16]`
  (fixed-point ×1000 → bit-identical across desktop/web/lockstep; the `chance` skew input stays pure, only
  the roll touches Package A and **latches**). The governing rule is the **pure/impure split** — pure
  reads compose freely; the single impure primitive (`chance`) is quarantined behind Package A + latch,
  and nothing reachable from a term may read wall-clock, re-roll, or mutate state.

### [EXT-5] Who adds primitives + cadence  **[PARTIAL — mechanism RESOLVED 2026-06-26; cadence OPEN]**
Under A/C, new **primitive** predicate/effect/profile types are an engine concern — define the cadence
and how authors request them. Under B, define the primitive set the expression layer exposes.
- **Resolution (mechanism):** engine adds primitive **types**; authors get a **named-composition library**
  as the author-side relief valve (e.g. `gt/lt/ge/le/eq/ne` and `xor` shipped as compositions, not
  primitives) **plus a primitive-request channel that doubles as a contributor on-ramp** (request → maybe
  join the dev team to build it, per `[REQ-16]`'s complexity-budget guidance).
- **STILL OPEN — cadence/process:** the release rhythm for landing requested primitives and the triage
  process (which requests resolve to "compose it like this" vs a real new primitive). A lightweight
  *process* detail, not a design fork.

### [EXT-6] One model for ALL author vocabularies  **[OPEN — narrowed to a per-vocabulary confirmation]**
The decision should apply **uniformly** to: F16 `[REQ]` predicates/terms, `[DLG-3]` effects, F4
CampaignRules profiles (incl. the `[REQ-10]` skew profile), and arguably `[MET]` actions/triggers.
Avoid divergent extensibility models across the "author vocabularies." Pick one.
- **Direction settled (2026-06-26): one model = A, uniformly** — no vocabulary shows a genuine
  B-requirement (a novel effect / profile / action is a **primitive request**, not author code). **What
  remains** is the honest confirmation step, not a fork: an explicit per-vocabulary pass verifying
  **`[DLG-3]` effects**, **F4 profiles**, and **`[MET]` actions/triggers** each adopt A with no
  divergence (and folding their "author-extensible" wording onto this answer). Low-risk; the only reason
  it is not auto-closed is that asserting ≠ checking.

---

## Related parked future-discussion topics (capture only — not this register's focus)
Recorded here so they are findable; each is a separate, non-blocking conversation:
- **Dialogue/conversation editor (`[DLG-8]`)** — *when/how* to build it; rides the deferred
  designer-authority (4a–4e GUI-vs-JSON) pass.
- **F16 v1 build-scope** — F16 grew into a general game-state query language (spatial · aggregate ·
  projection); the first build should ship a **subset**, the rest per-consumer. Which subset = a
  sweep/build call.
- **Chance gate → a unified "skill-check / contest" feature** — `[REQ-10]` is reusable for
  persuade/steal/intimidate/status-infliction. **Recorded as candidate F** in
  `design/candidate_systems_2026-06-23.md` (its proper feature-planning home — revisit at the priority
  re-eval), not just here.
- **Projection sharing** — `[REQ-15]` outcome projection, the **F5** next-resolution API, and the
  combat **damage-preview UI** must share ONE projection; a build-sequencing concern.

## Minor build-deferred details (enumerate at build; low risk)
Conversation **participant-role** vocabulary (`participant:<role>`), the exact **`targeted`-item**
contexts (steal/forge/break/trade…), the **`count` subject-set** list (party/faction/region/
participants), and the spatial **distance metric** (assumed grid-**Manhattan**).

## Cross-references
- Governs the extensibility claims in `[REQ]` (F16), `[DLG-3]` effects, F4 profiles, `[MET]`.
- Constrained by `project_campaign_content_model` (data+art packs, no code) and Package A determinism.
