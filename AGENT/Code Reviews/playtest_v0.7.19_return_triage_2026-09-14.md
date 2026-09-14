---
Role: dated
Type: code_review
Status: Active - triage of the accepted v0.7.19 return
Last verified: 2026-09-14
---

# v0.7.19 return — diagnostics triage

## Executive summary

v0.7.19 was **accepted** on its native Windows return and is the shipped, tagged
release. This document triages the evidence the tester actually returned, which had
not been read: four diagnostics bundles, a `godot.log`, and a `resume_battle` save in
`Incoming/v0.7.19 return/`.

The round's own verdict is not disturbed. What the evidence adds is five findings,
and the first two are about the **instrument**, not the game:

1. The layout audit in the shipped build walks hidden subtrees. 90% of the layout
   budget was spent on a screen the tester never opened, and **25 of the 29 seconds
   in which any layout record was produced show two or more mutually exclusive
   full-screen modals reporting at once.** The layout category of this return is
   uninterpretable end to end — including the records that name screens the tester
   *was* using. The fix already exists on `agent/integration` and is not in `main`.
2. The audit's dedupe key embeds the control's rect, so a drag-resize defeats
   deduplication entirely. 4,295 layout events fired inside a 177-second resize
   sweep; 3,094 were dropped. This is the second occurrence of the failure V0717-04
   was written to stop.
3. Two live `CampaignLibraryScreen` instances exist in the MainMenu tree. Read from
   the shipped scene files, not inferred from the audit.
4. A `load` of the suspend slot records a blank package identity while
   `campaign_id` is set. Needs a headless ordering check before it is called a defect.
5. The `v0.7.19` tag points at a commit the tester never played.

**The returned checklist had also not been read.** It came back marked up, and its
marks are the native evidence four tracker rows were explicitly waiting on — the
phase banner across resize and resumed load, compact Settings containment, slider
endcap visibility at 0/50/100, and the Campaign Library hub route with focus
restoration. It also states in the tester's own words that the campaign editor was
never opened. Section 7 reads it in full.

Nothing else in the return is a defect. No diagnostics record in any of the four
bundles carries `error: true`. Every pack install, activation, registry commit and
snapshot restore reports `completed`. Six chapters were played and won.

## 1. What was returned, and what was played

| | |
|---|---|
| Bundles | 4, created 2026-09-11 20:14:12Z, 20:33:53Z, 20:51:59Z, 21:01:59Z |
| Build stamp in every one | `version=0.7.19 commit=57a7dea2 built_at=2026-09-11T18:11:26Z` |
| Host | Windows 10.0.26200, Intel Core Ultra 5 225, Intel Graphics, GL `3.3.0 - Build 32.0.101.6647`, two 1920x1080 screens |
| Session span | last record at `ts_ms=2,967,696` — about 49.5 minutes |
| Campaign | `proving_grounds` from `prometheus-proving-grounds` 0.1.0, fingerprint `sha256:17e354f6…c204ba` |
| Chapters completed | `node_00_drill`, `node_01_rout`, `node_02_seize`, `node_03_boss`, `node_04_escape`, `node_05_defend` — all `winner_group=allies` |

The fourth bundle is a cumulative superset of the first three (2,600 records); the
analysis below reads it unless stated.

### Category budgets (bundle 4)

| Category | emitted | cap | dropped | sampled |
|---|---|---|---|---|
| layout | 1,201 | 1,200 | **3,094** | 200 |
| battle | 691 | 1,600 | 0 | 0 |
| viewport | 210 | 400 | 0 | 0 |
| session | 180 | 400 | 0 | 0 |
| pack | 79 | 400 | 0 | 0 |
| save | 27 | 400 | 0 | 0 |
| campaign | 12 | 400 | 0 | 0 |
| ai / input / nav | 0 | 400 | 0 | 0 |

Layout is the only category that capped, and it capped at `seq 1340`, `ts_ms=185,745`.

## 2. V0719-01 — the shipped layout audit walks hidden subtrees

**Confirmed, from the shipped source and from the returned data.**

`LayoutAudit._walk()` on `main` guards the *measurement* with the control's own
`visible` flag but recurses into children unconditionally:

```gdscript
if node is Control:
    var control := node as Control
    if control.visible and control.is_inside_tree():
        ...append findings...
for child in node.get_children():          # <- outside the guard
    _walk(child, viewport_rect, reason, findings)
```

Every full-screen modal in `MainMenu` is hidden at rest — `CampaignEditorScreen`
carries `visible = false` in `scenes/ui/MainMenu.tscn`, and `NewGameScreen`,
`SettingsScreen`, `CampaignLibraryScreen` and `LoadGameScreen` each carry it at their
own scene roots. Their descendants' own `visible` flags stay true, and a hidden
container does not re-sort on resize, so the subtree keeps whatever geometry it was
last laid out with. The audit then measures that stale geometry against the live
viewport and reports it as overflow.

What that produced:

- 1,400 `control_overflow` records. **1,266 of them (90%) are inside
  `/root/MainMenu/CampaignEditorScreen`**, across 38 distinct control paths — a
  screen with no evidence of ever having been opened. The commonest shape is the
  whole editor shell reporting a 1920-wide rect against a 1280x720 viewport.
