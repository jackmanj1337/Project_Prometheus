---
Role: dated
Type: plan
Status: Active — the work order for the v0.7.17 round
Last verified: 2026-09-05
---

# v0.7.17 round work order — a bigger build, and a build that reports on itself

Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)

The v0.7.16 Windows return was triaged and the candidate **rejected**. Its findings and
root causes are in `AGENT/Code Reviews/playtest_v0.7.16_root_cause_review_2026-09-04.md`
and are not restated here. This document says what the next round contains, in what
order it is built, and — the part that is new — what the build must record about itself
so that the next return is decided by evidence the executable emitted rather than by
what the tester thought to write down.

Authority for state is `coordination/tasks.json`. Where this prose and the tracker
disagree, the tracker wins.

## Why this round is shaped differently

Three rounds in a row were decided by instrumentation, or lost for the want of it.

- **v0.7.15** could not close its only remaining defect because nothing in the build
  recorded the banner's geometry. The round ended with one open item and a request for a
  measurement.
- **v0.7.16** closed that defect in a day, because `PROMETHEUS_BANNER_TRACE` had been
  added for exactly one widget and produced 46 lines that made the arithmetic obvious.
  The same round then lost three sections to save failures whose exact causes were
  **already in the returned logs** — `training_sword not found`,
  `saved campaign fingerprint does not match installed content` — while the dialogs the
  tester actually read said only that something had failed.
- Every round so far has asked the tester to transcribe sentences, count error lines and
  eyeball whether a label was truncated. Those are measurements, and the executable is a
  better instrument than a person reading a screenshot.

The conclusion the owner drew on 2026-09-05: **stop spending tester attention on
observations the build can make itself.** A tester's scarce and irreplaceable
contribution is a real display, a real GPU, a real window manager and a human judgement
about whether the game is any good. Transcription is none of those.

This round therefore has two halves: the carried fixes, and a diagnostics programme that
turns most of the checklist's "record what you see" items into log records.

## The queue

Build in this order. `V0717-ROUND-PREP-2026-09-05` gates the candidate and depends on
every row above it.

| Order | Row | What it is |
|---:|---|---|
| — | `V0716-RETURN-FIXES-2026-09-05` | Merge the v0.7.16 UI repairs to `agent/integration`. Already built and green. |
| — | `V0710-MAIN-MENU-CLIPPING-2026-08-25` | Merge a 22-line Compact main-menu fix that has sat unmerged since 2026-08-25. |
| — | `PACK-FEATURE-COVERAGE-WARNINGS-2026-08-07` | Merge the pack feature-coverage warnings; `in_review` since 2026-08-08. |
| — | `LOAD-GAME-EMPTY-PROFILE-ENTRY-2026-08-28` | Already merged; owed a native pass in this round. |
| 1 | `DIAG-SESSION-CHANNEL-2026-09-05` | The diagnostics channel and session header. Everything else writes through it. |
| 2 | `DIAG-SAVE-PACK-LIFECYCLE-2026-09-05` | Save and pack lifecycle records, and refusals that name the missing content. |
| 3 | `DIAG-VIEWPORT-TRACE-2026-09-05` | Window, viewport and content-scale trace. |
| 4 | `DIAG-LAYOUT-AUDIT-2026-09-05` | Runtime layout self-audit. |
| 5 | `DIAG-BATTLE-CAMPAIGN-2026-09-05` | Battle and campaign telemetry. |
| 6 | `DIAG-RETURN-BUNDLE-2026-09-05` | One-action export of everything a return needs. |
| 7 | `V0717-CAMPAIGN-PLAYABILITY-2026-09-05` | Play chapters 1-5 headlessly before shipping them. |
| 8 | `V0717-ROUND-PREP-2026-09-05` | Cut the candidate, the pack and the checklist. |

## Part A — carried fixes

### A1. Merge the v0.7.16 UI repairs

