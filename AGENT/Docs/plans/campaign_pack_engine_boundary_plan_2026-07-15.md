---
Type: plan
Status: Planned - ownership boundary ratified; implementation split by track
Last verified: 2026-07-15
---

# Campaign Pack / Engine Boundary And Delivery Plan

## Outcome

Campaign packs are portable authored data and approved media. The engine owns
all executable behavior, validation, runtime state, persistence, package
transactions, and player-facing surfaces. A shared campaign must never require
or execute pack-supplied GDScript.

## Campaign-pack ownership

A finished pack may contain:

- `manifest.json`: durable pack id/version, package format version,
  builder-content compatibility, and optional lineage;
- `data/catalogue.json`: the authoritative Tier-2 document index;
- campaign graphs and nodes, including map bindings and authored deployment
  constraints;
- map registry rows, map grids, start positions, objectives, placements, and
  supported authored events/dialogue;
- starting rosters and authored unit state;
- classes, weapons, items, skills, terrain, and later registered content
  families;
- pack-scoped Tier-1 PNG, TTF/OTF, OGG, and WAV media; and
- authored default/recommended/required rule-profile references once that
  contract exists.

Pack data may select a registered engine behavior by durable id. It may not
define executable behavior, replace an engine service, write saves, activate
itself, or modify global settings.

## Engine ownership

The engine retains:

- movement, pathfinding, combat, RNG, turns, factions, AI, objectives,
  deployment validation, and every other executable rule;
- runtime services and mutation boundaries (`GameState`, `CampaignManager`,
  `DataManager`, `SaveManager`, registries, ledgers, resolvers, and handlers);
- Retry, Suspend, Rewind, autosaves, manual slots, migrations, and all live or
  durable player state;
- menus, package discovery/selection, Prep, results, map UI, settings, and
  service panels;
- archive inspection, validation, installation, export, rollback, activation,
  and optional-media repair; and
- application settings such as display, audio, controls, input prompts, and
  accessibility.

Campaign rules cross the boundary in a controlled way: the engine defines and
executes each rule field; a pack may eventually name a default or allowed
profile; the player's resolved values live in the campaign save and are the
runtime source of truth.

Saves are never pack content. A save may reference durable pack/content ids,
but import/export must exclude campaign slots, suspend state, ledgers, settings,
and other user state.

## Repository state

`Project_Prometheus_Campaign_Pack_0` is currently a loose source-asset holding
area (0x72, EverRogue, Kenney, DB32, MiniWorld/Puny World). It is not yet a
valid package: it lacks the manifest, catalogue, campaign graph, normalized
content, and licensing inventory. Windows `Zone.Identifier` sidecars must not
enter a pack artifact.

`Project_Prometheus_Campaign_Pack_FE` currently contains only its README. Its
intended Fire-Emblem-inspired content requires per-asset provenance and explicit
distribution permission; resemblance to an existing game is not evidence of a
reusable license.

The first implemented portable Tier-2 validator set is deliberately minimal:
`campaign`, `map_registry`, `map_data`, `roster`, and `class`. Add weapons,
items, skills, terrain, events, dialogue, and other families only alongside
their real runtime parser, cross-reference validation, and focused fixtures.

## Delivery sequence

### Milestone 1 - save reliability (`B1-LEDGER`)

1. Collapse the special suspend file into the unified slot namespace.
2. Add `origin: manual|auto` and persist the complete ledger in suspend slots.
3. Add author-tunable manual/autosave pools and registry-backed autosave
   triggers, structurally preventing autosaves from overwriting manual slots.
4. Add the durable-mid-map policy warning and its documentation check.
5. Expose player-spendable Rewind over ledger checkpoints, choose one
   authoritative charge field, and discard the abandoned future after restore.

Each slice must preserve old-save defaults, transactional writes, deterministic
RNG restoration, and whole-party/board rollback coverage.

### Milestone 2 - Prep validation (`B4-PREP-DEPLOYMENT`)

Run the outstanding Windows/editor pass for keyboard, mouse, and gamepad focus,
long-roster scrolling, required-unit locking, deployment caps, and text fit.
Keep convoy/trade/shop panels under `B3-PHB`; they do not widen the deployment
or save slice.

### Milestone 3 - safe package storage (`B6-CAMPAIGN-SHARING`)

1. Extract a preflighted ZIP to unique staging.
2. Validate the staged tree again through the manifest, catalogue, concrete
   validators, cross-references, and asset resolver.
3. Atomically promote a valid tree; reject an existing `{id, version}` by
   default; remove staging and preserve installed bytes on every failure.
4. Export only admitted files in deterministic lexical order, exclude all user
   state/caches, and re-preflight the artifact.
5. Prove deterministic export/import round-trip behavior.

The detailed slice contract remains
[`b6_campaign_archive_pipeline_handoff_2026-07-15.md`](b6_campaign_archive_pipeline_handoff_2026-07-15.md).

### Milestone 4 - discovery and selection (`B6-CAMPAIGN-SHARING`)

Discover installed packs, cache validated summaries, present them in New Game,
activate the selected source only through `DataManager`, and persist the selected
pack identity in campaign saves. Then add branch-node choice and `[CST-6]`
single-map auto-wrap. Installation remains inert: it must never select or launch
a campaign.

### Milestone 5 - campaign presentation and services

Build the dedicated results screen with rewards, casualties, progression, save
status, and successor/branch choice. Preserve validate-before-commit campaign
advancement. Add Prep service panels later through their owning `B3-PHB` slices.

## Definition of done

- Packs contain only indexed authored data and approved media.
- The engine is the only executable authority and the only owner of saves.
- Suspend, manual, and automatic persistence share safe transactional slots.
- A hostile package cannot escape staging or mutate installed/runtime/save state.
- A valid package round-trips deterministically and remains inert until selected.
- The player can select a pack, run its campaign, save/load it, and advance
  through Prep and results without content-source ambiguity.

