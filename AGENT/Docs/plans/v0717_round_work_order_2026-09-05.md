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

**Stage 0 — bookkeeping, executed 2026-09-05.** Four rows read open while their work was
already merged, and one of them was holding another row hostage. All four are closed; no
code moved. Recorded here because the queue below is only executable once they are.

| Row | Was | Why it was closed |
|---|---|---|
| `WINDOWS-PASS-READINESS-2026-08-20` | `in_progress` / `2-return` | Carried the Windows candidate line from v0.7.8 to v0.7.16. Its last bundle shipped, was played and was **returned on 2026-09-04** — a rejected return is a finished return. It was also a dependency of `V0710-MAIN-MENU-CLIPPING-2026-08-25`, so a round that had already come back was blocking a 22-line fix. The next candidate belongs to `V0717-ROUND-PREP-2026-09-05`. |
| `V0715-EXPECTED-SAVE-DIAGNOSTIC-SEVERITY-2026-09-03` | `in_review` / `3-cascade` | 0 commits ahead of `agent/integration`. Its invariant is now load-bearing for Part B — see principle 2 below. |
| `V0715-MIGRATION-FIXTURE-REAL-DELTA-2026-09-03` | `in_review` / `3-build` | 0 commits ahead of `agent/integration`. Note the v0.7.16 review **withdrew** the v0.7.15 diagnosis behind it: the fixtures were never broken. |
| `LOAD-GAME-EMPTY-PROFILE-ENTRY-2026-08-28` | `in_progress` / `3-build` | 0 commits ahead. It was held open only for a native pass, which cannot happen before a bundle exists. That pass is now a **checklist item owned by `V0717-ROUND-PREP-2026-09-05`**, not a row state. |

One row was opened: `SAVE-IDENTITY-BLOCK-UNIFICATION-2026-09-05` (`planned`, `5-backlog`),
carrying decision 3's scheduled unification. It is **deliberately not** a dependency of
this round — see "Decisions settled" below.

| Order | Row | What it is |
|---:|---|---|
| 1 | `V0716-RETURN-FIXES-2026-09-05` | Merge the v0.7.16 UI repairs to `agent/integration`. Built and green; 4 commits ahead, 2 behind. |
| 2 | `V0710-MAIN-MENU-CLIPPING-2026-08-25` | ~~Merge a 22-line Compact main-menu fix.~~ **Done 2026-09-05 by archiving the branch, not merging it** — the full label fits at every supported width, so the row's own disposition closed it. See A3. |
| — | `PACK-FEATURE-COVERAGE-WARNINGS-2026-08-07` | **DROPPED from the round, 2026-09-05 — the last open decision, now answered.** Removed from `V0717-ROUND-PREP`'s dependencies and moved to `5-backlog`, on the 2026-08-22 scope-reassessment grounds. The branch stands and the row stays `in_review`: this is a scheduling ruling, not a verdict on the work. |
| 3 | `DIAG-SESSION-CHANNEL-2026-09-05` | The diagnostics channel and session header. Everything else writes through it. |
| 4 | `DIAG-SAVE-PACK-LIFECYCLE-2026-09-05` | Save and pack lifecycle records, and refusals that name the missing content. |
| 5 | `DIAG-VIEWPORT-TRACE-2026-09-05` | Window, viewport and content-scale trace. |
| 6 | `DIAG-LAYOUT-AUDIT-2026-09-05` | Runtime layout self-audit. |
| 7 | `DIAG-BATTLE-CAMPAIGN-2026-09-05` | Battle and campaign telemetry. |
| 8 | `DIAG-RETURN-BUNDLE-2026-09-05` | One-action export of everything a return needs. |
| 9 | `V0717-CAMPAIGN-PLAYABILITY-2026-09-05` | Play chapters 1-5 headlessly before shipping them. |
| 10 | `V0717-ROUND-PREP-2026-09-05` | Cut the candidate, the pack and the checklist. |

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

### A3. Two stale branches, one archived and one undecided