`agent/from-integration/v0716-ui-return-fixes` carries V0716-01 (banner hidden by a
`visible` flag with tween ownership, plus V0716-06's vertical centring), V0716-04
(Compact label wrapping) and V0716-05 (the picker measured before it is centred). The
full suite is green on that branch — **166 suites, 0 failures**, including
`test_session8_pack_proof` and `test_session9_pack_proof`, which the v0.7.16 review had
recorded as an unrelated red baseline. That baseline is now clean; do not carry the
caveat forward.

The merge is this row's closeout.

### A2. The half of V0716-02 that was not built

The save gate was fixed: `save_slot()` now validates in the save's own catalogue instead
of whichever content session happens to be active. The review's *second, independent*
defect was not addressed — an import refusal still reads

> The imported save could not be stored in the selected slot.

and never names the content it could not resolve, although the log does. That work moves
into `DIAG-SAVE-PACK-LIFECYCLE-2026-09-05`, where it belongs: it is the same fact
reaching two audiences.

### A3. Two stale branches worth their merge

- `agent/from-integration/v0710-main-menu-clipping` — 22 lines, tested, unmerged since
  2026-08-25, and directly on this round's Compact theme. Note the row's `branch` field
  still points at the abandoned `agent/playtest-release-v0.7.13-fixes`; re-point it with
  `--branch` **and then re-run `check_tasks.py`**, because claimed paths resolve against
  the row's branch.
- `agent/from-integration/pack-feature-coverage-warnings` — warns when a pack marked
  complete exports content implying an engine feature it never exercises. Builder-facing
  rather than player-facing, which is why it has drifted; it is also exactly the class of
  thing the 2026-08-22 scope reassessment said stops mattering the moment it stops being
  adopted.

## Part B — the diagnostics programme

### The principles these six rows share

1. **A diagnostic exists to answer a question a return will ask.** Every record below is
   traceable to a specific observation someone had to make by hand in v0.7.15 or v0.7.16.
   Do not add records that answer no question; volume is not the goal.
2. **Bounded, never a storm.** V0715-05 was an error-storm defect and its fix must not be
   undone here. Expected states print at info severity, never `push_error`. Every category
   carries a per-session cap and a dedupe key, so a repeating record collapses to
   `event ... xN` instead of N lines. The in-memory ring stays bounded, as
   `TransitionTelemetry` already does with `MAX_RECORDS`.
3. **Follow the existing precedent rather than adding a parallel one.**
   `scripts/autoloads/TransitionTelemetry.gd` is already an EventBus-subscribing telemetry
   autoload with a bounded ring and an opt-in print policy keyed on
   `OS.is_debug_build()`. The channel generalises that; it does not sit beside it.
4. **Machine-readable first, human-readable anyway.** One line per record,
   `ts_ms | category | event | key=value ...`, greppable by eye and parseable by script.
5. **The player-facing string and the log record carry the same facts.** Where a refusal
   has a cause, the dialog says the cause. The log is not a place to hide the answer.

**One-in-one-out:** this is product code and tests of product behaviour, which the
`AGENTS.md` rule explicitly does not bind. The one mechanism actually retired is
`PROMETHEUS_BANNER_TRACE`, whose env var, launcher batch file and bespoke print calls are
absorbed into the `viewport` category and deleted.

### B1. `DIAG-SESSION-CHANNEL-2026-09-05` — the channel and the session header

A `DiagnosticsLog` autoload owning the record format, the category gates, the bounded
ring, and a file at `user://logs/diagnostics-<iso>-<pid>.log` written alongside Godot's
own log. Categories — `session`, `viewport`, `layout`, `nav`, `save`, `pack`, `battle`,
`campaign`, `ai`, `input` — gate independently, default on in a playtest build, and are
individually suppressible so a category can be silenced without a rebuild.

The session header is written once at boot and re-emitted whenever a mutable part of it
changes. It must carry, at minimum:

- **Build** — version, commit sha, export preset, debug/release, and the BUILD STAMP the
  exporter already bakes and verifies.
- **Platform** — OS name and version, CPU model, GPU adapter and driver version, physical
  memory, locale.
- **Display** — screen count; per screen its resolution, DPI, refresh rate and scale;
  which screen the window is on.
- **Window** — mode, size, position, borderless, vsync, and the whole content-scale
  configuration (`mode`, `aspect`, `content_scale_size`, `content_scale_factor`).
- **Settings** — a snapshot of every `SettingsManager` key and value, and a `settings`
  record on every subsequent change. Half the v0.7.16 checklist's Section 0 exists to
  make the tester put the build into a known state; this makes the build say what state
  it is in.
- **Content** — every installed pack with its id, version, content schema version and
  fingerprint, and which one is active. Fingerprints are what V0716-03 turned on.
- **User data** — the resolved user-data root, and whether the v0.7.1 migration ran.
- **RNG** — the `RngService` seed for the session, so a run can be replayed.

### B2. `DIAG-SAVE-PACK-LIFECYCLE-2026-09-05` — saves, packs, and refusals that explain themselves

Records for install, activate, validate, `save_slot`, load, `inspect_portable_save`,
`import_portable_save`, `migrate_save_into_slot`, `revalidate_slot` and the disabled-slot
path. Each carries the slot, the outcome, and on refusal a stable `reason_code` plus the
unresolved ids.

Two records earn their place on the evidence of the last two rounds specifically:

- **Both identity blocks, side by side.** Log `campaign.{package_id, package_version,
  content_schema_version, content_fingerprint}` next to `source.{...}` on every save
  read and write. V0716-03 was precisely these two blocks disagreeing, and printed like
  this it is visible at a glance rather than after a headless probe.
- **Which content session was active at the moment of the check.** V0716-02 was a
  validation that asked the right question of the wrong catalogue. A record naming the
  active session at each gate makes that failure self-evident.

This row also carries **A2**: `import_portable_save` and the migration commit must
surface the unresolved content ids to the player, in the same register the disabled-save
recovery messages already use.

### B3. `DIAG-VIEWPORT-TRACE-2026-09-05` — window, viewport and scale

Generalises the one-off banner trace. On every `size_changed`, window-mode change, screen
change or content-scale recalculation, record before and after: viewport size, window
size and mode, `content_scale_factor`, stretch scale, safe-area insets, the resolved size
class and density. Then record each screen's response to it.

The defect class this exists to catch — a resting coordinate derived from a viewport that
has since changed — has now appeared on two separate UI elements. A record that pairs a
control's cached geometry against the live viewport catches the third one before a tester
does.

`PROMETHEUS_BANNER_TRACE`, its env var and `run-with-banner-trace.bat` are removed in this
row; the launcher's job becomes "run the game", because the trace is no longer optional.

### B4. `DIAG-LAYOUT-AUDIT-2026-09-05` — the build reads its own screen

The audit runs when a screen settles and again after any resize, walks the visible
`Control` tree, and records:

- `label_clipped` — a `Label` whose rendered text is ellipsised or truncated: control
  path, full text, visible width, `autowrap_mode`, `clip_text`, overrun behaviour, font
  size, menu scale, density, size class. **V0716-04 was found by a human reading an
  ellipsis in a screenshot**, while the containment suite passed — the review's own words
  were that containment can pass while comprehension fails. This is that assertion made
  at runtime.
- `control_overflow` — a control whose rect leaves its parent's rect or the safe viewport.
- `dialog_geometry` — for every popup: `min_size` as requested, size at the `popup_*`
  call, size after the layout settles, and the resulting position delta. **This is
  V0716-05 exactly**, and it would have been one line in a log instead of two screenshots
  and a measured left edge.
- `focus_lost` — the focus owner going null while a modal is open.

Records are emitted on change, not per frame.

### B5. `DIAG-BATTLE-CAMPAIGN-2026-09-05` — the round's balance dataset

`EventBus` already carries almost everything needed — `combat_started`,
`combat_resolved`, `unit_damaged`, `unit_died`, `unit_healed`, `unit_leveled_up`,
`unit_promoted`, `phase_changed`, `ai_unit_acting`, `map_victory`, `map_defeat`,
`map_resolved`, `reward_committed`. This row is mostly a subscriber, not new
instrumentation.

Record: `chapter_start` (node, map, deployed roster with classes, levels and stats);
`turn_begin` (turn number, faction, living unit counts, HP totals per side); `combat`
(attacker, defender, weapons, hit and crit chance, projected damage, rolled damage, the
RNG stream and draw index, result); `unit_died`; `level_up` (rolls against growths);
`item_used`; `gold_delta`; `objective_eval`; `ai_activation` (unit, disposition, chosen
action, score, and how many candidates were scored); and a `chapter_end` summary of
turns taken, deaths, surviving HP, gold and wall-clock time.

**Why now:** the round adds a full campaign playthrough, and there is no valid combat or
balance data anywhere in the project. The v0.4.0 data predates the pack pipeline, and the
v0.7.0 round was played with every skill inert, which voided its combat numbers. Without
this row, a five-chapter playthrough returns as "chapter 3 felt hard".

### B6. `DIAG-RETURN-BUNDLE-2026-09-05` — one artifact instead of a folder

One action — Settings, plus a hotkey — writes
`Prometheus_diagnostics_<version>_<timestamp>.zip` to a path it then shows the player,
containing the diagnostics logs, the Godot logs, `BUILD_INFO`, the settings snapshot, the
installed pack manifests (manifests only, never pack payloads), the save-slot documents,
and a manifest of its own contents. The same bundle is written automatically at exit when
the session recorded any error.

The v0.7.16 return required the tester to find five logs, two saves and eleven screenshots
by hand, in three different directories, and Section 0.3 of that checklist exists purely
to stop test files landing in the wrong folder. Screenshots stay manual — those need a
human deciding what looks wrong. Nothing else should.

## Part C — `V0717-CAMPAIGN-PLAYABILITY-2026-09-05`

The shipped Proving Grounds pack is a real six-node campaign: a drill prologue, then rout,
seize, defeat-boss, escape and defend. **Nothing past `map_001` has been played on a real
machine since v0.4.0**, in July, before the zero-content and pack pipelines existed. Every
v0.7.x round has been fix verification on menus and saves.

Before the round ships, drive chapters 1-5 headlessly to completion and confirm each is
winnable, that its objective resolves, that rewards commit, that the campaign advances,
and that a save taken and resumed at each node returns to the right place. Retune or
repair anything that is not; record what was changed and why. The prologue proved the
value of this in v0.7.16 — the tester reached the save-heavy sections without playing a
full battle first, and every one of those sections passed.

Note the constraint from V0715-09: `map_001` is also the shared battlefield fixture for
about a dozen suites and shares its enemies with `map_001_c3_factions`, so retuning it is
not a local change. Chapters 2-5 have no such entanglement.

## Part D — `V0717-ROUND-PREP-2026-09-05`

Cut the candidate only when Parts A-C are merged, green and exercised. Then:

1. Regenerate the pack through the pipeline — `extract_proving_grounds_pack.gd` →
   `scripts/retune_public_pack.py` → `validate_pack.gd` → `export_pack_archive.gd` —
   applied as a **delta**, because a wholesale copy of the regenerated pack deletes the
   v0.7.9 `campaign_vars` repair, which has no engine source.
2. Assemble the bundle with `scripts/package-tester-bundle.sh` and confirm
   `builds/tester/Project_Prometheus_v0.7.17_tester_bundle.zip` exists. A cut candidate
   is not a delivered one; `SHA256SUMS.txt` and `BUILD_INFO.json` are bundle artifacts,
   not repo files, and a checklist naming them is unsatisfiable until the bundle is built.
3. Write the checklist **against the diagnostics**, not against the tester's memory. The
   shape of an item becomes "do this, then export the bundle", and the sections that used
   to ask for transcribed sentences and counted error lines are deleted, because the log
   now answers them. What stays manual: does it look right, does it feel right, and does
   anything the log cannot see go wrong.
4. Keep the install-order trap in Section 0. Installing a pack un-gates New Game, so
   pack-free sections must run first or the round's evidence is destroyed unrecoverably.
5. Give the round a real campaign section. The point of this build is the first full play
   of the campaign; the fix verifications are secondary and are mostly automated now.

## Open decisions for the owner

1. **The v0.7.16 review is still `In review - owner walkthrough pending`.** Its seven
   decisions are listed there; the code already took the recommended option on five. The
   walkthrough is mostly ratification, but it should happen before the merge in A1.
2. **How much of the checklist to delete.** The diagnostics make roughly half of the
   v0.7.16 checklist redundant. The aggressive reading deletes those sections outright;
   the cautious one keeps them for one round as a cross-check against the new records.
   Recommendation: cross-check for this round only, then delete.
3. **Whether the campaign section is bounded.** Five chapters is a real time commitment
   for a tester. Recommendation: ask for chapters 1-3 as the required section and 4-5 as
   optional, since the telemetry means a partial run still returns usable data.
