---
Type: plan
Status: Active - planning input
Last verified: 2026-06-29
---

# GDD_10 Active Work Coverage Matrix

**Started:** 2026-06-29. Transition artifact for the Project Control Plane and
unified GDD rewrite.

**Purpose.** Prove that live work in `AGENT/GDD/GDD_10_Roadmap.md` has a home in
the new dependency-band system before rewriting `GDD_10`.

This is an audit matrix, not the final tracker. It maps old rows to the future
Project Control Plane so the rewrite can move detail safely.

## Audit Policy

The coverage source is:

1. status-bearing rows in the `GDD_10` Open Items Register,
2. active release gates, validation queues, and pre-release cleanup rows,
3. the milestone status snapshot where it still names live work,
4. Phase 3 backlog bullets that are open and not already surfaced by the Open
   Items Register,
5. missing rows from the reprioritized triage that must be added even though
   old `GDD_10` does not yet track them directly.

Fine-grained legacy checklist bullets under old milestones are not mapped one by
one. They become source detail for an umbrella control-plane row unless they
represent a separate release gate, validation item, or dependency.

## Band And Bucket Key

| Value | Meaning |
|---|---|
| Band 0 | Pre-GDD scope lock and tracking-system setup. |
| Band 1 | Determinism and save gate. |
| Band 2 | Shared authoring/runtime contracts. |
| Band 3 | Core authoring foundations. |
| Band 4 | Campaign loop vertical slice. |
| Band 5 | Tactical v1 enrichment. |
| Band 6 | V1-lean/stretch packs. Campaign sharing/exporting is a v1 owner decision here. |
| Band 7 | Optional after stable core. |
| Band 8 | Post-v1 / parked. |
| Validation | Manual/live verify, playtest rerun, or fixture evidence. |
| Release gate | Public release, branch, package, identity, or legal gate. |
| Cleanup | Pre-release removal or debug-aid cleanup. |
| Historical / supersede | Old prose or rows that should be retired after their live work is represented. |
| Needs split | Old row mixes several future rows and must be split in the control plane. |

## Open Items Register Coverage

