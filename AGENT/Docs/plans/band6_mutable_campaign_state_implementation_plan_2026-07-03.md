---
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-03
---

# Band 6 Mutable Campaign State And Packaging Implementation Plan

**Started:** 2026-07-03.

**Track IDs:** `B6-CAMPAIGN-SHARING`, `B6-CAMPAIGN-STATUS`, `B6-PER-MAP-OVERRIDES`.

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 6 rows. Drafted from the settled **Q8** and **Q13** walkthrough decisions
(2026-07-01) in
[`band5_plus_preimplementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md)
→ "Walkthrough Decisions (2026-07-01)".

## Purpose

Build the one **mutable campaign state** store that Q8 (campaign sharing /
carry-forward) and Q13 (per-map overrides + permanent rule mutation) both landed
on, plus the packaging (export/import) that ships a self-contained campaign.
Q13 Implication 2 is explicit: "permanently change campaign defaults" and Q8's
`CampaignStatusRecord` carry-forward are **the same net-new save concern** —
*"unify into one mutable campaign state store rather than two carry-forward
mechanisms."* This plan builds that one store, the 3-layer rule resolver that
reads/writes it, and the package/status artifacts that move it between campaigns.

The rule vocabulary stays **data-driven**: a rule flip, a per-map override, a
carry-forward fact, and an import-compatibility check are all authored predicate/
resource data the engine reads (`[TCV]`/`REQ-16`), never a fixed struct of named
fields or an engine `match`. Adding a status fact or an override target is
content, not an engine edit ([EXT], AGENTS.md open-registry principle).

This is a build plan only. It does not authorize starting before the gates land.

## Scope

1. **3-layer rule resolver (`B6-PER-MAP-OVERRIDES`, Q13).** Highest-wins:
   **mid-map (triggered) override > per-map rules > campaign rules/defaults.**
   The mid-map layer **IS** Band 3's `apply_rule_flip` (`[CST-4/6/11]`), now
   carrying a `revert_scope` param. Respect existing mandate(locked)/default/
   `protected_fields` semantics.
2. **Mutable campaign state store (Q13 Impl 2 + Q8).** The save persists the
   **current effective campaign defaults** (a patch-log of permanent flips) plus
   the carry-forward facts — one F1 region, not two. Per-map override values and
   active mid-map overrides also survive a suspend save.
3. **Campaign package export/import (`B6-CAMPAIGN-SHARING`, Q8 slice 1).** A
   self-contained pack (manifest + data + raw-loaded art) exports/imports as a
   single artifact with import validation and a load/repair flow.
4. **`CampaignStatusRecord` carry-forward (`B6-CAMPAIGN-STATUS`, Q8 slice 2).**
   Scan compatible records on new-campaign start, choose one/none, manual import
   for foreign records. Status facts + import rules are TCV/resource data.

## Non-Goals

- No event/cutscene **trigger source** for the mid-map flip — Band 3 resolved
  `[CST-11]` to *seam only* (`apply_rule_flip` + `campaign_rule_flipped`),
  triggered from a debug/test hook until the event system exists. This plan adds
  `revert_scope` + the resolver, not a trigger authoring UI.
- No public authoring GUI (`B8-PUBLIC-BUILDER`) and no cross-author compatibility
  resync (`B8-CONTENT-RESYNC`). Import compatibility here is same-author /
  declared-compatible only.
- No new asset pipeline. Art is raw-loaded via the existing `AssetResolver`
  seam (`campaign_asset_taxonomy_and_format_2026-07-01.md`); this plan **consumes**
  it, it does not build it.
- Do not model status facts, override targets, or import rules as an `enum` +
  `match`. They are registry/predicate data.

## Source Docs

- [`band5_plus_preimplementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md)
  → "Walkthrough Decisions (2026-07-01)" **Q8** and **Q13**.
