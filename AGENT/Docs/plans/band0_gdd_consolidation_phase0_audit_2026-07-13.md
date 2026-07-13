---
Type: plan
Status: Active - audit and implementation plan
Last verified: 2026-07-13
---

# Band 0 GDD Consolidation — Phase 0 Audit And Implementation Plan

## Scope And Authority

This is the read-only contract audit for `B0-DOC-ROLE-MANIFEST`,
`B0-VOCAB-NAMING`, `B0-GDD-CONSOLIDATION`, and `B0-GDD-ANCHORS`. Phase 0
does not change numbered GDD contract text. It records the evidence and commit
boundaries for the prune-and-split-in-place pass authorized on 2026-07-09.

Material is resolved in this order: ratified decisions and resolved registers;
code and tests for implemented-behavior claims; the Project Control Plane for
work state; numbered GDD chapters for concise design contracts; active design
and implementation sources for supporting detail. Session notes are discovery
evidence only.

Baseline validation before this audit: `python3 AGENT/Docs/check_docs.py` passed
all 29 checks on commit `7093110`.

## Inventory And Primary Ownership

Counts are physical lines and level-two headings at the start of Phase 0.

| Document | Lines | `##` sections | Primary role and Phase 2 disposition |
|---|---:|---:|---|
| `GDD_00_Overview.md` | 219 | 10 | Authority and navigation index; Phase 2 reconciled 2026-07-13 — scope/release/platform summaries retained, stale issue/status ownership removed, and exact work routed to the control plane. |
| `GDD_01_Architecture.md` | 1907 | 12 | Architecture and shared contracts; split after cross-domain UI/camera prose and operational guidance are routed to their owners. |
| `GDD_02_Core_Mechanics.md` | 686 | 18 | Combat, turns, EXP, conditions, and death-mode behavior; link weapon/economy/progression detail to `GDD_03`/`GDD_04`. |
| `GDD_03_Units_Classes.md` | 317 | 9 | Roster, classes, promotion, reclass, and progression; move the operational class-authoring checklist to an existing guide. |
| `GDD_04_Weapons_Items.md` | 397 | 10 | Weapon, item, proficiency, inventory, and economy contracts; authoritative owner for WEXP and economy detail. |
| `GDD_05_Skills.md` | 423 | 11 | Skills, grants, loadouts, action grants, and secondary movement; move the operational skill-authoring checklist to an existing guide. |
| `GDD_06_Maps_Objectives.md` | 498 | 11 | Maps, terrain/movement, objectives, map objects, fog, and spawn policy; move the operational map checklist to the map-authoring guide. |
| `GDD_07_UI_UX.md` | 1218 | 7 | Input, cursor, screen/panel catalog, UI state, feedback, and accessibility; split after de-duplication. |
| `GDD_08_Enemy_AI.md` | 285 | 10 | AI composition, profiles, forecast use, determinism, performance, and generation. |
| `GDD_10_Roadmap.md` | 190 | 11 | Human build guide only; the Project Control Plane owns exact state and next actions. |
| `GDD_Feature_Index.md` | 68 | 3 | Navigation from feature groups to GDD owners, Track IDs, sources, code, and tests; exact anchors wait for Phase 4. |

The measured `GDD_01` and `GDD_07` sizes supersede the older 1798/1167-line
estimates in the handoff. Together they contain 3125 of the 5731 lines in
`GDD_01`-`GDD_08`, which confirms that the approved split targets remain the
right ones.

## Role-Manifest Audit

The directory layout matches the manifest's major role families. Four changes
are needed before ownership can be enforced:

1. The `GDD rewrite transition artifacts` exception says it is allowed while
   `B0-GDD10-REWRITE` and `B0-FEATURE-INDEX-WIRING` remain open; both rows are
   already Implemented. Phase 1 must remove or replace that stale exception.
2. The `design_contract` path rule names only the original eight filenames and
   must explicitly include the approved `GDD_01`/`GDD_07` split files before
   those files are created.
3. The manifest says active plans/design docs need a tracker row, feature-index
   row, source exception, or lifecycle marker. A filename-backlink preflight
   found 8 non-historical plans and 15 non-historical design docs not named by
   the Project Control Plane or Feature Index. These are candidates, not yet
   proven violations, because the future check must understand group/source
   exceptions rather than merely search for a filename.
4. `GDD_00` still says `GDD_10` owns the authoritative bug/pending-validation
   list. The role manifest and control-plane schema make the control plane the
   owner; Phase 2 can replace the stale sentence with a tracker link.

Candidate plans needing an owner or explicit exception:

- `band3_implementation_plan_handoff_2026-06-30.md`
- `feature_dependency_atlas_2026-06-23.md`
- `planning_backlog_2026-06-20.md`
- `registry_nonschema_slices_handoff_2026-07-09.md`
- `scope_reframe_and_gdd_stale_audit_plan_2026-06-29.md`
- `stat_breakdown_character_sheet_plan_2026-06-14.md`
- `v0.4.0_review_fix_handoff_2026-07-13.md`
- `v0.4_next_session_handoff_2026-07-13.md`

Candidate design sources needing an owner or explicit exception:

- `ai_system_design_vision_2026-06-22.md`
- `campaign_asset_taxonomy_and_format_2026-07-01.md`
- `campaign_save_expectations_and_foundations_2026-06-23.md`
- `candidate_systems_2026-06-23.md`
- `design_review_foundation_fix_todo_2026-06-28.md`
- `difficulty_profile_manifest_contract_2026-06-28.md`
- `f1_save_schema_manifest_contract_2026-06-28.md`
- `foundations_end_shapes_2026-06-23.md`
- `input_mode_architecture_design_2026-06-20.md`
- `items_equipment_unified_model_2026-06-23.md`
- `mouse_only_cursor_mode_design_2026-06-19.md`
- `open_registry_conversion_checklist_2026-06-28.md`
- `player_facing_scope_map_2026-06-23.md`
- `terrain_more_info_paging_design_2026-06-19.md`
- `ui_ux_art_asset_research_2026-07-02.md`

Phase 1 will classify each candidate as linked owner, named source exception,
Superseded/Historical with its required marker, or a real failure. It will not
bulk-archive or delete files.

## Retired-Vocabulary Audit

The explicit manifest phrases are already absent from numbered GDD prose except
for older generic milestone wording that is outside the manifest's exact term
list. The active-doc scan found these classes:

| Class | Evidence | Disposition |
|---|---|---|
| Actionable active terminology | `minigame_activity_type_initial_specs_2026-06-28.md:439`, `minigame_scripting_runtime_research_2026-06-28.md:10`, `player_facing_scope_map_2026-06-23.md:182`, `shop_activate_configs_open_questions_2026-06-27.md:121` used `mini-game module seam`. | Replaced with the specific `ActivityRunner` seam in Phase 1b. <!-- retired-vocabulary: historical-quotation --> |
| Resolved-decision history | `prep_hub_open_questions_2026-06-23.md:32` records the no-wander-area decision; `datamanager_decomposition_open_questions_2026-06-21.md:136` records the superseded campaign-overlay model. | Preserve as decision evidence; mark the line as historical/superseded context if needed for a checkable exemption. |
| Transition/audit quotation | The coverage matrix, unified-pass follow-up, review evidence, this handoff, and tracking-system plan quote retired language to identify it. | Preserve; the checker needs a narrow quotation/evidence exemption. |
| Manifest self-definition | The preferred/retired term tables necessarily contain every banned phrase. | Exclude the vocabulary manifest itself from failures. |
| Archive and session history | Historical files and session notes contain the former language. | Exclude by role/lifecycle, not by a growing file allowlist. |

The Phase 1 checker will scan active prose, skip archive/session roles and files
whose first-ten-line lifecycle marker is Historical/Superseded, exempt the
manifest's own term tables, and support a narrow marked historical-quotation
form. Focused temporary fixtures must prove both a real failure and every
supported exemption.

### Phase 1b result (2026-07-13)

The four actionable activity-seam references now use `ActivityRunner`; the
tracking-system recommendation no longer repeats a retired consolidation term.
Decision/audit quotations carry the explicit
`<!-- retired-vocabulary: historical-quotation -->` marker. Check 31 reads the
retired-term table from the vocabulary manifest and scans active GDD/Docs prose
while excluding archives, session notes, lifecycle-marked files, the manifest's
own definition table, fenced examples, and marked quotations. A controlled
active-GDD probe failed on the retired activity-seam term and the clean corpus
passed after its removal.

## Duplicate Contract Map

