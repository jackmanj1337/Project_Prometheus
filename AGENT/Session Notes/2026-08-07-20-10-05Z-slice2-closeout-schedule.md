# Session Note - 2026-08-07-slice2-closeout-schedule

## Branch context

- Branch: `agent/integration` (docs line — planning session, no code changed)
- Base branch: `agent/integration`
- Base SHA: `14c2a3ce`
- Coordination Work ID: `PACK-SKILLS-INERT-2026-08-07` (and five sibling rows registered
  this session)

## What was done

A planning session, following the "carried forward" finding at the end of the V070-11
handoff: schedule the skills family and the rest of zero-content Slice 2 before the next
bundle is exported. Owner scope call taken at the top of the session: the skills family
**plus** the M9 movement hooks, and **all** of Slice 2, not a subset.

**The grounding was measured on this line at `14c2a3ce`, not read from earlier plans**,
because the earlier plan was wrong about this exact thing — the zero-content
implementation plan (`:486`) lists skills as absent but says the ids "answer against the
engine's own set", and they do not.

Established, and it changed the shape of the schedule:

- `skill`, `pair_up` and the registry documents have no Tier-2 kind
  (`CampaignTier2Validators.gd:8-19` registers ten kinds). `campaign` and `map_registry`
  are validated only by legacy shape checks (`:394`, `:408`).
- **The behaviour mostly exists already.** `SkillHandler._dispatch` (`:26-85`) has 18
  real implementations and ~30 ids mapped to `_apply_unimplemented`; `data/skills/` holds
  55 authored `.tres`. So registering the family is **not** gated on M9 — the 18 fire the
  moment `_skills` is non-empty under a pack. That is what makes the schedule a family
  job with a bounded M9 addendum rather than a band.
- The three M9 movement hooks have exactly three call sites, all in `GridManager`
  (`:167-172`, and `is_passable` twice at `:206-213` and `:216-225`), and
  `SkillHandler._skills_for` (`:436`) is already the query-shaped accessor they need.

Three findings that the M9 half has to deal with, none of them in any existing plan:

1. `phasing.tres`, `dash.tres` and `swiftfoot.tres` are all `trigger = "on_combat_start"`
   — an event trigger, while the hooks are query-time predicates called during
   pathfinding. Nothing would ever ask them. `"passive"` is already in the declared
   trigger vocabulary (`SkillData.gd:6`), so the seam exists and the **data** is what is
   mis-shaped.
2. **There is no `pass.tres`.** `GridManager.gd:216` names "Pass skill (Trickster)" and
   the skill was never authored, so `can_pass_through_enemies` has no content to read.
3. All three are `release_available = false`; flipping that is the go-live switch and
   should be a deliberate line, not a side effect.

**A pre-existing row was adopted rather than duplicated.** `PACK-SKILLS-INERT-2026-08-07`
already existed from the V070-11 session with better research than this session had
produced — it measured 14 referenced skill ids against zero skill documents in the pack,
established that the pack's 24 classes unlock 0 skills (so there is no level-up path to
reacquire one), and found a second gap in the same place: `select_tier2_campaign_source`
never runs `collect_validation_errors` at all, so class `skill_unlocks` are cross-checked
by nothing. Registering a skill schema without adding that pass would give the family
shape validation and no cross-reference validation. It became stage S3.

## Owner rulings taken later in the session

**The export gate is sequenced after Slice 2**, and its `IMPL-PACK-SAVE-EXPORTS`
dependency is dropped. Two things were established rather than assumed before making the
edit:

- That dependency was pointed at the **wrong slice** anyway. `IMPL-PACK-SAVE-EXPORTS` is
  portable-save/clean-pack/backup *surfaces*, while the row's own trigger asks for
  "pack-aware loads" — that would be `IMPL-PACK-SAVE-LOAD-MIGRATION`.
- The save coupling that would have justified either **does not exist**.
  `GameState.active_roster_source` is compared against the literal
  `"res://data/roster/default/"` (`GameState.gd:536`), but it is a runtime variable that
  `SaveCodec` does not persist (zero hits), so no shipped save names `res://data` and
  deleting the source cannot orphan one.

**But the blast radius is ten runtime sites, not the one fallback**, and this is the
substantive reason the row belongs after Slice 2: four of those ten are
`ObjectiveConditionRegistry.gd:13`, `ItemEffectRegistry.gd:13` and
`PairUpBonusResolver.gd:15` — the registry documents and pair-up table that stages S4 and
S5 are registering as pack families. S4/S5 build the pack-side path; this row removes the
engine-side one. Sequencing it earlier would delete a source with no replacement.

**Next session is the combat feedback research trio**, opened by
`AGENT/Docs/plans/combat_feedback_research_session_handoff_2026-08-07.md`. The finding that
shaped that handoff: every mechanical register feeding those three rows is already RESOLVED
(`SKL`, `LDC`, `DIF`, `DTH`, `STY`, `DSP`, `BAT`, `AGT`, `SMV`, `RDR`, `CVR`, `RCT`, `VAL`),
so the open work is only the presentation layer — and all three converge on one shared
feedback vocabulary, which `DISCUSS-COMBAT-ACTIONS-UX`'s own trigger already notes. Writing
them as three independent docs would produce three competing vocabularies for one thing,
which is the anti-pattern that cost this codebase terrain's six tables and the two range
authorities.

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`.

Two commits on this line: the schedule document plus its Project Control Plane entry (the
control plane is where check 30 resolves active-plan ownership, so the two cannot be
split), and this note. The tracker changes are on the container repo's
`agent/staging-area`, not here.

## Gates

- `python3 AGENT/Docs/check_docs.py` — PASS, all 43 checks green.
- `python3 coordination/check_tasks.py` (container) — `OK: 356 tasks valid, no conflicts`.
- `python3 AGENT/Docs/gen_docs_index.py` re-run and committed in the same change, per the
  documentation DoD.
- No code changed, so no suite run is claimed for this session.

## Next

S1, `SKILL-EFFECT-REGISTRY-2026-08-07`: lift `SkillHandler._dispatch` into an open
`scripts/registries/SkillEffectRegistry.gd`, with a regression pin over the exact
effect-id set and its implemented/inert split — the terrain precedent, consolidate the
vocabulary before putting a schema over it. All three of its files are unclaimed.

Cut a fresh branch from `agent/integration`. Do **not** continue on
`agent/from-integration/terrain-variants-pack-terrain`, which the claim audit measured as
0 commits ahead.

**Two things need an owner answer before they are silently assumed:**

1. `IMPL-ZERO-CONTENT-EXPORT-GATE` is the only correct fix for two v0.7.0 reports ("no
   pack installed still plays the preinstalled proving grounds"; "switching packs
   restores the baseline"), and closing Slice 2 does **not** make it reachable — it also
   depends on `IMPL-PACK-SAVE-EXPORTS`, which is planned and untouched. Is that
   dependency real? Deleting the `res://data` fallback (`NewGameScreen.gd:346-352`) and
   building portable-save surfaces look separable. The question is recorded on the row.
2. The chosen scope is seven stages before the bundle, on top of the V070 fixes still
   outstanding. The next bundle will not be exported soon. That is the consequence of the
   scope, not an argument against it, but it should be a decision made with the number
   visible.