- [`campaign_save_open_decisions_2026-06-21.md`](../registers/campaign_save_open_decisions_2026-06-21.md)
  (`[CST-4]` campaign-owned rules block, `[CST-8]` suspend scope, `[CST-11]`
  `apply_rule_flip` seam, `[CST-10]` import/last-played pointer).
- [`campaign_save_expectations_and_foundations_2026-06-23.md`](../design/campaign_save_expectations_and_foundations_2026-06-23.md)
  (the L1 `SaveManager`/`SaveCodec` seam + L4 `CampaignRules` layer).
- [`campaign_save_technical_plan_2026-06-21.md`](campaign_save_technical_plan_2026-06-21.md)
  (the F1 save schema this store extends).
- [`campaign_status_property_recruitment_plan_2026-06-29.md`](campaign_status_property_recruitment_plan_2026-06-29.md)
  (the `CampaignStatusRecord` shape/decisions this plan implements — that doc is a
  decisions-capture note, this is the build plan).
- [`campaign_asset_taxonomy_and_format_2026-07-01.md`](../design/campaign_asset_taxonomy_and_format_2026-07-01.md)
  (the self-contained pack layout + JSON Tier-2 / raw-loaded Tier-1 + `AssetResolver`).
- [`project_campaign_content_model`] — memory: self-contained per-campaign packs
  (`[ICO-1..6]`), no runtime overlay, copy `res://`→`user://` on first run.

## Decisions Not To Reopen

- **One** mutable campaign state store, not two carry-forward mechanisms
  (Q13 Impl 2). The permanent-flip patch-log and the carry-forward facts share it.
- Rule resolution is a **3-layer resolver** (mid-map override > per-map > campaign
  default), not a flat field read. Band 3 builds the resolver, not just a seam
  (Q13 upgrades the earlier "leave the seam" rec).
- A mid-map triggered override carries `revert_scope ∈ {end_of_map, permanent}`.
  `permanent` mutates the stored effective campaign defaults.
- Per-map override lifecycle: begins on node/map selection, ends on map clear OR
  cancel. Override values + active overrides + permanent mutations survive suspend.
- Mandate(locked) / default / `protected_fields` semantics are honored by the
  resolver — a mandated rule cannot be overridden by a lower-authority layer.
- Campaign packs are self-contained (`[ICO-1..6]`): art in the package, never the
  save; raw-loaded; referenced by id/path through `AssetResolver`. Tier-2 data is
  canonical JSON; user packs are pure JSON.
- Status facts, override targets, and import-compatibility rules are **data**
  (TCV/`REQ-16` predicates), extensible without an engine edit.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates:

- `B1-CST` / `B1-F1` — the `SaveManager`/`SaveCodec` seam and F1 schema this store
  extends. **Hard gate:** the mutable-state region is net-new F1 schema.
- `B1-SUSPEND` — active mid-map overrides + per-map override state are part of the
  between-action suspend snapshot (`[CST-8]`).
- `B3-CAMPAIGN-RULES` — the `CampaignRules` home object + `apply_rule_flip` seam +
  the campaign-owned rules block (mandate/default/`protected_fields`). The 3-layer
  resolver **extends** Band 3; confirm Band 3 leaves the resolver seam (Q13 Impl 1).
- `B3-TCV` / `B3-REQ` — carry-forward facts + import-compatibility predicates.
- `B2-DATAMANAGER-SEAMS` — JSON validate/load for pack `data/`.
- `AssetResolver` (from the asset-taxonomy note) — the single raw-load site for
  packaged art. Package import copies the pack into `user://campaigns/<pack_id>/`.

## Existing Code Touchpoints

Verified 2026-07-03:

- `scripts/resources/CampaignRules.gd` — today a **stub** (Stage 4.3): loose rule
  fields mirrored from `GameState`, `make_default()`. Its own header says
  "consolidation into this class is Target design; use GameState's rule fields
  until then." `[CST-4]` resolved to **B** (hard-migrate call sites to real
  `CampaignRules`), so Band 3 makes this the real rule home; **this plan assumes
  that migration and builds the resolver + `revert_scope` on top of it.**
