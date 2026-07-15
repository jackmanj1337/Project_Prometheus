> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# Campaign Rules Firming Notes — 2026-05-25

Purpose: keep a short list of design constraints visible while the Phase 3
campaign loop is still being specified.

## Decision locked today

- `pair_up`, `support`, and `rescue` should be treated as **campaign rules**.
- They should not be implemented as ad-hoc map flags unless a future campaign
  mode explicitly overrides the default ruleset.

## Why this matters

- These rules affect the save schema, because they change long-term unit state
  and what data must persist between maps.
- They affect prep/deployment UX, because the player needs one clear place to
  understand and manage the current campaign rules.
- They affect roster/content authoring, because map balance, skill value, and
  unit identity shift a lot depending on whether these systems are enabled.

## Related design areas that should be firmed up together

- Campaign structure:
  chapter progression, map unlock flow, branching, and what "Continue" loads.
- Save/load ownership:
  which state belongs to the campaign save, which belongs only to a mid-battle
  suspend save, and which values are derived from static content.
- Prep/deployment flow:
  deployment limits, benching, convoy access, inventory management, and whether
  support/pair-up/rescue setup can be changed before battle.
- Progression rules:
  skill cap enforcement, inventory cap enforcement, promotion/reclass
  persistence, forge persistence, and any support-rank or rescue-related state.
- UI surfaces:
  where the player can read the active campaign rules and how rule-dependent
  actions are explained when unavailable.

## Questions to answer before the full campaign loop is built

1. Are these campaign rules chosen only on `New Game`, or can they change later?
2. If they can change later, is that a per-save permanent toggle, a difficulty
   preset, or a chapter-by-chapter override?
3. What state must persist for each rule?
   Pair Up: existing pairings only, or also support progression / affinity data?
   Support: rank, affinity, unlocked conversations, passive bonuses?
   Rescue: carried unit state, canto interactions, move penalties, drop rules?
4. How do Pair Up and Rescue coexist?
   Mutual exclusion is the safest default unless a later ruleset explicitly says
   otherwise.
5. Does the prep screen allow rule-dependent setup?
   Examples: form Pair Ups pre-map, break Pair Ups, review support bonuses,
   assign convoy inventory with rescue-ready weight/CON considerations.
6. How does save migration behave when a later version adds or reshapes any of
   these systems?

## Recommended defaults

- Campaign rules are selected on `New Game` and stored in the campaign save.
- They remain stable for the life of that save unless there is a deliberate
  ruleset-migration feature.
- Campaign saves store rule flags explicitly, not inferred from content.
- Pair Up and Rescue should be designed as mutually exclusive until a concrete
  combined ruleset is specified and tested.
- Support data should be versioned separately from map runtime state so future
  save migrations stay manageable.

## Follow-up

- When the between-map save/load design starts, use this note as a checklist.
- When the prep/deployment screen is specced, fold the settled answers back into
  the relevant GDD files and remove any resolved questions from this note.

---

## Milestone review locks — 2026-05-25 (afternoon pass)

A focused review of the open questions called out under §"Next-Session Review
List" in `AGENT/Session Notes/2026-05-25.md` was completed the same day. Each
question was discussed with options + pros/cons + recommendation; the user
selected one per question. The resulting decisions are now reflected in the
canonical docs:

- `GDD_10_Roadmap.md` — added a *Locked design decisions — 2026-05-25 review*
  block to milestones **M8**, **M9**, **M15 Part A**, and **M16** (Maps 002–005
  followup).
- `GDD_10a_Overview.md` — Bucket C rows for C4 / C5 / C10 now name the locks,
  and the Phase 3 Maps row for Maps 002–005 names the authoring rules.
- `GDD_02_Core_Mechanics.md` — *Status Conditions* table and schema updated for
  the Poison floor, Berserk targeting, Silence scope, and minimal record shape.
- `GDD_05_Skills.md` — *Full Skill Reference* preamble carries the four M9
  rules (M9a/M9b split, trigger discipline, hybrid effect calc, Pair Up out).
