---
Type: research findings
Status: Applied — research recommendations approved; ready for implementation planning
Last verified: 2026-07-28
Owner approval: 2026-07-23 — all ten recommendations approved
Research handoff: campaign_data_ownership_research_handoff_2026-07-23.md
Tracker rows: RESEARCH-ECONOMY-OWNERSHIP-2026-07-23, RESEARCH-PACK-SAVE-OWNERSHIP-2026-07-23,
  RESEARCH-ENGINE-ZERO-CONTENT-2026-07-23, RESEARCH-RULE-PROFILE-CONTRACT-2026-07-23
---

# Campaign Data Ownership — Research Findings (2026-07-23)

Work status and eventual delivery sequencing remain owned by the
[Project Control Plane](project_control_plane_2026-06-29.md). This document
records research evidence and recommendations only; it does not schedule work.

## Executive summary

The four threads point to one consistent ownership model:

1. A selected pack owns immutable campaign definitions and identifies the
   schema/version against which a run was created.
2. The save owns only run state, mutations, resolved campaign defaults, and the
   exact pack identity needed to interpret those values.
3. The engine owns validation, storage, migrations, deterministic simulation,
   and every executable behavior. Pack data may select and parameterize a
   registered engine primitive; it may not supply code or arbitrary expressions.
4. A campaign profile should be a pack-authored definition referenced by id at
   campaign creation, then resolved into the save's campaign-default snapshot.
   Updating a pack therefore changes future runs without silently changing the
   rules of an existing run.

This is a delta-save model, but not a minimal event log. The durable save remains
a self-contained snapshot of **mutable state**. It refers to immutable definitions
by durable ids rather than copying full class, item, map, and campaign documents.
A portable save can be one JSON file, but it cannot be playable without a
compatible pack unless it embeds a pack snapshot—which would turn it into a
different artifact and defeat the single-source-of-truth goal.

## R1 — Economy ownership

### Consumer audit

| Consumer | Present assumption | Required ownership seam |
|---|---|---|
| `GameState.gd` (`party_gold`, capture/resume, ledger entries) | One integer belongs to the player party; save path is `party.resources.party_gold`; each history entry stores `party.gold`. | Replace the scalar with a wallet table and serialize/restore the complete table in every checkpoint. Keep the legacy field only at the import boundary. |
| `ResourceLedger.gd::_resolve_wallet` | `resource_id + scope` selects one of two hardcoded handlers; party gold resolves to `GameState.party_gold`, unit gold to `UnitData.gold`. | Resolve a durable `owner_ref` to a wallet, then address `resource_id` within that wallet. Handler code remains engine-side. |
| `CostSpec.gd` | `scope` identifies an allowed subject category and `subject_binding` names a runtime context object. | Preserve both fields. The bound subject should resolve to an `owner_ref`; do not add faction-specific fields. |
| `TurnManager.gd` battle rewards | Rewards always credit `party_gold/party`, and results read `GameState.party_gold`. | Reward data/context must supply the receiving owner; results read the active controller/faction owner's wallet. |
| `MapMenu.gd` | HUD always displays the single party total. | Resolve the viewed/acting controller's configured wallet owner. Do not equate faction colour with ownership. |
| `ProjectionService.gd` | A simulation is pure if RNG and the one gold scalar are unchanged. | Snapshot/compare the full wallet table (or its stable digest). |
| `SaveData.gd` and `SaveIntegrity.gd` | Save schema and header derive one party-gold value; legacy loaders normalize old aliases into it. | Persist wallets canonically; derive a display total for the header; migrate old `party_gold` to the blue/player campaign wallet. |
| Tests and `SaveBudgetMeasurement.gd` | Fixtures encode the scalar path and one-wallet rollback. | Add multi-owner/multi-resource atomicity, migration, projection-purity, and save-budget fixtures. |

`CampaignManager.gd` does not directly mutate gold in the current branch; it
captures/restores the campaign envelope through `GameState`. Its relevant
assumption is therefore indirect rather than a separate gold store.

### Recommended wallet shape

Use a durable value object for ownership:

```json
{"kind": "faction", "id": "blue"}
```

Allowed first-slice kinds are the owner-approved `faction`, `shop`, `campaign`,
`unit`, and `arena`. Canonicalize the pair to a stable key such as
`faction:blue`, but serialize the structured form so validation does not depend
on parsing punctuation. Store balances as:

```json
{
  "wallets": {
    "faction:blue": {
      "owner_ref": {"kind": "faction", "id": "blue"},
      "balances": {"gold": 500, "bonus_exp": 20, "training_points": 3}
    }
  }
}
```