- `scripts/autoloads/GameState.gd` / `DataManager.gd` — the live rule fields +
  data loading; the resolver and store hang off these once Band 1/3 consolidate.
- `apply_rule_flip` / `SaveManager` / `SaveCodec` do **not** exist in code yet
  (Band 1/3 planned artifacts). This plan drafts against those planned APIs, same
  as the Band 5 plans — grounding is at the design/register level.
- Tests to create: `test_rule_resolver.gd`, `test_mutable_campaign_state.gd`,
  `test_campaign_package.gd`, `test_campaign_status_record.gd`.

## Slice 0 - Preflight After Gates

**Goal:** confirm the save spine, rules home, and asset resolver exist before
building on them.

Implementation checklist:

- Confirm `B1-CST`/`B1-F1` (`SaveManager`/`SaveCodec` + F1 schema) landed and
  `B3-CAMPAIGN-RULES` consolidated `CampaignRules` per `[CST-4]` B.
- Confirm `apply_rule_flip(rule, value, reason)` + `campaign_rule_flipped` exist
  (Band 3, `[CST-11]` A) — the mid-map layer extends this, does not re-add it.
- Confirm `AssetResolver` + `user://campaigns/<pack_id>/` layout exist.
- Reserve the F1 rows: `campaign_rule_patches`, `per_map_overrides`,
  `active_mid_map_overrides`, `carry_forward_facts`, `imported_record_ref`.

Tests: none required in preflight.

## Slice 1 - The 3-Layer Rule Resolver

**Goal:** one resolver returns the effective value of any rule knob, honoring
authority order and mandates.

Files to create or touch:

- `scripts/resources/CampaignRules.gd` (or a `RuleResolver` helper it owns)
- `scripts/autoloads/GameState.gd` (route rule reads through the resolver)
- `scripts/tests/test_rule_resolver.gd`

Implementation steps:

1. `get_effective_rule(rule_id)` resolves highest-wins:
   **mid-map override (if active) > per-map override > campaign default**, with
   a **mandate short-circuit**: a mandated (locked) rule ignores any lower-layer
   override and resolves to its mandated value (honors `[CST-4]`/`protected_fields`).
2. `apply_rule_flip(rule, value, reason, revert_scope)` — extend Band 3's seam
   with `revert_scope ∈ {end_of_map, permanent}`. `end_of_map` pushes onto the
   active-mid-map-override layer (reverted at map clear); `permanent` writes the
   patch into the mutable campaign state store (Slice 2). Still emits
   `campaign_rule_flipped`.
3. Per-map override layer: `set_map_override(rule, value)` seeds on node/map
   selection; cleared on map clear OR cancel (the Q13 lifecycle). Rejected for
   mandated rules.
4. Overlays are **rule-agnostic** — the resolver reads any rule id present in the
   campaign rules block; adding a rule knob is data, not a resolver edit.

Tests:

- With no overrides, `get_effective_rule` returns the campaign default.
- A per-map override shadows the default; clears on map clear and on cancel.
- A mid-map `end_of_map` flip beats the per-map layer during the map, reverts
  after; a `permanent` flip persists as the new default (assert via Slice 2).
- A **mandated** rule cannot be overridden by either lower layer (mandate wins).
- Adding a fixture rule id resolves through the same resolver with no engine edit.