| Old source | New bucket | Future track parent | Coverage note |
|---|---|---|---|
| A: v0.2.3 Display build live-verify closeout | Validation | `VAL-V023-DISPLAY` | Keep as a validation row tied to GDD_07 and `playtests/playtest_checklist_v0.2.3.md`. |
| A: v0.2.3 branch to `main` fast-forward merge | Release gate | `REL-V023-MERGE` | Keep separate from feature work. This is process/release plumbing. |
| A: Debug Web playtest build | Validation / Band 6-adjacent | `B6-WEB-DEBUG` | Triage says useful but not core game-system v1. Track as private playtest channel work. |
| A: Input-mode / gamepad architecture | Band 6 | `B6-INPUT` | Parent for input-mode resolver, gamepad layer, key rebind UI, and selector extraction. |
| A: Package A / Determinism | Band 1 | `B1-PKGA` | Direct row. Build first; Steps 1-2 gate campaign/save. |
| A: Campaign / save cluster | Band 1 | `B1-CST` | Direct row. Depends on Package A and F1 save-schema lock. |
| A: Individual unit threat range | Band 6 | `B6-MRD` | Fold under map-readability. Keep TUR design as source. |
| A: Map-readability cluster | Band 6 | `B6-MRD` | Parent for hover peek, path arrows, threat range, and grid dim slider. |
| B: V021-04 terrain corner-snap on editor scale | Validation | `VAL-V021-04` | Live-verify/UI polish queue; not a foundation feature. |
| B: V021-15 shared selector extraction | Band 6 | `B6-INPUT` | Also reduces risk for gamepad/key-rebind work. |
| B: V021-12 class-skill More Info drilldown | Validation / UI polish | `VAL-V021-12` | Keep as focused UI backlog unless folded into selector work. |
| B: V021-18 / V021-19 crisp scaling and 1440p/4K | Validation | `VAL-V023-DISPLAY` | Same validation parent as the v0.2.3 display closeout. |
| C: v0.2.2 live-verify check-backs | Validation | `VAL-V022-CHECKBACKS` | One umbrella row that links `playtests/v0.2.2_review_checkbacks_2026-06-20.md`. |
| D: V021-09 duration labels with no producer | Band 5 | `B5-DURATION-LIFECYCLE` | Lands with conditions, skill procs, or equipment-duration lifecycle work. |
| E: 8.4 tonic expiration rerun | Validation | `VAL-PLAYTEST-RERUN` | Evidence/rerun queue. |
| E: E.6 oversized window rerun | Validation | `VAL-PLAYTEST-RERUN` | Evidence/rerun queue. |
| E: 7.2 full Map 900 faction cycle | Validation | `VAL-PLAYTEST-RERUN` | Evidence/rerun queue. |
| E: 3.1 Routing Red does not win | Validation | `VAL-PLAYTEST-RERUN` | Evidence/rerun queue; likely objective/content validation. |
| E: 7.4 camera panning memory fixture gap | Validation | `VAL-FIXTURE-GAPS` | Test-fixture gap, not a defect row unless reproduced. |
| E: C.1 / C.2 New Game comments | Band 1 | `B1-CST` | Accepted deferred behavior; campaign layer replaces the flow. |
| F: D-A public-identity rename | Release gate | `REL-REN` | Public RC gate; needs owner names. |
| F: DOC-012 / OPEN-12 legal/licensing | Release gate | `REL-LEG` | Blocking public release gate; needs owner source-corpus/license input. |
| F: OPEN-5 broken-weapon degraded mode | Band 7 | `B7-BWN` | Optional rule after CampaignRules/IEQ/shop repair seams. |
| F: remove playtest-2 debug aids | Cleanup | `CLEAN-DEBUG-AIDS` | Pre-release cleanup row. |
| F: remove F9 all-faction hotseat override | Cleanup | `CLEAN-F9-HOTSEAT` | Pre-release cleanup row. |
| F: remove debug-mode HUD banner | Cleanup | `CLEAN-DEBUG-HUD` | Pre-release cleanup row. |
| F: D-B / D-D 1.0 definition and campaign prerequisites | Release gate / Band 4 | `REL-1P0-SCOPE`, `B4-CAMPAIGN-LOOP` | Split gate definition from deployment/shop/recruit campaign-loop dependencies. |
| G: M12 Laguz System | Band 8 | `B8-LAGUZ` | Post-v1 / parked. |
| G: M13 Awakening Supplement | Band 8 | `B8-AWAKENING` | Post-v1 / parked. |
| G: M15 Part B Remote Play | Band 8 | `B8-REMOTE-PLAY` | Post-v1; keep online decisions as source evidence. |
| G: Phase 3 backlog | Needs split | See backlog coverage below | Old umbrella is too broad for the control plane. |
| G: Apple Vision Pro reach | Band 8 | `B8-VISION-PRO` | Parked until web release is Safari-verified. |
| H: Planning backlog | Historical / supersede | See missing-row list below | Much of this text is superseded by registers, triage, and source plans. Retire after coverage rows exist. |

## Milestone Snapshot Coverage