| Duplicate or misplaced material | Authoritative owner | Phase 2 action |
|---|---|---|
| Input actions and cursor behavior in `GDD_01` and `GDD_07` | `GDD_07` input contract | Keep only engine registration/load-order constraints in architecture; link to the UI/input owner for behavior. |
| Rendering/display settings and camera zoom in `GDD_01`, with platform/UI behavior in `GDD_00`, `GDD_06`, and `GDD_07` | `GDD_00` for platform target, `GDD_06` for tactical camera rules, `GDD_07` for settings/input presentation | Replace repeated settings/action tables with direct owner links. |
| WEXP rules in `GDD_02` and `GDD_04` | `GDD_04` | Keep combat-facing effect/timing summary in `GDD_02`; keep thresholds, migration, and weapon-data detail in `GDD_04`. |
| Promotion trigger in `GDD_02` and promotion/reclass contracts in `GDD_03` | `GDD_03` | Keep only action/turn consequences in `GDD_02`; link the progression owner. |
| Gold/economy in `GDD_02` and items/economy in `GDD_04` | `GDD_04` | Keep victory-credit integration in `GDD_02`; keep wallets, prices, inventory, and shop-facing rules in `GDD_04`. |
| Operational `Adding Future Classes`, `Adding a New Skill`, and `Adding a New Map` sections | Existing operational guides | Move unique author instructions to the appropriate guide and leave a short contract link; do not delete unique steps. |
| Exact script signatures and resource pseudo-code mixed with architecture principles in `GDD_01` | Split runtime/data contract files | Preserve binding fields and invariants; remove stale code transcription where a direct code anchor is clearer. |
| Exact work status in `GDD_00`/`GDD_10` prose | Project Control Plane | Retain readable summaries and link exact rows; do not duplicate row-level next actions. |

### Phase 2 progress (2026-07-13)

`GDD_00_Overview.md` is reconciled. Its authority order now distinguishes
ratified design, shipped evidence, tracker state, domain contracts, supporting
sources, and historical evidence. Navigation includes the build guide and
generated indexes; the stale combat-preview issue snapshot was removed; release,
baseline, and platform prose now route exact state through existing Track IDs.
No player-facing behavior or release scope changed.

Terrain is intentionally split rather than duplicated: `GDD_02` owns combat
effects while `GDD_06` owns authored terrain/movement/map behavior. Conditions
also require a deliberate summary/detail split between core mechanics and
skills; Phase 2 must preserve that boundary instead of deleting either section.

`GDD_02_Core_Mechanics.md` is reconciled. Terrain authoring and movement tables now
live only with `GDD_06`; WEXP thresholds, caps, migration, and economy formulas route
to `GDD_04`; promotion state changes route to `GDD_03`. The action table no longer
claims that unimplemented Trade or Shove ships, and mid-exchange weapon breakage is
classified from its production implementation and focused regression coverage.

## Contradictions And Drift

### Mechanically resolved

| Finding | Evidence | Resolution |
|---|---|---|
| Consolidation depended on final anchors even though anchors require stable post-split headings. | The two Band 0 rows and the handoff agree on the intended order. | This Phase 0 commit makes anchors depend on consolidation and removes anchors from consolidation's prerequisites. |
| `GDD_01` says `project.godot` has a `full fourteen` autoloads and lists an order that omits all Band 2 services, `SaveManager`, and `GameConstants`/`EventBus` placement changes. | `project.godot` currently registers 21 autoloads, including `RegistryManager`, `ActionEffectRunner`, `ResourceLedger`, `OccupancyService`, `DeathLifecycle`, and `ProjectionService`. | Reconcile the architecture/autoload section to code and the autoload-order checker in the `GDD_01` chapter commit. |
| The role-manifest transition exception is gated by two rows that are Implemented. | Project Control Plane statuses vs. manifest exception text. | Reclassify the actual transition artifacts and remove the stale blanket exception in Phase 1. |
| The July 5 inline-enemy-placement review finding is no longer open. | `GDD_01:1698`, `GDD_06:246`, `MapData.gd:11-16`, and `GameMap.gd:292-303` all state the exactly-one-of `unit_data_path`/`unit_data` rule. | Record as reconciled evidence; do not repeat the old finding as active work. |
| The old `GDD_01`/`GDD_07` size estimates drifted. | Phase 0 line counts are 1907 and 1218. | Use measured counts in the tracker and migration plan. |

Band 2 contracts are already represented in GDD prose: action/effect,
resource-ledger, occupancy, death-lifecycle, and projection references were all
found in their owner chapters and corresponding focused tests exist. Phase 2
still needs a field-by-field review; presence alone does not prove every slice
limit is stated accurately.

### Decision required

No equal-authority player-facing or scope contradiction was found in Phase 0.
The proposed split filenames below directly describe existing role boundaries,
so they do not require a new taxonomy decision. Any contradiction discovered
during field-by-field reconciliation will be added to the single decision
packet rather than interrupting independent work.

## Split And Migration Plan

### `GDD_01`

Retain `GDD_01_Architecture.md` as the entry contract for core philosophy,
folder/scene composition, autoload responsibilities, and concise onboarding
constraints. Create:

- `GDD_01_Runtime_Contracts.md` for `CampaignRules`, determinism/snapshot/online,
  shared service boundaries, and binding runtime invariants;
- `GDD_01_Data_Contracts.md` for resource schemas and validation invariants.