F1 obligations: `active_mid_map_overrides` + `per_map_overrides` rows reserved
(written in Slice 2's store).

DoD#1 obligations: update `GDD_01` (CampaignRules Contract — resolver + `revert_scope`)
and `GDD_06`; flip the matching `GDD_10_Roadmap` status.

DoD#2 obligations: `check_docs.py` guard that `revert_scope` is a documented fixed
value-set (`end_of_map|permanent`) matching the GDD, mirroring the mouse-cursor /
`_danger_mode` value-set checks.

## Slice 2 - The Mutable Campaign State Store

**Goal:** the single F1 region that persists permanent rule mutations and
carry-forward facts, restored on load and included in suspend.

Files to create or touch:

- `scripts/resources/MutableCampaignState.gd` (the store resource)
- `scripts/autoloads/GameState.gd` (owns the live store instance)
- the `SaveCodec`/F1 serializer (Band 1) — add the store region
- `scripts/tests/test_mutable_campaign_state.gd`

Implementation steps:

1. `MutableCampaignState` holds: `rule_patches` (a **patch-log** of permanent
   flips: `{rule_id, value, reason, source}`), `carry_forward_facts` (a TCV-keyed
   Dictionary — Slice 4 fills it), and `imported_record_ref` (Slice 4). Effective
   defaults = authored campaign rules with `rule_patches` applied in order.
2. The resolver's campaign-default layer reads **effective defaults** (authored ∪
   patches), so a `permanent` flip (Slice 1) changes what the bottom layer returns.
3. Serialize the store into the campaign save (persistent) and the between-action
   suspend snapshot (`[CST-8]` — active mid-map overrides + per-map override state
   ride the suspend snapshot; permanent patches live in the campaign save).
4. Migration: an older save with no store region loads as an empty store (no
   patches) — pre-existing campaigns keep authored defaults. Guard the schema
   version bump.

Tests:

- A `permanent` flip appends a patch; `get_effective_rule` returns the patched
  value after a save/load round-trip.
- `end_of_map` overrides do **not** enter the patch-log (they revert).
- Active mid-map + per-map override state round-trip through a suspend snapshot.
- A pre-store save migrates to an empty store (authored defaults intact).
- Patch-log order is deterministic (last patch for a rule wins).

F1 obligations: `rule_patches`, `carry_forward_facts`, `imported_record_ref`,
`per_map_overrides`, `active_mid_map_overrides` rows — must exist before code.

DoD#1 obligations: update `GDD_01` (save schema — mutable campaign state region)
+ `GDD_07`; flip `GDD_10_Roadmap`.

DoD#2 obligations: guard that the store region is present in the F1 manifest and
that a new carry-forward fact key loads as data (no struct field edit).

## Slice 3 - Campaign Package Export / Import

**Goal:** move a whole self-contained campaign between systems as one artifact,
with validation and a load/repair flow.

Files to create or touch:

- `scripts/autoloads/CampaignPackager.gd` (export/import service)
- `scripts/resources/PackManifest.gd` (id/version/`forked_from`/
  `builder_content_version`/`format_version`)
- `scripts/tests/test_campaign_package.gd`

Implementation steps:

1. **Export:** bundle `user://campaigns/<pack_id>/` — `manifest.json`, `data/`
   (canonical JSON content + graph + rules + `MapData`), and `art/`, `fonts/`,
   `audio/` (raw Tier-1 media) — into a single artifact (zip; single-`.json` for
   art-free packs, zip-sniff on import per the L1 seam). The **save is never
   bundled with the pack** — pack = content, save = run state (`[ICO]`).
2. **Import:** validate the manifest (`format_version` compatible, required
   Tier-2 data present, referenced art ids resolvable via `AssetResolver`), then
   copy into `user://campaigns/<pack_id>/`. Import compatibility is a **predicate**
   (`REQ-16` / declared rules), not a hardcoded version check.
3. **Load/repair flow:** on a missing/corrupt art reference, fall back through the
   `AssetResolver` chain (missing icon → text row, missing portrait → silhouette,
   …) and surface a repair report rather than hard-failing — a pack with a broken
   optional asset still loads.
4. The importer registers the pack into the `[CST-6]` campaign selector (as a
   normal, non-dev campaign), setting the last-imported pointer (`[CST-10]`).