`CostSpec.scope` continues to say which owner kinds a resource accepts, and
`subject_binding` continues to select a value from transaction context. That
value resolves to an `owner_ref`. This reuses the current indirection and avoids
putting a literal faction or owner field into every cost. Direct authored grants
still need an engine-validated context binding; pack data must not name a live
object or filesystem path.

Wallet lifecycle follows owner lifecycle: campaign/faction wallets last for the
run; unit wallets follow durable unit ids; map shops and arenas require an
explicit persistence policy (`campaign`, `map`, or `transaction`) in their owner
definition. Unknown owners fail closed. All balances use signed transaction
deltas but may not finish below zero unless a future resource definition
explicitly permits debt.

### Rewind verdict

Do **not** put rewind charges in the ordinary rewindable wallet table.
`GameState.rewind_last_action` deliberately restores the target checkpoint and
then subtracts a charge from the restored value. If the cost lived inside the
restored wallet snapshot, a rewind could refund its own price. The current
separation is semantically correct.

Rewind charges may later share the resource-transaction API only if resource
definitions have an explicit checkpoint policy such as `rewindable` versus
`timeline_budget`. The latter must be captured in durable saves but remain
outside the state restored from a selected history entry. Adding that policy
solely to make rewind charges look like other currency is unnecessary for the
first multi-wallet slice.

Every ordinary wallet balance should be captured together in each map-ledger
entry. Restore must validate the complete wallet snapshot before applying any of
it, preserving the existing validate-before-commit behavior.

## R2 — Pack/save ownership

### Duplication map

Not every repeated value is harmful duplication. Header summaries and rewind
checkpoints are intentional derived/cache/history copies. The authoring problem
is copying immutable definitions into mutable saves or maintaining defaults in
multiple authoring locations.

| Fact | Locations today | Finding |
|---|---|---|
| Package/campaign/node identity | `SaveData.campaign`, derived `SaveData.header`, active `DataManager`/`CampaignManager` state | Keep campaign identity authoritative; header is a derived index/cache and must be regenerated, never edited. |
| Campaign rule defaults | `CampaignRules.gd` property defaults, `SaveData._default_campaign`, authored campaign overrides, and the live/resolved rule dictionaries in `GameState` | Real drift risk. One schema/default provider must normalize pack profiles and saves; `SaveData` should not hand-copy the field list/defaults. The save still needs a resolved snapshot for an existing run. |
| Party inventory | Live `GameState.party_items`, save `party.convoy.entries`, legacy `party.items`, roster unit inventories, and ledger `party.items` | `party.items` is compatibility-only and should remain read-only. Convoy and per-unit inventory are distinct owners; ledger copies are required history. Use one codec for all representations. |
| Gold/resources | Live `GameState.party_gold`, save `party.resources.party_gold`, derived header gold, ledger `party.gold` | Replace with one wallet codec. Header remains derived; ledger remains an intentional checkpoint. |
| Roster/unit data | Pack starting roster, live `UnitData`, save `roster.units`, and each ledger entry's roster snapshot | Correct delta boundary: pack owns starting definitions; save owns mutable unit state keyed by durable unit id. Ledger copies are required for Retry/Rewind. Avoid serializing unchanged class/item definitions into each unit. |
| Campaign graph/maps/classes/items/skills | Pack/project `data/`; runtime typed resources | These should never be copied into a normal save. Save references durable ids plus mutations only. |
| Package version | `manifest.json`, active package identity, save campaign identity | Manifest is authoritative for the installed pack; the save records the version it was created/resolved against. This is provenance, not competing authoring. |

### Delta versus self-contained recommendation

Use **definition references plus mutable snapshots/deltas**:

- The pack supplies immutable definitions and defaults.
- A new campaign resolves its selected definitions into initial state.
- The save stores current mutable state, mutation records needed by existing
  mechanics, resolved rule defaults, and durable content ids.
- A save never stores executable behavior or complete copies of pack documents.

This is simpler and safer than replaying a minimal mutation log at load. It also
keeps a save inspectable and bounds migration work. The cost is that loading
requires the named pack (or an explicitly compatible successor). If absent,
load must stop before changing runtime state and offer pack installation or
version selection.

### Version and migration contract

Each save needs four separate compatibility fields:

- `save_format_version`: engine-owned JSON/schema version (the existing
  `SaveData.FORMAT_VERSION` role);