- `agent/from-integration/v0710-main-menu-clipping` — **RESOLVED 2026-09-05: archived
  unmerged, and this is the outcome the row asked for, not a deferral.** The text above
  said rebase and merge; the row said something narrower, and the row won. Its standing
  disposition was *await the native return; if the full label fits at the narrowest width,
  archive this branch and close the row.* It fits, on two independent kinds of evidence.
  The v0.7.13 and v0.7.15 returns both recorded the complete
  `New Game (No Data Packs Installed)` visible with no clipping at ~360x640 — though both
  left the transcribe-it line blank, which is a tick and not a measurement, and is the
  whole reason Part B exists. So it was measured instead: in real `SubViewport`s the label
  needs 202.0 px against 202.0 / 236.0 / 276.0 / 316.0 px available at 282, 320, 360 and
  400 logical px, unchanged at menu scale 1x, 2x and 3x. Menu scale cannot move it because
  `MainMenu.apply_menu_scale` is deliberately type-neutral — the main menu is a
  pinned-large home screen that ignores the Menu Scale preference (`MainMenu.gd:78-95`) —
  so the 2x failure mode that broke Settings in v0.7.15 cannot reach this label.
  Preserved as tag `archive/agent/from-integration/v0710-main-menu-clipping`; the branch
  is deleted. Nothing merged, so `MainMenu.gd` keeps the full label at every size class
  and the 2026-08-27 cross-row notice about reconciling with the Manage Campaigns wiring
  is moot.
  - **The number to carry forward: at 282 logical px the slack is exactly 0.0 px.** The
    label clears the narrowest supported width with nothing to spare, so any change to the
    menu font, the compact gutter token or `_PANEL_WIDTH_RATIOS` starts clipping it there
    first. `MAIN-MENU-LABEL-FIT-GUARD-2026-09-05` added that assertion to
    `test_main_menu_responsive.gd` and named the string `MainMenu.NO_PACK_LABEL` so the
    test reads the shipped label rather than a copy of it.
  - **Worth knowing before writing the next fit test:** the first version of that guard
    passed on a deliberately over-long label. A `Button` takes its minimum width from its
    own text, so a longer string widens the button and the panel instead of overflowing
    them — text-vs-button stays true right up until the menu hangs off the edge of the
    screen. The assertion that moves is button-vs-viewport, and both are measured now.
    Relatedly, a Control only measures at its real width inside a `SubViewport` of that
    size: `ResponsiveLayout.apply_logical_size()` sets the class and tokens but not the
    viewport, so a probe without one silently measures the headless default (~1152 px).
- `agent/from-integration/pack-feature-coverage-warnings` — warns when a pack marked
  complete exports content implying an engine feature it never exercises. Builder-facing
  rather than player-facing, which is why it has drifted; it is also exactly the class of
  thing the 2026-08-22 scope reassessment said stops mattering the moment it stops being
  adopted. **It is 834 commits behind `agent/integration`** (9 files, +253 lines), and
  whether it is in this round at all is the one decision still open — see the queue. Do
  not start the rebase before that is answered.

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

### B5. `DIAG-BATTLE-CAMPAIGN-2026-09-05` — what the battle actually did

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

**Why now:** the round adds a full campaign playthrough, and there is no valid combat data
anywhere in the project. The v0.4.0 data predates the pack pipeline, and the v0.7.0 round
was played with every skill inert, which voided its combat numbers. Without this row, a
five-chapter playthrough returns as "chapter 3 felt hard".

**Scope, per decision 4 below: this is a correctness record, not a balance dataset.** The
question each record answers is *did the engine do what it said it did* — did the rolled
damage follow from the projected numbers and the named RNG draw, did the AI score and
choose, did the objective evaluate, did the chapter end in the state it reported. Read the
field list that way: `hit and crit chance` against `rolled damage` is there to catch a
formula or RNG defect, not to judge whether the fight was fair. If a proposed field is
only interpretable against an intended difficulty, it does not belong in this row.

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

## Decisions settled 2026-09-05

The three decisions this document parked were reviewed against the code and ratified by
the owner on 2026-09-05. What follows is the ruling, not the recommendation.

### 1. The v0.7.16 review is ratified

`AGENT/Code Reviews/playtest_v0.7.16_root_cause_review_2026-09-04.md` is accepted as it
stands. It does not gate the A1 merge.

This document previously said the code had taken the recommended option on five of the
review's seven decisions. **That was wrong: it had taken six.** Verified against the
branches on 2026-09-05:

| Review decision | Taken | Evidence |
|---|---|---|
| 1. Is v0.7.16 blocked | yes | candidate rejected, all six rows worked |
| 2. `save_slot()` gets an explicit content scope | yes | `scripts/autoloads/SaveManager.gd:1030` `_validate_in_saved_catalogue`, called at `:109` and `:1022` — the explicit scope, not the per-call-site wrapper |
| 3. Patch identity, assert agreement | yes | `scripts/save/SaveMigrationService.gd:419-423` checks all four fields on **both** `source` and `campaign` |
| 4. Take all of V0716-01, plus V0716-06 | yes | `d58bbac2` and `fb57b174` |
| 5. Picker row text | yes | rows carry label, location and timestamp; the redundant package/campaign paths that made the dialog 962 px wide are gone |
| 6. Probes become suites | yes | `test_v0716_save_return.gd`, and `test_phase_banner.gd` rewritten around the 1280→1920 resize |
| 7. What the next round tests | — | this document is the answer |

Nothing was left for a walkthrough to change, which is why it became a ratification rather
than a gate. Decision 3's *scheduled* half — unifying the duplicated `campaign` and
`source` identity blocks behind one writer — was the only genuinely unfinished item and
had no row; it is now `SAVE-IDENTITY-BLOCK-UNIFICATION-2026-09-05`, `planned`/`5-backlog`,
and **excluded from this round on purpose**: it refactors a path the round depends on, and
the assert already makes the round safe without it.