| Old source | New bucket | Future track parent | Coverage note |
|---|---|---|---|
| Status Snapshot M8 Status Conditions | Band 5 | `B5-CONDITIONS` | Build after shared save/action/projection foundations. Old detailed checklist remains source detail. |
| Status Snapshot M9 Skill Content | Band 5 | `B5-SKILLS-EFFECTS` | Split into required v1 effect ids, optional content ids, and open-registry effect conversion. |
| Status Snapshot M10 Extra-Turn System | Band 5 / Band 6 | `B5-ACTION-GRANT`, `B6-RESCUE-CARRY` | Reinvigorate/dancer/secondary movement are tactical v1 enrichment; rescue/carry expansion rides Band 6. |
| Status Snapshot M11 Content Expansion | Needs split | `CONTENT-V1`, `CONTENT-POSTV1` | Old "all handbook/Awakening" scope exceeds v1. Split v1 campaign data from post-v1 supplement content. |
| Status Snapshot M12 Laguz | Band 8 | `B8-LAGUZ` | Same as Open Items Register. |
| Status Snapshot M13 Awakening | Band 8 | `B8-AWAKENING` | Same as Open Items Register. |
| Status Snapshot M14 Faction System | Historical / validation | `VAL-M14-LEFTOVERS` | Core implementation is shipped. Only leftover tactical-AI scoring becomes Band 5/7 AI work. |
| Status Snapshot M15 Hotseat / Remote | Validation / Band 8 | `VAL-HOTSEAT-A`, `B8-REMOTE-PLAY` | Part A acceptance checks stay validation; Part B is post-v1. |
| Status Snapshot M16 Objective System | Historical / validation | `VAL-OBJECTIVE-MAPS` | Core implementation is shipped. Map 002-005 status conflicts with Phase 3 backlog and needs one resolved row. |
| Old implementation order prose | Historical / supersede | `B0-GDD-REWRITE` | Replace with dependency-band narrative. |

## Phase 3 Backlog Coverage

| Old source | New bucket | Future track parent | Coverage note |
|---|---|---|---|
| Code Health: decompose `DataManager._ready()` | Band 2 | `B2-DATAMANAGER-SEAMS` | Refactor/validation seam supports campaign self-contained load and registry validation. |
| Content: remaining classes/weapons/skills/items | Needs split | `CONTENT-V1`, `CONTENT-POSTV1` | Split short-campaign needs from full handbook/supplement corpus. |
| Content: forging UI/shop system | Band 7 | `B7-FORGING` | Optional after stable core. Shop itself is Band 4. |
| Content: class promotion UI with 3+ paths | Band 4 / content | `B4-PROMOTION-UI` | Needed only if v1 content uses 3+ paths. |
| Systems: campaign-rules contract | Band 1 / Band 3 | `B1-CST`, `B3-CAMPAIGN-RULES` | Old row should be split between save envelope and author-facing profiles/tunables. |
| Systems: between-map save/load | Band 1 | `B1-CST` | Direct campaign/save child row. |
| Systems: mid-battle suspend save | Band 1 | `B1-SUSPEND` | Depends on Package A snapshot contract and F1 manifest. |
| Systems: Fog of War / LoS | Band 6 | `B6-FOW` | V1-lean/stretch after save slices and map-event seams. |
| Systems: Rescue and carry | Band 6 | `B6-RESCUE-CARRY` | Depends on occupancy/displacement/death lifecycle. |
| Systems: ally NPC phase | Historical / supersede | `B4-FACTIONS` | Superseded by faction system; no active row needed beyond validation if bugs appear. |
| Systems: additional AI profiles | Band 5 | `B5-AI-COMPOSITION` | Fold into AI composition/profile registry row. |
| Systems: stationary weapon interaction | Band 7 | `B7-STATIONARY-WEAPONS` | Optional after map_objects, STY, and AI profile support. |
| Systems: doors and chests | Band 4 | `B4-MAP-OBJECTS` | Direct campaign-loop map-object row. |
| Systems: pre-battle deployment screen | Band 4 | `B4-PREP-DEPLOYMENT` | Campaign-loop prerequisite with convoy/trade inventory flow. |
| Systems: cap-management UI | Band 5 | `B5-LOADOUT-CAPS` | Loadout caps for skills/styles/sources; prep-only panel. |
| Systems: FE map sprite importer | Band 6 / tooling | `B6-SPRITE-IMPORTER` | Useful production tooling; not a game-system blocker. |
| Maps 002-005 | Validation / content | `VAL-OBJECTIVE-MAPS` | Conflicts with M16 checklist marking them done. Resolve during GDD_10 rewrite. |
| Polish placeholders: sprites, portraits, terrain, UI art, animations | Polish | `POLISH-ART` | Keep separate from systems schedule. |
| Polish: class-skill More Info drilldown | Validation / UI polish | `VAL-V021-12` | Same as Open Items Register. |
| Polish: music and sound effects | Polish | `POLISH-AUDIO` | Audio milestone, not foundation work. |
| Polish: story and dialogue system | Band 4 | `B4-DIALOGUE-V1` | Rename old polish wording; dialogue v1 is now a campaign-loop dependency. |
| Polish: Steam / itch.io / GitHub release packaging | Release gate | `REL-PACKAGING` | Package/distribution row. |
| UI/UX: hover range, movement arrows, threat range, grid slider | Band 6 | `B6-MRD` | Map-readability umbrella. |
| UI/UX: camera settings | UI polish / Band 6-adjacent | `UI-CAMERA-SETTINGS` | Not a foundation blocker. |
| UI/UX: display/accessibility controls | Validation | `VAL-V023-DISPLAY` | Existing v0.2.3 validation parent. |
| UI/UX: key rebinding, gamepad, touch | Band 6 | `B6-INPUT` | Input/platform umbrella. |
| UI/UX: full character sheet and More Info mode | UI polish / Band 6-adjacent | `UI-INSPECTION` | Some pieces shipped; keep remaining selector/info work explicit. |
| UI/UX: attack-by-target, richer forecast, combat prediction layout, minimap | Band 6 / Band 7 | `UI-TACTICAL-UX` | Split ergonomic improvements from forecast/projection-dependent work. |
| Pre-Release Cleanup section | Cleanup | `CLEAN-*` rows | Covered by the three cleanup rows from Open Items Register. |