- `package_id` and `package_version`: exact source identity already captured;
- `content_schema_version`: pack-document schema understood by the engine; and
- optionally `content_fingerprint`: a deterministic digest of the admitted
  catalogue/manifest set to detect a pack version whose bytes were replaced.

Migration order should be transactional:

1. Parse and migrate the engine save format.
2. Locate the exact pack or a newer same-id pack declaring compatibility with
   the saved version/version range.
3. Apply a deterministic chain of pack-declared migration **data** through
   engine-owned migration primitives.
4. Validate every resulting id/reference and the complete save.
5. Commit activation and runtime state only after all steps pass.

Migration declarations belong in the newer pack because it knows its new ids
and schema, but they may only select engine-registered operations such as rename
id, map enum/value, set default when absent, transform a numeric field using an
allow-listed operator, or reject. No pack script or arbitrary expression is
executed. If no complete migration chain matches, the save remains untouched and
the UI reports the required package id/version and missing migration edge.

### Export modes

| Operation | Includes | Excludes / behavior |
|---|---|---|
| Portable save | One validated save JSON, integrity stamp, exact package identity/version/fingerprint | No pack data. Import may store it, but play is disabled until a compatible pack is installed. The existing `SaveManager.export_slot` is already this surface. |
| Full pack backup | The deterministic clean pack ZIP plus a separate `user_state/` envelope containing selected saves/status records and its own manifest | Never treat the combined backup as an installable content pack. Restore splits and validates content and user state through their existing independent pipelines. |
| Clean pack export | Only manifest, indexed pack data, and approved media | No slots, suspend state, ledger, status records, settings, caches, or editor files. The existing `CampaignPackExporter` already implements this allow-listed direction. |

This resolves the phrase “pack owns the save” as **the pack identity owns the
save namespace and interpretation**, not “mutable saves are files inside an
installable pack.” Keeping user state out of installable ZIPs preserves the
existing package-security boundary.

## R3 — Zero-content engine and the data/script boundary

### Entity-document and provenance obligations

Each identity-bearing entity is authored as one document; generated schema,
reference, and contents files are projections from the engine schema registry and
package catalogue, not additional authoring sources. A package owns a reusable source
registry and every identity-bearing document carries nonempty resolving
`source_refs`. Direct transcription requires document coverage. Transformed,
disputed, conflicting, or ambiguous fields additionally name stable occurrence-audit
ids. Generated contents/reference views must be reproducible and validated against
the indexed documents and source registry.

Complete-pack validation and export fail on missing required provenance or any
dangling source/audit reference. Editor-only draft launch may waive missing
occurrence coverage, but must show persistent warnings and a prelaunch report and
must isolate resulting saves. It cannot waive structural, safety, dependency, or
dangling-reference errors. Private derivative fixtures and numeric evidence remain
in their private pack repositories; public engine fixtures stay generic.

### Baked-content inventory

The current `data/` tree contains 212 `.tres` and 17 `.json` files across these
families. The classification is architectural, not a claim that every family
already has a Tier-2 JSON validator.

| Family | Classification | Current blocker |
|---|---|---|
| Campaign graphs | Pack-movable now | Tier-2 validator/adapter exists. |
| Map registry, map grids/encounters, placements, objectives, rewards | Pack-movable in target; partial now | Tier-2 covers a minimal map shape, not the full split battle-map/encounter vocabulary and every objective/event field. |
| Starting rosters and authored units | Pack-movable now for minimal shape | Expand validation for full inventory, skills, progression, factions, and authored state. |
| Classes | Pack-movable now for minimal shape | Full class fields and cross-family references need Tier-2 coverage. |
| Weapons, items, skills, terrain | Pack-movable in target | No Tier-2 validators/runtime adapters yet for these families. |
| Pair-Up bonus tables | Pack-movable in target | Needs a catalogue family, stat-id validation, and adapter. |
| Registry entries (`resource_types`, objective conditions, item effects, action/occupancy primitives) | Pack-movable **selectors/configuration** | Required-family loading currently assumes `res://data/registries`; entries may name only engine-known primitive handlers. |
| Primitive handler implementations, parsers, codecs, validators, registries, RNG/combat/pathfinding/AI logic | Engine-must-keep | Executable trusted computing base. |
| UI scenes/themes, pack manager, settings/accessibility/input | Engine-must-keep | Needed to boot and select/install a pack with no gameplay content active. |
| Formula selectors and parameters | Pack-movable when schema-validated | Requires an engine registry for each formula family. |
| New algorithms or stateful behaviors | Engine-must-keep until implemented as a reviewed primitive | Cannot be safely represented as arbitrary pack code. |

