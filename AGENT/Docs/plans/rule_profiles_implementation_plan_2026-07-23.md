---
Type: implementation plan
Status: Planned — approved contract; implementation not started
Last verified: 2026-07-23
Decision source: campaign_data_ownership_research_findings_2026-07-23.md
Tracker: IMPL-RULE-PROFILES
---

# Pack-Authored Rule Profiles — Implementation Plan

## Outcome and data shape

After the shared pack catalogue and save-schema seams land, add the smallest
independent authoring slice: pack-owned JSON profiles containing only existing
`CampaignRules` fields.

```json
{"id":"standard","schema_version":1,"rules":{"death_mode":"casual",
"leveling_method":"growth_random","hit_formula":"two_roll"}}
```

A campaign names `profile_id` and may provide explicit campaign defaults. New Game
resolves schema defaults → selected profile → explicit campaign defaults, then stores
both selected id and the fully resolved defaults. Existing runs read their saved
snapshot; a pack/profile update affects future runs unless an explicit pack migration
updates an existing run.

Profiles add no runtime precedence layer. Existing order stays: mandate → node
override → mid-map override → resolved campaign default.

## Current-state inventory

- `CampaignRules` exports the supported fields and `make_default`.
- `GameState.apply_campaign_rule_overrides`,
  `commit_current_campaign_rules_as_defaults`, `get_effective_campaign_rule`,
  `begin_campaign_map_rules`, `apply_rule_flip`, `_campaign_rules_to_dict`,
  `_campaign_rule_defaults_to_dict`, `_apply_campaign_rules_dict` implement current
  defaults/mandates/overrides and persistence.
- `SaveData._default_campaign` duplicates defaults today; the pack-save plan replaces
  it with the shared schema/default provider.
- `CampaignTier2Validators.registry` and `Tier2Catalogue` currently have no profile
  kind; `CampaignTier2RuntimeAdapter._build_campaigns` builds campaign definitions.
- New Game campaign selector/editor import/export flows are the author/player seams.

## Validator, adapter and catalogue contract

Add `rule_profile` as a catalogue kind. Validate exact top-level keys, durable local
id, supported schema version, rules dictionary, known fields, field types and allowed
values through `CampaignRuleSchema`. Errors include package/profile/path/field and
expected values. Unknown fields/values/ids reject activation. Campaign validation
requires the referenced profile and validates its explicit overlay without mutating
the profile document.

Runtime resolution returns an immutable `{profile_id, resolved_defaults}` value used
to initialize `CampaignRules` and save state. It never retains a mutable reference to
catalogue data.

## Slice, dependencies and compatibility

**`IMPL-RULE-PROFILES`** depends on `IMPL-ZERO-CONTENT-BASE-PACK` and
`IMPL-PACK-SAVE-SCHEMA` (and therefore the v1 formula registry for `hit_formula`).
One product slice targeting `agent/integration` adds validator/adapter/catalogue,
campaign reference/overlay, New Game resolution and save/load identity/snapshot.
Convert base/template profiles into ordinary base-pack documents. Editor/import/copy
duplicates a document into the destination pack with a new/local id; no engine-baked
template gameplay data is introduced.

Old campaigns with no profile use an import-only synthetic/default resolution and
write the resolved snapshot on next save; old runs never re-resolve silently. A
missing profile in a new campaign rejects the pack; an existing save can load from its
snapshot only through the persistence plan's compatible-pack validation, not by
ignoring a missing identity.

## Tests and player/author validation

- Exact resolution and overlay order; full existing field matrix; unknown field,
  value, schema and profile id; duplicate ids.
- Mandate, node override and mid-map override retain precedence over resolved default.
- Save/load preserves id and resolved bytes; pack profile update changes a new run but
  not an existing run; explicit migration can replace snapshot deliberately.
- Copied/imported profile is independent pack data with local id and export round trip.
- Windows: profile label/defaults at New Game, locked mandate presentation, copied
  profile author flow if editor UI exists; headless tests own semantics.

## Documentation, enforcement and exclusions

Update GDD 01/06/07, campaign authoring guide, save-schema manifest, GDD 10, Feature
Index and Control Plane. Extend `check_docs.py` when profile schema/precedence becomes
mechanical: allowed first-slice fields must be derived from the shared schema and
profile docs may not introduce a fifth precedence layer. This plan narrows and
supersedes the broader profile portion of `B3-CAMPAIGN-RULES-2026-07-19`; locked/start/
mid-run vocabulary expansion remains separately planned. Exclude new rule fields,
arbitrary formulas, per-map profile switching, live re-resolution, marketplace
templates and broad editor redesign.
