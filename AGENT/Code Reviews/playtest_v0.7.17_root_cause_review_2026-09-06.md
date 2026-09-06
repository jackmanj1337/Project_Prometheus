---
Role: dated
Type: code_review
Status: Ratified 2026-09-06 (owner walkthrough complete)
Last verified: 2026-09-06
---

# v0.7.17 Windows return — findings and the fix queue for the next build

## Executive summary

The returned executable is the intended `0.7.17/54c2e3e8` build and the round's central
bet paid off: the diagnostics programme built in orders 3-8 produced a structured session
log, a save/pack lifecycle trace and a one-action return bundle, and **every finding below
was found in the bundle rather than in the tester's prose.** The tester wrote two
sentences all round. That is the outcome the work order asked for.

The candidate is nonetheless **rejected**. Sections 3 and 5 pass outright — a complete
Proving Grounds run through all six node types with no crash, and a clean sweep of the
phase-banner rows that cost v0.7.15 and v0.7.16 their returns. One Section 4 row failed,
and it is the serious one: **restoring a campaign backup can leave every save in that
backup permanently unopenable, with no recovery path inside the game.** No save data is
lost — the refusal dialog is honest that the save is kept as-is — but the player is told
to reinstall a package version that is already installed, and nothing they can do from the
UI will change that.

Nine defects follow. Seven were in the draft; **V0717-08 and V0717-09 were added
during the owner walkthrough on 2026-09-06**, which also corrected the root cause of
V0717-02 and withdrew part of V0717-03's analysis. They divide cleanly:

1. **V0717-01** is the reported failure: `CampaignBackupService` skips a bundled pack
   whenever id+version already exists, **without comparing content fingerprints**, so a
   restore silently keeps the wrong content and every restored save is then refused.
2. **V0717-02** is that the fixture shipped to test that row is itself wrong, so the row
   could not have passed even with V0717-01 fixed. The next round needs a corrected
   `campaign_backup_v2.zip` before it can retest anything.
3. **V0717-03** is an engine error observed in the run — fort healing silently did nothing
   in a resumed battle — whose mechanism is **not determined** by this review.
4. **V0717-04 through -07** are defects in the new diagnostics themselves. The most
   important, V0717-04, silenced the layout channel 2.5 minutes into a 55-minute session,
   which is why this round has almost no layout evidence for the fullscreen and 4K work it
   was built to capture.
5. **V0717-08 and V0717-09** are the coverage gaps the walkthrough found in the
   diagnostics programme itself: the backup/restore path emits no records at all, and a
   return bundle carries the records of only one process. Together they are why V0717-01
   had to be argued from an absence and why V0717-03 has no mechanism.

This is a targeted review of the returned bundle plus the implicated code paths, not a
full-project audit. **No product code was changed and no headless probes were run** —
unlike the v0.7.16 review, the confirmations below are artifact-plus-source arguments, and
each finding states its own confidence. Two of the seven are proven arithmetic; one is
open.

## Evidence reviewed

- `Incoming/v0.7.17 return/`: the completed `PLAYTEST_CHECKLIST.md`, both PNGs,
  `Prometheus_diagnostics_0.7.17_20260906T182703.zip`, the exported `resume_battle.json`
  and `auto_campaign_progress_01.json`, and the returned status record
  `185aac6a7fd3edd81134bbeb.json`.
- Inside the bundle: `MANIFEST.json`, `BUILD_INFO.json`, `diagnostics/records.json`,
  `diagnostics_logs/diagnostics-20260906T173104-2260.log` (1383 records),
  `godot_logs/godot.log`, `settings/settings_snapshot.json`, three pack manifests and
  eight save-slot documents including `saves_index.json`.
- The shipped bundle `builds/tester/Project_Prometheus_v0.7.17/`: all three
  `campaign-packs/*.zip` and `tester-fixtures-v0.7.17.zip` including
  `campaign_backup_v2.zip`, unpacked and diffed.
- `scripts/resources/CampaignBackupService.gd`, `scripts/core/TurnManager.gd`,
  `scripts/autoloads/SaveManager.gd`, `scripts/autoloads/RegistryManager.gd`,
  `scripts/autoloads/DataManager.gd`, `scripts/actions/ActionPrimitiveRunner.gd`,
  `scripts/shared/LayoutAudit.gd`, `scripts/shared/DiagnosticsReturnBundle.gd`,
  `scripts/autoloads/DiagnosticsLog.gd`, `scripts/registries/RegistryCatalog.gd`.

Every one of those six autoload/service files is **byte-identical between `54c2e3e8` and
the reviewed checkout** (verified by `git hash-object` against `54c2e3e8:<path>`), so the
source read below describes the executable the tester ran.

## Verification performed

