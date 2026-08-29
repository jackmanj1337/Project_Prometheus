---
Type: register
Status: Split - PER-1..12 RESOLVED; PER-13..17 OPEN 2026-08-29
Last verified: 2026-08-29
Register: PER-1..17
Resolved-in: 2026-06-27 — full perception walk in one session. PER-1..6/10 design-locked; PER-7 union (no precedence); PER-8 occupancy in v1 (around|through + DSP-14/DSP-12 follow-ups); PER-9 = a two-channel (player-view A / AI-view B, may be equal) communicated CampaignRules constant + debug reveal-all override (sibling of [FOW-3]); PER-11 no-softlock + two-hook finding; PER-12 detection-vs-appraisal = two F16 contest axes (same or different sight term, author's choice). PER-4 RESOLVED-but-INERT (forward-req on the valuation AI [CVR-4]/[RCT-1])
---

# Perception / Masking — AI & Player Forecast Manipulation — Open Questions

**Started:** 2026-06-27, from the owner detour "how does the prediction engine work, and can features
be hidden from the prediction without hiding them from reality" — to (a) dumb down AI on easier
difficulties and (b) bait enemies into traps.

**Status:** the original **model, control surfaces, contest, occupancy, and player-communication are
design-locked** (`PER-1..12`, resolved 2026-06-27). On 2026-08-29 this register absorbed the genuinely
open cursor-traced-pathing question formerly numbered `[MRD-8]` and opened `PER-13..17` around the
shared visibility/path-execution boundary. `PER-4` remains an inert dependency until the forecast-driven
valuation AI exists (`[CVR-4]`/`[RCT-1]`). Nothing in `PER-13..17` is built or owner-ratified yet.

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

---

## 2026-08-29 comparative research: hidden information and committed routes

This pass combines the masking work with the last open Map Readability question: a player may need to
route around a *suspected* ambush or trap even when the destination is unchanged. The useful comparison
is therefore not fog alone. It is the contract between **what the player knows**, **the route previewed**,
and **what happens when movement discovers that the route is invalid or dangerous**.

### Case 1 — *Fire Emblem* (The Blazing Blade, GBA) — unit-centred fog and route preview

Nintendo's European manual documents movement by selecting a unit and cursor destination and lists
Torch/Torch Staff tools for dark maps. In play, allied vision reveals nearby tiles while unseen enemies
remain absent; encountering an unseen enemy ends movement at the discovery point. The movement arrow is
cursor-authored before confirmation, but uncertainty can invalidate its continuation.

**Lesson for Prometheus:** preserve the player's traced route as intent, but make discovery a first-class
interrupt rather than silently substituting a different shortest path. A visible route is a promise about
attempted traversal, not a promise that hidden information cannot stop it.

Source: [Nintendo UK — Game Boy Advance manuals (Fire Emblem)](https://www.nintendo.com/en-gb/Support/Legacy-system/Game-Boy-Advance-games-manuals-928652.html).

### Case 2 — *Fire Emblem: The Sacred Stones* — temporary vision as a tactical resource

The second GBA Fire Emblem retains unit-centred fog, thieves with better sight, and Torch/Torch Staff
effects that temporarily expand what the army can see. A unit that finds an unseen enemy while moving
stops rather than completing an impossible route through the occupied tile.

**Lesson for Prometheus:** route choice and information-gathering compose. A longer traced route can be a
deliberate scouting action, while authored vision modifiers change the risk without requiring a separate
pathfinding system. The UI must distinguish currently visible danger from merely unexplored travel.

Source: [Nintendo UK — Game Boy Advance manuals (The Sacred Stones)](https://www.nintendo.com/en-gb/Support/Legacy-system/Game-Boy-Advance-games-manuals-928652.html).

### Case 3 — *Advance Wars 2: Black Hole Rising* — explicit ambush interruption

Fog limits every unit to its own vision range; infantry and mechs gain extra sight from mountains, while
concealing terrain can require adjacency to reveal its occupant. Movement follows the displayed arrow.
If that route meets an unseen unit, the mover is ambushed, stops immediately, and loses its remaining
orders for the turn.

**Lesson for Prometheus:** this is the clearest precedent for joining `PER-8` occupancy with manual
pathing. Detection must run per traversed tile, and the interrupt result must be deterministic and visible.
Prometheus should not copy the forced loss of all remaining actions unless an author chooses that penalty.

Source: [Nintendo — Advance Wars 2 manual](https://www.nintendo.com/eu/media/downloads/games_8/emanuals/game_boy_advance_8/Manual_GameBoyAdvance_AdvanceWars2BlackHoleRising_EN_DE_FR_ES_IT.pdf).

### Case 4 — *XCOM 2* — route-level detection disclosure

Squads can begin concealed. Attacking or entering an enemy's field of vision breaks concealment; the
planning surface exposes detection risk before commitment when the relevant enemy is known. Individual
Rangers may retain concealment after the rest of the squad is revealed.

**Lesson for Prometheus:** known perception consequences belong on the path preview, not only on the
destination. Unknown enemies must remain unknown, but every traversed tile whose reveal/detection outcome
is already derivable should be marked. Per-unit masking can diverge without changing the route contract.

Source: [2K Support — XCOM 2 concealment FAQ](https://support.2k.com/hc/en-us/articles/216650707-XCOM-2-FAQ).

### Case 5 — *Invisible, Inc.* — information gathering before commitment

The system makes facing, blind spots, overwatch danger, hiding tiles, peeking, and observed guard paths
part of turn planning. Opening a door and peeking can reveal information without cancelling melee
overwatch, and the UI marks tiles that hide agents from overwatching guards. A limited rewind option is a
separate difficulty affordance rather than hidden path correction.

**Lesson for Prometheus:** expose all *known* consequences and provide explicit scouting actions; do not
let auto-pathfinding use information denied to the player. Undo/rewind policy is independent of whether a
route may be traced and should remain a campaign/difficulty decision.

Source: [Klei patch notes — Invisible, Inc. Archive Ghosts](https://store.steampowered.com/news/posts/?appids=243970&enddate=1418154489).

### Convergent findings

1. Visibility is evaluated from the acting side's knowledge, never from an omniscient route preview.
2. A displayed path is player intent; silently replacing it after confirmation breaks that contract.
3. Known detection/reveal consequences should be previewed per tile; unknown occupants stay unknown.
4. Discovery during traversal needs a deterministic interrupt point and an explicit post-interrupt state.
5. Vision tools, scouts, terrain, and masks should modify one visibility query rather than fork pathfinding.
6. Rewind/undo and the penalty after discovery are difficulty/content policy, not path algorithm details.

---

## Combined open questions (`PER-13..17`)

### PER-13 — What route does confirmation commit? `[OPEN; formerly MRD-8]`

- **A — Destination only:** recompute the cheapest route at execution time.
- **B — Exact traced route:** commit the cursor history after loop removal and movement-cost validation.
- **C — Traced preference:** commit the traced route, but permit deterministic repair only when a
  *newly discovered* fact invalidates the next step.
- **Recommendation: B.** A removes the requested tactical control. C sounds forgiving but makes the
  engine decide which deviations still express the player's intent. B is legible: follow the arrow until
  completion or a defined interrupt. A player can cancel and choose again after an interrupt.

### PER-14 — What does the preview reveal along the route? `[OPEN]`

- **A — Destination warnings only.**
- **B — Per-step warnings derived from the acting faction's current knowledge.**
- **C — Omniscient warnings, including currently hidden threats.**
- **Recommendation: B.** Mark known detection, trap, terrain, reaction, and movement-cost consequences on
  the arrow segment where they occur. C leaks the hidden state; A withholds information the engine and
  player already possess.

### PER-15 — What happens when traversal discovers a hidden occupant or hazard? `[OPEN]`

- **A — Stop before entering the triggering tile.**
- **B — Enter the tile, reveal, then resolve `PER-8`'s authored `on_cross`/`on_stop` outcome.**
- **C — Automatically detour around it if another route reaches the destination.**
- **Recommendation: B, with the outcome defaulting to reveal + fail/revert.** This reuses the already
  resolved occupancy contract and the shipped per-step crossing resolver. C spends hidden information on
  the player's behalf; A cannot express pass-through traps or authored collision outcomes.

### PER-16 — May the player revise movement after a perception interrupt? `[OPEN]`

- **A — Never; the move and action are consumed.**
- **B — Always; return to the pre-move state with the newly learned information.**
- **C — Campaign rule: `commit` or `revise`, with the chosen rule communicated before play.**
- **Recommendation: C.** Classic Fire Emblem/Advance Wars severity and accessibility-friendly revision are
  both legitimate campaign shapes. The information discovery remains latched either way, preventing
  repeated blind probing from resetting knowledge.

### PER-17 — What is saved and replayed? `[OPEN]`

- **A — Destination only.**
- **B — Normalized traced tile sequence plus the knowledge revision used to validate it.**
- **C — Input events/cursor motion.**
- **Recommendation: B.** Save/replay needs the semantic command, not device-specific input noise. Validate
  each step against the acting faction's knowledge snapshot, then apply deterministic reveal interrupts.
  This keeps replays stable across mouse, keyboard, controller, and touch.

## Proposed acceptance boundary (not ratified)

- Cursor history normalizes immediate backtracking/loops and never exceeds movement cost.
- Confirmation records an exact tile sequence; execution never substitutes an omniscient shortest path.
- The preview annotates every consequence knowable to the acting faction and leaks no hidden occupant.
- Visibility and `PER-8` occupancy are checked after every traversed tile through shared services.
- A reveal interrupt records the triggering tile, newly revealed entities, applied outcome, and remaining
  route; save/replay reproduces the same result.
- Mouse, keyboard, controller, and touch author the same semantic route command.