- The remaining 134 are not trustworthy either. Grouping every overflow record by
  second and listing which top-level screen it names: **25 of the 29 populated
  seconds contain two or more mutually exclusive modals.** At `t=185 s`,
  `NewGameScreen`, `CampaignLibraryScreen` and `CampaignEditorScreen` all report
  together; at `t=152-157 s` it is `SettingsScreen` and `CampaignEditorScreen`; at
  `t=308-310 s` it is all three again. At most one of those can have been on screen.

**Therefore no layout finding in this return may be opened as a defect**, including
the two that would otherwise be the most interesting — an x-axis overflow of
`SettingsScreen/Panel/ScrollContainer/Margin/VBox/KeybindList/_HBoxContainer_1962`
(566 px) and of `HBoxSFX/LabelSFXTitle`, both clipped by the ScrollContainer rather
than the viewport, which is the one class `_overflow_of()`'s own note calls "a real
defect and the commonest one this audit exists to catch". They are recorded here so
the next round can look for them deliberately; they are not evidence today.

**The fix exists and is not in the release.** `41d74930` on `agent/integration`
changes both call sites to `is_visible_in_tree()` and adds a `HiddenScreen` /
`HiddenOverflow` / `HiddenDialog` fixture to `scripts/tests/test_diagnostics_layout.gd`.
It landed after the v0.7.19 candidate was cut. The next candidate is cut from
`agent/integration` and will carry it; the row exists to make that a checked fact
rather than an assumption, because the cost of missing it is another round whose
layout evidence is void.

## 3. V0719-02 — the dedupe key embeds the rect, so resizing defeats it

**Confirmed, from the returned data. The disposition is to re-measure, not to
re-budget.**

A record's `dedupe_key` is `control_overflow:<path>:<the full field payload>`, and
that payload contains the control's `rect`. Two reports of the same control at two
different sizes are therefore two different keys. During a drag-resize the rect
changes every frame, so one control emits one record per settle: 38 editor control
paths produced 1,266 records, about 33 apiece.

Measured: 4,295 layout events (1,201 emitted + 3,094 dropped) inside a resize sweep
running `t=147.9 s` to `t=325.3 s`. The audit fires only on `settled_resize` (1,320)
and `size_class_changed` (80), so layout observation legitimately ends when the tester
stops resizing at `t≈375 s`; the loss is entirely *inside* the window that matters.

**The budget work from V0717-04 did what it was built to do.** That round measured
layout emitting 401 and dropping 10,277 — 96% lost, with the channel going silent at
`t=150 s` and nothing late surviving. The settled fix raised the caps from measured
rates and added reservoir sampling. This round: 72% lost, and 200 sampled records
survive past the cap. Do not size the budget a third time on this evidence.

**What is left is the event rate, and 90% of it is V0719-01.** 1,266 of the 1,401
retained layout records come from the hidden editor subtree. Removing that source
should drop the rate by roughly an order of magnitude and leave the cap unreached, at
which point the rect-keyed dedupe costs nothing. The right order is: ship V0719-01,
re-measure the next return's `layout` counters, and only then decide whether the
dedupe key needs a path-scoped budget. Acting on both at once would spend a second
process change on a symptom the first one may have already removed.

## 4. V0719-03 — two live CampaignLibraryScreen instances

**Confirmed, from the shipped scene files.**

`scenes/ui/MainMenu.tscn:107` instances `CampaignLibraryScreen.tscn`, and
`scenes/ui/NewGameScreen.tscn:155` instances it again. Both are in the tree at once,
each with its own signal wiring (`MainMenu.gd` connects `back_pressed`;
`NewGameScreen.gd:79-80` connects `back_pressed` and `campaigns_changed` on its own
copy) and its own state. This is what puts `/root/MainMenu/CampaignLibraryScreen` and
`/root/MainMenu/NewGameScreen/CampaignLibraryScreen` in the same audit pass.

Whether it is intended is a design question, not an audit question:
`CAMPAIGN-LIBRARY-UI-UPDATE-2026-09-10` added the Main Menu "Manage Library" hub
beside the pre-existing picker inside New Game, and that row is still `playtesting`.
Two instances of an import/export/backup surface can diverge, and the second copy is
reachable through a different path than the one the accepted UI describes.

## 5. V0719-04 — a suspend load records no package identity

**Observed; needs a headless ordering check before it is a defect.**

At `ts_ms=1,042,993`, `save | load | slot=resume_battle` carries
`active_session={"campaign_id":"proving_grounds","content_fingerprint":"","content_schema_version":0,"package_id":"","package_version":"","path":""}`,
while every `save_slot` record in the same session carries the full fingerprint.

`SaveManager._active_diagnostics_session()` fills `campaign_id` from
`CampaignManager.active_campaign_id` and the other four from
`DataManager.active_package_identity()`. A blank package block therefore means no
package was active at the moment the record was emitted. That is plausibly correct
ordering for a load — the record may precede activation — and the pack records show
`activate` firing normally either side of it. The check is cheap and headless: emit a
load against a suspend save and assert whether the identity block is expected to be
populated. These are the fields the recovery diagnostics use to explain a
missing-pack refusal, so a blank one in a *real* refusal would be the failure case.

