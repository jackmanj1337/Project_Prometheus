# Package A (`RngService`) — Implementation Draft + Open Questions Register

**Started:** 2026-06-21d
**Status:** Planning draft — register OPEN. **Special case:** a near-complete build
guide already exists (`rng_determinism_design_2026-06-11.md`, two-RN update 2026-06-13).
This doc does **not** re-derive that plan; it captures only the **gaps the session note
flagged** — service shape confirmation, the roadmap home, save integration — as a
one-by-one register.
**Source:** `planning_backlog_2026-06-20.md` §2/§2b(J); session note 2026-06-21c Tier 1 #1.
**Companion (authoritative build guide):** `rng_determinism_design_2026-06-11.md`.
**Sequencing:** built FIRST, before the §2 spine ([CST-12] → C). Unblocks §2 suspend
(real `rng` fields) and the rewind mechanic (§2b/J).
**Pattern:** mirrors §1 ICD / §2 CST registers. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)

- **No `RngService` exists.** Gameplay dice are raw `randi() % 100` in
  `CombatResolver` (hit/crit), `Unit.level_up()` growths, and `SkillHandler`
  activation (e.g. Miracle). The §6 migration sweep (`grep -rn "randi\|randf"`) is
  the audit; the §10 T5 lint test is the guard.
- **Snapshot today is hand-rolled.** `GameState._snapshot_unit_data` /
  `_map_start_snapshot` (in-memory Retry). It stores `Vector2i` + live
  `InventoryEntry` Resources — **not** JSON-safe (this is also [CST-2]'s problem).
  `RngService.to_save_dict()` is two ints, so it rides along trivially once the
  shared snapshot contract lands (Build Order Step 2).
- **`CampaignRules` is an unwired stub.** It does **not** yet have a
  `rewind_charges` field; the design doc assumes one (§8.3). §2/[CST-4] consolidates
  rules; this field lands either here (Step 4) or in §2 — see [PKGA-4].
- **Autoload order** (`project.godot`): the doc specifies inserting `RngService`
  after `EventBus`, before `GameState` (the twelve become thirteen). No code yet.

## 2. Draft plan (already specified — pointer only)

The build guide is implementation-ready: §2 service code, §3 event records, §4 chain
rules, §5 canonical roll order, §6 integration touch-list, §10 seven-test plan, §12
five-step build order. **Classic FE convention** is already baked in (Turnwheel-style
rewind, ironman = 0 charges, accepted probing/Wait-reroll exploits priced by charges).
The planning gap is **not** the algorithm; it is the three items below.

## 3. Open questions register

### [PKGA-1] Roadmap home for Package A  **[OPEN]**
The session note says Package A "has a design doc but **no roadmap home**." Steps 1–2
were tentatively slotted "Bucket B, before C4 (M9a)"; Steps 3–4 "new Bucket E". But
[CST-12] re-sequenced Package A to go **before §2** — so the roadmap placement must be
re-stated as the *next execution milestone*, not a Bucket-B insert.
- **A — New top-level milestone "Package A / Determinism" ahead of §2**, with Steps 1–5
  as its checklist; GDD_10 Open Items Register gets a row. Matches the [CST-12] decision.
- **B — Keep the original Bucket B/E split** and just note §2 waits on Steps 1–3.
- **Rec: A** — [CST-12] already made Package A a named, first execution step; the roadmap
  should reflect that single source of truth rather than two scattered buckets.
- **Resolution:** _[OPEN]_

### [PKGA-2] Build-order scope for the FIRST shippable slice  **[OPEN]**
The doc's Step 1 (service + migration sweep + T1/T3/T4/T5/T7) ships standalone value
(reproducible combat tests). Step 2 (snapshot contract) is what §2 actually needs.
Question: does "Package A first" mean **Steps 1–2** before §2, or **Steps 1–4** (incl.
suspend + rewind) before §2?
- **A — Steps 1–2 only gate §2** (service + snapshot contract). Suspend (Step 3) and
  rewind (Step 4) interleave *with* §2 (which owns the save UI anyway). Minimises the
  pre-§2 critical path.
- **B — Steps 1–4 all land before §2.** §2 then only adds campaign-graph/prep/economy
  on top of a finished determinism+suspend+rewind base.
- **Rec: A** — Step 3 (suspend) is co-owned by §2's save plumbing (Continue flow, slot
  menu); building it twice is waste. Land the substrate (1–2), then let §2 absorb 3–4.
  Ties to [CST-13] (fold rewind into §2 vs hooks-only).
- **Resolution:** _[OPEN]_

### [PKGA-3] `CampaignRules.rewind_charges` field — land here or in §2?  **[OPEN]**
Step 4 says "create the `CampaignRules` stub here if it doesn't exist." It exists but
lacks `rewind_charges`. [CST-4] hard-migrates all rule call sites in §2.
- **A — Add `rewind_charges` (+ default 3, 0 = ironman) to `CampaignRules` now**, in the
  Package A change, since the snapshot already serializes it (§8.3).
- **B — Defer the field to §2's `CampaignRules` consolidation** so all rule-field churn
  lands in one commit ([CST-4]'s ~70-ref pass).
- **Rec: B** — adding one rule field outside the consolidation invites a double-touch and
  a half-wired field. Package A Steps 1–2 don't need charges (rewind is Step 4). Let §2
  own every `CampaignRules` field in one pass; Package A's snapshot just reads it if present.
- **Resolution:** _[OPEN]_

### [PKGA-4] Two-RN hit model — confirm it lands with Step 1, not later  **[OPEN]**
RULE-001 (two-RN: hit when `floor((r1+r2)/2) < displayed_hit`) is a **gameplay-feel**
change (true 50% feels different from single-roll), bundled into the same migration. The
save-compat baseline note (§11) says it ships *with* `RngService` so there's nothing to
migrate — but it changes balance the moment it lands.
- **A — Ship two-RN with Step 1** (as the doc specifies). One change, no migration debt,
  and M9 skills land on the final model.
- **B — Ship single-roll first, two-RN as a follow-up** behind a flag.
- **Rec: A** — splitting creates a save-breaking migration later (the exact thing §11
  avoids) for no benefit; the feel change is desired (classic FE "true hit"). Flag it in
  the playtest note so the balance shift is observed, not silent.
- **Resolution:** _[OPEN]_

## 4. Notes
- No new test plan needed — the doc's T1–T7 are the contract. The only *new* test this
  register implies is asserting `rewind_charges` round-trips in the snapshot, which is
  already covered by T2's deep-equal once the field exists.
- DoD#2: the T5 raw-RNG lint test **is** the durable check; it belongs in
  `run_tests.sh` / CI, not `check_docs.py` (that one guards docs vocab, not GDScript).
