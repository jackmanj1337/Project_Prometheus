# Pillar 1 — Code Review (2026-08-09)

Procedure: `AGENT/Review Procedures/01_Code_Pillar.md`

Audited snapshot: `agent/integration` at
`41c0e5fc1116a9a01aed3afc48dbc92f021d018d`

Prior report: `AGENT/Code Reviews/code_review_2026-07-15.md`

**Score:** 6/10

## Executive summary

The runtime has improved substantially since July: package activation commits whole
catalogues rather than overlays, objective/item/skill extensibility now routes through
registries, gameplay randomness remains event-scoped, and the reviewed combat, terrain,
fog, crossing, responsive-layout and text-entry seams are well factored and typed. The
green 135-suite baseline and a clean whole-scope `gdlint` pass support those positives.

Two correctness gaps keep the pillar at 6/10. Campaign resume still changes the active
content package before all later rejection points, contradicting its own transactional
claim. Separately, the one-time user-data migration writes its permanent completion
marker even after a copy error; a transient failure can therefore strand some legacy
saves, settings, packs or status records from all future automatic attempts. Both exact
implementations are present unchanged in the frozen v0.7.1 candidate.

## Issues

### High — Failed campaign resume can leave a different content package active

**File and line:** `scripts/autoloads/GameState.gd:1048-1087`,
`scripts/autoloads/DataManager.gd:138-163`,
`scripts/autoloads/CampaignManager.gd:767-847`.

**Problem:** `configure_campaign_resume()` claims every rejecting check precedes live
state writes, but `_activate_saved_campaign_source()` runs at line 1057. Successful
activation replaces the live catalogues and registry candidate. The function can then
return `false` because `CampaignManager` is absent, convoy entries do not resolve,
mutable/override dictionaries are malformed, or the campaign envelope fails. None of
those paths restores the previously active content. `CampaignManager` stages its own
fields before lines 838-846, but that local discipline does not roll back the earlier
package switch.

**Root cause:** validation needs the saved catalogue, while package selection and
campaign restoration have separate commit boundaries. The resume path neither builds a
non-mutating content candidate nor captures/restores the prior `ContentSession`.

**Impact:** a failed Continue/Load can report failure while subsequent menus and saves
silently use a different class, item, map, terrain and authored-registry set.

**Recommended fix:** validate the complete resume against a non-live content/registry
candidate and commit once. As a bounded first repair, capture the complete previous
session and restore it on every post-activation rejection. Add a package-backed test
that fails after activation and asserts package identity, catalogue lookups, registry
ids and campaign position are unchanged.

**Tradeoffs:** a staged resume object is more code, but makes the existing contract
explicit and reusable. Rollback is smaller but every new rejection path must remember it.

**Classification:** recurring/partially fixed from the 2026-07-15 High finding; no
specific existing tracker row was found in the locally available canonical-task view.
The exact `GameState.gd` blob is also in frozen candidate `0db30fd1`, so this **affects
the frozen v0.7.1 candidate** and belongs in the final audit's proposed release intake.

### High — A transient legacy-data copy failure is permanently marked complete

**File and line:** `scripts/shared/UserDataMigration.gd:39-71`,
`scripts/shared/UserDataMigration.gd:85-114`.

**Problem:** `run()` records individual copy failures in `report["errors"]`, then
unconditionally writes `.legacy_user_data_migrated`. Every later launch exits at the
marker check. A partial directory is worse: the next attempt would skip any destination
that now exists, even if only some of its files arrived. The tests prove successful
nested/binary copies and marker idempotence, but do not inject a write failure or assert
retry behavior (`scripts/tests/test_user_data_migration.gd:58-108`).

**Root cause:** the marker means both “migration fully resolved” and “migration was
attempted.” Copying directly into final directories also provides no complete-tree
promotion boundary.

**Impact:** a full disk, permission problem, interrupted write or other transient error
on the first renamed build can make legacy saves, settings, installed packs or campaign
status appear missing forever. The source directory is deliberately retained, so this
is recoverable by hand rather than physical deletion, but the game never retries or
explains the recovery.

**Recommended fix:** copy each root into a sibling temporary path, promote it only after
the complete root succeeds, and write the global marker only when every present legacy
root is either copied or deliberately skipped because a pre-existing complete target
wins. Preserve an explicit retryable error state and test failure between nested files.

**Tradeoffs:** staging temporarily doubles the migrated root's disk use. A per-root
completion ledger is more complex but permits progress without confusing partial output
with a user-owned pre-existing target.

**Classification:** newly scoped (the rename landed after the July audit) and currently
represented only by the completed implementation row
`IMPL-IDENTITY-RENAME-USERDATA-2026-08-02`, whose recorded verification covers success
and no-clobber behavior, not failure recovery. The exact runtime blob is also in frozen
candidate `0db30fd1`, so this **affects the frozen v0.7.1 candidate**.

