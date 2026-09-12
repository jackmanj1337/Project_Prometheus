# Session Note - 2026-09-03

## Branch context

- Branch: `agent/from-integration/v0715-return-root-cause-review`, then
  `agent/from-integration/session89-pack-content-unmerged`, then `agent/integration`
- Base branch: `agent/integration`
- Base SHA: `660c07e9`, then `463d2025`
- Coordination Work ID: `V0715-RETURN-ROOT-CAUSE-REVIEW-2026-09-02`,
  `SESSION89-PACK-CONTENT-UNMERGED-2026-09-03`,
  `V0715-PHASE-BANNER-COORDINATE-LIFECYCLE-2026-09-03`,
  `V0715-MIGRATION-FIXTURE-REAL-DELTA-2026-09-03`,
  `V0715-EXPECTED-SAVE-DIAGNOSTIC-SEVERITY-2026-09-03`

The session started as a review of the existing v0.7.15 return analysis and a decision
about what to do with it. The owner took the walkthrough, ratified all six choices, and
then asked for everything needed to leave the next session able to finish the fixes.

## The red baseline was not a defect

The review branch carried a note that it could not pass the push gate because the
repository baseline was red on `test_session8_pack_proof` and `test_session9_pack_proof`.
It was committed locally instead. That assessment was wrong, and the cost of it was a
whole review sitting unmerged.

Both suites resolve authored content from the sibling checkout at
`Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds` via
`scripts/tests/support/adopter_pack.gd`. That checkout sat on `main` at `af5525b`, five
commits behind `origin/agent/staging-area` at `3415dd4`. The content both proofs assert
on — `proving_venom`, `proving_drowse`, `proving_ward`, `proving_pulse`, the tick sources
and the compositions — was authored **after** `main` was last accepted and exists only on
the pack line's staging-area.

`git merge --ff-only origin/agent/staging-area` in the pack repo turned both suites green,
15/15 and 5/5, with zero engine edits. The full exact-HEAD gate then passed on tree
`b5d6c60f` and the review merged to `agent/integration` at `463d2025`.

**What made this expensive is that the suites printed no error text at all** — twelve and
three bare `FAIL` lines that read exactly like an engine regression. `check_pack_freshness`
in the push gate *does* print the branch (`[on 'agent/staging-area', not 'main' -- UNMERGED
content]`), but only on a push, which is the thing that was never reached.

### The fix

`AdopterPack.require_entries(pack_path, required_entry_ids)` reads the pack's
`data/catalogue.json` and asserts the declared ids **before** the first check runs. Both
proofs now name the ids they cannot run without and fail once, with a message that says the
directory is present, that this is content rather than a missing checkout, that the pack
repo is probably on a branch predating the content, and where to read the branch.

Verified in **both** directions, per the pack-freshness lesson: 15/15 and 5/5 on correct
content, and on a deliberately reverted checkout one actionable line instead of twelve
silent failures.

This extends the existing `FOUND` / `MISSING` / `ABSENT` rule rather than replacing it.
`locate()` answers a question about directories; `FOUND` was never enough, because a
directory that exists can still be the wrong content.

## The phase banner had no test at all

The review's V0715-01 notes it plainly: the August width fix for `[V070-09]` shipped,
regressed at another scale, and the 159-suite gate had nothing to say about it either
time. `scripts/tests/test_phase_banner.gd` now exists — eight cases covering width
derivation, tween ownership, overlapping animations, an animation starting from the
offscreen edge, and the settled state after the full 1.4s sequence.

**Two cases deliberately pin the current state and say so in their own assertion text** —
that the banner stores no tween handle and has no completion reset. They must be inverted
when V0715-01 lands. A test that silently blessed the defect would be worse than no test.

**The suite does not attempt the fullscreen coordinate defect.** That is a
logical-versus-physical conversion on a root `CanvasLayer`; Playwright could not reproduce
it either, and the row requires a native instrumented run first. Asserting the current
logical geometry would produce a green test on a build the tester has already rejected —
which is precisely the trap V0715-03 documents, where a containment assertion passed on an
unreadable screen. The width cases here assert only what holds in every coordinate space.

