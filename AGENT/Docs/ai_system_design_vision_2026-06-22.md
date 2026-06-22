# AI System — Design Vision (player-facing · campaign-builder · architecture)

**Started:** 2026-06-22
**Status:** Design vision — drafted 2026-06-22a. Informs the eventual AI design plan and the
`[AIP-1..5]` build; this is a vision/architecture record, NOT a decisions register (no DoD status
flip). Open sub-decisions are flagged inline as **[OPEN]**.
**Source:** session 2026-06-22a (AIP §8 gap analysis); `ai_profiles_open_questions_2026-06-21.md`;
FOW-2 encounter-layer idea (`fog_of_war_los_open_questions_2026-06-21.md`); campaign-save branch I
(`campaign_save_player_facing_firming_2026-06-21.md`).
**Companion:** `GDD_08_Enemy_AI.md`, `ai_profiles_open_questions_2026-06-21.md`.

---

## 0. The one idea: AI as composition, not a profile enum

Today AI is a flat `match enemy.data.ai_profile` in `EnemyAI._act()`. Keeping that shape means
every future behavior edits the match, and campaign authors are stuck with hardcoded presets.
The vision treats a unit's AI as a **composition of three pluggable axes** plus two cross-cutting
layers. The named "profiles" (`territorial`, `flee`, …) become **presets** = bundles over the axes.

**Three axes (per unit):**
1. **Activation** — *when does it engage?* `proximity | event/flag | turn | always | never` (+ `group_id`).
2. **Disposition (movement intent)** — *where does it want to be?* `pursue_unit | hold_tile |
   seek_tile | flee`; **target may be a unit OR a tile**; `home_tile`/leash params.
3. **Engagement (combat evaluation)** — *given it can act, what's best?* `target_policy`,
   `weapon_select`, `trade_eval`, `item_use`.

**Two cross-cutting layers:**
- **Grouping** — aggro/events usually address a *squad* (`group_id`), not one unit.
- **Difficulty** — an author-defined overlay that may scale stats, add units/reinforcements, and
  swap AI options/engagement tier (see §3).

Each §8 AI gap then becomes "**extend one axis**," never "rewrite the dispatch":
- event/turn aggression → Activation; goal-tile seeking → Disposition; weapon/trade/item smarts →
  Engagement (the separate "combat AI" workstream).

---

## 1. Player-facing side — what the AI feels like

