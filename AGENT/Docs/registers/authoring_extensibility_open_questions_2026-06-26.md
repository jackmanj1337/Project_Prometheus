---
Type: register
Status: OPEN 2026-06-26
Last verified: 2026-06-26
Register: EXT-1..6
Resolved-in: —
---

# Authoring Extensibility — What "Author-Extensible" Means Across the Vocabularies — Open Questions

**Started:** 2026-06-26 (parked by the F16/`[REQ]` sweep; owner: **dedicated session NEXT, before
A5**).
**Status:** **[EXT-1..6] OPEN** — a deliberate, scheduled design walk. **Not yet decided.**
**Why this exists:** the F16 `[REQ]` predicate vocabulary, the `[DLG-3]` effect taxonomy, and the F4
CampaignRules profiles have all been called **"author-extensible"** with the *mechanism* glossed as
"rides F4 / the sweep." That word makes a promise that is **not pinned**, and it matters because the
campaign content model is **self-contained packs of data + raw art with no code**
(`project_campaign_content_model`). "Author-extensible" therefore cannot naively mean "authors ship
evaluator logic." This register seeds the walk that settles what it *does* mean — **once, for all the
author vocabularies** (EXT-6).

**Candidate directions (to weigh next session — surfaced 2026-06-26, NOT chosen):**
- **A — Data-composition only.** Authors parameterize + compose the engine-provided primitives and can
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
  decoupled for now. A future pure-only `from_predicate` down-bridge is the natural EXT-6 extension if
  demand appears.

This does **not** pre-decide EXT-1 for the whole vocabulary (DLG effects, F4 profiles, MET) — it is one
data point that **A is sufficient and content-model-clean for the math case**.

## Open questions to walk

### [EXT-1] The core meaning — A (compose-only) vs B (expression layer) vs C (engine-only)  **[OPEN]**
Pick the model. Drives everything below.

### [EXT-2] Content-model fit  **[OPEN]**
Packs are **data + raw art, no code** (self-contained model). Does the chosen option preserve that? B
introduces author-authored logic (even sandboxed) — reconcile with "no code in packs," or scope it as a
deliberate exception.

### [EXT-3] Validation & safety  **[OPEN]**
How is an author composition/expression **validated** at load (`DataManager.validate`)? Bad references
(unknown predicate type, missing subject, nonexistent stat/item), type errors (string vs numeric
`compare`), and unbounded/contradictory Requirements. Fail-loud at build vs degrade.

### [EXT-4] Determinism & save-safety  **[OPEN]**
Any author-defined logic must stay **deterministic** and **side-effect-free** for save/replay/rewind —
especially around the **REQ-10 `chance`** gate (RNG only via `RngService`/Package A) and the
`[DLG-11]` `visited_trail` latch. An expression layer must not be able to read wall-clock, re-roll, or
mutate state.

### [EXT-5] Who adds primitives + cadence  **[OPEN]**
Under A/C, new **primitive** predicate/effect/profile types are an engine concern — define the cadence
and how authors request them. Under B, define the primitive set the expression layer exposes.

### [EXT-6] One model for ALL author vocabularies  **[OPEN]**
The decision should apply **uniformly** to: F16 `[REQ]` predicates/terms, `[DLG-3]` effects, F4
CampaignRules profiles (incl. the `[REQ-10]` skew profile), and arguably `[MET]` actions/triggers.
Avoid divergent extensibility models across the "author vocabularies." Pick one.

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