Tests:

- Round-trip: export a fixture pack, import it, assert data + art references
  resolve and the campaign appears in the selector.
- An incompatible `format_version` / missing required data reports a useful,
  non-crashing error.
- A pack with one missing optional icon imports and falls back (repair report),
  not a hard failure.
- The save is not present in the exported pack.

F1 obligations: none (packages are content on disk, `no_save_guard` on the
packager); the imported pack id is recorded via the existing selector pointer.

DoD#1 obligations: update `GDD_01`/`GDD_07` (packaging) + `GDD_10_Roadmap`.

DoD#2 obligations: guard that a new asset group in a pack registers a resolver +
fallback chain (no engine edit) and that the manifest required-field set matches
the documented schema.

## Slice 4 - CampaignStatusRecord Carry-Forward

**Goal:** the second consumer of import — a portable status artifact that a later
campaign reads, built on the same store and import UI.

Files to create or touch:

- `scripts/resources/CampaignStatusRecord.gd` (the portable artifact)
- `scripts/autoloads/CampaignPackager.gd` (record scan/import — reuse Slice 3 UI)
- `scripts/tests/test_campaign_status_record.gd`

Implementation steps:

1. `CampaignStatusRecord` is a compact portable artifact (NOT a full save):
   `format_version`, `record_id`, `author_id`, `campaign_id`, `campaign_version`,
   completion subset, and a **`facts` Dictionary keyed by authored status-fact ids**
   (villages_saved, units_recruited, story_flags, …) + counters. Facts are the
   `carry_forward_facts` in the mutable store (Slice 2) — a run **exports** its
   facts, a new run **imports** them. Facts are data, not named struct fields.
2. On new-campaign start, **scan** `user://` for records whose author/campaign
   declare compatibility (predicate, `REQ-16`), let the player choose one or none,
   plus a **manual import** path for foreign records (reuse Slice 3's importer UI).
3. Imported facts seed the new run's TCV variables so `B3-TCV` conditions and
   `B3-REQ` predicates read them ("chose flag X" → a starting condition) — no
   bespoke carry-forward scripting.
4. A completed run **exports** a `CampaignCompletionRecord` (the completion subset)
   so the short web campaign can feed a larger sequel (Q8: makes the artifact
   v1-lean, not post-v1).

Tests:

- A run exports a record; a new campaign scans, lists it as compatible, and
  imports its facts into TCV.
- An incompatible/foreign record is offered only via manual import, not the
  auto-scan list.
- Choosing "none" starts a clean campaign (no imported facts).
- Imported facts drive a TCV condition (e.g. a recruited-unit flag gates a start).
- Adding a new status fact id is data — no `CampaignStatusRecord` field edit.

F1 obligations: `carry_forward_facts` + `imported_record_ref` (from Slice 2) hold
the imported record identity + derived vars.

DoD#1 obligations: update `GDD_01`/`GDD_07` (status record carry-forward) +
`GDD_10_Roadmap`.

DoD#2 obligations: guard that a new status-fact / import-rule id loads as data and
that the record `format_version` field set matches the documented schema.

## Implementation Commit Order

1. Slice 0 preflight (gates present).
2. Slice 1 the 3-layer rule resolver (extends Band 3 `apply_rule_flip`).
3. Slice 2 the mutable campaign state store (F1 region; permanent flips + facts).
4. Slice 3 campaign package export/import (the reusable importer + validation).
5. Slice 4 `CampaignStatusRecord` carry-forward (second import consumer).

Slices 1-2 are the store + resolver core (highest F1 risk; do first). Slice 3
builds the importer; Slice 4 reuses it. The whole plan gates on `B1-CST`/`B1-F1`/
`B3-CAMPAIGN-RULES`; Slice 2's suspend integration additionally gates on
`B1-SUSPEND`.

## Verification Checklist

Same as the Band 2/3/4/5 plans. Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
```