- Bundle identity: `BUILD_INFO.json` and `MANIFEST.json` both report
  `0.7.17 / 54c2e3e8 / 2026-09-06T01:39:20Z`. `godot.log` build stamps agree across all
  five launches.
- Pack fingerprints were read directly from the lifecycle trace rather than recomputed:
  `v076_migration_fixture 1.0.0` activates at `sha256:74e9e91e…`, `2.0.0` at
  `sha256:45391892…` (log lines 1326 and 1347).
- `campaign_backup_v2.zip` was unpacked and its bundled `2.0.0` pack diffed against the
  shipped `campaign-packs/migration-v2.zip`. They differ in content, not just formatting.
- Record counts and cap state were read from `diagnostics/records.json` counters and
  cross-checked against first/last timestamps per category in the log.
- No probe was written and no suite was run. **Every "Recommended fix" below is
  unverified until the fix's own test exists.**

## Returned observations

The tester ran all six sections and left two comments.

- **Section 4, row 3 — the only failed row.** *"I had all three supplied campaign packs
  installed, but it still said that I need the campaign."* Correct on both counts: the
  bundle's `pack | install` records show all three installed before the restore, and the
  dialog in `attempt to load restored campaign.png` does say to reinstall. See V0717-01.
- **Section 6, closeout.** *"Windows 11 Nvidia rtx 4070ti 4k display."* The diagnostics say
  RTX **5070** Ti, driver 610.74, Windows 10.0.26200, two screens with the active one at
  3840×2160 @ 120 DPI. Section 1 asks that disagreements be noted rather than reconciled;
  noting it, and going with the instrument.

Sections 1's five rows were left unticked. They are the "read the diagnostics" rows, which
is this review's job; all five are satisfied — the session header carries real resolution,
DPI, refresh and scale; the window record carries mode, size, position and content-scale
configuration; build and pack identities are correct; the ZIP opens cleanly with logs,
settings, manifests, saves and a contents manifest.

## Issues found and root causes

### [High] V0717-01 — Backup restore skips a same-version pack without comparing content, locking every restored save

- **Location:** `scripts/resources/CampaignBackupService.gd:783-791` (the skip),
  `:773-812` (`_validate_restore_candidates` package loop).
- **Problem:** restore treats "a directory already exists at this id/version" as "this
  component is already where restore would put it" and skips installing it:

  ```gdscript
  if DirAccess.dir_exists_absolute(installed):
      # Same id AND version is the same release by definition of the library's
      # identity rules, so this is not a conflict to refuse — it is a component
      # that is already where restore would put it.
      result.skipped_packages.append(...)
      continue
  ```

  The saves in the backup are then restored against whatever content happens to be
  installed under that id and version. If that content differs from what the saves were
  made with, every one of them fails revalidation and cannot be opened.
- **Root cause:** the identity the library keys on (`id|version`) is coarser than the
  identity saves are validated against (`id|version|content_fingerprint`). The comment
  states the coarse rule as an invariant; nothing enforces it, and the fingerprint that
  would detect the violation is available on both sides at the moment of the skip.
- **Confirmation:** the trace shows the collision exactly.
  - `2608754 | pack | install | v076_migration_fixture 1.0.0`
  - `2615404 | pack | install | v076_migration_fixture 2.0.0`  ← genuine v2, `45391892…`
  - `2641478 | save | inspect_portable_save | source_path=user://.backup_staging/…/imported_01.json outcome=disabled reason_code=fingerprint_mismatch`
  - `2670738 | save | revalidate_slot | slot=resume_battle reason_code=fingerprint_mismatch outcome=refused`

  Between the install at 2615404 and the restore at 2641478 there is **no `pack | install`
  record** — the bundled pack was skipped, as the code says it will be. The backup's saves
  are stamped `2.0.0 / sha256:74e9e91e…`; the installed `2.0.0` is `sha256:45391892…`.
- **Why the message is worse than the bug:** `attempt to load restored campaign.png` reads
  *"The installed campaign package does not match this save. This save needs
  v076_migration_fixture v2.0.0 (content schema 1). Saved content fingerprint: 74e9e91e…
  Reinstall the exact package version this save was made with."* Version 2.0.0 **is**
  installed. The instruction is unfollowable, and the player has no way to learn that two
  different builds of "2.0.0" exist. This is the tester's comment, verbatim, explained.
- **Why this is not an exotic case:** it is the ordinary authoring loop. An author edits a
  pack without bumping its version, backs the campaign up, and restores on a machine that
  holds the earlier edit. Per the 2026-08-22 scope reassessment the builder is the product,
  so this is a first-class path, not an edge.
- **Why no test caught it:** the restore suites exercise "pack absent" (restores and
  installs) and "pack present at the same version" (skips), and both behave as written.
  There is no case where the same id/version is present with *different content*, because
  the coarse-identity comment is treated as an axiom rather than a condition to test.
