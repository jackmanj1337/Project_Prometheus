---
Type: design decisions
Status: Accepted (partial) — Branches A–H resolved with the owner; I–K pending
Last verified: 2026-07-24
Tracker: DISCUSS-CAMPAIGN-LIBRARY-UX-2026-07-23
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Campaign Library UX — Owner Decisions (session of 2026-07-24)

Records owner decisions taken in the design discussion that walked the
[owner-questions packet](campaign_library_owner_questions_2026-07-23.md) branch by branch.
Companion research: [Campaign Library UX Research](campaign_library_ux_research_2026-07-23.md).
Planning ownership and sequencing remain in the
[Project Control Plane](../plans/project_control_plane_2026-06-29.md).

Each entry copies the stable id and the exact owner answer. "Accepted-default" means the
research recommendation was affirmed without re-litigation; "Answered" means an explicit
owner decision, sometimes refining the recommendation.

## Discussion structure

The 55 questions were reorganised into dependency-ordered branches so each mostly depends
only on branches above it:

| Branch | Topic | Questions | State after 2026-07-24 |
|---|---|---|---|
| A | Object model & hierarchy (the spine) | CL-MODEL-01/02/03, CL-SAVE-01 | Resolved |
| B | Library role & top-level shape | CL-MODEL-04/05, CL-NAV-01 | Resolved |
| C | First run & zero-content boot | CL-FIRST-01/02/03/04 | Resolved |
| D | Install & pack lifecycle | CL-LIFE-01…09 (+ CL-MISSING-04 fingerprint case, pulled forward) | Resolved |
| E | Launch / New Game / rule profiles | CL-LAUNCH-01…05 | Resolved |
| F | Runs & saves detail | CL-SAVE-02/03/04/05 | Resolved |
| G | Missing / incompatible content | CL-MISSING-01…05 | Resolved |
| H | Transfers: import/export/backup/restore | CL-TRANSFER-01…06 | Resolved (restore mechanics -03/04/05 ride the deferred backup backlog) |
| I | Navigation & accessibility (cross-cutting) | CL-NAV-02…07 | Pending (controller fallback recurs) |
| J | Safety, trust, privacy (cross-cutting) | CL-SAFETY-01…04 | Pending (CL-SAFETY-01 wording pre-answered) |
| K | Author / advanced surfaces | CL-ADV-01…04 | Pending (editor integration lands here) |

## Branch A — Object model & hierarchy

- **CL-MODEL-01 — Answered.** Top-level player object is the **Campaign**, displayed grouped
  under its installed **Pack**. Pack is the content-management/grouping boundary (install,
  version, export, repair); campaign is the launch object (the row you select to play).
- **CL-MODEL-02 — Answered.** A pack may contain **many campaigns**, grouped by pack.
- **CL-MODEL-03 — Answered.** Player-facing vocabulary: **Campaign, Run, Save, Backup**.
  **Pack** and **Rule Profile** are reserved for details/secondary surfaces.
- **CL-SAVE-01 — Answered.** Saves organise as **Campaign → Run → Save**. A *run* is one
  playthrough bound to a chosen rule profile and its cumulative progress; a *save* is a
  recovery point inside a run. The global "Load" shortcut becomes a **filtered deep-link**
  into this same tree, not a second flat model.

Rationale the owner affirmed: runs let a player replay a campaign under different rules
without reinstalling the pack or deleting old saves. Consequence: the **rule profile is a
property of the Run** (this pre-answers CL-LAUNCH-02). Engineering cost: `SaveManager.gd`
today uses a flat save namespace; adopting this tree adds campaign+run grouping keys and a
migration path for existing saves.

## Branch B — Library role & top-level shape

- **CL-MODEL-04 — Answered.** Library is a **progressive-disclosure hybrid**: launch-first by
  default, management behind a Manage section. Main Menu restructures to: **Continue**,
  **Manage Library** (absorbs the former New Game + Load), Settings, Quit.
- **CL-MODEL-05 — Answered.** Row metadata: title, pack + author, status, last-played,
  compatible-run count. Version / licence / fingerprint live in the details pane.
- **CL-NAV-01 — Answered.** Layout is a **list + master-detail pane**, collapsing to
  sequential screens at narrow widths / small windows.
- **Continue** = resume the **most-recently-touched save** (created or resumed), disabled when
  there are zero saves. It is the fast path; the Library can therefore afford previews and
  confirmations because impatient players use Continue.
