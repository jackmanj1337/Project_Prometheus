---
Type: register
Status: OPEN 2026-06-27
Last verified: 2026-06-27
Register: PER-1..11
Resolved-in: 2026-06-27 (PER-1..6, PER-10 design-locked in the perception walk) — remaining PER-7/8/11 OPEN, PER-9 DEFERRED
---

# Perception / Masking — AI & Player Forecast Manipulation — Open Questions

**Started:** 2026-06-27, from the owner detour "how does the prediction engine work, and can features
be hidden from the prediction without hiding them from reality" — to (a) dumb down AI on easier
difficulties and (b) bait enemies into traps.

**Status (mixed):** the **model + control surfaces are design-locked** (PER-1..6, PER-10 — owner locks
in the walk); **PER-4 is inert until the forecast-driven valuation AI exists**; PER-7/8/11 OPEN; PER-9
DEFERRED. Nothing is built. No GDD/roadmap behavior change yet (design-capture only).

**The insight:** the AI/player decision is a **three-stage pipeline**, and manipulation = filtering the
**inputs** at one stage. The two owner examples land on *different* stages, which is the whole shape.

```
Stage 1  ENUMERATION   "who is even a target?"        → GridManager.get_attackable_enemies_from_tile()   [the ninja]
Stage 2  VALUATION      "which valid target is best?"  → (no AI scoring exists yet; EnemyAI picks nearest) [the defender-bait]
Stage 3  FORECAST       "what will this exchange do?"  → CombatResolver.preview_combat()                  [hide-a-skill]
```

Severity spectrum: **hard** (stage 1, removed from existence to the observer) · **medium** (stage 2,
valued wrong) · **soft** (stage 3, outcome blinded). Only stage 3 exists today (the `preview` flag at
`SkillHandler.apply_trigger:172` already excludes random-activation skills from the forecast while they
still fire in `resolve_combat()` — the precedent for "hide from prediction, not reality").

**Contest substrate (DO NOT RE-DERIVE — see PER-6):** the pierce-vs-stealth check is **NOT bespoke**. It
is an instance of the **shared Requirement/Predicate system, Foundation F16** — a **pure term comparison**
(deterministic reveal, previewable) or the **`[REQ-10]` `chance`** predicate (probabilistic reveal,
commit-only, roll-once-and-latch via Package A). `[REQ-10]` already names itself "a shared contest/check
gate, mirroring combat hit math." Perception is another **F16 consumer**, it does not define a contest.

**Code:** `scripts/core/CombatResolver.gd` (`preview_combat` :553, `_collect_combat_modifiers` :134),
`scripts/skills/SkillHandler.gd` (`apply_trigger` preview branch :172, activation roll :186-189),
`scripts/core/EnemyAI.gd` (`_find_nearest` :122/:146 — nearest-target, no scoring), `scripts/core/
GridManager.gd` (`get_attackable_enemies_from_tile` — the enumeration hook), `scripts/units/Unit.gd`
(`get_effective_stat` :300 — contest term source). Legend: **[OPEN]** / **[RESOLVED]** / **[DEFERRED]**.

---

## PER-1 — The three-stage perception pipeline  `[RESOLVED — model]`
Enumeration / valuation / forecast as above. Each stage is a distinct injection point; a feature picks
*which stage* it manipulates. This naming IS the design.

## PER-2 — Two control surfaces  `[RESOLVED — owner lock]`
- **(A) Per-effect authoring flag** — `SkillData.forecast_visibility` (static, author-set). Stage-3 only:
  does *this skill* show in the forecast. Generalizes the existing deterministic/random split.
- **(B) Per-unit perception status** — carried **by the perceived unit** (owner lock: not a per-perceiver
  debuff). One status covers all observers, travels with the unit, reuses the `active_modifiers`
  `duration_type` lifecycle (add `"turn"`). Can target any stage; overrides the (A) default per unit/turn.

## PER-3 — Stage-1 hard targetability mask (the ninja)  `[RESOLVED — owner lock: hard + soft both]`
- `hard_untargetable: bool` → removed from `get_attackable_enemies_from_tile` for the observer.
  **Works against the current nearest-target AI today** (the one piece shippable before valuation AI).
- `audience: "ai" | "both"` — `ai` = player still sees & clicks (the ninja example); `both` = true
  stealth (no one targets). Player-only enumeration hiding is rejected (hostile UX).