- **Recommended fix (primary):** compare fingerprints at the skip. Compute the installed
  package's content fingerprint and compare it with the backup component's; skip only on a
  match. On a mismatch, do not silently proceed — this is the one place with enough
  information to say something true. Two candidate dispositions for the walkthrough:
  refuse the restore naming the conflict, or install the backup's copy side-by-side under
  a distinguishing identity. Recommendation: **refuse, and say why**, because installing
  side-by-side needs a library identity change that this round should not carry.
- **Recommended fix (secondary, and cheap):** the refusal text must distinguish "that
  version is not installed" from "that version is installed but its content differs".
  Today both render as *"Reinstall the exact package version this save was made with."*
  The second case should say the installed copy of that version does not match, and name
  the two fingerprints.
- **Tests:** a restore case with the same id/version installed at a different fingerprint,
  asserting the restore does not silently skip; a case asserting the two refusal texts
  differ; and — per the standing rule that a playtest row is closed by its own evidence —
  a case driving the corrected `campaign_backup_v2.zip` from V0717-02 end to end.
- **Confidence:** high. The mechanism is read from source, the collision is in the trace,
  and the fingerprints are quoted from the build's own records. Not yet reproduced
  headlessly; the probe is small and should be written before the fix.

### [High] V0717-02 — The shipped `campaign_backup_v2.zip` fixture contains v1 content labelled 2.0.0

- **Location:** `builds/tester/Project_Prometheus_v0.7.17/tester-fixtures-v0.7.17.zip`
  → `campaign_backup_v2.zip` → `packs/v076_migration_fixture-2.0.0.zip`.
- **Problem:** the pack bundled inside the backup as "2.0.0" is v1 content wearing a v2
  label. Diffed against the shipped `campaign-packs/migration-v2.zip`:

  | | fixture's "2.0.0" | shipped 2.0.0 |
  |---|---|---|
  | class id | `skirmisher` | `veteran_skirmisher` |
  | roster `class_id` | `skirmisher` | `veteran_skirmisher` |
  | `destination_content_fingerprint` | `sha256:74e9e91e…` | `sha256:45391892…` |
  | `save_migrations[0]` id map | empty | `{"skirmisher": "veteran_skirmisher"}` |

  `74e9e91e…` is v1.0.0's fingerprint. The fixture is internally consistent — its "2.0.0"
  genuinely hashes to v1's value because it *is* v1's content — which is why nothing
  flagged it at build time.
