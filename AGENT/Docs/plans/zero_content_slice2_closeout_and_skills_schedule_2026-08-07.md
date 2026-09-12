---
Role: dated
---

# Zero-content Slice 2 closeout and skills schedule — 2026-08-07

Status: Active. The ordered schedule for the remaining zero-content content families —
skills (including the M9 movement hooks), pair-up, registry documents, then campaigns
and map registry — and the single pack re-extraction that carries them all.

Last verified: 2026-08-07

Tracker: `IMPL-ZERO-CONTENT-FAMILIES` (parent), with per-stage rows registered below.
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)

**Why this exists.** V070-11 quietened ~3,200 `ERROR:` lines from unresolved skill ids
and, in doing so, established that none of the eleven ids were typos: `select_tier2_campaign_source`
never sets `session.skills` because **the skills family is unregistered**, so under any
active campaign pack `_skills` is empty and every skill a pack's units reference is
inert. The units in the returned v0.7.0 playtest were fighting without their skills. The
error volume was the only signal, and it has now been turned down — so the gap needs a
schedule rather than another return to rediscover it.

Owner scope call, 2026-08-07: the skills family **plus** the M9 movement hooks, and
**all** of Slice 2 closed before the next bundle is exported.

---

## Established facts

Measured on `agent/integration` at `14c2a3ce`, not read from earlier plans.

| Fact | Evidence |
|---|---|
| `skill`, `pair_up` and the registry documents have no Tier-2 kind. | `CampaignTier2Validators.gd:8-19` registers ten kinds: class, advancement_edge, advancement_route, weapon, roster, asset_registry, item, map_data, terrain, terrain_variant. |
| `campaign` and `map_registry` are validated, but only by legacy shape checks. | `CampaignTier2Validators.registry()` maps both to `_validate_campaign` (`:394`) / `_validate_map_registry` (`:408`), not to `_validate_registered_entity`. |
| `ContentSession.skills` exists and nothing fills it. | `ContentSession.gd:9`; no assignment anywhere in `select_tier2_campaign_source`. |
| Skill *behaviour* mostly exists already. | `SkillHandler._dispatch` (`SkillHandler.gd:26-85`) has 18 real implementations; ~30 ids map to `_apply_unimplemented`. `data/skills/` holds 55 authored `.tres`. |
| Registering the family is therefore **not** gated on M9. | The 18 implemented effects fire the moment `_skills` is non-empty under a pack. |
| The three M9 movement hooks have exactly three call sites, all in one file. | `GridManager.get_move_cost` (`:167-172`); `GridManager.is_passable` twice (`:206-213` phasing, `:216-225` pass). |
| A query-shaped skill accessor already exists. | `SkillHandler._skills_for(unit)` (`:436`) — distinct from the event-shaped `apply_trigger` (`:150`). |
| Pair-up is one document. | `data/pair_up/pair_up_bonus_table.tres` → `PairUpBonusTable` (`scaling_divisor`, `scaling_stats`, `class_bonuses`). |
| Registry documents are 27 `RegistryEntry` resources in five families. | `data/registries/`: action_primitives 2, item_effects 6, objective_conditions 8, occupancy_policies 8, resource_types 3. Each carries `primitive_handler`. |
| `_validate_registry_document` is a bare type check today. | `CampaignTier2Validators.gd:531-537` — asserts the document is a Dictionary and nothing else. |
| Almost every file this schedule touches is unclaimed. | Free: `SkillHandler.gd`, `GridManager.gd`, `SkillData.gd`, `ContentSession.gd`, `CampaignTier2RuntimeAdapter.gd`, `Tier2Catalogue.gd`, `PairUpRegistry.gd`, `scripts/registries/`, `scripts/tools/extract_proving_grounds_pack.gd`. That is the payoff of the 2026-08-07 claim audit. |

### Three findings that change the M9 half

1. **The authored movement skills carry the wrong trigger shape.** `phasing.tres`,
   `dash.tres` and `swiftfoot.tres` are all `trigger = "on_combat_start"`. But the hooks
   are *query-time predicates* called during pathfinding, not combat events — nothing
   would ever ask them. `"passive"` is already in `SkillData`'s declared trigger
   vocabulary (`SkillData.gd:6`) and `_skills_for` is already the query-shaped
   accessor, so the seam exists; the data is what is mis-shaped.
2. **There is no `pass` skill.** `GridManager.gd:216` names "Pass skill (Trickster)"
   and `data/skills/` contains no `pass.tres`. `can_pass_through_enemies` has no content
   to read until one is authored.
