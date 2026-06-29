---
Type: plan
Status: Active - planning input
Last verified: 2026-06-29
---

# Project Vocabulary Manifest

**Started:** 2026-06-29. Draft vocabulary map for the Project Control Plane and
unified GDD rewrite.

**Purpose.** Define the preferred terms, Track ID prefixes, dependency-band
names, retired aliases, and naming rules for active planning docs.

Track ID prefixes and band/queue values are enforced by
[`check_docs.py`](../check_docs.py) through the Project Control Plane checks.
The retired-vocabulary scan remains future work until the numbered GDD chapter
rewrites remove or quarantine old milestone language.

## Status Vocabulary

Use the governance status labels exactly:

| Label | Use |
|---|---|
| Implemented | Built and verified for the stated scope. |
| Pending validation | Built or planned enough to need manual/live evidence. |
| Known issue | Confirmed defect, contradiction, or evidence gap. |
| Target design | Ratified design that has not been built for the stated scope. |
| Planned | Intended work that still needs build planning or execution. |
| Deferred | Deliberately out of the active build path. |
| Open decision | Requires owner input or unresolved design choice. |
| Historical | Historical record only. |
| Superseded | Replaced by a newer source. |

Status-bearing sections must also follow the governance ban on the three
prohibited status words named in `documentation_governance_2026-06-13.md`.

## Track ID Prefixes

| Prefix | Queue | Naming rule |
|---|---|---|
| `B0-` | Scope, rewrite, and tracking setup | Use for control-plane, GDD rewrite, vocabulary, role, and feature-index wiring. |
| `B1-` | Determinism and save gate | Use for Package A, F1, save codec, campaign/save, suspend, and save-owned rules. |
| `B2-` | Shared authoring/runtime contracts | Use for registries, actions/effects, resource ledger, occupancy, death lifecycle, projection, and load seams. |
| `B3-` | Core authoring foundations | Use for CampaignRules profiles, TCV, predicates, MET, PHB, text, stat registry, and pools. |
| `B4-` | Campaign loop vertical slice | Use for IEQ, PXP, map objects, convoy, shop, DCH, village, dialogue v1, recruit, difficulty/death mode, deployment. |
| `B5-` | Tactical v1 enrichment | Use for conditions, skills, Source+Style, action grants, secondary movement, AI composition, minimum scorer, utility staves. |
| `B6-` | V1-lean/stretch packs | Use for campaign sharing/export/import, rescue/carry, fog, destructibles, relationship minimum, prep progression, map readability, input, web debug, v1-support tooling. |
| `B7-` | Optional after stable core | Use for arena, battalions, stationary weapons, forging, PvP, advanced AI valuation. |
| `B8-` | Post-v1 / parked | Use for side activities, public builder, content resync, remote play, Laguz, Awakening, hex, perception, ML, Vision Pro. |
| `VAL-` | Validation queue | Use for live verify, playtest rerun, fixture gaps, and evidence reconciliation. |
| `REL-` | Release gate queue | Use for branch/package/public-release gates. |
| `CLEAN-` | Cleanup queue | Use for debug-aid removal and stale-doc cleanup. |
| `CONTENT-` | Content queue | Use for v1 campaign content and post-v1 corpus/supplement content. |
| `POLISH-` | Polish queue | Use for art/audio polish. |
| `UI-` | UI queue outside a dependency band | Use only for UI backlog that is not clearly a Band 6 input/accessibility row. |

Do not introduce new Track ID prefixes until this manifest and the Project
Control Plane enforcement check both know the prefix.

## Dependency Band Names

| Band | Preferred name | Short meaning |
|---|---|---|
| Band 0 | Scope and tracking | GDD/control-plane setup before the rewrite. |
| Band 1 | Determinism and save gate | Package A, F1, SaveCodec, campaign/save envelope. |
| Band 2 | Shared authoring/runtime contracts | Shared APIs that prevent feature-specific forks. |
| Band 3 | Core authoring foundations | Variables, predicates, events, panels, text, stats, resources. |
| Band 4 | Campaign loop vertical slice | One short campaign loop from map to prep to next map. |
| Band 5 | Tactical v1 enrichment | Tactical systems needed for varied v1 maps. |
| Band 6 | V1-lean/stretch packs | Valuable v1-adjacent work after Bands 1-5 prerequisites. |
| Band 7 | Optional after stable core | Extra systems after the campaign loop can absorb permutations. |
| Band 8 | Post-v1 / parked | Later or parked work. |

## Preferred Terms