Route rendering, input-map, and camera behavior to `GDD_00`, `GDD_06`, or
`GDD_07` before the split. Route detailed test/how-to notes to existing guides.

### `GDD_07`

Retain `GDD_07_UI_UX.md` as the cross-cutting entry contract for design
reference, UI state, feedback, accessibility, and navigation. Create:

- `GDD_07_Input_Cursor.md` for input actions, mode behavior, repeat, cursor, and
  threat-display interaction;
- `GDD_07_Screens_Panels.md` for the screen/panel catalog and per-surface
  contracts.

These names extend the existing numbered-family convention; they do not create
a new document role.

### Inbound links and stable identifiers

The exact-filename sweep found 31 Markdown files mentioning
`GDD_01_Architecture` and 22 mentioning `GDD_07_UI_UX`. Live candidates are 13
and 11 respectively; the remainder are review, archive, or session evidence.
There are no existing Markdown links with `GDD_01_Architecture.md#...` or
`GDD_07_UI_UX.md#...` fragments, so Phase 3 creates an old-heading to new-path
table before Phase 4 adds exact anchors.

The two source chapters currently contain these identifiers, all of which must
survive the split:

- `GDD_01`: `B1-CST`, `B1-PKGA`, `B1-SAVECODEC`, `B1-SUSPEND`,
  `B2-ACTION-EFFECT`, `B2-OCCUPANCY`, `B2-PROJECTION`, `B2-REGISTRY`,
  `B3-REQ`, `B3-RESOURCE-POOLS`, `B3-STAT-REGISTRY`, `B5-AI-COMPOSITION`,
  `B6-INPUT`, `OPEN-4`, `OPEN-5`, `OPEN-13`, `RNG-1..4`, `RULE-001`,
  and `STM-5`.
- `GDD_07`: `B5-VICTORY-PROGRESSION-SEQ`, `B6-INPUT`,
  `B8-PUBLIC-BUILDER`, `UI-INSPECTION`, `UI-VIEWPORT-ASPECT`, `DOC-011`,
  `OPEN-8`, `OPEN-11`, `SET-013`, `MRD-1`, `MRD-5`, and `MRD-7`.

The migration commits will also search owner-family references such as bare
`GDD_01`/`GDD_07`, update the role manifest and `check_docs.py` path assumptions,
and preserve historical references unless they are live links that would break.

## Commit-Sized Schedule

1. **Phase 0:** correct the tracker order and add this audit/plan.
2. **Phase 1a:** revalidate the role manifest, classify all 23 ownership
   candidates, retire stale exceptions, and add focused ownership enforcement.
3. **Phase 1b:** normalize only manifest-listed retired terms and add the
   fixture-proven retired-vocabulary check.
4. **Phase 2:** reconcile/de-duplicate `GDD_00`, then one owner chapter per
   commit for `GDD_02`-`GDD_06` and `GDD_08`; reconcile `GDD_01` and `GDD_07`
   content immediately before their split commits.
5. **Phase 3a:** split `GDD_01`, update live links/path checks, and publish the
   heading-migration table.
6. **Phase 3b:** split `GDD_07`, update live links/path checks, and extend the
   heading-migration table.
7. **Phase 4:** add Feature Index exact anchors, run ID/link reachability, update
   all four Band 0 statuses and `GDD_10` follow-ups, and collect any owner
   questions into one decision packet.
8. **Closeout:** run the full repository suite and add the session note/index
   row in a separate commit.

## Validation Matrix

| Change | Focused validation | Required shared validation |
|---|---|---|
| Phase 0 tracker/audit | Control-plane dependency and link inspection | `gen_docs_index.py`, `check_docs.py`, `git diff --check` |
| Role enforcement | Temporary unowned active-doc failure; linked owner, explicit exception, and lifecycle-marker passes | Generated indexes, all documentation checks |
| Vocabulary enforcement | Temporary active-prose failure; manifest, archive/session, lifecycle, and marked quotation passes | Generated indexes, all documentation checks |
| Per-chapter reconciliation | Search affected Track/register IDs; compare implemented claims to production code and focused tests | Link checks, documentation checks, `git diff --check` |
| Each split | Old-heading/new-path table; inbound filename search; preserved-ID set comparison | Generated indexes, all documentation checks |
| Exact anchors | Every Feature Index GDD target includes a reachable section fragment; repository-wide Track ID reachability | Generated indexes, all documentation checks |
| Closeout | `bash run_tests.sh`; retired-term, split-filename, and stable-ID sweeps | Full suite and clean worktree |

## Unresolved Owner Decisions

None identified in Phase 0. This section remains the single packet location. A
future entry must include the conflicting claims, authority level, affected
paths, concrete options, impact, and a recommendation.