### A negative result the next session needs

**The 1.4s settle case passes in a bare headless tree.** The tween completes and the panel
leaves the visible area. Together with the review's failed Playwright attempt, that means
the persistence defect is not reproducible in a plain scene — it needs the resumed-load
path specifically. That narrows where to look: `start_map_from_suspend()` and the state of
the tree during restore, not the banner's animation in isolation.

`PROMETHEUS_BANNER_TRACE=1` now prints one line per phase signal and per animation
boundary, carrying visibility, panel geometry, viewport transform and the phase signal —
the four things the row asks for — plus `tree_paused`, which is the leading mechanism
candidate and the reason it is in there. Inert unless the variable is set; delete it when
V0715-01 lands.

The trace's only `finished` handler is the trace itself, deliberately. Adding a real one
would *be* the lifecycle fix, and that has to follow the measurement rather than precede it.

## The migration ruling

The review left one question open: whether runtime unit IDs map to stable destination
identities, or are save-owned pass-through values validated with their owning map. It
framed this as a product choice. Reading the code shows it is not one.

`CampaignPackRegistry.gd:119-142` builds `content_ids["unit"]` **exclusively** from
documents whose entry kind is `roster`. Enemy units are not roster entries — they are
defined inline in map data as `enemy_placements[].unit`. Nothing adds those to
`content_ids["unit"]`, and there is no `units` family in `RegistryCatalog` at all. The
registry-identity option was never available: it would mean inventing a family or
duplicating every map's enemies into rosters purely to satisfy a validator.

The returned save shows the split exactly. `alden` and `mira` are in both `roster.units`
and `map_runtime.units` and resolved fine; `red_02_a/b/c` are in `map_runtime.units` only
and produced `migration_destination_missing`.

The actual bug is a category error in the path table: `SaveMigrationService.gd:13` maps
`roster.units[].unit_id` to family `unit` and `:24` maps `map_runtime.units[].unit_id` to
the same family. One family covering two different kinds of thing.

Ruled: **partition on ownership.** Units present in `roster.units` keep full alias mapping
and destination validation, because a renamed `alden` must still be caught. Units absent
from it are map-owned instances validated against the destination map's placements — the
save carries `map_runtime.map_id`, so once the map reference is aliased the check has
somewhere to look. A blanket pass-through classification was explicitly rejected: it would
stop catching genuine roster renames, which is what migration exists for.

This also shrinks V0715-05. Four of the eight `push_error` lines in the returned log are
these destination-missing diagnostics — a correct state reported as an engine fault. They
disappear at the source when V0715-02 lands, which is an argument for keeping the existing
sequencing rather than merging the two rows.

## Tracker

The row the review said held its findings, `V0715-RETURN-ROOT-CAUSE-REVIEW-2026-09-02`,
**did** exist — an early read of a stale local `tasks.json` said otherwise. The registration
attempt was refused by the claim guard, which is what surfaced the truth. The documented
trap, hit again: tracker mutations go straight to origin and a clean `git status` says
nothing about whether the local file is current.

Most findings landed on rows that **already own the relevant files**, so creating parallel
rows would have been refused by the claim guard and correctly so. Three new rows plus the
unblock row; five existing owners updated with the finding and its ratified direction;
`WINDOWS-PASS-READINESS-2026-08-20` now depends on all ten. Both original dependencies were
preserved and read back afterwards, because `--depends-on` replaces without a guard.

`check_tasks.py --github` and `gen_active_work.py --check` both exit 0.

## Left for next session

[`v0715_remediation_handoff_2026-09-03.md`](../Docs/plans/v0715_remediation_handoff_2026-09-03.md)
carries the execution order. Nothing in it waits on an owner: all six walkthrough
questions plus the migration ruling are answered.

The one thing that cannot be done in this container is the native instrumented run for
V0715-01. The instrumentation is in place and inert, so that run is now a matter of
setting one environment variable on a Windows host.
