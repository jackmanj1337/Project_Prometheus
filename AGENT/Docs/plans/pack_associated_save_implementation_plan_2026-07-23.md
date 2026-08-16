---
Type: plan
Status: Planned — approved contract; implementation not started
Last verified: 2026-08-02
Decision source: campaign_data_ownership_research_findings_2026-07-23.md
Tracker: IMPL-PACK-SAVE-SCHEMA, IMPL-PACK-SAVE-LOAD-MIGRATION, IMPL-PACK-SAVE-EXPORTS
---

# Pack-Associated Saves and Exports — Implementation Plan

## Ownership contract

The engine writes user state outside installable packs. Package id plus campaign id
own its namespace and interpretation. Saves reference immutable definitions by
durable id and snapshot mutable run state; they do not copy campaign/map/class/item/
skill documents or executable behavior. Headers and rewind entries remain intentional
derived/history copies, never authoring sources.

## Current-state inventory

- `SaveData.FORMAT_VERSION`, `from_dict`, `to_dict`, `_default_campaign`, header
  generation and legacy normalization define the envelope.
- `CampaignRules.make_default`; `GameState._campaign_rules_to_dict`,
  `_campaign_rule_defaults_to_dict`, `_apply_campaign_rules_dict`, capture/resume
  paths duplicate the rule field/default list.
- `SaveManager.save_slot`, `load_slot`, `import_slot`, `export_slot`, index/header
  management and atomic write helpers own storage and portable save transfer.
- `GameState.capture_campaign_save`, `capture_suspend_save`,
  `configure_campaign_resume`, `configure_suspend_resume`,
  `_activate_saved_campaign_source`; `CampaignManager` owns progression state.
- `CampaignPackRegistry`, installer/preflight, `CampaignPackExporter.export_zip`,
  `SaveIntegrity`, `CampaignStatusRecord`, and `LoadGameScreen` are compatibility,
  transfer, integrity and UI seams.

## Canonical data shape

```json
{
  "save_format_version": 2,
  "source": {
    "package_id": "base_game",
    "package_version": "1.0.0",
    "content_schema_version": 2,
    "content_fingerprint": "sha256:...",
    "campaign_id": "proving_grounds"
  },
  "campaign": {
    "profile_id": "standard",
    "resolved_defaults": {},
    "state": {},
    "roster": {"units": []},
    "inventory": {},
    "wallets": {}
  },
  "map_runtime": {},
  "history": []
}
```

One engine-owned `CampaignRuleSchema` supplies field ids, types, allowed values,
defaults, normalization and serialization. `CampaignRules`, Tier-2 profile/campaign
validation, SaveData codecs and GameState capture/apply all delegate to it. The save
stores resolved defaults deliberately; the provider eliminates manual authoring
duplication, not provenance/history snapshots.

Mutable snapshots contain durable unit state, convoy/per-unit inventory, complete
wallets, mutable campaign facts/patches/progression, live map state and rewind
checkpoints. Immutable definitions remain durable ids. Each representation shares
one codec per value family.

## Transactional load and migration

1. Read bytes, verify integrity and migrate engine `save_format_version` in memory.
2. Resolve exact installed package, or a same-id compatible successor declared by
   its manifest; compare saved fingerprint and never silently accept changed bytes.
3. Find a complete declarative migration chain keyed by package/content schema.
4. Apply engine-owned primitives to a deep copy: initially `rename_id`,
   `map_value`, `set_default_if_absent`, bounded numeric transform, move/copy/delete
   known field, and explicit reject. Paths and target families are allow-listed.
5. Validate full envelope, every durable reference, rules and wallet/checkpoint
   invariants against the candidate pack.
6. Atomically activate the pack and runtime snapshot; on any failure restore the
   prior catalogue/runtime and leave source bytes/index unchanged.

No migration script, expression, callable, filesystem/runtime-object access, partial
chain, best-effort reference repair, or mutation before validation is allowed.

## Incremental slices and dependencies

1. **`IMPL-PACK-SAVE-SCHEMA`** depends on the base package identity/catalogue and
   v1 formula ids. Add the shared rule-schema/default provider; introduce the source
   fields and deterministic catalogue fingerprint; migrate existing saves in memory;
   namespace index/group labels by package/campaign. Exit: old and new saves round
   trip, existing behavior is unchanged, and unknown immutable definitions are not
   copied into saves.
2. **`IMPL-PACK-SAVE-LOAD-MIGRATION`** adds compatible-pack resolution, declarative
   migration schema/registry/chain, reference validation and transactional activation.
   Missing/incompatible/mutated packs show required and installed identities. A
   portable save may import into disabled state without activating.
3. **`IMPL-PACK-SAVE-EXPORTS`** preserves `SaveManager.export_slot` as portable
   save; preserves clean pack export; adds a full backup envelope containing a clean
   deterministic pack archive plus separate `user_state/manifest.json`, saves and
   status records. Restore splits both through their independent validators and
   commits only after all selected components pass.

### Deferred recovery-message improvement

Keep the current save package and runtime behavior unchanged for v0.6.1. In the
load/migration slice, replace the generic missing-package failure with a bounded,
actionable diagnostic that distinguishes missing, incompatible-version,
fingerprint-mismatch, corrupt/invalid, and missing campaign/content identities. Show
the saved package name/id/version and fingerprint when available, state explicitly
that no save bytes or progress were modified, and offer Manage Campaigns, Retry, and
Back actions without exposing filesystem paths. Cover the wording and focus order in
headless UI tests and the Windows checklist.

## Compatibility, security and tests

- Migrate legacy package aliases and rule/resource fields; the economy plan adds the
  `party_gold` → player campaign wallet migration on this schema seam.
- Golden old-save fixtures for each existing format; migration-chain gaps/cycles,
  wrong package, fingerprint mismatch, missing ids and malformed operations.
- Failure injection at parse, write, pack activation, migration and index promotion;
  assert byte/state rollback and no partial files.
- Portable-save, clean-pack and full-backup byte/semantic round trips; reject state
  inside installable pack and pack bytes masquerading as a save.
- Enforce path containment, archive/file/count/size budgets, duplicate/case collision,
  digest algorithm/length and human-readable bounded diagnostics.
- Windows: import missing-pack save, install compatible pack, load; exercise mismatch
  and full backup restore UI, labels, focus and confirmation. Headless owns semantics.

## Documentation, enforcement, exclusions

Product work targets `agent/integration`. Update GDD 01/06/07, GDD 10, Feature
Index, Control Plane and save-schema manifest per behavioral slice. Extend
`check_docs.py` with exact required identity fields and the clean-pack/no-user-state
rule when ratified mechanically. Update `campaign_pack_engine_boundary_plan_2026-07-15.md`
wording as described by the zero-content plan. Do not add cloud sync, account DRM,
cross-package saves, embedded pack snapshots, pack dependencies, arbitrary migration
code, minimal event-log replay, or editor redesign.