## Missing Rows To Add From Reprioritized Triage

Old `GDD_10` does not directly track several new foundation gates. The control
plane must seed them even though the legacy roadmap has no clean row yet.

| Needed row | Band | Future track parent | Why it must be added |
|---|---|---|---|
| F1 save schema lock and manifest | Band 1 | `B1-F1` | Gates all new save fields. Package A and campaign/save imply it but do not own it. |
| SaveCodec / SaveData fixture obligation | Band 1 | `B1-SAVECODEC` | Needed to make F1 enforceable and testable. |
| Registry manifest contract | Band 2 | `B2-REGISTRY` | Enforces open registries for author-facing vocabularies. |
| Action/effect primitive runner | Band 2 | `B2-ACTION-EFFECT` | Prevents separate MET/DLG/SAC/STY mutation runners. |
| Resource ledger / cost resolver | Band 2 | `B2-RESOURCE-LEDGER` | Shared cost/wallet API for shops, training, arena, styles, sources, and resources. |
| Occupancy transaction service | Band 2 | `B2-OCCUPANCY` | Shared placement path for spawn, forced movement, carry/drop, and object-unit interactions. |
| Death lifecycle funnel | Band 2 | `B2-DEATH-LIFECYCLE` | Required before scripted deaths, hazards, arena, battalion host death, or death inventory disposition. |
| Projection / forecast service | Band 2 | `B2-PROJECTION` | Shared dry-run path for preview, AI valuation, perception, and predicates. |
| F6/TCV typed variable store | Band 3 | `B3-TCV` | Story flags, difficulty tunables, predicates, objective updates, and map counters. |
| F16 requirement/predicate system | Band 3 | `B3-REQ` | Gates dialogue, shops, objectives, recruit, perception, and author requirements. |
| F13 text indirection | Band 3 | `B3-TEXT` | Needed before dialogue/story text grows. |
| F14 stat registry | Band 3 | `B3-STAT-REGISTRY` | Prevents hardcoded stat-name growth. |
| F7 resource pools | Band 3 | `B3-RESOURCE-POOLS` | Required by combat arts, skills, training resources, and charges. |
| F9 PHB panel framework | Band 3 | `B3-PHB` | Shared prep/on-map panel surface for shops, convoy, training, arena, and activities later. |
| Item/equipment composition build | Band 4 | `B4-IEQ` | Needed before inventory, convoy, sources, story items, and item effects. |
| Proficiency / XP framework | Band 4 | `B4-PXP` | Needed for progression, training, bonus EXP, and action proficiency. |
| Map object component contract | Band 4 | `B4-MAP-OBJECTS` | Generalizes doors/chests/shops/activations and replaces object-specific switches. |
| Dialogue v1 line/choice/command slice | Band 4 | `B4-DIALOGUE-V1` | Needed for recruit, village, support hooks, and story scenes. |
| Difficulty and death mode | Band 4 | `B4-DIFFICULTY-DEATHMODE` | Player-facing campaign rules before broad v1 playtest. |
| AI composition/profile registry | Band 5 | `B5-AI-COMPOSITION` | Replaces closed profile switches and supports first campaign maps. |
| Source + Style pipeline | Band 5 | `B5-SOURCE-STYLE` | Shared combat action model for arts, staves, gambits, capture, AoE, and effects. |
| Campaign sharing/export/import | Band 6 | `B6-CAMPAIGN-SHARING` | Owner decision 2026-06-29: in v1 after campaign/save spine. |
| Bonus EXP / training halls | Band 6 | `B6-PREP-PROGRESSION` | V1-lean progression sinks that reuse PHB, resource ledger, and PXP. |
| Arena | Band 7 | `B7-ARENA` | Optional after death/economy progression is stable. |
| PvP hotseat scenario | Band 7 | `B7-PVP` | Optional; not single-player campaign core. |
| ActivityRunner / activity templates / public scripting VM | Band 8 | `B8-ACTIVITIES` | Owner decision 2026-06-29: side activities are not v1. |
| Public campaign builder / authoring GUI | Band 8 | `B8-PUBLIC-BUILDER` | Post-v1 after gameplay and content-pack rules stabilize. |
| Content-pack compatibility / resync | Band 8 | `B8-CONTENT-RESYNC` | Public-authoring compatibility gate, not core campaign v1. |
| Hex topology | Band 8 | `B8-HEX` | Parked thought experiment. |
| Perception / masking | Band 8 | `B8-PERCEPTION` | Post-v1 unless AI/forecast scope changes. |
| ML evaluation function | Band 8 | `B8-ML-EVAL` | Product-roadmap parked. |

