---
Role: dated
---

# Pillar 1 — Code review architecture checkpoint (2026-08-09)

Status: **Superseded** by `code_review_2026-08-09.md`; retained as the durable
Session 3 scope boundary.

Audited snapshot: `agent/integration` at
`41c0e5fc1116a9a01aed3afc48dbc92f021d018d`

Procedure: `AGENT/Review Procedures/01_Code_Pillar.md`

Prior report: `AGENT/Code Reviews/code_review_2026-07-15.md`

## Bounded scope completed

This session covered the architecture/high-risk half assigned by the standing audit
handoff. It enumerated every non-test GDScript at the pinned snapshot, then traced the
following runtime boundaries in detail:

- content replacement and one-active-pack isolation: `scripts/autoloads/DataManager.gd`,
  `scripts/resources/CampaignTier2RuntimeAdapter.gd`,
  `scripts/resources/ContentSession.gd`, `scripts/resources/CampaignPackRegistry.gd`,
  `scripts/resources/CampaignPackInstaller.gd`, and
  `scripts/resources/CampaignArchivePreflight.gd`;
- author-extensible registries and their runtime consumers:
  `scripts/autoloads/RegistryManager.gd`, `scripts/registries/**`,
  `scripts/actions/**`, `scripts/autoloads/ActionEffectRunner.gd`, and the objective
  integration in `scripts/core/TurnManager.gd`;
- campaign progression, battle launch and objective/result flow:
  `scripts/autoloads/CampaignManager.gd`, `scripts/core/GameMap.gd`, and the objective,
  reward and phase boundaries in `scripts/core/TurnManager.gd`;
- save/load, rewind and mutable campaign state: `scripts/autoloads/SaveManager.gd`,
  the persistence sections of `scripts/autoloads/GameState.gd`, and `scripts/save/**`;
- combat determinism and returned-playtest correctness seams:
  `scripts/core/CombatResolver.gd`, `scripts/autoloads/RngService.gd`, and the
  EXP-faction, magical-damage, event-commit and death-application paths.

The spot checks searched all in-scope non-test scripts for raw RNG calls, setters,
autoload cross-references, state enums/closed dispatch, signal connections,
per-frame callbacks, assertions, and error/TODO markers. Falsifiable lifecycle traces
confirmed that package activation commits a complete `ContentSession`, objective
conditions route through the open registry, combat commits its RNG event once before
level-up draws, and the July archive-size/export-replacement findings are fixed.

## Provisional finding

### High — Campaign resume still changes active content before all rejection points

**File and line:** `scripts/autoloads/GameState.gd:1048-1082`,
`scripts/autoloads/DataManager.gd:138-163`,
`scripts/autoloads/CampaignManager.gd:767-847`.

**Problem:** `configure_campaign_resume()` says every rejecting check occurs before
live state is written, but it calls `_activate_saved_campaign_source()` at line 1057.
Successful activation replaces every live content catalogue and the registry candidate.
Only afterward does resume check for `CampaignManager`, resolve convoy entries,
validate mutable/override dictionaries, and validate the campaign envelope. Any of
those later failures returns `false` without restoring the previously active content.

The July finding is therefore only partially fixed. `SaveData` now validates malformed
mutable-state internals and the current regression protects campaign fields for that
specific same-source failure, but there is still no staged package/campaign transaction
and no regression proving that a late failure in a package-backed save preserves the
prior package identity and catalogues.

**Root cause:** reference validation requires the saved catalogue to be active, while
content selection and campaign-state restoration have separate commit boundaries.
The validation path in `SaveManager._validate_for_saved_content()` temporarily swaps
and restores catalogues, but `GameState.configure_campaign_resume()` does not use an
equivalent rollback or a non-mutating candidate.

**Why it matters:** a failed Load/Continue can report failure while silently switching
the game's classes, items, maps, terrain and authored registries. Subsequent menu or
save actions then operate on mixed old runtime state and newly selected content.

**Recommended fix:** build a non-mutating content/registry candidate and validate the
campaign envelope, roster, convoy and mutable state against it before one final commit.
If that boundary is too large for the first fix, capture the complete prior content and
registry session and restore it on every post-activation rejection. Add a package-backed
regression whose campaign envelope fails after activation and assert package identity,
catalogue lookups, registry ids and campaign position are unchanged.

**Classification:** recurring from the 2026-07-15 High finding; not yet reconciled
against the frozen v0.7.1 candidate. Session 4 must perform that comparison and link an
existing tracker row if one owns the remaining transaction work.

## Positive architecture observations

- One campaign pack replaces rather than merges content. `_commit_session()` assigns
  a complete catalogue and identity, so duplicate ids in different installed packs do
  not collide.
- Objective conditions and item effects now have registered validation/display/runtime
  handlers. This fixes the July closed-vocabulary finding without turning content ids
  into another engine enum.
- Archive inspection now rejects an oversized outer artifact before buffering it, and
  campaign/status/save exports use staged promotion with rollback. These close two July
  resilience findings at the reviewed snapshot.
- Combat reads `WeaponData.uses_mag`, gates earned EXP through
  `CampaignRules.exp_gaining_factions`, and routes gameplay randomness through the RNG
  service/formula boundary. No raw gameplay RNG regression was found.
- `CampaignManager.restore_campaign_state()` validates campaign, node, cleared-node,
  flag and variable identities before writing its own fields. The remaining transaction
  defect is the coordination boundary before that method, not its internal commit.

## Exact unchecked Pillar 1 scope

Session 4 must finish the code pillar without redoing the architecture traces above:

1. Review the complete remaining runtime groups line by line: `scripts/ui/**`,
   `scripts/ui/text_entry/**`, `scripts/ui/prep/**`, `scripts/units/**`,
   `scripts/items/**`, `scripts/skills/**`, `scripts/shared/**`, and `scripts/assets/**`.
2. Finish detailed correctness/style/performance review of the non-architecture portions
   of `MapCursor.gd`, `MapCursorInput.gd`, `MapCursorSelection.gd`,
   `MapCursorTargeting.gd`, `EnemyAI.gd`, `GridManager.gd`, `CameraController.gd`,
   `FogRuntime.gd`, `FogService.gd`, `TerrainRegistry.gd`,
   `TerrainTileSetBuilder.gd`, `ThreatPerimeterOverlay.gd`, and
   `UnitSpriteFramesResolver.gd`.
3. Cover the remaining smaller autoload/service/resource runtime files not traced in
   depth above, including controller/input, settings/responsive/text-entry, pair-up,
   crossing, occupancy, projection, death and resource-ledger owners.
4. Reconcile this provisional finding and all July findings against current tracker
   rows, the v0.7.0 root-cause review, and frozen candidate
   `0db30fd17adb83fb7e912c57b7630933c31588d6`.
5. Write the authoritative `code_review_2026-08-09.md` with an anchored score, top
   findings, full delta, v0.7.1 applicability and procedure friction. Clearly
   supersede this checkpoint so only the final report is authoritative.

## Procedure friction

- The procedure requests the Godot analyzer autoload tool, but that tool is not exposed
  in this environment. The pinned `project.godot` wiring was already covered by Pillar
  4; filesystem inspection and the supplied green headless baseline were sufficient for
  this checkpoint.
- The code procedure describes a single exhaustive pass, while the approved handoff
  deliberately splits it across two sessions. This checkpoint supplies the missing
  durable reviewed/unchecked boundary so Session 4 can satisfy the full procedure.
