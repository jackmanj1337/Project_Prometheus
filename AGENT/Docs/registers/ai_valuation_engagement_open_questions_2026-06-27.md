---
Type: register
Status: RESOLVED 2026-06-27
Last verified: 2026-06-27
Register: VAL-1..13
Resolved-in: 2026-06-27 — full end-shape walk in one session (session 2026-06-27b), the keystone the perception walk teed up. VAL-1 whole-action scoring; VAL-2 static leaf eval (forecast + post-move exposure); VAL-3 configurable search_depth (negamax seam now, depth=0 v1, recursion staged); VAL-4 pure board forward-model (forward-req, triple-use); VAL-5 score = F16 term-tree + engine forecast term-sources; VAL-6 the forecast term-source vocabulary (new authoring surface, REQ-15 pattern); VAL-7 ai_target_weight is the Stage-2 multiplier (closes PER-4); VAL-8 author-selectable ai_activation_order ∈ {fixed, priority_sort, greedy_best_first, random=seeded}; VAL-9 determinism (fixed-point + stable tie-breaks); VAL-10 the AIP pure-planner seam is the unbuilt prerequisite; VAL-11 non-combat actions fold into the scorer (dancer-timing = the known hard edge, PARTIAL); VAL-12 consumers wired (PER-4/PER-12/CVR-4/RCT-1); VAL-13 forward DoD#2 + campaign-guide obligations. This register IS the engagement/combat-AI workstream the AIP docs deferred as [AIP-14].
---

# AI Combat Valuation / Engagement Brain — Open Questions

**Started:** 2026-06-27 (session 2026-06-27b), from the owner plan "return to the AI / prediction model
— review how it works and see if it can be improved." The perception walk `[PER-1..12]` had pinned four
threads (`[PER-4]`, `[PER-12]`, `[CVR-4]`, `[RCT-1]`) on "the forecast-driven valuation AI that does not
exist yet." This register **is** that AI.

**Status (RESOLVED — end-shape locked, build staged):** the four owner forks (decision unit · horizon ·
scoring home · activation order) all got decisive calls; the architecture, the determinism rails, the
reuse map, and the staging are design-locked. What remains are **deferred build pieces** (the pure board
forward-model + depth>0 recursion) and **forward-reqs on adjacent systems** (the AIP pure-planner seam;
F16 forecast term-sources), each flagged inline. Nothing is built (design-capture only; no GDD/roadmap
behavior change yet).

**The one idea:** an AI turn is *one* question — **"of all the legal things this unit could do, which is
best?"** — answered by scoring whole candidate actions against the combat **forecast**. This maps exactly
onto the `[PER-1]` three-stage pipeline, so the perception walk was implicitly deriving this architecture:

```
Stage 1  ENUMERATION  candidate set (tiles × targets × weapons × actions)  → GridManager.get_attackable_enemies_from_tile / get_movement_range
Stage 2  VALUATION     a score per candidate                                → THIS REGISTER (absent today; EnemyAI picks nearest)
Stage 3  FORECAST      predicted exchange feeding the score                 → CombatResolver.preview_combat() (exists, AI never calls it)
```

**Today's AI (the baseline being replaced):** `EnemyAI._act()` is a flat `match enemy.data.ai_profile`
(`basic`/`passive`/`healer`). Target = nearest by Dijkstra cost (`_find_nearest`); move = any tile it can
attack *anyone* from, tie-broken by nearness (`_choose_move_tile`). Move and attack are decided
**separately and greedily**, and the forecast is **never read** — so the AI walks into lethal counters and
chips targets it cannot dent. Activation order = registration/placement order (`GameState.get_living_units_of`).

**Code:** `scripts/core/EnemyAI.gd` (`_act` :78, `_choose_move_tile` :222, `_find_nearest` :275,
`run_phase` :13 — the activation loop), `scripts/core/CombatResolver.gd` (`preview_combat` :553 — the
forecast leaf), `scripts/autoloads/GameState.gd` (`get_living_units_of` :239 — current order),
`requirement_predicate_system_open_questions_2026-06-25.md` (F16/REQ-16 — the score expression + REQ-15
projection pattern), `perception_masking_open_questions_2026-06-27.md` (PER-4 the Stage-2 knob).
**Companions:** `ai_system_design_vision_2026-06-22.md` (§6 ML eval = a future Engagement-tier swap),
`ai_first_build_design_2026-06-22.md` (the pure-planner seam this brain plugs into; this register = its
deferred `[AIP-14]`). Legend: **[OPEN]** / **[RESOLVED]** / **[DEFERRED]** / **[PARTIAL]**.

---