- `GDD_06_Maps_Objectives.md` — `seize` and `escape` condition entries refer to
  the `can_seize` tag and the escape semantics; a new *Phase 3 Maps 002–005 —
  Authoring Rules* section captures the showcase plan and authored-defeat
  standard.
- `AGENT/Docs/hotseat_test_map_plan_2026-05-21.md` — new §8 captures the four
  M15 Part A decisions.

### M8 — Status Conditions

| # | Question | Decision |
|---|---|---|
| 1 | Can Poison reduce a unit to 0 HP? | **Configurable per source.** Default floors at 1 HP. Optional `can_be_lethal: bool` (default `false`) on the source data opts in to lethal damage. |
| 2 | Berserk targeting priority | **Highest projected damage** (hit/crit-weighted, post-mitigation) → nearest in tiles → lowest unit id. Reproducible under a fixed seed. |
| 3 | Silence scope | **Tomes and staves only** — a filter on the action's `weapon_type`. No per-skill `silenceable` flag for M8. |
| 4 | Condition schema discipline | **Minimal `{ type, turns_remaining }`.** Extra fields are added per-condition only when genuinely needed (e.g. Hex). |
| 5 | Tick timing (**amended 2026-06-20**) | **Per-faction-phase duration ticking + activation-time enforcement** (supersedes the 2026-05-25 activation-based framing in GDD_10 §M8). Poison damage + `turns_remaining` decrement at the **start of the holder's faction phase** (the existing `"turn"`-modifier + fort-heal tick point; round start in `ALTERNATING`); Sleep/Stun skip, Berserk, and Silence are enforced at the unit's **activation**. Rationale: counts "lasts N turns" once per round (no M10 extra-turn double-tick), reuses an existing tick point, and keeps Poison parallel to fort heal. Canonical text: GDD_02 §Status Conditions (tick timing). |

### M9 — Skill Content

| # | Question | Decision |
|---|---|---|
| 1 | Internal M9a/M9b split? | **Internal split, public roadmap unchanged.** M9a closes the engine (every `apply_trigger()` `match` arm + shared helpers) against a minimal test set; M9b authors the bulk of `.tres` content. |
| 2 | Trigger-type discipline | **Strict reuse, flags first.** No new `trigger` types unless an existing trigger + `context.flags.*` provably cannot express the skill. |
| 3 | Dynamic vs stored modifiers | **Hybrid.** Threshold/state-dependent effects (Resolve, Frenzy, Aegis halving) evaluate at query time; static passives (Zeal, Tough) remain stored modifiers. |
| 4 | Pair Up / Rescue scope | **Fully out of M9.** Campaign-rule features; handled in the campaign-rules milestone. |

### M15 Part A — Hotseat

| # | Question | Decision |
|---|---|---|
| 1 | Per-player keybindings? | **Skipped for Part A.** One shared `InputMap`; revisit with split-controller co-op. |
| 2 | Hotseat assignment surface | **Updated 2026-06-11:** per-map data; CLI/dev override deferred. No pre-battle lobby UI in Part A. |
| 3 | HUD controller label | **`Faction - Controller` text** (e.g. `Red - Player 2`, `Green - AI`). |
| 4 | `ALTERNATING` hotseat scope | **Fully out of Part A.** Revisit only after scheduler/extra-turn work settles. |

### Objective-Map followup (Maps 002–005)

| # | Question | Decision |
|---|---|---|
| 1 | Map showcase plan | **One map per primary objective type** — Seize / Defeat Boss / Escape / Survive-Defend. |
| 2 | Multiple primary objectives per map? | **No** — one primary per early map. Defeat conditions still vary. |
| 3 | Allowed-seizer policy | **Per-unit `can_seize` tag on `UnitData`** (not class-derived, not per-map allowlist). |
| 4 | Escape semantics | **Alive, removed from map, no further actions** this map. Classic FE Escape. |
| 5 | Authored defeat standard | **Updated 2026-06-11:** at least one authored defeat appropriate to the map; Rout is never implicit. |