- **Copy / Edit** buttons and GUI campaign-editor integration are **deferred to Branch K**.
  The editor stays an optionally-bundlable but **separable program**, and authors get a
  dedicated **encounter/balance test environment** (its own fixtures, not the player save
  model). Editing installed content implies an unpack-to-editable working copy → re-export
  flow, because installed packs are immutable (CL-ADV-01).

## Branch C — First run, discovery & the import architecture

- **CL-FIRST-01 — Answered.** The empty library leads with getting content in. Primary path is
  an **in-engine, controller/touch-navigable list of a known inbox folder**; secondary are an
  **Import from file** button (native OS picker) and a **drop area** (drag-and-drop).
- **CL-FIRST-02 — Answered.** v1 discovery = **one fixed, app-managed known inbox folder**
  (scanned into the in-engine list) **plus** native-picker import **plus** drag-drop. A
  configurable folder path is deferred post-v1. This pulls a scan folder *into* v1, driven by
  the Steam Deck evidence below.
- **CL-FIRST-03 — Answered (player side).** No bundled *playable* example in the player UI
  (zero-content boot stands). A **non-playable author template** may exist with the editor
  tooling (Branch K), outside the runtime install.
- **CL-FIRST-04 — Answered.** Distinct explicit states — **empty / scanning / permission-denied
  / unreadable-invalid** — each with its own message, action (Retry / Choose Folder), and
  accessibility announcement.

### Import architecture (spans C and D)

```
   Inbox folder  ⇄  two-way exchange (raw archives in, exports out)
        │ explicit one-tap import (preflight passes) — never auto-install
        ▼
   Verified store  →  installed, promoted, immutable packs (CampaignPackRegistry scans here)
        │  content hash recorded at import
        ▼
   Every scan / load: recompute hash, compare → non-blocking "modified" warning on mismatch
```

- **Inbox is a discovery/exchange location, not the install store.** Dropping a `.zip` makes it
  *discovered* (read-only preflight → "Ready to import" / "Invalid"), not installed. Import runs
  the existing stage-and-atomic-promote pipeline into the verified store, then removes the
  redundant archive from the inbox.