## VAL-1 — The decision unit: whole-action scoring  `[RESOLVED — owner Fork A]`
A candidate = **`{move_tile, action, target, weapon}`** scored as one unit; the planner enumerates the
legal set and picks the highest score. This fixes the greedy two-step (you cannot pick the best tile
without knowing what attack it enables and at what risk). The candidate set is bounded (reachable tiles ×
valid targets × equipped weapons + staff/item/wait) — small enough to score exhaustively on typical maps.
**Folds in weapon-select for free:** the best weapon simply scores highest (one of the `[AIP-14]` smarts,
no special code). Rejected: keep move/attack separate (today's shape).

## VAL-2 — The leaf evaluation (static eval)  `[RESOLVED — owner Fork B leaf]`
A candidate's *static* score = its **immediate `preview_combat` forecast** plus a **post-move threat-
exposure** penalty = forecasted enemy damage that can reach the **destination tile** next turn (a static
lookup against the opposing faction's threat range / danger-zone infra — `[MRD]`/threat-range — **not** a
search). Feature axes feeding the score: expected damage dealt / overkill, kill-secured (large +), damage
taken from counters, self-death risk (large −), target value (`[VAL-7]`), positional gain (terrain
DEF/dodge), and post-move exposure. The exposure term is the single feature that separates an AI that
suicides from one that plays safe.

## VAL-3 — Configurable search depth  `[RESOLVED — design; build staged]`
`search_depth` is an **engagement-axis parameter** (composes per-preset/disposition like `target_policy`;
"cautious enemies look further" → `sleeper`/`guard` bosses ship a higher default, `grunt` stays 0). The
planner is shaped as a **negamax**: at `depth=0` an action's score = the `[VAL-2]` static leaf; at
`depth≥1` it = static eval minus the opponent's best-response score, recursively.
- **Staging (owner):** the **negamax shell + the `search_depth` field go in from day one** (seam), but
  **v1 defaults depth=0** and the recursion is **deferred** (it needs `[VAL-4]`). Depth>0 is then purely
  additive. Full permutation/N-ply search beyond this is **rejected** (branching factor; vision §6
  "score, don't search").
- **Owner note carried to the build:** depth>0 is big cost for minimal tactical gain in FE-likes →
  `[VAL-13]` requires a prominent campaign-guide perf warning on the setting.

## VAL-4 — The pure board forward-model  `[DEFERRED — forward-req; gates VAL-3 depth>0]`
Depth≥1 recursion needs **`apply(PlannedAction, board) -> board'`** — `preview_combat` only yields the
*exchange* (HP deltas); recursion needs the *whole resulting board* (positions, deaths, who-can-act-next)
to enumerate the opponent's replies. Heavier than anything today. **Triple-use, so not single-purpose:**
the same forward-model is also required by the deferred **action-preview** (`[AIP-12]`) and the **ML
harness** (vision §6 step 2). Build with depth>0, not before.

## VAL-5 — Where the scoring formula lives  `[RESOLVED — owner Fork C, the "A-plus" shape]`
The score **is an F16 / REQ-16 value-tree** (`[REQ-16]` fixed-point ×1000 arithmetic), so it is
data-composed, **deterministic by construction**, author-tunable per campaign, and reuses the project's
one extensibility model. The **engine computes the features** (`[VAL-6]`) and exposes them as term-sources;
**v1 ships a default weighted-sum expressed AS a tree** (the "A-plus" / EXT porous-line pattern — authoring
is data from day one, the relief valve stays open). Rejected: hardcoded GDScript sum (un-authorable,
against the grain) and a fixed-feature/author-coefficients-only model (less expressive than the tree).

## VAL-6 — Forecast term-sources (the new authoring surface)  `[RESOLVED — direction; vocab firms at build]`
F16 terms today read unit stats, not combat projections, so the score-tree needs new **forecast
term-sources**: `expected_damage`, `would_kill`, `damage_taken`, `post_move_exposure`, `target_value`,
(and likely `overkill`, `hit_chance`, `crit_chance`). This is the **one genuinely new vocabulary** the
brain adds — and it is **precedented**, not new machinery: it is the same **REQ-15 outcome-projection
pattern** (`condition_would_kill` / `next_tick_damage`) already pinned on F5/preview. **Forward-req on
F16** to add the sources; the exact list firms at build alongside the F16 v1 vocab build.

## VAL-7 — Stage-2 valuation knob = `ai_target_weight`  `[RESOLVED — closes PER-4]`
The `[PER-4]` per-unit `ai_target_weight` (carried by the perceived unit, `[PER-2]` surface B) is a
**multiplier term into the score** (the `target_value` feature). This register is PER-4's consumer:
PER-4 was "RESOLVED-but-INERT pending the valuation AI" → **now has its consumer**, so the bait-the-
defender example (Stage-2 mis-valuation) becomes expressible. The deterministic/contest reveal that gates
whether an observer mis-values a unit rides `[PER-12]` (detection vs appraisal) → F16 contest (`[REQ-10]`).

## VAL-8 — Activation ordering  `[RESOLVED — owner Fork D]`
**Who acts in what order** is today a non-decision (registration/placement order). It becomes an
**author-selectable campaign rule** `ai_activation_order` (CampaignRules; campaign-default + the standard
per-map override cascade, mirroring `[FOW-3]`/`[DSP-17]`; validated value-set + `check_docs` guard at
build per `[VAL-13]`). **Build all four** (owner: "build everything, let authors pick"):
- `fixed` — placement order (today).
- `priority_sort` — stable sort by a per-preset `activation_priority` key (supports/ranged early).
- `greedy_best_first` — each step, execute the **highest-scoring `[VAL-1]` action across all not-yet-acted
  units**, then re-score the rest. Emergent good sequencing (kill-secures/openers first) for almost no new
  code, and — key — **needs no forward-model** (each action is executed for real, so the board updates
  itself; O(units²×candidates), fine for ~dozen enemies).
- `random` — **seeded deterministic shuffle from the map seed via RngService / Package A**, never engine
  RNG (unseeded would break the determinism pillar and desync lockstep — same rail as `[REQ-10]`).
Composes with a per-preset `activation_priority` bias and **group contiguity** (`group_id` squads act
together).

## VAL-9 — Determinism  `[RESOLVED]`
Scores are **fixed-point** (`[REQ-16]` ×1000) with **stable integer tie-breaks** (path cost, then a
deterministic key — GDD_08 §Determinism). The only RNG is the latched `[REQ-10]` `chance` (contest) and
the `[VAL-8]` seeded shuffle. Any future ML eval (vision §6 Option A) must feed a **ranking** into these
tie-breaks, never introduce nondeterministic float ordering. This is what also makes `plan_action` a pure
function (and therefore the action-preview dry-run) possible.

## VAL-10 — Prerequisite: the AIP pure-planner seam  `[RESOLVED — sequencing]`
The brain is the **Engagement evaluator** that plugs into the `ai_first_build_design` **pure
`plan_action(unit, board) -> PlannedAction`** seam — which is **itself not built yet** (`EnemyAI` is still
the `match`). Building the valuation into today's match-statement is exactly the "paint into a corner" the
vision §4 warns against. **Order: land the AIP first-build composition/planner seam, then this brain as the
engagement tier.** (Gated per-chapter / global setting, **not** a difficulty band — `[AIP-11]`/`[AIP-14]`.)

## VAL-11 — Non-combat actions fold into the scorer  `[PARTIAL — dancer-timing flagged]`
Staff-heal, item-use, and dance/refresh (`[AGT]`) become **scored actions in the same candidate set** — no
special-case `_act_healer` dispatch; the healer "profile" becomes "engagement weights that value healing."
**The one genuinely hard edge: dancer/refresher timing.** Greedy `[VAL-8]` handles it *only if the scorer
values the refresh's downstream enablement* (the dance is good because it lets another unit act again),
which the static leaf `[VAL-2]` does not see without lookahead. **Open at build:** either a bespoke
enablement feature-term, or rely on depth>0, or an `activation_priority` ordering rule for refreshers.

## VAL-12 — Consumers wired  `[RESOLVED]`
This register closes the forward-deps the perception/interceptor walks parked: **`[PER-4]`** (Stage-2 knob
→ `[VAL-7]`), **`[PER-12]`** appraisal axis (its value lands with this AI), **`[CVR-4]`** and **`[RCT-1]`**
("the combat forecast must reflect the real defender AND the AI target-eval reads the same forecast" — now
true, since the AI reads `preview_combat` here). The cover/reposition preview principle and this brain's
forecast read are the same `preview_combat` call.

## VAL-13 — Build-time obligations (DoD#2 + guide)  `[RESOLVED — forward]`
At build (not now — design-capture only, mirroring the PER precedent):
- **DoD#2 `check_docs` guards** for the new validated value-sets: `ai_activation_order`
  (`fixed|priority_sort|greedy_best_first|random`) and an **absolute safety ceiling** on `search_depth`
  (+ a node-count ceiling on the score-tree, the `[REQ-16]` precedent). `target_policy` already has its set.
- **Campaign-guide note** (owner): a prominent warning that raising `search_depth` can slow the game for
  minimal tactical gain.
- **DoD#1**: update `GDD_08_Enemy_AI.md` + flip `GDD_10_Roadmap.md` status in the build commit.

---

## Resolution summary
End-shape **design-locked** (VAL-1/2/3/5/6/7/8/9/10/12). **Deferred build:** VAL-4 forward-model (+ VAL-3
depth>0). **PARTIAL:** VAL-11 dancer-timing. **Forward-reqs on other owners:** the AIP pure-planner seam
(VAL-10), F16 forecast term-sources (VAL-6), F16 v1 vocab build. **Reuse map:** `preview_combat` (leaf) ·
the `[PER-1]` enumeration funnel · `get_movement_range`/`dijkstra_costs` (candidates) · F16/REQ-16 (score)
· REQ-15 pattern (term-sources) · threat-range/danger-zone (exposure) · `ai_target_weight` (VAL-7) ·
Package A (seeded shuffle + latched chance). **New surface:** forecast term-sources + the candidate
enumerator + the default scoring tree + the `plan_action` planner.
