---
Role: dated
Type: register
Status: RESOLVED 2026-06-27
Last verified: 2026-06-27
Register: PER-1..12
Resolved-in: 2026-06-27 — full perception walk in one session. PER-1..6/10 design-locked; PER-7 union (no precedence); PER-8 occupancy in v1 (around|through + DSP-14/DSP-12 follow-ups); PER-9 = a two-channel (player-view A / AI-view B, may be equal) communicated CampaignRules constant + debug reveal-all override (sibling of [FOW-3]); PER-11 no-softlock + two-hook finding; PER-12 detection-vs-appraisal = two F16 contest axes (same or different sight term, author's choice). PER-4 RESOLVED-but-INERT (forward-req on the valuation AI [CVR-4]/[RCT-1])
---

# Perception / Masking — AI & Player Forecast Manipulation — Open Questions

**Started:** 2026-06-27, from the owner detour "how does the prediction engine work, and can features
be hidden from the prediction without hiding them from reality" — to (a) dumb down AI on easier
difficulties and (b) bait enemies into traps.

**Status (RESOLVED):** the **model, control surfaces, contest, occupancy, and player-communication are
all design-locked** (PER-1..11). The one residual is a *dependency*, not an open question: **PER-4 (the
valuation-bias lever) is inert until the forecast-driven valuation AI exists** (`[CVR-4]`/`[RCT-1]`).
Nothing is built. No GDD/roadmap behavior change yet (design-capture only).

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
- `hard_untargetable: bool` → removed from the observer's candidate list.
  **Works against the current nearest-target AI today** (the one piece shippable before valuation AI).
- `audience: "ai" | "both"` — `ai` = player still sees & clicks (the ninja example); `both` = true
  stealth (no one targets). Player-only enumeration hiding is rejected (hostile UX).
- **Two hooks, not one (PER-11 finding):** the AI queries targets in **two** places — `EnemyAI.
  _living_hostiles_for_faction` (:91, drives *approach/movement*) and `GridManager.
  get_attackable_enemies_from_tile` (:440, drives *the attack*). Stage-1 masking must filter **both**,
  or a masked unit still attracts AI movement (the enemy walks up to an invisible target and flails).

## PER-4 — Stage-2 soft valuation bias (the defender-bait)  `[RESOLVED design — INERT, forward-req]`
- `ai_target_weight: int` on the perceived unit — positive = lure/taunt, negative = soft-ignore. The
  general lever (the ninja's hard mask is the extreme; a big negative is soft-ignore).
- **Dependency:** there is **no AI scoring hook** today (`EnemyAI._find_nearest`). This field ships
  **inert** and activates with the forecast-driven valuation AI — **now walked as `[VAL]`**
  (`ai_valuation_engagement_open_questions_2026-06-27.md`); `ai_target_weight` is its Stage-2 multiplier
  term `[VAL-7]`. Schema it now to avoid retrofit. The defender-bait goal is genuinely downstream of that AI.
- **See-through (appraisal):** this is an *appraisal* mask (misdirection), so it carries an optional F16
  see-through contest — distinct from PER-6 detection. See **PER-12**.

## PER-5 — Stage-3 forecast visibility  `[RESOLVED — extends existing split]`
- `forecast_hidden_to: "ai" | "player" | "both" | ""` (per-unit override of the PER-2A default).
  Generalizes `if preview and skill.activation_chance_stat != "": continue` to "skip if the requesting
  audience is hidden." `ai` = difficulty/blinding lever · `player` = fog/surprise · `both` = concealed
  reaction (the interceptor-family bait case, `[ICP-4]`).

## PER-6 — Reveal / pierce counterplay = an F16 consumer  `[RESOLVED — owner lock: spec now]`
This is the **detection** half (concealment); the **appraisal** half (misdirection) is **PER-12** — same
F16 pattern, possibly the same or a different sight term. Two halves of one contest; **the contest is F16,
not bespoke** (see header callout):
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

## PER-7 — Multi-observer resolution  `[RESOLVED — union, no precedence needed]`
The proposed "highest pierce wins" framing was wrong: reveals are **purely additive/monotonic** — more
sight only ever reveals more, never less. So there is **no precedence/tiebreak**. The contest is
evaluated **per `(observer, unit)` pair** using *that observer's* `pierce_strength`; a unit U is
targetable by observer X iff **∃ a winning observer O such that `X ∈ O.share_scope`** (self = {O}; aura =
{O + allies in radius}; faction = whole faction). The reveal set is the **union** across all winners —
`faction`-share from any single winner subsumes the rest automatically. Strength only matters *within*
one observer's own contest, never compared between observers.

## PER-8 — Occupancy of a masked unit's tile  `[RESOLVED — owner: in v1, around|through + follow-up]`
Occupancy is a **separate** axis from targetability (PER-3), authored per mask. For units that **cannot
perceive** the masked unit:
- **`stealth_pathing: around | through`** (default `around`).
  - `around` — the tile is treated as **blocked/impassable** (normal occupancy). Simple, but a
    pathfinder detour can itself leak "something is here."
  - `through` — the tile is treated as **empty/passable**; unaware units may cross or stop on it.
- **Follow-up when `through` (two cases, author-selectable):**
  - **`on_cross`** — a unit moves *across* the tile without stopping. Default = nothing (true ghost);
    opt-in = a **reactive trigger** (reveal / attack-of-opportunity / spring a trap — the "bait into
    traps" use-case). Reuse the reactive/off-turn displacement path (`[DSP-12]`) + the reaction-family
    event surface, **not** a bespoke movement hook.
  - **`on_stop`** — a unit *ends its move on* the occupied tile (two units, one tile). **Reuse the
    `[DSP-14]` invalid-destination outcome set** (`fail` = revert/re-route [default], `collision_damage`,
    `chain_push`, `force_onto_invalid`) plus a perception-specific `reveal` outcome. The transient
    two-on-one-tile state reuses the **PairUpRegistry off-map-sentinel** substrate (`[DSP-2]`); the move
    itself rides the **`[DSP-1]`** occupancy-mutation primitive. Default = **reveal + `fail`** (the
    intruder discovers the unit and the overlap is resolved by re-route).
- **No new collision code** — PER-8 is a thin perception-aware front on the displacement framework.

## PER-9 — Forecast fidelity = a two-channel campaign constant (+ debug override)  `[RESOLVED — owner: CampaignRules]`
Forecast fidelity is **not** a per-feature UI tell — it is a **campaign/difficulty `CampaignRules` (F4)
constant, communicated to the player alongside the other campaign rules** (the surface that shows
difficulty modifiers at campaign start / settings). It declares **two channels** (owner 2026-06-27):
- **Channel A — what humans see** (`player_forecast_fidelity`): the fidelity of the displayed forecast.
- **Channel B — what the AI evaluates on** (`ai_forecast_fidelity`): the fidelity the AI's valuation reads.
- **A and B may be equal** (full-info run) or diverge (e.g. honest player display + blinded/dumbed AI on
  easy, or a fogged player + cheating AI). B is the **difficulty/dumb-down lever**; A is the
  fairness/fog dial. The per-feature `forecast_hidden_to` (PER-5) and per-unit masks layer **on top** of
  these run-wide baselines; the campaign constant is the floor everyone can read.
- **Debug / author-testing override** (`forecast_reveal_all`, owner 2026-06-27): a dev/author switch that
  **forces both channels to full fidelity** (and reveals masked units) — bypasses all PER blinding so the
  author can verify the real picture. **Projection/display only — never touches `resolve_combat` (PER-10);
  off in shipped runs.**
- **Sibling of `[FOW-3]` `ai_respects_fog`:** both are run-wide "what each side knows vs reality" rules in
  the **§2 CampaignRules consolidation** (channel B ≈ the AI-knowledge dial; A ≈ the player-fog dial).
- **Display surface:** rides whatever renders campaign rules to the player — built with **fog-of-war / the
  §2 CampaignRules consolidation** (neither built yet). The *decision* (two communicated channels + debug
  override) is settled; **revisit only the shared display widget when FoW / §2 lands.**

## PER-10 — Determinism: perception filters projection inputs only  `[RESOLVED — hard rule]`
Every knob filters **enumeration/valuation/forecast inputs only** — **never `resolve_combat()`**. If a
unit is forced into combat (player click, forced effect), the real path is canonical and replay-safe. The
existing `preview`/`dry_run` split (`preview_combat` snapshots and restores) is the precedent.

## PER-11 — AI softlock fallback when all targets masked  `[RESOLVED — no softlock; verified in code]`
Verified against `EnemyAI._act` (:78): **no hard softlock.** Each pass sets unit state
(`MOVED`/`DONE`) unconditionally; empty hostiles → `DONE` (:92-94); empty *attackable* set → staff-heal
attempt → `DONE` (:127). The loop always terminates. The real issue was behavioral, not a hang — see the
PER-3 **two-hook** finding (a mask on only `get_attackable_enemies_from_tile` leaves the unit attracting
*movement* via `_living_hostiles_for_faction`). Filtering both hooks fixes it. **TODO when built:** a test
that an all-masked board makes the AI advance/hold without flailing.

## PER-12 — Detection vs appraisal: two contest axes  `[RESOLVED — owner Q 2026-06-27]`
"Sight that *finds* a unit" and "insight that *judges* a unit" are **distinct axes**:
- **Detection** (stage 1) overcomes **concealment** — perceive a unit that is hiding (the ninja).
  Contest = pierce vs `stealth_strength` (**PER-6**).
- **Appraisal** (stage 2/3) overcomes **misdirection** — read the *true threat* of a unit that is
  perceived but **disguised** (a healer made to look dangerous; the tough defender made to look juicy).
- **Reframe (key):** a *genuinely* harmless unit (unarmed healer = 0 damage, no counter) is already read
  as low-threat by **any full-fidelity forecast** — no sight needed to see the obvious. Appraisal only
  matters when threat is **actively masked** (PER-4 `ai_target_weight`, PER-5 `forecast_hidden_to`).
- **Gap this closes:** PER-6 specced only the *detection* contest; the appraisal masks (PER-4/PER-5) were
  unconditional. Now **each appraisal mask carries an optional F16 see-through contest** (same pattern,
  author-chosen term). Default = no contest (mask is flat) unless the author attaches one.
- **"Same sight for both?" = content choice, not an engine fork:** point the detection and appraisal
  contests at the **same term** (one `perception` stat → the scout who finds the ninja also reads the
  healer truly) or **different terms** (`sight` vs `insight` → scout detects, tactician appraises). Both
  work because every contest term is an **F16** value term.
- **Relationship to threat-eval:** **detection gates *entry*** into the AI's target-eval (unperceived =
  not evaluated); **appraisal-insight gates whether the masks *fool*** the evaluator once it is looking.
  Both consume F16; the AI's eval reads the **post-mask, post-contest** valuation/forecast inputs.
- **Per-audience:** appraisal masks carry the `ai | player | both` audience like all PER — a threat-
  disguise can fool the AI, the player, or both; the insight to pierce it is contested per side.

---

## Net
- **Shippable now (vs the current AI):** PER-3 hard mask + PER-6 pierce/contest (enumeration is the only
  stage today's AI uses), PER-5 forecast visibility (small extension), PER-10 invariant.
- **Inert until valuation AI:** PER-4 soft weight — its consumer is now `[VAL-7]` (the valuation brain,
  walked 2026-06-27b); PER-12's appraisal value also lands with `[VAL]`.
- **Settled 2026-06-27:** PER-7 (union, no precedence), PER-8 (occupancy in v1 — `around|through` +
  `on_cross`/`on_stop` reusing `[DSP-14]`/`[DSP-12]`/`[DSP-1]`/`[DSP-2]`), PER-9 (communicated
  CampaignRules constant, sibling of `[FOW-3]`), PER-11 (no softlock; two-hook fix).
- **Two contest axes (PER-12):** detection (PER-6, find the hidden) vs appraisal (PER-4/5 see-through,
  judge the disguised) — same F16 pattern; one term unifies "sight", separate terms split it.
- **Only residual = the PER-4 dependency** (valuation AI), and two *build-time revisits*: PER-9's shared
  display widget (lands with FoW/§2) and the PER-11 all-masked-board test.

## Cross-references
- **Contest substrate = `[REQ-10]` / Foundation F16** (`requirement_predicate_system_open_questions_2026-06-25.md`).
  Perception is an F16 consumer. **This is the link that kept getting lost — do not re-spec a contest.**
- **Forecast precedent:** `[STY-10]` generalized effect forecast, `[REQ-15]` outcome projection,
  `[ICP-4]` interceptor forecast as a pure dry-run.
- **Valuation-AI dependency:** `[CVR-4]`/`[RCT-1]` (AI target-eval reads the same forecast → forecast
  fidelity = AI capability). PER-4 is inert until this lands.
- **Duration/lifecycle reuse:** `active_modifiers` `duration_type` (add `"turn"`), `skill_use_counters`.
- **MET-4** ("richer predicates added later") and perception both consume F16 — one contest, two consumers.
- **Occupancy (PER-8) = Displacement framework reuse:** `[DSP-1]` occupancy primitive, `[DSP-2]`
  PairUpRegistry off-map sentinel (two-on-one-tile), `[DSP-12]` reactive/off-turn (the `on_cross`
  trigger), `[DSP-14]` invalid-destination outcome set (the `on_stop` resolution). No new collision code.
- **Fog-of-War family (PER-9 + PER-3/4):** `[FOW-3]` `ai_respects_fog` is the sibling rule — both wrap the
  single AI-acquisition seam `EnemyAI._living_hostiles_for_faction` and both live in the **§2 CampaignRules
  consolidation**. Perception's AI-blinding (PER-4) generalizes FOW-3; player-blinding (PER-9) is its
  player-side twin. Revisit PER-9's display widget when FoW / §2 builds.