## Positive observations

- `DataManager` commits one complete `ContentSession`; two installed packs may legally
  reuse content ids without a merged-catalogue collision.
- Objective conditions, item effects and skill effects now resolve through registered
  handlers. This closes July's closed-vocabulary finding without another content enum.
- `CampaignManager.restore_campaign_state()` validates campaign/node/cleared-node/flag
  and variable shapes before writing its own state (`scripts/autoloads/CampaignManager.gd:767-847`).
- `SkillHandler` consumes event-owned RNG and suppresses counter writes during previews;
  no raw gameplay RNG call was found in the whole non-test script scan
  (`scripts/skills/SkillHandler.gd:113-185`).
- `FileDialogInputGuard` funnels four platform-dependent Escape stages through one
  synchronous transition and records which stage won, making the remaining Windows
  uncertainty observable (`scripts/ui/FileDialogInputGuard.gd:40-129`).
- The remaining UI/unit/item/skill/shared/asset scope passes `gdlint`, and its few
  `_process()` loops are input-repeat, transition, or reflow owners rather than large
  per-frame catalogue/grid scans.

## Architectural observations

- Large orchestration owners remain concentrated in `MapCursor`, `GameState`,
  `TurnManager`, `Unit`, `SettingsScreen` and `UnitDetailsScreen`. The newer helper,
  registry and service seams are the right direction; keep new behavior out of those
  coordinators where a bounded owner already exists.
- The resume defect is a transaction-coordination problem, not evidence against the
  existing `SaveData` / `SaveCodec` / `SaveManager` / `GameState` separation.
- The migration defect shows a recurring repository pattern: successful-path
  verification is broad, while filesystem failure injection remains thin. Pillar 4's
  report independently found a stale destructive migration tool; the rollup should
  reconcile the shared transactional-tooling theme without merging the two findings.

## Prioritized action plan

1. Make package-backed campaign resume validate-then-commit (or restore the full prior
   content session on every late failure) and add the late-rejection regression.
2. Make legacy user-data migration retryable and root-transactional; test a failure
   between nested file writes before accepting v0.7.1.
3. Continue extracting bounded services from the six largest runtime coordinators as
   those areas next change; do not perform a size-only rewrite.

## Delta vs. the 2026-07-15 review

- **Fixed:** outer campaign/save artifact budgets are checked before whole-file reads.
- **Fixed:** campaign-pack, campaign-status and portable-save exports use staged
  promotion/rollback rather than deleting or truncating the prior artifact first.
- **Fixed:** objective and item dispatch joined open registries; skill effects now use
  the same author-extensible direction.
- **Partially fixed / recurring:** malformed mutable state is staged earlier, but package
  activation still precedes several rejection points, leaving the July resume finding
  open in a narrower but still High form.
- **Newly introduced:** the one-shot legacy migration arrived with the application-name
  change after the July snapshot and has no retry contract after a partial failure.
- **No regression found:** one-active-pack replacement, deterministic gameplay RNG,
  magical-damage selection, EXP-faction enforcement, and typed-array adaptation remain
  intact at the pinned snapshot.

## Review sample and verification

- Session 3 enumerated every non-test `scripts/**/*.gd` file and traced autoloads,
  content activation, registries, campaigns, saves, battle state, maps/objectives and
  combat/RNG at the pinned SHA.
- Session 4 completed `scripts/ui/**`, `scripts/ui/text_entry/**`, `scripts/ui/prep/**`,
  `scripts/units/**`, `scripts/items/**`, `scripts/skills/**`, `scripts/shared/**` and
  `scripts/assets/**`; it also finished the named cursor, AI, grid, camera, fog, terrain,
  overlay, sprite-resolution and smaller service/resource paths from the checkpoint.
- Static spot checks covered setters, raw RNG, typed-array writes, signal lifecycles,
  per-frame callbacks, error/TODO markers and public typing. `gdlint` reported
  `Success: no problems found` over the entire Session 4 directory set.
- Falsifiable candidate comparison used Git blobs, not ancestry assumptions: both
  finding files are byte-identical between the pinned snapshot and `0db30fd1`.
- The supplied Session 1 baseline remains authoritative: documentation 43/43 and all
  135 suites passed. The general suite was not rerun, as required by the pillar procedure.

## Procedure friction

- The requested Godot analyzer autoload tool was not exposed. Filesystem wiring and the
  supplied green headless baseline covered parser/autoload failures.
- The procedure asks for an exhaustive single pass, while the approved multi-session
  handoff split Pillar 1 in two. The committed checkpoint made the boundary durable.
- The prior-report glob includes checkpoints and specialized release-delta reports;
  semantic purpose still has to outrank lexical filename order.
- Pillar 1 says it has a pillar-specific scoring rubric, but defines none beyond the
  master bands. This report uses the master rubric.