| Preferred term | Use instead of | Notes |
|---|---|---|
| Project Control Plane | giant GDD, mega roadmap, master checklist | One row-per-work-item tracker. |
| Build guide | roadmap as source of all detail | `GDD_10` becomes narrative and next-work guide. |
| Track ID | item id, task id, ticket id | Stable control-plane identifier. |
| Dependency band | milestone sequence, Phase 3 bucket | Bands describe build dependencies, not calendar dates. |
| V1-core | everything firmed | Bands 1-5. |
| V1-lean/stretch | loose stretch | Band 6; campaign sharing/exporting is still a v1 owner decision. |
| Post-v1 / parked | future maybe, later bucket | Band 8. |
| Self-contained campaign package | campaign overlay, base-plus-overlay | Campaigns load as independent packs. |
| Campaign sharing/export/import | campaign packaging only, content-pack compatibility | V1 row after campaign/save spine; public compatibility/resync is later. |
| Side activities | mini-game module seam | ActivityRunner/templates/public scripting are parked. |
| ActivityRunner | arbitrary mini-game module | Use only for the future shared activity runtime. |
| Open registry | enum plus match, closed type switch | Required for author-facing vocabularies that grow with content. |
| Action/effect primitive | separate MET/DLG/SAC/STY runners | One mutation path for authored commands/actions/effects. |
| Resource ledger | ad hoc gold/resource edits | One transaction API for costs, refunds, wallets, and resources. |
| Occupancy transaction | direct spawn/move placement | One placement API for blocked tiles and rollback. |
| Death lifecycle funnel | direct `take_damage` death side effects | Every death cause routes through one death context. |
| Projection service | preview-only clone logic | One no-mutation dry-run path. |
| Source + Style | combat art fork, weapon art fork | Unified combat-action model. |
| PHB panel | prep/on-map service panel | Shared option-panel framework. |
| MET | map events/triggers | Use the acronym only after first expansion in new prose. |
| TCV | typed campaign-variable store | Use the acronym only after first expansion in new prose. |
| REQ | requirement/predicate system | Use the acronym only after first expansion in new prose. |

## Retired Or Limited Terms

| Term | Replacement | Rule |
|---|---|---|
| Phase 3 Post-Awakening | Dependency bands or a specific Track ID | Retire as active schedule language. |
| M8-M13 implementation order | Band narrative and Track IDs | Keep old milestone detail only as historical source detail. |
| "All other registers remain OPEN" | Link to `AGENT/Docs/REGISTERS.md` | Delete during `GDD_10` rewrite. |
| mini-game module seam | Side activities / ActivityRunner | Split runtime seam, templates, and public scripting VM. |
| campaign overlay | Self-contained campaign package | The overlay model was superseded. |
| wander area | prep hub / PHB panels | Owner decided no wander area for v1. |
| all handbook/Awakening content as v1 | `CONTENT-V1` and `CONTENT-POSTV1` | Split short-campaign content from post-v1 corpus/supplement content. |
| one giant GDD | Project Control Plane plus GDD chapters | The control plane owns rows; chapters own design contracts. |
| roadmap owner for every detail | build guide | `GDD_10` links to tracker rows and source docs. |
| arbitrary public scripting VM | public scripting VM | Keep parked behind first-party activity evidence and trust policy. |

## Naming Rules

| Item | Rule |
|---|---|
| Track IDs | Uppercase prefix, hyphen, uppercase slug. Examples: `B1-F1`, `B4-IEQ`, `VAL-V021-12`, `REL-LEG`. |
| Band references | Use `Band N` on first use in prose; table cells may use `N` only in the Project Control Plane band column. |
| Queue names | Use `Validation`, `Release gate`, `Cleanup`, `Content`, `Polish`, or `UI` exactly. |
| GDD file references | Use numbered filenames: `GDD_01_Architecture.md`, not "architecture doc." |
| Register references | Use the register id when useful, such as `[TCV-1..6]`, and link the register file when the row needs source authority. |
| Source docs | Prefer repo-relative paths in code spans or Markdown links. |
| Acronyms | Expand on first use in rewritten GDD prose unless the acronym is in a table headed by source IDs. |

## Author-Facing Vocabulary Families

These families must use open registries or data-driven manifests when built.
Closed enums plus engine `match` branches need an explicit engine-only exception.

| Family | Preferred registry language | Related Track ID |
|---|---|---|
| Objective conditions | Objective predicate/action registry | `B3-REQ`, `B3-MET` |
| AI profiles/presets | AI spec/profile registry | `B5-AI-COMPOSITION` |
| Map objects/activation types | Map object component registry | `B4-MAP-OBJECTS` |
| Panels/services | PHB panel registry | `B3-PHB` |
| Effects/actions | Action/effect registry | `B2-ACTION-EFFECT` |
| Stat names | Stat registry | `B3-STAT-REGISTRY` |
| Movement types | Movement type registry | `B3-MOVEMENT-VULN-REGISTRY` |
| Vulnerability groups | Vulnerability group registry | `B3-MOVEMENT-VULN-REGISTRY` |
| Resource types | Resource registry | `B3-RESOURCE-POOLS`, `B2-RESOURCE-LEDGER` |
| Difficulty profiles | Difficulty/rule profile registry | `B3-CAMPAIGN-RULES`, `B4-DIFFICULTY-DEATHMODE` |
| Predicates/terms | Requirement/predicate term registry | `B3-REQ` |
| Activities | Activity registry | `B8-ACTIVITIES` |

## Enforcement Status

| Check | State | Reads | Rule |
|---|---|---|---|
| Track ID pattern and prefix | Enforced | Project Control Plane; prefix list mirrors this manifest | Track IDs must use an allowed prefix and uppercase slug. |
| Band vocabulary | Enforced | Project Control Plane, this manifest | Band/queue values must match the allowed names. |
| Retired vocabulary scan | Backlog | This manifest, active docs | Retired terms fail outside Historical/Superseded sections or quoted historical notes. |
| Registry discipline | Backlog | Project Control Plane, this manifest | Author-facing vocabulary work needs a registry impact note or exception. |