## PER-4 — Stage-2 soft valuation bias (the defender-bait)  `[RESOLVED design — INERT, forward-req]`
- `ai_target_weight: int` on the perceived unit — positive = lure/taunt, negative = soft-ignore. The
  general lever (the ninja's hard mask is the extreme; a big negative is soft-ignore).
- **Dependency:** there is **no AI scoring hook** today (`EnemyAI._find_nearest`). This field ships
  **inert** and activates with the forecast-driven valuation AI (`[CVR-4]`/`[RCT-1]`). Schema it now to
  avoid retrofit. The defender-bait goal is genuinely downstream of that AI work.

## PER-5 — Stage-3 forecast visibility  `[RESOLVED — extends existing split]`
- `forecast_hidden_to: "ai" | "player" | "both" | ""` (per-unit override of the PER-2A default).
  Generalizes `if preview and skill.activation_chance_stat != "": continue` to "skip if the requesting
  audience is hidden." `ai` = difficulty/blinding lever · `player` = fog/surprise · `both` = concealed
  reaction (the interceptor-family bait case, `[ICP-4]`).

## PER-6 — Reveal / pierce counterplay = an F16 consumer  `[RESOLVED — owner lock: spec now]`
Two halves of one contest; **the contest is F16, not bespoke** (see header callout):
- **Mask** (perceived unit): a `stealth_strength` term (or boolean in the simple mode).
- **Pierce** (observer/scout): `pierce_strength` term + `pierce_share`:
  - `self` — only the scout sees through ("scout sees, nobody else").
  - `aura (+ radius)` — confers sight to allies in radius ("scout shares your location to nearby enemies").
  - `faction` — any faction member who wins reveals to the whole faction ("anyone pierces → everyone sees").
- **Default = deterministic/pure comparison** (`pierce_strength > stealth_strength`): a **pure F16
  predicate**, so targetability is **previewable and stable** as units move (no per-look reroll). This
  matters: `[REQ-10] chance` is **commit-only / not previewable** and **roll-once-and-latch**, which fights
  a per-observer perception gate — so probabilistic "might spot them" is the **opt-in** `[REQ-10]` variant,
  not the default. (It then inherits Package A seeding + latch automatically.)
- **Consequence:** stage-1 targetability is **computed per-observer** — `is_targetable_by(observer)` runs
  the F16 contest + applies the share scope — not a stored bool.

## PER-7 — Multi-observer precedence  `[OPEN]`
When several scouts of differing `pierce_strength`/`pierce_share` observe one masked unit: proposed
**"highest pierce_strength among contest-winners wins, then apply the widest share scope among winners."**
Needs ratification (interacts with `faction`-share short-circuiting the per-observer evaluation).

## PER-8 — Occupancy vs targetability are separate  `[OPEN — design note]`
"Unoccupiable space" (AI won't path onto/through the tile) is a **movement/occupancy** flag, NOT a
targeting one. Keep them separate — an author may want untargetable-but-walkable. Decide whether to
introduce a parallel `ai_pathing_mask` or leave occupancy out of v1.

## PER-9 — Player-fog fairness tell  `[DEFERRED — UI]`
Stage-3 blinding toward the *player* needs a tell ("forecast may be incomplete") or it feels unfair.
UI-layer, post-schema.

## PER-10 — Determinism: perception filters projection inputs only  `[RESOLVED — hard rule]`
Every knob filters **enumeration/valuation/forecast inputs only** — **never `resolve_combat()`**. If a
unit is forced into combat (player click, forced effect), the real path is canonical and replay-safe. The
existing `preview`/`dry_run` split (`preview_combat` snapshots and restores) is the precedent.

## PER-11 — AI softlock fallback when all targets masked  `[OPEN — verify]`
If a stage-1 mask hides *every* target, the aggressive AI must fall back to advance/hold
(`EnemyAI._choose_move_tile`). Verify the existing fallback catches an empty candidate list before
shipping stealth; add a test.

---

## Net
- **Shippable now (vs the current AI):** PER-3 hard mask + PER-6 pierce/contest (enumeration is the only
  stage today's AI uses), PER-5 forecast visibility (small extension), PER-10 invariant.
- **Inert until valuation AI:** PER-4 soft weight (`[CVR-4]`/`[RCT-1]` dependency).
- **Open:** PER-7 precedence, PER-8 occupancy split, PER-11 softlock fallback. **Deferred:** PER-9 tell.

## Cross-references
- **Contest substrate = `[REQ-10]` / Foundation F16** (`requirement_predicate_system_open_questions_2026-06-25.md`).
  Perception is an F16 consumer. **This is the link that kept getting lost — do not re-spec a contest.**
- **Forecast precedent:** `[STY-10]` generalized effect forecast, `[REQ-15]` outcome projection,
  `[ICP-4]` interceptor forecast as a pure dry-run.
- **Valuation-AI dependency:** `[CVR-4]`/`[RCT-1]` (AI target-eval reads the same forecast → forecast
  fidelity = AI capability). PER-4 is inert until this lands.
- **Duration/lifecycle reuse:** `active_modifiers` `duration_type` (add `"turn"`), `skill_use_counters`.
- **MET-4** ("richer predicates added later") and perception both consume F16 — one contest, two consumers.
