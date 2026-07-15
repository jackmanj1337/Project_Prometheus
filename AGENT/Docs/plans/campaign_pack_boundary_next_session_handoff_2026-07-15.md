---
Type: plan
Status: Implemented - archive storage/import/export pipeline landed
Last verified: 2026-07-15
---

# Campaign Pack Boundary - Next-Session Handoff

## Resume point

- Branch/worktree: `agent/codex/2026-07-15/prep-save-followup` in
  `Project_Prometheus_prep_save`.
- Read the latest session note, the boundary/delivery plan, and the existing B6
  archive handoff before editing.
- Archive slices 1-2 are implemented: concrete Tier-2 validators and pure hostile
  ZIP preflight. Preflight deliberately performs no extraction, installed-state
  write, source activation, selector mutation, campaign start, or save write.
- The branch also contains the implemented campaign save spine, ledger Phases
  0-2, Prep deployment/manual save, and the Proving Grounds test entry.

## Locked ownership rule

Packs contain indexed authored data and approved media. The engine owns code,
runtime behavior, validation, installation/activation, UI, settings, and saves.
Do not accept pack GDScript, save-shaped JSON, or unindexed structured files.
Do not make archive installation select or launch content.

## Implemented unit

Implemented B6 archive slice 3: rollback-safe staged installation.

1. Add a non-autoload package installer/service consuming a successful
   `CampaignArchivePreflight` result.
2. Create a unique service-owned staging directory under the campaign-pack
   storage area; never extract directly into the final destination.
3. Extract only the paths admitted by preflight.
4. Validate the staged filesystem again using `PackManifest`, `Tier2Catalogue`,
   `CampaignTier2Validators`, cross-reference checks, and `AssetResolver`.
5. Derive the final destination from validated manifest identity, not archive
   filenames or caller-provided paths.
6. Reject an existing `{id, version}`. Do not overwrite, merge, or invent a
   replacement policy.
7. Atomically promote staging into the installed-pack directory.
8. On every failure, remove staging and leave installed bytes, active content,
   selector state, and saves unchanged.

## Required tests

- Valid fixture installs exactly once under the validated identity.
- Invalid archive and invalid second-pass tree create no installed directory.
- Simulated extraction, validation, and promotion failures clean staging.
- Existing-version rejection preserves every prior byte.
- Missing optional media returns a repair report; missing required content
  rejects installation.
- Import does not call campaign-source selection, change selector entries, start
  a campaign, or write any save/suspend file.
- Paths outside service-owned staging/final roots are never written.

Run focused tests first, then:

```bash
python3 AGENT/Docs/check_docs.py
bash scripts/ci/check_rng_usage.sh
bash run_tests.sh
git diff --check
```

## Stop conditions

Stop and request an owner decision if the slice requires overwriting an installed
version, choosing a player-facing global archive-size policy, defining new
compatibility semantics, or activating installed content. Those decisions are
outside transactional installation.

## After archive storage

Deterministic export and round-trip validation are implemented. Return to the
delivery plan for installed-pack discovery/selection, then the remaining
persistence unification, live Prep validation, and campaign presentation work
according to owner priority.