3. **All three are `release_available = false`.** Flipping that is the go-live switch and
   should be a deliberate line in the change, not a side effect.

---

## The schedule

Seven stages. Stages 1–2 are engine-only; 3–6 add one content family each; 7 is the
single re-extraction that carries every one of them into both packs.

### S1 — Skill effect registry consolidation *(engine only)*

Lift `SkillHandler._dispatch` into `scripts/registries/SkillEffectRegistry.gd`, an open
registry beside `ItemEffectRegistry` and `ObjectiveConditionRegistry`.

This is the **terrain precedent**: consolidate the vocabulary first, put the schema over
it second. Registering a schema against a `match`-style table inside a handler would
create the competing authority the zero-content plan forbids.

- The registry distinguishes *unknown effect* from *known but not implemented*, so the
  S3 schema can reject the first and admit the second with a warning. Today
  `_execute_skill` (`:227-240`) can only `push_error` on an unknown `effect_id`.
- **Regression pin**, as `test_terrain_registry` did for the six terrain tables: assert
  the exact effect-id set and its implemented/inert split, so a consolidation that
  silently drops or promotes an effect fails a test rather than a playtest.
- Files: `scripts/skills/SkillHandler.gd`, new `scripts/registries/SkillEffectRegistry.gd`,
  new `scripts/tests/test_skill_effect_registry.gd`. All free.

**Exit:** every dispatch resolves through the registry; the pin is green; full suite green.

### S2 — M9 movement hooks *(engine + the three data files)*

Implement the three stubs against passive skills read through `_skills_for`.

- `get_move_cost_override`, `can_pass_through_enemies`, `can_phase_through`
  (`SkillHandler.gd:89-99`) stop returning `-1`/`false` unconditionally.
- Retrigger `phasing`, `dash`, `swiftfoot` to `"passive"` (finding 1 above).
- Author `pass.tres` (finding 2) or record explicitly that `can_pass_through_enemies`
  ships with no content behind it — do not leave the call site reading a skill that
  does not exist.
- Flip `release_available` deliberately (finding 3).
- **Check the interaction with `IMPL-CROSSING-RESOLVER-2026-08-01`** (in_review): that
  work puts resolution inside `Unit.move_along_path` while these hooks sit on
  GridManager's pathfinding queries. Confirm the resolver does not re-ask `is_passable`
  under different state, or a unit will path through a wall and then halt on it.

**Scope fence:** this is the three *movement* hooks only. The other ~30
`_apply_unimplemented` effects and the condition model stay in
`B5-SKILLS-CONDITIONS-2026-07-23`, which is still backlog and still wants an owner
go/no-go. Do not let S2 grow into it.

**Exit:** each hook is exercised by a test from both directions (skill present → override
applies; absent → engine default), proven by revert.

### S3 — Skills family schema and adapter *(+ the V070-02 validator half)*

Register `skill` as a version-1 engine-owned schema projecting `SkillData`'s surface.

- `effect_id` resolves through `SkillEffectRegistry` as an **open vocabulary** — the
  item family's `ItemEffectRegistry` precedent.
- `trigger` is a **closed engine vocabulary**. Its present source is a comment block
  (`SkillData.gd:6-11`); single-source it into `GameConstants` the way
  `VALID_ACTIVATION_MODES` was, so schema and runtime cannot drift.
- `activation_chance_stat` resolves through `StatRegistry`.
- Fill `ContentSession.skills`; `select_tier2_campaign_source` sets it; `_skills` is
  built from the committed session. **This is what makes V070-11's warnings go quiet for
  the right reason** rather than by suppression.
- Extractor emits `data/skills/` (55 documents).
- **Same session, same files: V070-02's validator half.** `EntitySchemaRegistry.gd:352`
  declares `uses_mag` but requires nothing of it, while it *does* cross-check
  `wexp_track` against `combat_family`. Make a magic family/track without
  `uses_mag: true` a document error, then emit the field from the extractor. Doing it
  here is what lets S7 be one re-extraction instead of two.

**Exit:** a pack's units resolve their skills; a pack referencing an unknown effect id is
refused with a document-qualified path; `content_status()["warnings"]` is empty for a
well-formed pack.

### S4 — Pair-up family

One document, small.