Pillars (owner-confirmed 2026-06-22a):
- **Predictable & deterministic.** Same board → same AI move, so the player can plan. Rides
  Package A determinism; the planner is a pure function of state (also powers §1's action-preview).
- **Telegraphed by default.** The HUD shows **danger zones** (aggregate danger zone built;
  per-unit threat range designed — MRD/TUR) **AND a per-enemy disposition/profile indicator**
  (aggressive / guard / asleep / fleeing…), so the player can read intent at a glance and luring
  is a legible tactic. *Disposition is visible by default* — not hidden.
- **Optional action-preview** *(deferred feature)* — "what would this unit do if it acted right
  now?" Rendered by dry-running the unit's planner against current state. **Author/difficulty-
  gated** (recommended for tutorial chapters + easy modes), not always-on. **Caveat (owner):**
  the preview is **non-binding** — it recomputes as earlier AI units act this phase, so it is a
  snapshot prediction, not a promise. UX must signal "may change." → **[OPEN]** exact gating
  surface (per-chapter flag vs difficulty band vs accessibility toggle).
- **Counterplay per behavior.** Every behavior has a learnable counter (lure a territorial group
  one at a time; bait an aggressor; block the looter's path; burst the boss before adds spawn).
- **Personality/variety.** A boss reads differently from a grunt; higher difficulty feels like
  smarter play (better engagement tier), not only bigger numbers — *if the author opts into it*.

## 2. Campaign-builder side — how AI is authored

Aligned to campaign-save **branch I** (data-driven, human-readable JSON, mod-friendly, load-
validated; formal pack format I3 deferred but unblocked). Owner: **presets-first**, with full
manual control as the escape hatch, and an **eventual GUI campaign builder/editor** on top of the
same data.

- **Presets first.** An author writes `ai: "aggressive_boss"` (a named preset), not five raw axis
  fields. Recommended presets ship in docs + the future editor. Raw axis overrides
  (`activation`/`disposition`/`engagement` keys) are the escape hatch for special cases.
- **Full manual control.** Authors set unit level, stat modifiers, special skill additions, and
  **every AI option the engine exposes** — per placement.
- **Group-based.** `group_id` authors a squad's activation/aggro once (one unit spotting the
  player wakes the group). Events (MET) address groups too.
- **Event hooks via MET.** "Wake group G on turn 6", "spawn reinforcements when the boss dies" —
  the MET trigger→action layer (+ the proposed `set_aggro`/`wake` action, AIP §8 gap #1).
- **Safe by default.** Sensible `GameConstants` defaults + the boot validator + load-time
  validation (branch I4 warn-and-continue) so a casual author can't easily ship a broken/soft-
  locking map.
- **Data home.** AI authoring rides the **encounter layer** (the FOW-2 reusable-terrain +
  per-encounter-overlay split): roster, AI specs, fog, weather, and difficulty bands are encounter
  data, not baked terrain. Until that split lands, it all lives on `MapData` next to
  `enemy_placements` (as today).

## 3. Difficulty model — author-defined bands as overlays

Owner's vision: difficulty is **not** a fixed engine Normal/Hard/Lunatic — each **campaign declares
the difficulty levels it supports** (0..N), and the player picks from that set (one offered band ⇒
no choice).

- A **difficulty band** = `{ id, display_name, modifiers }`, where `modifiers` may include: stat
  scaling, **extra units**, **extra/earlier reinforcements**, AI-option swaps (e.g., a smarter
  `engagement` tier), and other knobs. It is an **overlay applied to the base encounter at map
  load**, producing the effective roster + AI specs.
- **Persistence:** the chosen band is saved (campaign-save §2) and re-applied on load.
- **Composition order** (later overrides earlier): base preset → per-placement overrides → group
  inheritance → **difficulty overlay**.
- **[OPEN]** band-modifier vocabulary (the closed set of knobs a band may set) — firm when the
  encounter layer + §2 CampaignRules consolidation are designed.
- **[OPEN]** whether difficulty may change *activation/disposition* (not just stats + engagement
  tier + roster). Rec: allow engagement-tier + roster + stats first; gate disposition/activation
  changes behind explicit author opt-in to avoid a band silently rewriting a map's pacing.

---

## 4. Code design / extensibility — seams that support all of the above

The MVP `[AIP-1..5]` build ships only 4 profiles, but it should be **structured as the composition
engine from day one** (small preset library, not a `match`) so the §8 gaps + difficulty + preview
are additive, never a rewrite. Concretely:

- **AI spec resolver.** `resolve_ai_spec(placement, group, difficulty) -> AISpec` layering base
  preset → placement overrides → group → difficulty overlay. Profiles = entries in a **data-driven
  preset registry** (`preset_id -> {activation, disposition, engagement}`).
- **Planner replaces the match.** `EnemyAI` runs `plan_action(unit, board) -> PlannedAction` as a
  **pure function of state** (determinism + reusable by the action-preview dry-run), then executes
  it. The three axes are separate functions even in MVP:
  - **Activation/aggro manager** — group-aware; checks proximity OR a map-flag (the MET bridge)
    even in v1, so event-aggro slots in without touching callers.
  - **Disposition planner** — emits a **movement goal as a tile**, with the target abstracted as
    **unit-or-tile** from the start (so `seek_tile`/`flee goal_tile` are data, not new code).
  - **Engagement evaluator** — a **seam** even if v1 engagement = today's "attack best target."
    This is where the combat-AI workstream (weapon-select / trade-eval / item-use / value
    targeting) plugs in later, and where difficulty swaps the tier.
- **Single target-acquisition seam.** Keep AI hostile lookup funnelled through
  `_living_hostiles_for_faction` (already true) so the future `ai_respects_fog` rule + `weakest`
  policy wrap one function (FOW-3 / AIP-1 alignment).
- **Validator + check_docs guards** for the preset list, `target_policy`, and (later) the band-
  modifier vocabulary — mirror the `mouse_cursor`/movement-type value-set checks (DoD#2).

**Minimum "don't-paint-into-a-corner" rules for the MVP AIP build** (build Package A + §2 first):
1. Profiles resolve to an `AISpec`; no behavior is hardcoded in a `match`.
2. Disposition target is unit-or-tile from day one.
3. Activation reads an optional flag (MET bridge) from day one.
4. The engagement step is a function seam, even if trivial in v1.
These four are cheap in v1 and make every §8 gap + difficulty + preview purely additive.

---

## 5. Open sub-decisions (revisit when firming the AI design plan)
- **[OPEN]** Action-preview gating surface (chapter flag / difficulty band / accessibility).
- **[OPEN]** Difficulty band-modifier vocabulary (closed knob set); whether bands may touch
  activation/disposition or only stats/roster/engagement-tier.
- **[OPEN]** Preset library — the recommended named presets to ship (docs + GUI), and their
  axis bundles.
- **[OPEN]** The four held AIP MVP-spec refinements (register §7) fold in as preset/axis defaults.
- **[OPEN]** Disposition indicator visual language (icons/labels for the player-facing telegraph).
- Cross-ref: MET growth for the bridge (`set_aggro`/`wake`, `unit_hp_below`, spawn-acts-immediately
  — see `map_events_triggers_open_questions_2026-06-21.md` [MET-3] note).