### Explicit data/formula boundary

The safe pattern is **named engine behaviors selected and parameterized by
validated data**:

- Data may provide numbers, ids, ordered tables, curves/lookup tables, bounded
  arithmetic parameters, predicates composed from an allow-listed grammar, and
  a registered behavior id.
- The engine owns the implementation, validation, RNG draw count/order, mutation
  authority, error handling, and save semantics for every behavior id.
- Unknown ids and unsupported parameters fail pack validation before activation.
- A behavior whose RNG usage, target selection, loop bounds, side effects, or
  persistence cannot be statically validated remains engine code.

Existing examples support this direction: `CampaignRules.hit_formula` selects
engine predicates with fixed RNG counts; `WeaponData` accepts only integer or
`STAT/divisor` range forms; objective/item/action registries map authored ids to
engine callables; and `CostSpec.formula_term` is reserved but currently rejected.
The weapon range parser's closed stat switch is an example to replace with the
stat registry before broadening formula authoring, not a grammar to generalize.

Formula families should be separate registries (hit roll, damage, range, growth,
cost, requirement, AI scoring) because their allowed inputs and determinism
contracts differ. A universal expression language would become the sandboxed
scripting system this project explicitly does not want.

### Zero-content boot and packaging

`DataManager._ready` and `RegistryManager._ready` currently load
`res://data`, and `RegistryManager` requires five content families. A true
zero-content build therefore needs a boot state in which both managers have an
empty/inactive catalogue without reporting gameplay-content errors. Engine UI,
settings, installer, registry of trusted primitive handlers, and pack-selection
screens load first. Gameplay/New Game remains disabled until a selected pack
passes manifest, catalogue, family, and cross-reference validation.

The base game should be exported through the same pack pipeline as every other
campaign, not copied by a privileged `res://data` fallback. Each selected pack
should be self-contained for every family it uses. Explicit pack dependencies
could be designed later, but implicit inheritance from a hidden base pack would
reintroduce the ownership ambiguity and version coupling this work is removing.

This migration should share the physical content move with
`LEG-AUDIT-FE-NUMBERS`: move/re-author each value once into the appropriate pack,
attach provenance there, and leave only engine defaults required to validate a
schema—not a playable balance set.

## R4 — Rule-profile contract

### Recommendation

A profile is a pack-catalogued JSON document:

```json
{
  "id": "standard",
  "schema_version": 1,
  "rules": {
    "death_mode": "casual",
    "leveling_method": "growth_random",
    "hit_formula": "two_roll"
  }
}
```

The pack's campaign document references `profile_id`. At New Game the engine
validates the profile against the `CampaignRules` schema, overlays explicit
campaign defaults, then stores both the selected profile id and the fully
resolved defaults in the save. The reference preserves single-source authoring
for future campaigns; the snapshot preserves deterministic existing campaigns
and allows authors to fork/edit values after applying a profile.

Profiles live in packs (including separately distributed template packs or
editor-created packs), not in engine code. Documentation and the editor may
offer copy/import operations, but copied profiles become ordinary pack-owned
documents with new/local ids. The first slice must use only existing
`CampaignRules` fields. Mandates and node/mid-map overrides remain separate;
profile resolution feeds only the campaign-default layer and never bypasses the
existing precedence order.

## Owner-approved decisions

On **2026-07-23**, the owner approved all ten research recommendations:

1. Saves remain engine-written user state, namespaced and interpreted by pack
   identity; they never become writable files inside an installable pack.
2. A portable save does not embed pack definitions. It may be imported while its
   pack is missing, but play remains disabled until a compatible pack is installed.
3. Existing runs retain their resolved rule/default snapshot unless an explicit
   migration changes it.
4. Pack migrations use declarative, engine-registered transforms. Unsupported
   migrations are rejected; pack scripts are not allowed.
5. Saves record a deterministic content fingerprint in addition to package id
   and version so changed bytes under the same version are detected.
6. A full backup contains a clean pack plus separately stored user state;
   installable pack ZIPs remain clean.
7. Shop and arena wallets explicitly declare `campaign`, `map`, or `transaction`
   lifetime. There is no implicit lifetime.
8. Rewind charges remain a dedicated, non-rewindable timeline budget for v1. A
   shared resource API is reconsidered only after checkpoint policy exists.
9. Every playable v1 pack is self-contained for all referenced content families,
   with no pack dependencies or hidden base inheritance.
10. Formulas use separate allow-listed registries rather than one general
    expression language, initially covering only existing selectors and limited
    grammars.

