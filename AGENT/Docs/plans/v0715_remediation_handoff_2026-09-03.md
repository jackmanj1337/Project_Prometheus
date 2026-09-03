---
Role: dated
Type: plan
Status: Active — the work order for the v0.7.15 replacement round
Last verified: 2026-09-03
---

# v0.7.15 remediation work order

Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)

The v0.7.15 Windows return was triaged and the candidate **rejected**. This is the
execution order for the replacement round. The findings and their root causes are in
`AGENT/Code Reviews/playtest_v0.7.15_root_cause_review_2026-09-02.md`; this document
does not restate them, it says what to do next and in what order.

Authority for state is `coordination/tasks.json`. Where this prose and the tracker
disagree, the tracker wins.

## What the owner ruled on 2026-09-03

All six walkthrough questions are answered, plus the one the review left open. There
are **no outstanding owner decisions** against this return.

1. **Round scope is all nine findings**, not a blockers-only recut.
2. **V0715-01 banner:** instrument a native resumed load *before* patching; centre on
   the **safe viewport**, not the playable map rect.
3. **V0715-06 modals:** a **shared modal stack owned by MainMenu**, not a local Load
   Game hide/reopen. No delay, no repeated `grab_focus()`.
4. **V0715-03 Compact Settings:** the tester's **vertical label-over-control rows**;
   a disclosed effective-scale cap is the fallback only.
5. **V0715-07/08:** one reusable manual-save replacement picker; free-roam Prep return
   gated on recorded navigation **origin**, not `_is_revisited_hub()`.
6. **V0715-04 and V0715-09 are in scope** rather than deferred.
7. **Runtime unit IDs (V0715-02) are save-owned pass-through values validated against
   their owning map** — see "The migration ruling" below.

## Done this session

**The review is landed.** Merged `--no-ff` to `agent/integration` at `463d2025`.

**The red baseline was not a defect.** `test_session8_pack_proof` (3/15) and
`test_session9_pack_proof` (2/5) failed because the sibling
`Project_Prometheus_Campaign_Pack_FE` checkout sat on `main`, five commits behind
`origin/agent/staging-area`, where the authored conditions and world effects actually
live. Fast-forwarding that checkout turned both green with zero engine edits and the
full 159-suite gate then passed. A previous session had recorded this as an
unpushable red baseline and committed locally instead.

`AdopterPack.require_entries()` now closes that hole: a pack directory that exists but
does not declare the ids a proof depends on fails **once**, with a message naming the
missing ids and telling the reader to check what branch the pack checkout is on.
Verified in both directions — 15/15 and 5/5 on correct content, one actionable line
instead of twelve bare `FAIL`s on stale content.

**`test_phase_banner.gd` exists.** Before it there was no phase-banner test at all,
which is why the August width fix regressed at another scale without the gate
noticing. Eight cases covering tween ownership, overlapping animations, the settled
state after the full 1.4s sequence, and width derivation.

Two of its cases deliberately pin the **current** state — that the banner stores no
tween handle and has no completion reset — and say in the assertion text that they
must be inverted when V0715-01 lands. They are a tripwire, not an endorsement.

**Banner instrumentation is in place and inert.** `PROMETHEUS_BANNER_TRACE=1` prints
one line per phase signal and animation boundary carrying the four things the row
asks for — visibility, panel geometry, viewport transform, phase signal — plus
`tree_paused`, which is the leading mechanism candidate. Delete it when V0715-01 lands.

## A negative result worth knowing before the native run

The new suite's 1.4s settle case **passes** in a bare headless tree: the tween
completes and the panel leaves the visible area. Combined with the review's failed
Playwright attempt, that means the persistence defect is **not** reproducible in a
plain scene — it needs the resumed-load path specifically.

Do not read that as evidence the defect is not real; the native screenshot and the
checklist are the evidence. Read it as narrowing where to look: something about
`start_map_from_suspend()` and the state of the tree during restore, not the banner's
animation in isolation. `tree_paused` is in the trace for exactly that reason.

## Execution order