## 6. V0719-05 — the tag does not point at the played commit

**Confirmed.**

- Every returned bundle and log stamps `commit=57a7dea2`, built `2026-09-11T18:11:26Z`.
- `refs/tags/v0.7.19` points at `3473fcf9`, and `builds/windows/Project_Prometheus/artifact-manifest.json`
  records that binary as built `2026-09-12T18:50:40Z` from `3473fcf9`.
- `git diff --stat 57a7dea2 3473fcf9` is three files: `scripts/shared/DiagnosticsReturnBundle.gd`
  (+6), `scripts/tests/test_diagnostics_return_bundle.gd` (+16/-4), `AGENT/Ledger/CLAIMS.tsv` (+1).

So the accepted playtest and the tagged binary are not the same build. The delta is
the empty-log diagnostics hash guard and nothing else, and the return proves the guard
was needed: `godot.log` carries exactly one engine error,
`ERROR: Condition "len == 0" is true. Returning: FAILED  at: update (core/crypto/hashing_context.cpp:53)`,
which is the empty-log hash that `0fa34e93` fixes.

The tag policy sentence — "a release tag must point to the exact commit baked into the
corresponding executable's BUILD STAMP" — is satisfied by the binary on disk. What is
not recorded anywhere is that the *accepted* binary was a different one. The risk is
small here and the disposition is to state it, not to retag: a future reader
correlating a v0.7.19 log against the tag will find three commits they cannot account
for.

## 7. The returned checklist, and what it does and does not discharge

`Incoming/v0.7.19 return/PLAYTEST_CHECKLIST.md` came back **marked up**, and it had
not been read into the tracker. Its marks are the round's acceptance evidence and they
settle several rows that were waiting on exactly this.

**Checked by the tester:** Section 2 (library route with focus restoration both ways;
Settings labels stacking without clipping below 600 px; slider trough, fill, endcaps
and thumb visible at 0%, 50% and 100%; a dialog fully visible and usable with keyboard
or controller, with no stale clipping after fullscreen recovery), Section 3 (the phase
banner spans and centres in the safe viewport after fullscreen/windowed changes and
resize; after Suspend & Quit and reload it settles and hides, with no superseded banner
across two close phase changes), Section 4 (all four save/migration items), Section 5
(all three playability items) and Section 6.

**Renewal, Section 3a.** The tester wrote *"No renewal enemy, renewal behaved as
expected."* The table carries two completed runs — max HP 16, 7→8 at phase start on
turn 4, 8→9 on turn 5, one increase per eligible phase, matching
`min(max(1, floor(max_hp * 0.10)), max_hp - hp_before)`. **Run 3, the
suspend-during-Renewal / Continue-without-replay row, is blank**, and run 2 is
recorded `none` because no enemy Renewal fixture was authored. Suspend-and-resume
itself is evidenced twice elsewhere (Sections 3 and 4). So the ruling that Renewal
passed is supported; the single unmeasured cell is the *interaction* — that
post-Renewal HP survives Continue with no second application — and it should be
carried into the next round's checklist rather than re-derived.

**The one explicit exclusion:** *"No problems noted anywhere, but campaign editor not
investigated at this time."* Every editor row's acceptance gate is therefore
untouched by this round, by the tester's own statement — which independently confirms
§2: a screen nobody opened produced 90% of the layout records.

**Two checklist-hygiene notes for the next round.** Section 1's second and third boxes
— *"Export Diagnostics produces a readable diagnostics ZIP … Return it with this
checklist"* and *"Compare diagnostics records with this checklist"* — are **unchecked**,
yet four diagnostics ZIPs were returned. The export happened and the comparison did
not; this document is that comparison, three days late. A checklist item that asks the
tester to do the reviewer's job is the item that will not get done, so the next
checklist should ask the tester only to return the ZIP.

## 8. What passed and must not be re-tested

- Pack lifecycle: 79 records, every one `completed` / `installed` / `chosen` /
  `skipped`. Install of the proving-grounds pack, 22 activations, 22 registry commits
  at `entry_count=33`, 19 snapshot restores at `error_count=0`, and both
  `v076_migration_fixture` installs.
- Backup and restore: 8 `inspect_portable_save` records, all `outcome=ready`, and 8
  matching `restore_save` records, all `outcome=accepted`, across two backup
  staging directories.
- Save durability: 9 `save_slot` records, all `outcome=completed`, all carrying the
  full content fingerprint.
- Campaign progression: six `chapter_start` / `chapter_end` pairs, turns 2, 14, 7, 3,
  4 and 7, no losses.
- Combat: 691 battle records — 89 combats, 27 deaths, 12 level-ups, 96 AI activations
  — with no error record.

## 9. Process note

*One-in-one-out:* this change adds no check, hook, guard, tracker or document class.
It is a document in the existing `Type: code_review` class and five rows in the
existing tracker, so nothing is retired, and the reason is recorded here as the rule
requires.