- **Root cause (corrected at the 2026-09-06 walkthrough; the draft had this wrong).** It
  is not a hand-edited version field. All ten data files are byte-identical to the shipped
  **v1** pack, and the manifest is a complete, well-formed v2 manifest whose
  `save_migrations` block was *computed over v1 content*:

  | | fixture "2.0.0" | shipped 2.0.0 |
  |---|---|---|
  | `destination_content_fingerprint` | `sha256:74e9e91e…` (v1's) | `sha256:45391892…` |
  | `aliases.class` | `{}` | `{"skirmisher": "veteran_skirmisher"}` |

  An empty alias map is what a correct generator derives from a v1→v1 diff. So the
  generator ran correctly over the wrong input pack, which is why every field is
  self-consistent and nothing flagged it.
- **The sharper problem: there is no generator.** `campaign_backup_v2` appears in no
  `.py`, `.sh` or `.gd` in either repo. The fixture that certifies the restore path was
  produced by an ad-hoc process that no longer exists, so "regenerate it" is not currently
  an action anyone can take.
- **Provenance, established after the walkthrough — the correct v2 source was tracked all
  along.** `builds/v0.7.16-fixtures/src-v2/v076_migration_fixture` is byte-identical, tree
  and manifest, to the shipped `campaign-packs/migration-v2.zip`. Only the copy bundled
  inside `campaign_backup_v2.zip` is wrong. So this is not a missing source; it is a
  missing *rebuild step*. `MIGRATION-FIXTURE-SOURCES-2026-08-29` closed exactly this shape
  for the migration pack archives and `scripts/rebuild-pack-archive.sh` implements it — the
  backup fixture was simply never brought under that rule, and nothing in either repo
  writes `tester-fixtures-*.zip` or `campaign_backup_v2.zip` today. The fix is to extend
  the existing rebuild-from-tracked-source pattern to the backup fixture, sourcing its
  bundled pack from `builds/v0.7.16-fixtures/src-v2`.
- **Consequence:** Section 4 row 3 is **unrunnable as shipped**, independent of V0717-01.
  Fixing V0717-01 alone will make the restore refuse loudly instead of failing confusingly
  — which is correct behaviour, and still a failed checklist row.
- **Recommended fix (settled 2026-09-06):** write a **checked-in generator** that
  assembles the backup from the shipped `campaign-packs/*.zip` and stamps its saves with
  the real destination fingerprint, then run it. The bundled pack must end up
  byte-identical to `campaign-packs/migration-v2.zip` and the saves' `74e9e91e…` stamps
  corrected to `45391892…`. A one-off regeneration was considered and rejected: it would
  fix this instance and leave the fixture unreproducible next round.
- **Tests:** a bundle gate asserting that every pack inside a shipped backup fixture is
  byte-identical to the correspondingly-named pack in `campaign-packs/`, and that every
  save inside it carries the fingerprint of the pack it names. Both are cheap and both
  would have caught this before the bundle left.
- **Confidence:** high — this is a file diff, quoted above.

### [High] V0717-03 — Fort healing failed with `unknown_primitive` in a resumed battle; cause not determined

- **Location:** `scripts/core/TurnManager.gd:403-435` (`_apply_fort_healing`),
  `scripts/actions/ActionPrimitiveRunner.gd:33-36` (the failing gate),
  `scripts/autoloads/RegistryManager.gd:97-101` (`deactivate`) and `:86-95`
  (`capture_snapshot`/`restore_snapshot`), `scripts/autoloads/DataManager.gd:209-268`.
- **Problem:** `godot.log` carries, once, in the 17:44:58 launch:

  ```
  ERROR: TurnManager: terrain healing failed for unit (unknown_primitive)
  ```

  It appears after `campaign_restored → node_resumed → campaign_restaged → node_resumed`.
  `unknown_primitive` means `_registry.has_entry("action_primitives", "apply_hp_delta")`
  returned false, so the live catalogue was empty or null at that moment. The player-visible
  effect is that a unit standing on a fort silently did not heal.
- **What is established:** the failure requires the catalogue to be absent, because
  `commit_candidate` refuses any candidate whose required families are empty
  (`RegistryCatalog.REQUIRED_FAMILIES` includes `action_primitives`), and the preceding
  `pack | activate | outcome=completed` proves a commit succeeded. So the catalogue was
  populated at activation and gone by the heal. Two paths can produce that:
  `RegistryManager.deactivate()`, which installs a fresh empty catalogue; and
  `restore_snapshot()` with an empty dictionary, which sets `_catalog = null` outright and
  has no guard. `ContentSession.registry_snapshot` defaults to `{}`.
- **What is not established:** which of those actually fired here. Every
  `restore_content_session` call site in `scripts/` pairs with a `capture_content_session`,
  so the empty-snapshot path has no obvious caller, and the trace shows an `activate` after
  the last `deactivate` in that launch. **This review does not have the mechanism.**
- **Why "it only happened once" is not reassurance:** `_apply_fort_healing` runs only when
  a unit is below max HP *and* standing on terrain with a non-zero `heal_fraction`. In the
  Proving Grounds pack exactly one terrain qualifies — `terrain__fort.json`, at
  `heal_fraction: 0.1`. One error may well be one occurrence out of one. It is equally
  consistent with "fort healing is broken in resumed battles" as with "a rare race".
- **Correction from the 2026-09-06 walkthrough — the draft's correlation does not hold.**
  `godot.log` records **six** boots (17:31:04, 17:44:58, 18:07:04, 18:20:14, 18:21:15,
  18:22:00), and `BuildInfo` prints that stamp once per boot from `Boot.gd`. The bundle
  contains **one** diagnostics log, `diagnostics-20260906T173104-2260.log`, named for boot
  1's stamp and pid; its records run to t=3,353,978 ms and `MANIFEST.created_at_utc` is
  `18:27:03Z`, so the exporting process booted at 17:31:04 and was **still alive at
  18:27:03** — through all five later boots. At t=836,269 (17:45:00) it logged a
  `pack | deactivate`, four seconds after boot 2 started. **At least two instances ran
  concurrently against one `user://` and one `godot.log`.** Therefore:
  - The fort-healing error belongs to **boot 2**, whose entire output is four
    `PLAYTEST CONTEXT` lines and the error, and whose diagnostics records were never
    returned (see V0717-09).
  - The step "the preceding `pack | activate | outcome=completed` proves a commit
    succeeded" reads that record out of a **different process**. The premise that the
    catalogue was ever populated in the failing process is unsupported. Adjacency in
    `godot.log` is not sequence; the file is a multi-process interleave.
  - This supplies a mechanism candidate the draft did not have: a second instance booting
    into a restored campaign while another instance holds and rewrites shared
    `user://campaign_packs` state.
- **Recommended fix:** none yet — **this needs a repro before a patch.** **Settled 2026-09-06: probe concurrency first** — two headless
  processes against one `user://`, asserting
  `has_entry("action_primitives", "apply_hp_delta")` survives the other instance's pack
  operations. The single-process probe (activate, save a battle, suspend, resume, assert
  across the resume, then walk the resume path with an injected assertion at each
  catalogue write) is second, not first, because the failing launch was demonstrably a
  concurrent instance. If the probe does not
  reproduce, add a `registry` diagnostics record on every catalogue commit, deactivate and
  snapshot-restore, and ship it in the next build rather than guessing.
- **Fix worth taking regardless:** `RegistryManager.restore_snapshot()` should refuse a
  snapshot with no catalogue instead of nulling the live one, and record it. A null
  catalogue turns every action primitive in the game into a silent no-op, which is too
  large a blast radius for an unguarded dictionary lookup. This is a guard, not the fix.
- **Confidence:** the error is certain; the cause is open. **Do not close this row on a
  green unit test for the guard above** — that would repeat the V0715-02 mistake of
  proving the code matches itself.

### [Medium] V0717-04 — The layout audit reports scrolled content as overflow, and silences its own channel in 2.5 minutes

- **Location:** `scripts/shared/LayoutAudit.gd:37-52` (`_walk`'s overflow test);
  `scripts/autoloads/DiagnosticsLog.gd:290-308` (the cap).
- **Problem:** `_walk` emits `control_overflow` for any visible Control whose global rect
  is not enclosed by the viewport rect, with no exemption for descendants of a
  `ScrollContainer`. A scroll container's content is *supposed* to exceed the viewport;
  that is what makes it scroll. The Settings screen therefore reports its entire subtree as
  overflowing on every settle:

  ```
  149246 | layout | control_overflow | path=…/Panel/ScrollContainer/Margin reason=size_class_changed rect="[P: (4.5, -306.0), S: (681.0, 1709.0)]" viewport="[P: (0.0, 0.0), S: (694.0, 720.0)]"
  ```

  A 1709 px-tall margin inside a 720 px viewport is a correctly configured scroll region,
  reported as a defect.
- **Consequence, and this is the real cost:** the `layout` category emitted 10,678 records
  and its 400-record cap fired at **t=150 s of a 3,300 s session**:

  ```
  150280 | layout | capped | limit=400 note=category_silenced_for_this_session
  ```

  Every layout record after 2.5 minutes is gone — the entire fullscreen pass, the 4K
  window, and all of Section 3's banner resizes. Section 3 explicitly instructs the tester
  to *"include the diagnostics ZIP so the resize records can be correlated with the
  screenshot"*, and those records do not exist. 388 of the 401 retained records are
  false-positive overflow from one screen. `battle` capped the same way at t=1768 s.
- **Root cause:** an instrument with a fixed budget and an unbounded false-positive rate
  spends its whole budget on the false positives, and does so earliest in the session when
  the least interesting thing is happening. The cap is working exactly as designed; the
  predicate is what is wrong.
- **Recommended fix:** exempt a Control from the overflow test when any ancestor is a
  `ScrollContainer` and the overflow is along that container's scrolling axis — test the
  control against its nearest clipping ancestor's rect, not the viewport's. Then
  reconsider the budget: a per-category cap that can be exhausted by one screen in one
  session should either be raised for `layout` or made a reservoir sample so late records
  survive.
- **Tests:** a case asserting a tall child of a `ScrollContainer` produces **no**
  `control_overflow` finding; a case asserting a control genuinely outside its clipping
  ancestor still does; and a cap test asserting a session that visits Settings and then
  resizes at fullscreen retains records from both.
- **Addition 1 (walkthrough): the budget problem is not downstream of the predicate.**
  `battle` capped with *no* false positives — 401 emitted, 400 dropped, 801 total — going
  silent at t=1,769 s of a 3,354 s session. **The back half of the campaign has no battle
  records**, including the chapters behind Section 5's pass. Fixing the overflow predicate
  does nothing for that.
- **Addition 2 (walkthrough): `diagnostics/records.json` contains no layout records at
  all.** `DiagnosticsLog.MAX_RECORDS = 512` bounds the in-memory ring, so the JSON dump is
  the last 512 records across all categories, beginning at t=873,996 — 14.5 minutes in.
  Its breakdown is `battle 380, save 41, session 40, pack 26, campaign 16, viewport 9`:
  zero layout, and none of V0717-05's evidence. The complete record survives only in
  `diagnostics_logs/*.log` (1,383 lines = the sum of all `emitted` counters). **The `.log`
  is authoritative; the JSON is a lossy tail.** Two caps stack on the same channel and the
  machine-readable artifact is the lossier one.
- **Settled 2026-09-06:** fix the predicate, **and** raise the caps to per-category values
  sized from this session's measured rates, **and** make the cap a reservoir sample so late
  records survive instead of the channel going silent. `records.json` becomes the full
  retained set. The draft's "measure next round before touching the budget" was rejected:
  `battle`'s overrun is already measured and free of false positives.
- **Confidence:** high for the predicate (source read plus the quoted records); the two
  additions are counter arithmetic from the build's own records.

### [Medium] V0717-05 — Four keybinding labels are clipped, contradicting the Section 2 pass

- **Location:** `scripts/ui/SettingsScreen.gd:65` and the `KeybindList` rows it builds;
  detector at `scripts/shared/LayoutAudit.gd:90-105`.
- **Problem:** the tester ticked *"no label is clipped"*. The instrument disagrees, twelve
  records across three settle events covering four distinct labels:

  ```
  149246 | layout | label_clipped | path=…/VBox/KeybindList/@HBoxContainer@1813/@Label@1812 text_length=28 size="(139.0, 17.0)" minimum="(1.0, 17.0)"
  149763 | layout | label_clipped | path=…/VBox/KeybindList/@HBoxContainer@1822/@Label@1821 text_length=34 size="(124.0, 15.0)" minimum="(1.0, 15.0)"
  ```

  28-34 characters rendered into 124-139 px. The `minimum` of `1.0` is the tell: these
  labels have an overrun behaviour configured, so they report a 1 px minimum width and
  their `HBoxContainer` never grows to fit them. The row cannot know it is too small.
- **Root cause:** the same shape V0716-04 found in compact stacking — a label that trims
  itself surrenders the minimum-size signal the container uses to allocate space. The
  keybind rows were not part of V0716-04's fix.
- **Confirmation of the instrument, not just the defect:** this is the round's diagnostics
  programme working as intended. A human at 694 px did not see it; the build did.
- **Recommended fix:** give the keybind rows the same treatment the compact stacking fix
  applied — stack label above control below the compact threshold, or let the label keep a
  real minimum width and elide only past it.
- **Tests:** extend `scripts/tests/test_settings_compact_containment.gd`, which already
  reaches `Panel/ScrollContainer/Margin/VBox/KeybindList`, with an assertion that no
  keybind label reports `minimum.x < size.x` at the compact width.
- **Confidence:** high — the records are unambiguous and name their nodes.

### [Medium] V0717-06 — `diagnostic_error_count` does not count engine errors, so the automatic error bundle never fires for them

- **Location:** `scripts/shared/DiagnosticsReturnBundle.gd:87`;
  `scripts/autoloads/DiagnosticsLog.gd:304-305` (the only increment), `:114-119` (the
  automatic export).
- **Problem:** `MANIFEST.json` reports `"diagnostic_error_count": 0`. `godot.log` from the
  same session contains four `ERROR:` lines, including V0717-03's. `_error_count` is
  incremented only for records emitted *through* `DiagnosticsLog` with `is_error` set;
  Godot's `push_error` never reaches it.
- **Why it matters more than a wrong number:** `_exit_tree` exports an automatic return
  bundle only `if _error_count > 0`. A session whose only failures are `push_error`s — which
  is exactly this session — exports nothing automatically. The safety net does not cover
  the most common way this codebase reports a failure.
- **Second-order cost:** the checklist tells the tester *"Do not spend time transcribing
  normal log lines or counting errors"* on the grounds that the build measures them. For
  `push_error` the build does not, and V0717-03 came within one `grep` of leaving with the
  round.
- **Addition (walkthrough): the cap returns before the counter increments.** In
  `DiagnosticsLog`, the `category_silenced_for_this_session` branch `return`s above
  `if is_error: _error_count += 1`. Once `layout` went silent at t=150 s and `battle` at
  t=1,769 s, an error record in either category stopped counting as an error at all — the
  safety net disarms itself on exactly the channels noisy enough to matter.
- **Second addition:** per V0717-03's correction, all four `ERROR:` lines may belong to
  processes other than the exporter, so `_error_count == 0` is over-determined. **An
  in-process `push_error` hook would still have returned zero here.** The bundle-time
  `godot.log` scan is the load-bearing half of the fix, not the optional one.
- **Recommended fix:** count engine errors too. Either install a log-capture hook that
  feeds `push_error`/`push_warning` into the channel, or scan the Godot log at bundle time
  and report both counts as separate manifest fields. Recommendation: **both counters,
  named separately** — conflating them would hide which instrument saw what.
- **Tests:** a case asserting a session containing one `push_error` and no channel error
  reports a non-zero engine-error count and triggers the automatic bundle.
- **Confidence:** high — source read plus the counted discrepancy (4 vs 0).

### [Low] V0717-07 — Two refusals that name a cause the player cannot act on

Both are small, both are in the family the round set out to fix, and both should be taken
while the files are open.

- **A. Slot-class-full renders as a generic commit failure.** At `2978937` an import was
  refused with `reason_code=commit_failed` and the text *"The imported save could not be
  stored in the selected slot."* The actual cause is in `godot.log`:
  `SaveManager: manual 'mid_map' slot class is full for campaign '…'`
  (`scripts/autoloads/SaveManager.gd:833-837`). The player is not told the class is full
  or that deleting a save resolves it — the tester retried 21 seconds later and it worked,
  so nothing was lost, but the message did not help them get there.
  **Fix:** propagate `_manual_write_allowed`'s reason through `_commit_validated_slot` so
  the refusal names the full slot class and offers the replacement picker, which already
  exists for the occupied-slot case.
- **B. A raw engine string in a structured reason field.** At `2368402`:
  `pack | validate | outcome=refused … reason_code="DataManager: save has no campaign
  package identity" unresolved_ids=["DataManager: save has no campaign package identity"]`.
  The source is `scripts/autoloads/DataManager.gd:687`, which assigns an engine-prefixed
  sentence to `_activation_errors`. Section 4 asks that no raw code be shown by itself;
  a class name and a colon in a `reason_code` is the same failure in a different costume,
  and `unresolved_ids` is meant to hold ids, not prose.
  **Fix:** give this refusal a real reason code and let the prose live in the message.

### [Medium] V0717-08 — The backup/restore path emits no diagnostics records at all

- **Added at the 2026-09-06 walkthrough.**
- **Problem:** across all 1,383 records there is no `backup` category and no `restore`
  action. The category/action tally covers `pack | install/activate/deactivate`,
  `save | save_slot/inspect_portable_save/revalidate_slot/import_portable_save/load`,
  `battle`, `campaign`, `layout`, `viewport` and `session` — and nothing else. The
  subsystem that produced the round's only failed row is the one subsystem
  `DIAG-SAVE-PACK-LIFECYCLE` cannot see.
- **Consequence:** V0717-01 had to be established from the **absence** of a `pack | install`
  record between 2615404 and 2641478. That is a sound argument here only because the
  surrounding records happen to bracket it; it is not a method the next round can rely on,
  and it cannot show *which* component was skipped or why.
- **Recommended fix:** emit restore lifecycle records — candidates chosen, each package
  installed or skipped **with both fingerprints**, each save revalidated with its outcome.
  Kept as its own row rather than folded into V0717-01, because it is a coverage gap in the
  instrument, not a defect in the service.
- **Confidence:** high — it is a tally of the returned records.

### [High] V0717-09 — A return bundle carries the diagnostics records of only one process

- **Added at the 2026-09-06 walkthrough.**
- **Location:** `scripts/shared/DiagnosticsReturnBundle.gd:152-163` (`_source_files`).
- **Problem:** the collector takes **every** `godot*.log` but only the current process's
  diagnostics log:

  ```gdscript
  if filename.begins_with("godot") …:
      sources["godot_logs/%s" % filename] = path
  elif path == current_diagnostics_path and filename.begins_with("diagnostics-") …:
      sources["diagnostics_logs/%s" % filename] = path
  ```

  `DiagnosticsLog` names its file `diagnostics-<stamp>-<pid>.log` and opens it with
  `FileAccess.WRITE`, so the file is per-process. This session had six boots and returned
  one log.
- **Consequence:** the structured records for five of six launches — including the one that
  raised V0717-03's error — exist on the tester's disk and did not come back. A return can
  therefore look complete while the failure it was collected to explain is missing from it.
  The asymmetry with `godot*.log` is what disguises this: the text log *is* complete, so
  the launches are visible while their records are not.
- **Recommended fix:** collect every `diagnostics-*.log` in `user://logs`, bounded by count
  and total size, matching the existing rule for `godot*.log`.
- **Tests:** a bundle case asserting that two diagnostics logs in `user://logs` both appear
  in the ZIP, and that the bound is applied newest-first.
- **Confidence:** high — source read plus the returned bundle's contents.

## Positive observations

Worth recording, because three of these are rows that cost previous rounds.

- **The phase banner is done.** All six Section 3 rows pass on a real 4K display, across
  windowed/fullscreen transitions, resize-during-animation, and two phase changes in quick
  succession. No banner record or error appears anywhere in the bundle. V0716-01 closed
  it and this round confirms it natively.
- **The campaign is playable end to end.** Six chapters, all six node types
  (drill/rout/seize/boss/escape/defend), `campaign_state: completed`, no crash, no
  progression dead end. Turn counts per chapter — 3, 12, 6, 3, 4, 7 — read like a game
  being played rather than skipped through.
- **Migration v1→v2 works, including the part that is hard.** `version change
  references.png` shows the preview naming `skirmisher → veteran_skirmisher`, 5 references
  renamed and 11 unchanged, with the original preserved; the trace confirms
  `migrate_save_into_slot … outcome=ready` and a clean load of `resume_battle_migrated`.
- **The free-roam round trip is clean.** Suspend → reload → export produced a non-empty
  save that correctly identifies `prometheus-proving-grounds 0.1.0 / proving_grounds`.
- **The diagnostics programme did its job.** Every finding above came out of the bundle.
  The tester wrote two sentences and the round is still fully diagnosable, which is
  precisely what the work order set out to achieve.

## What must be true before the next candidate ships

The fix queue, in build order. Ordering is by dependency, not severity.

| # | Fix | Blocks the round? | Rough size |
|---:|---|---|---|
| 1 | **V0717-02** — checked-in generator, then regenerate `campaign_backup_v2.zip` from the shipped v2 pack | Yes — nothing else can be retested without it | Moderate; the generator does not exist yet |
| 2 | **V0717-01** — fingerprint comparison at the restore skip; refuse and name the conflict; two distinct refusal texts | Yes | Small-to-moderate |
| 3 | **V0717-09** — collect every `diagnostics-*.log` in the bundle | Yes — without it the next return is as incomplete as this one | Small |
| 4 | **V0717-04** — scroll-aware overflow predicate, per-category caps sized from measured rates, reservoir sampling, `records.json` as the full retained set | Yes | Small predicate; moderate for the budget |
| 5 | **V0717-03** — concurrency probe first, then the resume probe; ship the `restore_snapshot` guard and registry records regardless | Yes to investigate; the *fix* may not be in this build | Unknown — that is the finding |
| 6 | **V0717-06** — count engine errors at bundle time, move `_error_count` above the cap return, arm the automatic bundle on both | Yes — it is the safety net for #5 | Small |
| 7 | **V0717-08** — restore lifecycle records with both fingerprints | No, but it is how #2 gets proved next round | Small |
| 8 | **V0717-05** — keybind row minimum widths | No, but cheap and in scope | Small |
| 9 | **V0717-07 A and B** — two refusal messages | No | Small |

## Decisions settled at the owner walkthrough, 2026-09-06

All seven of the draft's open questions were answered and two findings were added. Do not
re-open these.

1. **v0.7.17 is blocked**, on **V0717-01, -02, -04 and -09**. V0717-09 joins the draft's
   three because it is why V0717-03 has no mechanism: without it the next round's evidence
   is as incomplete as this one's.
2. **V0717-01's disposition: refuse now, side-by-side later.** The next build refuses the
   restore and names the conflict. Installing the backup's copy under a distinguishing
   identity is recorded as the *destination*, and lands as the closeout of
   `SAVE-IDENTITY-BLOCK-UNIFICATION-2026-09-05` — the refusal is explicitly an interim
   answer, not the end state.
3. **The coarse `id|version` identity does not survive, but not in this round.**
   `SAVE-IDENTITY-BLOCK-UNIFICATION-2026-09-05` is pulled forward off `5-backlog` and
   scheduled sooner on the strength of two consecutive rounds failing on
   fingerprint-vs-version disagreement (V0716-03, then V0717-01).
4. **V0717-02 is fixed by a checked-in generator**, sourced from the shipped
   `campaign-packs/*.zip`, not a one-off regeneration. This makes the row larger than the
   draft's "small" estimate. The bundle gate the draft proposes still applies.
5. **V0717-03: probe concurrency first.** The failing launch was demonstrably a second
   concurrent instance. The `restore_snapshot` guard and the registry records ship
   regardless; the fix ships only if a probe finds the mechanism.
6. **The layout budget changes now, not next round.** Predicate fix **plus** per-category
   caps sized from measured rates **plus** reservoir sampling, and `records.json` becomes
   the full retained set. `battle`'s overrun is already measured and free of false
   positives, so "measure first" would knowingly lose another campaign's back half.
7. **The next checklist shrinks Sections 3 and 5 to smoke checks and expands Section 4**,
   where both of the last two rounds actually failed.
8. **The GPU discrepancy needs no action** — the tester reported a 4070 Ti, the build
   recorded a 5070 Ti, and the instrument is the record. This is exactly the transcription
   error the diagnostics programme was built to make harmless, and it worked.

Two additions were made to the draft at the walkthrough: **V0717-08** (the restore path
emits no records) and **V0717-09** (a bundle returns one process's records). Two of the
draft's claims were corrected: V0717-02's root cause (a generator run over the wrong input,
not a hand-edited version field — and no generator is checked in at all) and V0717-03's
mechanism analysis (which correlated a `godot.log` error with diagnostics records from a
different process).

## Standing rules for closing any of these

- **Re-run the return's own evidence.** `Incoming/v0.7.17 return/` holds the real bundle,
  the real saves and the real fixture. A row opened by a playtest return is closed by
  driving those artifacts through the real service, not by a synthetic case written to
  match the code under test.
- **Write the probe before the fix.** A probe that fails on `54c2e3e8` and passes after is
  the only artifact that distinguishes a fix from a coincidence. V0717-01 and V0717-04 both
  have obvious ones.