Product work starts from current `agent/integration`, never from a playtest branch.

**0. Merge the unblock branch.** `agent/from-integration/session89-pack-content-unmerged`
is pushed with the full gate green. It carries the adopter diagnostic, the banner suite,
and the tracing. Merge it first so everything below inherits the tripwire.

**1. V0715-02 migration fixtures** (`V0715-MIGRATION-FIXTURE-REAL-DELTA-2026-09-03`).
Highest confidence of any finding, and it gates item 5. The ruling is settled — see below.

**2. V0715-06 nested modals** (`LOAD-GAME-EMPTY-PROFILE-ENTRY-2026-08-28`). Release
blocker, Playwright-reproduced, and the fix shape is decided.

**3. V0715-01 banner** (`V0715-PHASE-BANNER-COORDINATE-LIFECYCLE-2026-09-03`).
**Instrument the native run first.** The width defect and the persistence mechanism are
separate confidence levels and must not be patched as one change.

**4. V0715-03, -07, -08, -04, -09** on their existing owning rows. Independent of each
other; order by whoever is free.

**5. V0715-05 diagnostics** (`V0715-EXPECTED-SAVE-DIAGNOSTIC-SEVERITY-2026-09-03`).
**Only after item 1.** Re-measure the actual remaining diagnostic volume first — four of
the eight `push_error` lines disappear when item 1 lands, so this row may be much
smaller than the return suggested.

**6. Recut.** Do not repeat the passing dropdown, slider, backup/restore, renewal or
compatibility suites beyond regression smoke.

## The migration ruling, and why it is not a preference

The review left the runtime-unit-ID policy open. Reading the code closes it.

`CampaignPackRegistry.gd:119-142` builds `content_ids["unit"]` **exclusively** from
documents whose entry kind is `roster`. Enemy units are not roster entries — they are
defined inline inside map data, as `enemy_placements[].unit`, carrying their own
`unit_id` such as `red_02_a`.

Nothing adds those to `content_ids["unit"]`, and there is no `units` family in
`RegistryCatalog.REQUIRED_FAMILIES` or `OPTIONAL_FAMILIES` at all. So the
registry-identity option was never actually available: taking it would mean inventing
a family, or duplicating every map's enemies into rosters, purely to satisfy a
validator.

The returned save shows the split exactly — `alden` and `mira` are in both
`roster.units` and `map_runtime.units` and resolved; `red_02_a/b/c` are in
`map_runtime.units` only and produced `migration_destination_missing`.

The real bug is a category error in the path table: `SaveMigrationService.gd:13` maps
`roster.units[].unit_id` to family `unit`, and `:24` maps `map_runtime.units[].unit_id`
to the same family. One family, two different kinds of thing.

**Implement by partitioning on ownership.** Do *not* blanket-classify all of
`map_runtime.units[].unit_id` as pass-through — that would stop catching genuine roster
renames, which is what migration is for.

- **In `roster.units`** → full alias mapping and destination validation.
- **Not in `roster.units`** → map-owned instance. Validate against the *destination
  map's* placements. The save carries what that needs: `map_runtime.map_id` is
  `campaign-pack://v076_migration_fixture/1.0.0/skirmish_02`, so once the map reference
  is aliased, resolve that map's `enemy_placements[].unit.unit_id` set and check
  membership there.

That still catches a real defect — a pack that deletes an enemy from a map a suspend
save is sitting on — without demanding a registry entry the format does not have.

Cheaper fallback if scoped validation runs long: give map-only units a distinct family
such as `unit_instance` that validates as pass-through. It clears the blocker but
validates nothing. Take it as a schedule concession only, and record it if taken.

## Standing constraints

- Do not tag, promote, or cut another candidate while the round is open.
- Do not merge visually gated branches into the release line.
- The free-roam Proving Grounds archive is still reused build output from an unmerged
  pack branch. Whatever V0715-09 authors must be rebuildable from tracked sources —
  an acceptance map living only inside a `builds/` ZIP would recreate the defect that
  cost v0.7.13 its entire campaign section.