These approvals clear the research decision gate. Implementation plans may now
be written, while remaining faithful to decisions 1–6 for save/package work,
7–8 for economy work, and 9–10 for the zero-content boundary.

## Expected player and author experience

| Planned change | What a player will see | What an author will see |
|---|---|---|
| Multi-owner, multi-resource economy | Gold, bonus EXP, and training points belong to the correct player/faction or service. Hotseat factions and future AI can maintain and spend separate balances. Retry/Rewind restores ordinary balances together, while spending a rewind charge still has a real cost. | Wallet owners use stable `owner_ref` values (`faction`, `shop`, `campaign`, `unit`, or `arena`) and an explicit lifetime. Rewards and costs bind to an owner instead of assuming one global player purse. |
| Pack-associated saves and migrations | Saves remain portable files. A missing or incompatible pack produces a clear install/compatibility requirement instead of broken state. Existing campaigns do not silently change when pack defaults change. Clean packs and full backups are distinct exports. | Immutable definitions stay in one pack location; saves store mutable run state and durable ids. Authors publish versions, fingerprints, and declarative migrations without writing scripts or duplicating definitions in saves. |
| Zero-content engine and self-contained packs | With no active content, the game opens campaign-pack selection. Each installed pack is a complete playable experience, and invalid packs fail before starting a run. | The base game uses the same pack format as third-party campaigns. Classes, items, maps, balance numbers, and supported formula selections live in packs; executable algorithms remain reviewed engine primitives. |
| Allow-listed formula registries | Packs can produce different combat, range, cost, growth, or AI behavior while preserving deterministic saves and predictable errors. | Authors select documented formula ids and parameters for each formula family. Supported variation needs no code, while unknown combinations fail validation. |
| Pack-authored rule profiles | New Campaign can offer coherent presets such as Standard or Ironman. Once a run starts, its resolved rules remain stable unless explicitly migrated. | A profile is reusable pack JSON using existing `CampaignRules` fields. Campaigns reference it by id; authors may import/copy it and refine campaign defaults without changing mandate or per-map override precedence. |

## References inspected

Research performed and verified on **2026-07-23** against branch
`agent/from-integration/campaign-data-research`.

- Owner goals: `AGENT/Campaign data questions.md`
- Research scope: `AGENT/Docs/plans/campaign_data_ownership_research_handoff_2026-07-23.md`
- Existing boundary decision: `AGENT/Docs/plans/campaign_pack_engine_boundary_plan_2026-07-15.md`
- Economy: `scripts/autoloads/ResourceLedger.gd`,
  `scripts/resources/CostSpec.gd`, `data/registries/resource_types/*.tres`,
  `scripts/core/TurnManager.gd`, `scripts/ui/MapMenu.gd`,
  `scripts/autoloads/ProjectionService.gd`
- Save/rewind state: `scripts/autoloads/GameState.gd`,
  `scripts/save/SaveData.gd`, `scripts/save/MapLedger.gd`,
  `scripts/autoloads/SaveManager.gd`, `scripts/save/SaveIntegrity.gd`
- Pack identity/storage/export: `scripts/resources/PackManifest.gd`,
  `scripts/resources/Tier2Catalogue.gd`,
  `scripts/resources/CampaignTier2Validators.gd`,
  `scripts/resources/CampaignTier2RuntimeAdapter.gd`,
  `scripts/resources/CampaignPackRegistry.gd`,
  `scripts/resources/CampaignPackInstaller.gd`,
  `scripts/resources/CampaignPackExporter.gd`,
  `scripts/resources/CampaignArchivePreflight.gd`
- Content loading: `scripts/autoloads/DataManager.gd`,
  `scripts/autoloads/RegistryManager.gd`, current `data/` tree inventory
- Formula/behavior seams: `scripts/core/CombatResolver.gd`,
  `scripts/resources/WeaponData.gd`, `scripts/resources/CampaignRules.gd`,
  `scripts/registries/ObjectiveConditionRegistry.gd`,
  `scripts/registries/ItemEffectRegistry.gd`,
  `scripts/actions/ActionPrimitiveRunner.gd`
- Relevant regression coverage: `scripts/tests/test_resource_ledger.gd`,
  `test_rewind.gd`, `test_ledger_entry.gd`, `test_campaign_save_state.gd`,
  `test_save_manager.gd`, `test_campaign_pack_exporter.gd`,
  `test_campaign_pack_save_identity.gd`, `test_open_authored_registries.gd`,
  and `test_rng_combat_determinism.gd`