## Stale Navigation To Retire During Rewrite

| Source | Problem | Rewrite action |
|---|---|---|
| `GDD_10` status snapshot and implementation-order prose | Old M8-M13 sequence no longer matches the dependency-band schedule. | Replace with human-readable band narrative and next-work queue. |
| Planning backlog sentence: "All other registers remain OPEN" | Later sessions resolved many registers. | Delete or replace with a pointer to generated `AGENT/Docs/REGISTERS.md`. |
| Planning backlog v1 scope paragraph from 2026-06-23h | It predates the 2026-06-28/29 reprioritization and owner decisions. | Supersede with Bands 1-8 scope table. |
| "Phase 3 Post-Awakening" backlog label | It implies M12/M13 still precede most backlog work. | Split into control-plane rows by dependency band, release gate, validation, cleanup, content, and polish. |
| M11 all-handbook/all-Awakening content scope | It mixes v1 campaign content with post-v1 supplement content. | Split into `CONTENT-V1` and `CONTENT-POSTV1`. |
| M16 checklist vs Phase 3 Maps 002-005 backlog | One section marks objective-map work done while another leaves it open. | Resolve to one validation/content row with an evidence link. |

## Coverage Result

The agreed audit scope is covered:

- every Open Items Register row has a future bucket or band,
- old milestone snapshot rows have umbrella parents or supersession notes,
- Phase 3 backlog rows have either a parent row, a split instruction, or a
  cleanup/release/validation bucket,
- missing foundation rows from the reprioritized triage are listed for control
  plane seeding,
- stale navigation blocks are identified for the `GDD_10` rewrite.

## Next Step

Create `AGENT/Docs/plans/project_control_plane_2026-06-29.md` from this matrix.
Seed strict rows for Bands 1-8 plus `Validation`, `Release gate`, `Cleanup`,
`Content`, `Polish`, and `Tooling` queues, then rewrite `GDD_10_Roadmap.md` as
the human build guide that links to those rows.