### 2. Checklist deletion is per-section, not uniform

The parked recommendation was "cross-check for this round only, then delete". That does
not survive contact with Section 2, so the ruling is finer-grained:

- **Section 2 — the phase banner trace (~65 lines, the largest section) is deleted
  outright.** `DIAG-VIEWPORT-TRACE-2026-09-05` removes `PROMETHEUS_BANNER_TRACE`, its env
  var and its `run-with-banner-trace.bat` launcher. The section is not redundant, it is
  **unsatisfiable** — you cannot cross-check a mechanism the build no longer has.
- **Section 1 — build identity** is absorbed by the `DIAG-SESSION-CHANNEL` session header.
- **Sections 4, 5 and 6 survive, stripped to judgement.** Delete every "transcribe this
  string" and "count the error lines" item; keep "does it look right". `label_clipped`,
  `dialog_geometry` and `focus_lost` answer the rest, and the half a log cannot answer is
  the half worth a tester's attention.
- **Section 7** stays as smoke.
- **Section 3 — the prologue** is covered ahead of the round by Part C.

And the cross-check must have a reader. A cross-check nobody compares is unpaid tester
work, so **comparing the returned bundle against the surviving checklist answers is an
explicit closeout step on `DIAG-RETURN-BUNDLE-2026-09-05`.**

### 3. The campaign section may ask for a full playthrough

**Amended 2026-09-05 by owner ruling.** The original decision bounded this section at
roughly 45 minutes rather than by chapters. **A full playthrough may now be asked for.**
Stopping mid-chapter stays an explicitly valid return — asking for the whole thing is not
the same as requiring it — and the checklist must still say so.

What changed is the reason the bound existed. The 45 minutes was a hedge against spending
scarce tester attention on transcription; once the build emits its own records that cost
is gone, and a longer run buys real-machine coverage of chapters the engine has never seen
outside a headless harness. The original arguments, and what survives of them:

- The telemetry makes a partial run fully legible. **Still true, and it is why stopping
  early is a valid return** rather than why a finish line must not be named.
- A chapter count invites a tester to rush a chapter rather than stop honestly inside it.
  **Still true** — so ask for a full playthrough, not for "chapters 1-3", and say plainly
  that an honest stop beats a rushed finish.
- What only a real machine returns — input feel, camera, performance — is learned in the
  first battle, and chapters 4-5 mostly return length. **This is where the ruling lands
  differently:** the original sentence said chapters 4-5 "mostly return balance", and
  balance is no longer something this project measures at all — see the ruling below. What
  the later chapters return is playability on real hardware, which is exactly what a
  headless harness cannot fake.

One constraint on what Part C may do about anything it finds: `map_001` is the shared
battlefield fixture for about a dozen suites and shares its enemies with
`map_001_c3_factions` (V0715-09). Chapters 2-5 are free to retune. **A chapter 1 retune is
a separate row, not an inline fix during round prep.**

### 4. Balance testing is out of scope for this project

**Owner ruling 2026-09-05, and it is a project-wide scope boundary, not a round-local
one.** Too many of the variables that decide whether an encounter is well-tuned belong to
the campaign **author**, so a balance measurement the engine takes is measuring one pack
rather than the product, and generalises to nothing.

This has teeth in three places in this round:

- `DIAG-BATTLE-CAMPAIGN-2026-09-05` is a correctness and completability subscriber:
  did the objective fire, did the AI take its turn, did the chapter end in the state it
  reported, did anything crash or wall the player. **Record what happened, not whether it
  was fair.** A number that is only interpretable against an intended difficulty does not
  belong in the channel.
- `V0717-CAMPAIGN-PLAYABILITY-2026-09-05` proves the chapters are reachable, completable
  and crash-free. Its output is not balance evidence and must not be reported as any.
- The checklist `V0717-ROUND-PREP-2026-09-05` cuts asks no difficulty, damage-curve or
  pacing questions.

It also retires a premise this document opened with. The round's motivation included
"there is no valid combat or balance data anywhere in the project". The **combat** half
stands and is why the playthrough exists. The **balance** half is not a gap to be filled —
it was never this project's measurement to take. The retune latitude noted under decision
3 is unaffected: it is authoring latitude over pack content, which is precisely where the
ruling says tuning belongs.

### The condition under which 2 and 3 invert

Both assume `DIAG-SESSION-CHANNEL-2026-09-05` and its five dependents land green. If the
diagnostics slip, both rulings reverse: keep the full checklist, and the play request goes
back to a bounded ask rather than a full run — the tester's time then has to go somewhere,
and with no telemetry it has to go into writing things down. Re-read this section before
writing the checklist, not before starting Part B.

**Decision 4 does not invert.** It is a project-wide scope boundary rather than a bet on
this round's tooling, so it holds whether the diagnostics land or slip.