- Schema over `PairUpBonusTable`. `scaling_stats` and the inner keys of `class_bonuses`
  validate as `StatRegistry` stat ids using the **KEY vocabulary** form — the roster
  growth-map precedent, where an authored `strenght: 40` was admitted by a value-only
  check and then silently never applied.
- Outer `class_bonuses` keys cross-reference class ids.

**Exit** (plan's own wording): every table cell and referenced stat is bounded.

### S5 — Registry documents family

Replace the bare type check at `CampaignTier2Validators.gd:531`.

- `primitive_handler` resolves against the engine registry for the document's `family`.
- **A pack may not introduce a handler.** Same boundary as terrain: a pack retunes what
  the engine already provides and cannot introduce something the engine has no code
  for. An unresolvable handler is a document error, not a warning.

**Exit** (plan's own wording): handler ids exist in trusted primitive registries.

### S6 — Campaigns and map registry schemas

Last, per the plan, once every id they reference resolves — which is true only after
S3–S5.

- Register both kinds; retire `_validate_campaign` / `_validate_map_registry` as the
  authorities for shape, keeping any semantic checks where they are (the `map_data`
  precedent: **schema owns document shape, the existing validator owns semantics**).

**Exit:** `IMPL-ZERO-CONTENT-FAMILIES` closes.

### S7 — One re-extraction, both packs

Re-emit **once**, carrying skills, `uses_mag`, pair-up and registry documents together.

- Re-cut both Proving Grounds branches:
  `Project_Prometheus_Campaign_Pack_FE` `agent/from-main/proving-grounds-extraction`
  (tip `7fc7eb5`) and `Project_Prometheus_Campaign_Pack_0`
  `agent/from-main/proving-grounds-public-pack` (tip `80602fc`).
- Verify with `validate_pack.gd --require-playable`.
- **Do not re-emit at S3, S4 or S5 individually.** Each re-emission means re-cutting two
  branches in two repos; batching is the whole reason V070-02's validator half sits in
  S3 rather than in a row of its own.

**Exit:** both packs activate, 8/8 maps playable, no unarmed unit, and a unit with an
authored skill demonstrably fires it.

#### Added to S7 on 2026-08-16 — terrain variant content

`IMPL-TERRAIN-VARIANTS-AND-PACK-TERRAIN-2026-08-01` has been headless-green since
2026-08-01 and cannot be verified, because there is nothing authored to look at. Checked
on 2026-08-16: `git ls-tree -r` over **both** pack branches returns **zero files under
`assets/`**, and no terrain document carries a `variants` key. That is why the v0.7.0
tester's answer — *"the forests are dark green squares and the mountains are brown, there
is no variation noticed in either stat or visuals"* — was a correct observation of
untextured engine fallback rather than a defect report.

The row was therefore taken **off** the display-gated list: it is blocked on authoring,
not on a display, and queueing it again spends a scarce Windows slot to collect the same
non-answer. The authoring rides S7 for the same reason everything else does — one
emission, two branches, two repos.

**S7 must additionally emit:**

- at least one terrain with **two visually distinct variants**;
- at least one **pack-introduced terrain with its own tile source**.

> **This is the first asset content either pack will carry**, so the content-licensing
> rules bind here for the first time: `CSA-35` licensing and `CSA-6` `rights_status`
> validation apply to whatever art this introduces, and
> `LEG-ENGINE-ASSET-PROVENANCE-2026-07-26` — a dependency of `IMPL-ZERO-CONTENT-BASE-PACK`
> — is still open. **Do not emit art whose provenance is not recorded.** Emitting
> unprovenanced art into a public pack is harder to undo than delaying the terrain pass.

---

## S7 readiness — verified against `agent/integration` on 2026-08-16

The owner lifted the "do not execute extraction/re-cut yet" hold on
`IMPL-ZERO-CONTENT-BASE-PACK`. Everything below was checked in the tree, not inferred
from row status, and **S7 is the only remaining stage — all three blockers this document
recorded are discharged.** The blockers section that follows is kept as the record of what
they were; read it as history.

**S1–S6 are complete and their output is on `agent/integration`:**

| Precondition | Verified at |
|---|---|
| Skills family emitted | `extract_proving_grounds_pack.gd:84` `_emit_skills()` |
| Pair-up family emitted | `extract_proving_grounds_pack.gd:85` `_emit_pair_up_bonus_table()` |
| `uses_mag` emitted (V070-02, extractor half) | `extract_proving_grounds_pack.gd:360` |
| `uses_mag` enforced (V070-02, validator half) | `EntitySchemaRegistry.gd:1622-1629`, `magic_weapon_requires_uses_mag` |
| `--require-playable` exists | `validate_pack.gd:12,27-28,85` |
| Both re-cut targets still exist | `Campaign_Pack_0 agent/from-main/proving-grounds-public-pack`, `Campaign_Pack_FE agent/from-main/proving-grounds-extraction` |

**The `validate_pack.gd` claim collision is not a collision in practice.** Two reasons,
both checkable. S7 *runs* the tool, it does not edit it, and `--require-playable` is
already on `agent/integration` — so S7 does not need
`PACK-FEATURE-COVERAGE-WARNINGS-2026-08-07`'s branch to land. And that row's check only
fires for a pack that **declares itself complete**, while the extractor emits
`"authoring_status": "draft"` (`extract_proving_grounds_pack.gd:1085`) against the now-real
vocabulary `["draft", "complete"]` (`PackManifest.gd:6,31-36`). A draft pack cannot trigger
a completeness warning. The collision becomes live only if and when these packs are marked
`complete`, which is a separate decision — not part of S7.

> Note the vocabulary prerequisite that row identified — *"`authoring_status` IS AN
> UNENFORCED VOCABULARY: grep returns exactly ONE hit… no engine code reads it"* — has
> since been satisfied independently: `PackManifest` now validates it and rejects anything
> outside the two legal values.

**The other two blockers below are gone.** `V070-11-SKILL-ID-SPAM-2026-08-07` is completed,
so the `DataManager.gd` claim S3 needed is released. And the owner call on whether
`IMPL-ZERO-CONTENT-EXPORT-GATE`'s dependency on `IMPL-PACK-SAVE-EXPORTS` was real is moot —
the export gate is completed.

**So S7 is one session's work:** re-emit both packs once carrying skills, `uses_mag`,
pair-up and registry documents together; re-cut both pack branches; verify with
`validate_pack.gd --require-playable`. The exit is unchanged and the last clause is the one
to watch, because the v0.7.0 round met the first three on a build where every skill was
inert: **a unit with an authored skill must demonstrably fire it.** That clause cannot be
closed headlessly with confidence — it wants the next bundle.

---

## Blockers and open decisions

> **Historical as of 2026-08-16** — all three are discharged; see the readiness section
> above.

**Sequencing cost — stated plainly.** This is seven stages before the bundle, on top of
the V070 fixes still outstanding (`V070-RETURN-FIXES-2026-08-07` is in_review and needs
its tracker amendment before it can merge). The next bundle will not be exported soon.
That is the consequence of the chosen scope, not an argument against it — but it should
be a decision made with the number visible.

**The export gate is not reachable by closing Slice 2, and it is the fix for two
returned reports.** `IMPL-ZERO-CONTENT-EXPORT-GATE` deletes the `res://data` fallback
(`NewGameScreen.gd:346-352`) and is the only correct fix for *"with no pack installed the
game still has the preinstalled packless proving grounds"* and *"switching packs restores
the baseline — no change noticed."* Its dependencies are `IMPL-ZERO-CONTENT-BASE-PACK`
(exit met 2026-08-07) **and `IMPL-PACK-SAVE-EXPORTS`**, which is `planned` and untouched.

*Owner call needed:* is the `IMPL-PACK-SAVE-EXPORTS` dependency real? Deleting a data
fallback and building portable-save/backup surfaces look separable. **Recommendation:**
separate them, so the export gate can follow S7 and the two returned reports get their
actual fix in the same bundle as the skills. If the dependency is real, the reports carry
to the round after and should be marked as such rather than left implicitly queued.

**Claim to release.** `scripts/autoloads/DataManager.gd` is still claimed by
`V070-11-SKILL-ID-SPAM-2026-08-07`, which is `planned` in the tracker though its work is
Implemented and merged at `869d96db`. S3 needs that file. Release the claim and close the
row.

**One genuine claim collision.** `scripts/tools/validate_pack.gd` is held by
`PACK-FEATURE-COVERAGE-WARNINGS-2026-08-07` (in_progress) and S7 verifies through it.
Coordinate before S7, not during.

**Not in scope.** The ~30 unimplemented skill effects; the condition model; fog in
extracted maps (`map_data` admits no `fog_enabled` — belongs with `IMPL-FOG-RENDER`);
equip inventory slots; the `item_type` vocabulary; the class family's growth/cap KEY
vocabulary; the battle-map/encounter document split.