- **Content hash = the pack fingerprint.** Computed over the promoted content deterministically
  (aligns with the exporter's proven deterministic bytes), recorded at import, re-verified on
  every scan and load. The hash proves **integrity since import** (catches corruption / local
  edits), **not authenticity/provenance** (needs signatures, deferred by Rec #10).
- **Exports dump into the inbox**, so it holds mixed artifact types. The **inbox scanner routes
  by extension** (packs → Library, portable saves → Load, status records / backups → their
  flows). This makes the distinct extensions of CL-TRANSFER-02 load-bearing.

### OS file-picker & Steam Deck findings

- Swap the existing in-engine `FileDialog` nodes to **native** (`use_native_dialog`); add
  **drag-drop** (`files_dropped`); plan a **branded extension** for double-click import via OS
  file association (export/installer config — approval-gated, Windows-specific).
- **Steam Deck:** the native (portal) dialog appears under gamescope but is **not
  gamepad-navigable** — the Deck only papers over it with mouse-emulation (trackpad cursor,
  touchscreen, on-screen keyboard), and D-pad often tracks cursor position rather than focus.
  Therefore the **in-engine known-folder list is the primary path on the Deck**; native picker,
  drag-drop, and double-click are desktop-only conveniences. This is why a known inbox folder is
  in v1 (CL-FIRST-02). Evidence: godot#98962, godot PR#80104, Steam Deck / OpenMW community
  reports (2026-07-24).

## Branch D — Install & pack lifecycle

- **CL-LIFE-01 — Answered.** Preview is **mandatory** — the inbox scan supplies it read-only
  before any import.
- **CL-LIFE-02 — Answered.** Identity/trust fields: title, pack + author, version, licence,
  engine/schema compatibility; fingerprint in details; **no signature/"verified" claim**.
- **CL-LIFE-03 — Answered.** Same id + same version re-import is **rejected as already
  installed**; differing bytes are flagged as a **modified copy**. The details pane must
  distinguish multiple modified copies (fingerprint, import date, "modified" flag), plus a
  **local, player-assigned `hash → nickname` map** stored player-side (never written into the
  pack, which would change its hash).
- **CL-LIFE-04 / CL-LIFE-07 — Answered.** Same id / new version installs **side-by-side and
  immutable**. Existing runs stay **pinned** to their exact version+fingerprint; new runs
  default to the newest compatible version but may pick an older installed one. Multiple
  versions coexist; cleanup is manual (delete a version once no run pins it). Accepted disk cost
  to keep the "replay without breaking saves" promise.
- **Version updates are manual in v1 — no migration engine.** The upgrade path is:
  (1) export the old run → (2) import the new version (installs side-by-side) →
  (3) import the old run into the new version → (4) delete the old pack. Step 3 still faces
  compatibility (fingerprint mismatch → non-blocking warning; references must still resolve at
  activation). Rec #7's "automatic pre-migration backup" becomes "export your run first (step
  1) = your backup." Version numbers are advisory — sort order, author-declared editions, and a
  save-compatibility signal — never an auto-trigger.
- **CL-LIFE-05 — Accepted-default.** Different id / same title is allowed, disambiguated by
  author/id.
- **CL-LIFE-06 — Answered.** **No Disable in v1.** The per-pack/campaign action set is:
  **Import, Export clean, Export with runs, Export run(s) only, Export campaign status
  record(s), Delete.**
- **CL-LIFE-08 — Answered.** Dependency/load-order UI is **hidden**; the only validator language
  is "this pack is not self-contained."
- **CL-LIFE-09 — Answered.** Deletions require confirmation, with a **secondary confirmation when
  the pack/campaign includes runs not marked completed** (this guards step 4 of the manual
  upgrade). Imports are preview-then-commit; reversible/inspect actions need no confirmation.
  Trash/recovery is deferred (confirm + hard delete for v1; ties CL-SAFETY-04).

### Integrity vs validity policy (CL-MISSING-04 fingerprint case, pulled forward)

- **Hash mismatch → non-blocking warning** ("content modified since import — errors may occur").
  The player/author may proceed. This never traps a player behind a checksum and keeps installed
  content editable by authors.
- A non-blocking warning lets you *try*; it does not make genuinely broken content run. If the
  modified pack is also structurally invalid, it **fails at point of use with a diagnostic**, not
  a pre-emptive block. Two layers: *modified* = warn+allow; *unrunnable* = graceful failure at
  use.

Check-point contract (where each check runs):

| Checkpoint | Integrity (hash) | Validity (structure/references) | On failure |
|---|---|---|---|
| Inbox scan / preflight | candidate hash | hostile-ZIP + structure (read-only) | "Invalid, can't import"; store untouched |
| Import / promote | **hash recorded** | re-validate then atomic promote | rollback; source untouched |
| Library scan / rescan | recompute → compare | structural re-check | mismatch → non-blocking badge; broken → "Invalid pack" |
| Campaign select → New Run / activation | (optional) | **deep Tier-2 reference resolution** | unresolvable → this launch fails w/ diagnostic (the real hard gate) |
| Load / resume a run | compare run's fingerprint | required version present & enabled? | mismatch → non-blocking warning; missing → blocked ("Missing content") |
| Export (clean pack) | — | exporter revalidates | no export written |
| Migration / restore | verify source & target | validate before & after, transactional | rollback |

## Campaign status record — connection to current implementation

The status record is a **cross-campaign continuity artifact** (carryover gold/bonuses, narrative
branching that references prior named characters/choices) — explicitly **not a resumable save**.
It is **already implemented at the data layer** and the existing code matches the design:

- `scripts/resources/CampaignStatusRecord.gd` — open-dictionary payload (`completion`, `facts`,
  `counters`); "no story fact becomes an engine field"; SHA-256 `checksum` verified on load;
  provenance fields (record/author/campaign id + version, created_at_utc); `FORMAT_VERSION = 1`.
- `scripts/resources/CampaignStatusStore.gd` — separate store at `user://campaign_status`
  ("records are player state, never campaign-pack content"); atomic write with rollback;
  `is_compatible()` matches same-campaign NG+ or the target's author-declared
  **`compatible_status_sources`** (author_id + campaign_id + accepted `campaign_versions`);
  `import_into()` writes `carry_forward_facts` + `imported_record_ref`; `allow_manual_foreign`
  is the player override. `compatible_status_sources` is the same field `CampaignPackRegistry`
  already surfaces per campaign — the cross-pack sequel mechanism is wired end to end.

**Aligns with the open-registry / [EXT] extensibility principle** (author-defined payload, no
engine enum). **New work is only the player-facing integration** — a distinct branded extension,
export into the inbox, and import via the Library action menu — not building the artifact.
Security posture confirmed by the code: the checksum is self-computed and stored in the record,
so it detects corruption, **not** tampering → design carryover as **fun continuity, not
competitive integrity**.

## Branch E — Launch / New Game / rule profiles

- **CL-LAUNCH-01 — Answered.** Selecting a campaign row **opens its details pane**
  (master-detail), with explicit **Continue** / **New Run** actions inside. It does *not*
  launch on select. Speed already lives in the Main Menu **Continue** (Branch B, resume the
  most-recently-touched save), so the Library is free to be the context-and-confirmation
  surface — a preview boundary, not a hair-trigger. Rejected: immediate launch (one stray
  press mutates/loads) and an action-menu popup (extra tap, less room for status/metadata).

- **CL-LAUNCH-02 — Answered (pre-answered by Branch A).** Rule profiles are chosen in a
  **New Run step**, after campaign details — the rule profile is a property of the *Run*
  (CL-SAVE-01). Matches `IMPL-RULE-PROFILES`: New Game resolves schema defaults → selected
  profile → explicit campaign defaults, and stores both the selected `profile_id` and the
  fully-resolved snapshot on the run.

- **CL-LAUNCH-03 — Answered.** The New Run screen uses **source-labelled controls**: each
  rule shows an editable control tagged with where its value came from (schema default /
  profile / campaign default), **lock text** on mandated rules ("Locked by campaign"), and a
  **changed-value summary** listing what the player altered from the resolved default. This is
  cheap because `CampaignRules` fields are flat scalars (bools/enums/ints) and the precedence
  is already fixed — `mandate → node override → mid-map override → resolved campaign default`;
  the UI only needs a source label per field plus a locked flag. Rejected: summary-only
  (removes the point of adjustable profiles) and bare disabled controls (no "why is this
  locked?" explanation).

- **CL-LAUNCH-04 — Answered.** Two-tier validation: a **lightweight status** from the library
  scan for display (Ready / Modified / Invalid badge), and a **full Tier-2 reference + profile
  resolution run immediately before New Run / Resume commits**. This matches the Branch D
  checkpoint table, which already puts deep Tier-2 reference resolution at *New Run /
  activation* as the real hard gate, and it closes the stale-mutation window (a file edited
  between scan and launch fails safely with a diagnostic instead of launching broken). Rejected:
  validate-at-selection (latency browsing content you may not play) and scan-time-only
  (trusts a possibly-stale scan into a broken launch).

- **CL-LAUNCH-05 — Answered.** Persist **last-focused campaign + sort/filter state** across
  sessions, so returning players land where they left off and first-focus is meaningful.
  Deliberately **not** view-mode — v1 avoids view-toggle proliferation. A couple of new
  `SettingsManager` (`user://settings.cfg`) keys; these are Library-navigation prefs, kept
  distinct from the per-save gameplay rules that manager already refuses to globalise.

**Implementation linkage.** CL-LAUNCH-02/03 are the *player-facing presentation contract*
for the already-tracked **`IMPL-RULE-PROFILES`** slice (data/save layer); that row's reference
now points here so the New Run screen contract is not lost. CL-LAUNCH-01/04 are properties of
the Library launch surface (details pane + validate-before-commit gate) and CL-LAUNCH-05 adds
two `SettingsManager` keys — all folded into the consolidated Library implementation-planning
pass that follows the discussion (Branches F–K), not spun out as premature standalone rows.

## Branch F — Runs & saves detail

Branch F is largely a *confirm-and-nail-down* pass: the save-type taxonomy is already
**data-driven** in code (`scripts/resources/CampaignRules.gd` `save_slot_classes` +
`autosave_rules`) and the persistence/ledger work already drew the line between browsable
saves and in-memory internals. The owner affirmed that line and chose the **lean v1**
shape for scaling.

- **CL-SAVE-02 — Answered.** The run/save browser shows exactly the **persisted** classes:
  manual **Campaign Saves**, **Campaign Autosave**, **Suspend** (presented as *Resume* — a
  single slot, `consumed_on_load`, so it disappears after use), and **completed / imported
  status records**. The **rewind ledger is hidden** — it is the in-memory, mid-map decaying
  ledger (`undo_activations` / `undo_rounds`), never a browsable save; it surfaces only in a
  recovery context. This maps 1:1 onto `save_slot_classes` + `autosave_rules` + the status
  store, so the visible taxonomy stays **open-registry / data-driven** (a campaign can add a
  slot class or autosave pool without an engine enum edit, per `[EXT]`). Rejected:
  player-facing-only (hiding autosave/suspend makes a lost autosave invisible) and
  show-everything (browsable rewind entries — already rejected in the persistence design).

- **CL-SAVE-03 — Answered.** Players may rename the **run label** and a **manual Campaign
  Save label**. Autosave and Suspend labels stay **system-owned** (pool-managed, count-capped
  — a renamed autosave would fight the keep/rotate policy). The **campaign name is fixed**
  (it comes from the pack; renaming it would diverge the display name from pack identity and
  invite impersonation); the player-side **`hash → nickname` map** (CL-LIFE-03) already covers
  "which copy is which." *Engineering consequence:* slot classes carry only a class-level
  `label` today, so a renameable per-instance label is a new field on the save-index entry and
  the run header (small, additive). Rejected: manual-save-label-only (runs need a
  human-memorable name once there are several) and campaign-alias (identity/spoofing risk).

- **CL-SAVE-04 — Answered (lean v1).** Runs are **collapsed and sorted newest-first**. **No
  search/filter and no archive in v1** — runs leave the list only by delete. Accepted
  trade-off: within a single campaign a player rarely accumulates enough runs for search to
  earn its cost, and archive would add a state + storage bucket for little v1 value. **Search
  and archive move to a demand-gated backlog row** (same treatment as full-library backup —
  nothing lives only in a note). *Consequence to watch:* with no search, a run that holds many
  manual saves relies on newest-first ordering + the collapse; if playtest shows long
  within-run save lists, search graduates from the backlog first. Rejected here:
  collapse+search+archive (full research rec — deferred, not taken) as premature for v1.

- **CL-SAVE-05 — Answered.** Per run/save actions ship as **Resume, Inspect, Rename, Export,
  Delete**. **Archive is *not* included** — it was contingent on CL-SAVE-04 adopting archive,
  which it did not, so the two decisions stay coherent (archive rides the same backlog row).
  **Export** is the run/save half of the inbox exchange (Branches C/D — Export clean / with
  runs / run(s) only / status record(s)). **Duplicate is deferred** to Branch K with the
  copy/edit surface (it is the same "make an editable copy" plumbing). Rejected: lean set
  (dropping Rename contradicts CL-SAVE-03) and include-Duplicate-now (pulls Branch K scope
  forward).

**Implementation linkage.** Branch F adds no premature standalone tracker rows — like Branch
E it folds into the consolidated Library implementation-planning pass. The two concrete code
touches it implies are noted inline: a **per-instance rename label** on the save-index entry /
run header (CL-SAVE-03), and the browser reading its visible set straight from
`save_slot_classes` + `autosave_rules` + the status store (CL-SAVE-02). The deferred
**search + archive** work is the one item that gets a backlog row.

## Branch G — Missing / incompatible content

Mostly Branch D cashing out: the integrity-vs-validity **check-point contract** (Branch D)
already fixed where each check runs and how it fails, so Branch G confirms that policy and
**prunes the packet's lists to v1 reality** — two earlier decisions remove options: *no Disable*
(CL-LIFE-06) deletes "Enable"/"disabled", and *no migration engine* (CL-LIFE-04) deletes
"migration unavailable". Grounding in code: the save index already mirrors a **header** out of
each save doc (`SaveManager._slot_index_row`, carrying `campaign_id` + the
`package_id`/`package_version` identity) so a missing-pack save can be *listed and categorised
without loading the save or the pack*; and `PP-V053-CAMPAIGN-ERROR-DIAG` (completed) already
moved the engine toward **distinct campaign diagnostics** instead of one generic "Campaign Data
Error".

- **CL-MISSING-01 / CL-MISSING-02 — Answered.** A save whose pack is missing stays **visible,
  disabled, in its original campaign group**, marked with a **"Missing content" badge** rendered
  from the header index (no pack load). If the campaign itself is uninstalled, a **placeholder
  campaign row is derived from the save header** so its runs stay reachable. Repair actions:
  **Import required content** (deep-links the inbox/import flow **pre-filtered** to the needed
  id/version), **Inspect** (the diagnostic of CL-MISSING-05), **Export** (rescue the run *without*
  its pack), **Delete** (secondary, double-confirms when the run is not completed, per CL-LIFE-09).
  **No "Enable"** (no Disable in v1) and **no separate "Missing Content" filter view** — orphans
  show inline where the run lives, keeping CL-SAVE-04's lean-v1 (no search/filter) coherent; the
  dedicated filter rolls into the **existing** `BACKLOG-RUNSAVE-SEARCH-ARCHIVE` row, not a new one.
  Rejected: hiding orphaned saves (kills the repair path, reads as data loss).

- **CL-MISSING-03 — Answered.** Distinct, stable failure categories, **pruned to the v1 set**:
  **Missing content · Version not installed · Modified (fingerprint changed) · Invalid pack ·
  Corrupt save**. "disabled" and "migration unavailable" drop out (the latter folds into *Version
  not installed*). Each is a **stable code + player-facing string + support-doc anchor**. This is
  a *fixed engine diagnostic set*, not an author-extensible content vocabulary, so a closed set is
  correct here — it is not the closed-enum smell `[EXT]` warns about (these are integrity/validity
  outcomes the engine owns, not content authors extend). Extends the PP-V053 distinct-diagnostics
  precedent. Rejected: three coarse buckets ("Broken" hides import-a-version vs report-a-bug) and a
  single generic error (what PP-V053 just moved away from).

- **CL-MISSING-04 — Answered (confirms Branch D).** Layered override policy, matching the Branch D
  check-point table:
  - **Modified** (same-version fingerprint mismatch) → **non-blocking warning**, player may proceed
    ("content modified since import — errors may occur"). This is the fingerprint case Branch D
    pulled forward; the packet's open question ("is same-version fingerprint mismatch *always
    blocked*?") is answered **No**.
  - **Missing content / Version not installed** → **blocked** until the required content is imported
    (you cannot play what is not there).
  - **Invalid references / schema** (structurally unrunnable) → **never overridable**; hard-fails at
    **point of use** with a diagnostic — the real hard gate.

  Rejected: stricter (always block fingerprint mismatch — contradicts CL-LIFE-03) and looser
  (force-load invalid references — runs genuinely broken content, no safe outcome).

- **CL-MISSING-05 — Answered.** A failure shows a **plain-language summary line** plus an
  **expandable, copyable report with paths redacted** — relativised to `user://`, absolute home
  paths / usernames stripped — safe to paste into a bug report. The redaction is the privacy
  scrubber that Branch J (CL-SAFETY) owns; recorded here as the requirement, wired there. Rejected:
  summary-only (authors/bug reports lose the actionable id/version/path) and full raw paths inline
  (leaks usernames + filesystem layout into screenshots).

**Implementation linkage.** No premature standalone tracker rows — Branch G folds into the
consolidated Library implementation pass. The concrete code touches it implies are already inline:
the missing-content detection reads `package_id`/`package_version` from the existing header index
against `CampaignPackRegistry`; the category set is a small fixed engine enum + string table +
support anchors; the import deep-link reuses the Branch C/D inbox import pipeline pre-filtered to a
target id/version; and the redacted report is a shared scrubber owned by Branch J. The one deferred
item (missing-content *filter*) is absorbed by the existing `BACKLOG-RUNSAVE-SEARCH-ARCHIVE` row.

## Branch H — Transfers: import / export / backup / restore

**Scoping first.** Full Library Backup is deferred (`BACKLOG-FULL-LIBRARY-BACKUP`), and
**CL-TRANSFER-03/04/05 are backup-*restore* mechanics** (restore preview, restore granularity,
rollback) — so they ride that backlog row, not v1. The per-pack import preview + atomic promote +
rollback they would otherwise cover was **already settled in Branch D** (the check-point contract).
That leaves three live v1 questions — -01, -02, -06 — plus the concrete artifact-naming scheme
this branch was held open to nail down.

### File-extension rules & recommendations (the reminder, recorded)

- **Extension is a routing/UX hint, never a trust boundary.** Godot's `ZIPReader` and
  `CampaignArchivePreflight` identify by *content*; hostile-ZIP / zip-slip / zip-bomb checks run
  regardless of suffix. Branding buys *social* clarity (not confusing a save for a pack), not
  security — anyone can rename anything.
- **Format version lives inside the file, not the extension** (already true:
  `CampaignStatusRecord.FORMAT_VERSION`, pack `manifest.json`); the extension stays stable across
  format bumps.
- **OS file-association is export/installer config → approval-gated** and cannot be self-registered
  cleanly by the running app. On **Steam Deck** the native portal dialog is not gamepad-navigable
  (Branch C), so double-click / association is a **desktop-only convenience** — extensions earn
  their keep at the *scanner*, not the OS shell.
- **Recommendations:** distinct per artifact type; keep the proven container and brand the *name*
  (ZIP/JSON payload, the `.docx`/`.epub` = ZIP pattern); add an internal `artifact_type` tag as
  defense-in-depth so a renamed file is caught; keep suffixes short, lowercase, collision-safe
  (avoid claimed `.pack`/`.save`/`.dat`).

### Decisions

- **CL-TRANSFER-02 — Answered.** v1 uses **distinct filename suffixes on the generic containers**,
  not branded single-token extensions. Current code exports generic `.zip` (packs) and `.json`
  (saves) with no type marker — this scheme adds one. The **scanner routes on the compound
  `<type>.<ext>` suffix and confirms via an internal `artifact_type` field**. Display names
  affirmed: **Portable Run · Clean Campaign Pack · Full Library Backup** (+ **Campaign Status
  Record**). The v1 suffix scheme:

  | Artifact (CL-LIFE-06 action) | Display name | v1 filename suffix | Container |
  |---|---|---|---|
  | Export clean | Clean Campaign Pack | `.clean-pack.zip` | ZIP |
  | Export with runs | Campaign Pack (with runs) | `.with-runs.zip` | ZIP |
  | Export run(s) only | Portable Run | `.portable-run.zip` | ZIP |
  | Export campaign status record | Campaign Status Record | `.status-record.json` | JSON |
  | Full Library Backup *(deferred)* | Full Library Backup | `.library-backup.zip` | ZIP |

  **The transfer unit for playthrough state is the Run, not the save** (resolved with the owner
  mid-branch): a save is only meaningful relative to its run — it inherits the run's rule profile
  and its place in the run's cumulative progress — so a bare, run-less save is not independently
  resumable, and "Export run(s) only" (CL-LIFE-06) already made the *run* the export scope. Hence
  **Portable Run**, a ZIP bundling the run's rule profile + progress + its saves. The save-level
  **Export** action (CL-SAVE-05) produces a Portable Run *pinned to that snapshot* (a minimal
  one-save run), so every export carries run context and there is no un-resumable "bare save"
  format. In-browser the individual save type keeps the name **Save** (CL-SAVE-02); only the
  transfer artifact is a Run. *Code note:* today saves are fat/self-contained (each embeds the
  campaign envelope, roster, economy, turn/RNG state) and the first-class **Run** is still a
  planned grouping key (Branch A), so Portable Run is realised when the Campaign→Run→Save tree is
  built; until then a Portable Run is a single fat save plus run metadata.

  The **internal `artifact_type` tag** is a small additive requirement (packs → into `manifest.json`;
  Portable Runs → into the run/save `header`; status records already carry provenance). **Brand token
  deferred:** the single-token branded extensions (`.prompack`, …) and OS association become a
  **fast-follow bundled with the approval-gated Windows installer work**; the shipped brand token
  should match the *store title*, not the "Prometheus" codename — recorded as a backlog row.
  Rejected: branded extensions now (pulls approval-gated installer config into v1 for a
  desktop-only convenience the Deck can't use anyway) and status-quo generic (the save-as-pack
  leak risk; scanner can't tell pack from backup).

- **CL-TRANSFER-01 — Answered.** **Contextual actions** on each pack / campaign / run (the
  CL-LIFE-06 action set), **plus a thin Transfers hub** that only explains the scopes. The hub is
  deliberately thin in v1 because its main draw — full-library backup/restore — is deferred; it
  grows when that lands. Rejected: contextual-only (weaker "what can I export?" discoverability)
  and a single top-level Export/Import menu (divorces actions from their target, duplicates
  selection).

- **CL-TRANSFER-06 — Answered.** Every export scope shows an explicit **Included / Excluded
  summary at *both* preview and success**. This is load-bearing, not cosmetic: *Clean pack* and
  *with-runs* share the `.zip` container, so the component list — not the filename — is what proves
  a save did or didn't ride along. Ties to the CL-LIFE-06 clean/with-runs/run-only split. Rejected:
  preview-only (no post-hoc re-confirmation) and scope-label-only (a label can't prove exclusion).

- **CL-TRANSFER-03 / 04 / 05 — Deferred to the backup backlog.** Restore preview (full
  component/conflict/space summary), restore granularity (select components, commit atomically),
  and rollback (auto-restore prior state + retained exportable report) are all **whole-library
  backup/restore** mechanics. They are recorded against `BACKLOG-FULL-LIBRARY-BACKUP`, to be
  designed when that feature is demand-gated in. The analogous **per-pack import** preview + atomic
  promote + rollback is already specified in the Branch D check-point contract and stands for v1.

**Implementation linkage.** No premature standalone implementation rows — folds into the
consolidated Library implementation pass. Concrete touches noted inline: the pack exporter filename
builder gains the `<type>` suffix; the current `LoadGameScreen` single-save `.json` export is
replaced by a **Portable Run** `.portable-run.zip` (run metadata + save[s]), so a save-level export
wraps its snapshot as a one-save run; the inbox scanner routes on the compound suffix and reads a
new internal `artifact_type` tag; the export preview/success screens render the Included/Excluded
summary. One **new backlog row** is created for the branded-extension + OS-association fast-follow
(approval-gated, bundled with the Windows installer).

## Deferred / backlog (tracked, not dropped)

- **Full-library backup / restore** — out of v1; post-release candidate **gated on proven
  demand**. Recorded as a tracker backlog row (nothing lives only in a note).
- **Copy / Edit + GUI campaign-editor integration + author encounter/balance test environment**
  — Branch K.
- **Configurable inbox/scan-folder path** — post-v1 (v1 folder is fixed/app-managed).
- **App-managed trash/recovery** — post-v1 (v1 is confirm + hard delete).
- **Branded single-token extensions + OS file-association** (CL-TRANSFER-02) — v1 uses compound
  suffixes on generic containers; branded extensions (`.prompack`, …) and double-click OS
  association are a fast-follow bundled with the approval-gated Windows installer work. Brand token
  should match the shipped store title. Recorded as a tracker backlog row.
- **Run/save search + filter and run archive** (CL-SAVE-04/05) — deferred from v1; v1 is
  collapse + newest-first only. Demand-gated; recorded as a tracker backlog row. Within-run
  save search graduates first if playtest shows long save lists. **Also absorbs** the
  dedicated **"Missing content" filter view** (CL-MISSING-01) — v1 shows orphaned saves inline.

## Next session

Resume at **Branch I — Navigation & accessibility** (CL-NAV-02…07; cross-cutting, and the
controller/Steam-Deck fallback recurs — CL-NAV-01 was already resolved in Branch B as list +
master-detail). Then J → K. When each branch closes, copy its
ids/answers here and create implementation tracker rows only for accepted scope. Branch E closed
2026-07-24: launch = details-with-Continue/New-Run, source-labelled rule controls,
validate-before-commit, persist last-campaign + sort/filter. Branch F closed 2026-07-24:
visible saves = manual + autosave + suspend(as Resume) + status records (rewind hidden), read
data-driven from `save_slot_classes`/`autosave_rules`; rename run + manual-save labels only;
**lean v1** = collapse + newest-first, no search/archive (backlogged); actions =
Resume/Inspect/Rename/Export/Delete (no Archive, Duplicate → Branch K). Branch G closed
2026-07-24: orphaned saves show inline-disabled + "Missing content" badge (header index, no
filter) with Import/Inspect/Export/Delete repair; 5 stable failure categories (Missing / Version
not installed / Modified / Invalid pack / Corrupt save); layered override policy confirms Branch D
(Modified = warn, Missing/Version = block, Invalid refs = never); summary + copyable redacted
report. Branch H closed 2026-07-24: v1 transfer artifacts use distinct compound suffixes on generic
containers (`.clean-pack.zip` / `.with-runs.zip` / `.portable-run.zip` / `.status-record.json`,
scanner routes on `<type>.<ext>` + internal `artifact_type`), branded extensions + OS association
deferred to a Windows-installer fast-follow; contextual actions + thin Transfers hub;
Included/Excluded scope summary at preview + success; restore mechanics (-03/04/05) ride the
deferred backup backlog.
