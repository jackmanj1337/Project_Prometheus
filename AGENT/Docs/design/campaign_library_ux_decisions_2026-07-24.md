---
Role: dated
Type: design
Status: Accepted (partial) — Branches A–I resolved with the owner; J–K pending
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
| I | Navigation & accessibility (cross-cutting) | CL-NAV-02…07 | Resolved (reuses existing input/scale/modal infra; NAV-07 = web-safe cooperative chunking) |
| J | Safety, trust, privacy (cross-cutting) | CL-SAFETY-01…04 | Resolved 2026-07-24 |
| K | Author / advanced surfaces | CL-ADV-01…04 | Resolved 2026-07-25 — editor full-integration + runtime OR-gated warning; CL-ADV-01 dev-mode unpacked packs; -02 player summary vs editor validator; -03 block collisions / badge dev+local-mod / no "unsigned" + author version-bump note. Editor UX = separate design pass. Last owner-question branch. |

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
- **Copy / Edit** buttons and GUI campaign-editor integration were **deferred to Branch K**;
  the editor-distribution question is now **resolved there (2026-07-25)** — v1 ships the editor
  **fully integrated in all builds**, runtime-gated, and the optionally-bundlable **separable-program**
  preset is kept only as a fallback (see Branch K, which revises the earlier "separable program"
  default). Authors still get a dedicated **encounter/balance test environment** (its own fixtures,
  not the player save model). Editing installed content implies an unpack-to-editable working copy →
  re-export flow, because installed packs are immutable (CL-ADV-01).

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

## Branch I — Navigation & accessibility (cross-cutting)

Unlike A–H, Branch I is largely a *confirm-against-code* pass: it maps onto infrastructure that
**already exists** and should be **reused, not re-implemented** —
`scripts/ui/ModalScreen.gd` (shared modal base: menu-scale registration, input-mode focus handling,
cancel-to-close, prompt-refresh seam; 7 screens extend it), `scripts/ui/SelectionCursor.gd` (shared
navigation core adopted across the three More-Info surfaces), `scripts/ui/MenuScale.gd` (crisp
type-scaling, reaches 2.0×), `scripts/shared/InputDisplay.gd` (brand-aware pad glyphs) +
`InputModeManager` (mouse-kbd / gamepad / touch detection), and the data-driven `SettingsScreen`
schema (rows + remappable keybinds auto-listed from the InputMap).

- **CL-NAV-01 — (resolved in Branch B).** List + master-detail, collapsing to sequential screens at
  narrow widths.

- **CL-NAV-02 — Answered.** **Stable global** controller mapping: Confirm=primary, Cancel=back, a
  context action-menu button, a details toggle, shoulders switch top sections; a live, brand-correct
  legend via `InputDisplay.live_action_prompt`. Two engineering riders: (1) the Library needs
  **menu-semantic** section-switch actions rather than overloading the gameplay `next_unit`/`prev_unit`
  (LB/RB) actions; (2) **input-map defect found** — `confirm`=joy(1,0) and `cancel`=joy(2,1) share
  **button 1 (right face)**, so a menu leaning on both sees one button as accept *and* back. Recorded
  as a **playtest-gated investigation** (the first playtest that integrates the Library controller
  surfaces), not a copy tweak. Rejected: context-dependent remapping (unlearnable; the stable contract
  is the point).

- **CL-NAV-03 — Answered (accepted-default).** Explicit initial + return focus and explicit neighbors
  per state; **destructive actions never receive default focus**. Matches existing precedent
  (`LoadGameScreen` restores focus after a delete-confirm; Godot requires explicit focus and warns that
  auto-guessing mis-fires on complex UI). Cost is a per-state focus contract + the regression fixtures
  the research lists (focus owner, full controller route, cancel-return, no clipping at 200%). Rejected:
  auto-neighbor guessing.

- **CL-NAV-04 — Answered.** **Filters + sortable headings only; no free-text search in v1** — coherent
  with CL-SAVE-04 / CL-MISSING-01, which already backlogged search into `BACKLOG-RUNSAVE-SEARCH-ARCHIVE`.
  The apparent tension with CL-SAVE-03 rename (which *does* need controller text entry) resolves on
  frequency: rename is a **rare, explicitly-invoked** edit (an acceptable virtual-keyboard moment);
  search is a **browse-path hit every session** (avoid on controller). Rejected: virtual-keyboard search
  in v1 (slow controller text entry on the hot path).

- **CL-NAV-05 — Answered (accepted-default).** Stress target = **200% text + long translated labels +
  missing images**. Reality check: 2.0× is **already representable** (`SettingsManager.MENU_SCALE_LEVELS`
  tops out at 2.0), so this is **layout fixtures, not new infra** — but new Library scenes must join
  group `menu_scale_targets` and avoid the "override a root Theme can't reach" trap `MenuScale.gd`
  documents.

- **CL-NAV-06 — Answered (accepted-default).** Redundancy = **text + icon, colour supplementary** — and
  it is the *only* feasible v1 call: the project has **no colourblind / high-contrast / reduce-motion
  mode** anywhere, so status meaning must live in text+icon, never colour alone. Badges
  (Ready / Modified / Invalid / Missing, Branches D/G) draw from **registry display metadata**, not a
  `match`. A palette mode is post-v1. Rejected: colour+icon only (fails without a colourblind mode).

- **CL-NAV-07 — Answered.** Progress + cancel policy, refined by a build-cost + platform analysis:
  - **Threshold rule:** determinate progress bar **+ cancel-before-commit** on the ops that can run long
    (**inbox scan, pack import**); indeterminate spinner, **no cancel**, on the fast bounded ops
    (export, status-record write).
  - **Cancel is cheap; async is the real cost.** A live indicator only animates if the work is off the
    main thread *or* chunked — a synchronous `install_zip()` freezes the indicator and risks the OS
    "not responding" dialog. Cancel-before-commit is nearly free given the code: `install_zip` already
    stages to `.staging` and calls `_remove_tree` on any failure, with an atomic `_promote()` commit —
    so cancel = a flag checked in the **existing per-entry extraction loop** + the **existing rollback
    path**.
  - **Web-safe implementation constraint (checked): use a cooperative chunked coroutine (`await` a frame
    every N entries), NOT threads.** Web is a **shipping target** (playtest channel + portfolio demo;
    the Compatibility renderer was chosen *because web export requires it* — `GDD_00 §Platform Targets`),
    and Godot web exports are **single-threaded unless** SharedArrayBuffer + cross-origin isolation is
    available on the host, which a portfolio demo cannot assume. Threads (`WorkerThreadPool`/`Thread`)
    would be the portability hazard; cooperative chunking is the most portable path and matches the
    codebase (**zero threads today**). The same chunking avoids Android ANR (mobile deferred post-1.0,
    but not to be actively broken) and the browser "page unresponsive" prompt. Secondary web caveat to
    carry forward: `user://` on web is async-persisted IndexedDB, so import/backup is not durable-on-disk
    until the browser flushes — a flag for the backup backlog, not a v1 import blocker.
  - Rejected: cancel everywhere (saves little, frozen-looking app on the fast ops); synchronous + static
    overlay (spinner can't animate — worse than honest text); threaded installer (fragile on the web
    target).

**Implementation linkage.** Branch I reuses existing infra, so it adds no *new UI primitive* — but it
surfaces three tracked rows: (a) the **input-map double-bind playtest investigation**
(`BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND`, CL-NAV-02); (b) **async progress/cancel infra** for
scan/import (`IMPL-ASYNC-PROGRESS-CANCEL`, CL-NAV-07, cooperative-chunking / web-safe); and (c) it
**connects to the UI/UX pass** — the Library's list/detail/action-menu surfaces are the third and
fourth data-driven-list consumers (after `SelectionCursor`'s More-Info surfaces and `LoadGameScreen`),
so a **shared record-list + master-detail + action-menu widget** on the `PanelSelector`/`SelectionCursor`
core is scoped as the pass's first *structural* deliverable (`PLAN-UIUX-REUSE-PASS`). The *visual*
`UiThemeDef` / `AssetResolver` half of that pass stays gated on the art open-questions
(`B6-SPRITE-IMPORTER` / `[IMP]`). See `ui_ux_asset_inventory_and_reuse_2026-07-02.md`.

## Branch J — Safety, trust, privacy (cross-cutting)

Status: **in progress** (opened 2026-07-24). CL-SAFETY-01 resolved below; 02/03/04 pending.

### CL-SAFETY-01 — trust claim & validation status

**Decision.** The UI carries **two distinct signals**, not one variable "trust" badge:

1. **"Data-only / can't run code" — stated as *explanation*, not a per-pack badge.** This is a
   **loader invariant**, true by construction for every pack, so it must not be shown as something
   that was "checked" and could vary. Verified in code: both pack load paths are
   `FileAccess…get_as_text()` → `JSON.parse` (`CampaignPackRegistry.gd:174`, `Tier2Catalogue.gd:195`)
   — no `ResourceLoader.load()`/`load()`, no scene/resource instancing on pack paths; `Tier2Catalogue`
   also rejects `..` traversal. A stray `.gd`/`.tscn` in a pack is inert (nothing hands it to a
   loader); a non-data file *where data is expected* fails `JSON.parse` → raised error → reject
   (feeds CL-SAFETY-02). Copy: surface line *"Game data — the game reads it, never runs it"*; the
   "what does this mean?" expander carries the precise wording.
2. **"Valid pack — passed structure checks" — the single *per-pack* live signal.** This is the real
   verifiable claim and the machinery already exists: `PackManifest.parse` (required fields,
   `format_version`, id shape) + `CampaignTier2Validators` (campaign/map/registry structure +
   cross-reference resolution). Pass → "Valid pack"; fail → reject + the validator's own error
   strings (this *is* the CL-SAFETY-02 reject list and the CL-ADV-02 "plain summary + exportable
   report"). Rejected the original single "safe"/"unsigned" wording: "safe" is an unbounded claim;
   "unsigned" invents a signature threat model we don't implement (see CL-ADV-03).

**Surfacing (uses Branch C/D decisions).** Both signals live on the **mandatory install preview**
(CL-LIFE-01), inside the CL-LIFE-02 identity block a player must pass through to install — seen on
every import at no extra effort, not on library rows (CL-MODEL-05) and not a recurring launch nag.

**Media are in scope from v1 (packs supply textures & audio).** "Data-only" is preserved *because
the loader discipline is fixed now*: pack binaries load only through **byte decoders**
(`Image.load_from_file` → `ImageTexture`; `AudioStreamOggVorbis.load_from_file`; WAV from raw bytes
— exact 4.6 API to be confirmed), **never** `ResourceLoader.load()` and **never** accepting
`.tres`/`.res`/`.scn`/`.tscn`/`.gd` from a pack (a `.tres` can carry `script = ExtResource(...)` and
execute on load — that is the exact hole to keep shut). The schema gains first-class texture/audio
reference fields, validated (exists + allowed media extension) on the same reject path.

**Consequences / enforcement.**
- **Enforcement test (DoD#2):** pack content — data *and* media — is never loaded via
  `ResourceLoader`/`load()`; only via the approved byte decoders. This keeps "only data" from
  silently becoming false when media loading lands.
- **Web-safe correction to loader plumbing:** any batched asset loading must use the **cooperative
  chunked coroutine** model Branch I chose for CL-NAV-07 (`IMPL-ASYNC-PROGRESS-CANCEL`), **not**
  threads/`WorkerThreadPool` — web is a shipping target and single-threaded by default.
- **Known tradeoff (chosen, not accidental):** byte-loaded textures skip Godot's `.import` pipeline
  → **no VRAM compression, no baked mipmaps** (generate in code if wanted). Fine for 2D sprite/tile
  art; could cost VRAM/load time if packs ship large/high-res art. Dimension caps / in-code
  compression are post-v1 mitigations. Residual security risk shifts from "pack runs a script"
  (fully closed) to "malformed media bytes hit a decoder bug" (memory-safety class, Godot's decoder
  to harden) — noted in the threat model; does not weaken the player-facing claim.

### CL-SAFETY-02 — malformed content handling

**Decision (accept default).** **Reject the install and leave the source file untouched.** An
already-installed pack that later reads as corrupt is shown **disabled** (not deleted); deletion is
always a separate explicit action (ties CL-SAFETY-04 trash, not this reject). **Quarantine deferred.**

- Ratifies existing behavior: `PackManifest.parse` / `CampaignTier2Validators` accumulate an error
  list and refuse rather than half-loading; this names the UX, not new engine work.
- "Disabled, not deleted" keeps dependent saves visible/repairable (Branch G orphaned-save path).
- Rejected "retain external path only" — avoids storing stale absolute paths (collides with
  CL-SAFETY-03 privacy). Cost: no auto re-try on a transient failure (e.g. unplugged USB); acceptable.
- Deferred, noted: finer **per-component** status for *partial* corruption of an installed pack (one
  bad map, rest fine) — v1 shows the whole pack disabled.

**Note → Branch K.** More advanced malformed-content debugging (structured forensics beyond the
player-facing error list + exportable report) **ships with the GUI campaign editor / author
validator**, not the player runtime. Recorded against CL-ADV-02 / the deferred editor row.

### CL-SAFETY-03 — diagnostic path exposure

**Decision (accept default).** **Logical ids + safe relative paths by default; redacted otherwise; an
explicit action copies the full local path.** This is the concrete owner of the CL-MISSING-05
redacted-report scrubber (closes that dependency). Hard requirements:

- **Single redaction helper** every diagnostic *and* the exportable report routes through — one leak
  path defeats the guarantee.
- **Enforcement test (DoD#2):** diagnostic/report output never contains the user home or a real
  absolute path.
- **Logical ids = pack-id + pack-relative path** (not bare basename) so they're unambiguous without
  being absolute; "safe relative paths" are relative to the pack root or app-data dir, never the FS
  root.
- "Copy full local path" is an explicit **local** action; the full path never enters the *shared*
  artifact by default.

### CL-SAFETY-04 — trash / recovery policy

**Decision (v1 = confirm + immediate hard delete).** No trash in v1. The **confirmation carries the
safety**, and for high-impact deletes it must be **deliberate — not mash-past-able**:

- Destructive action is **never** the default focus (CL-NAV-03); dialog states "this can't be undone".
- **Proportional friction:** a manual save is a single light confirm; a heavier delete (e.g.
  uninstalling a pack **N runs depend on** — surfaces the CL-LIFE-06 dependency count) escalates to a
  **second, deliberate confirmation** (a distinct affirmative step, not a second identical OK that
  reflex can blow through).
- Ratifies Branch D's "confirm + hard delete for v1" and CL-LIFE-09 (confirm irreversible actions).

**Post-v1 backlog (see Deferred list).** App-managed, **cross-platform trash — web included, NOT
OS-trash** (`OS.move_to_trash()` is a no-op on the web target). Scope it as a real feature: storage
location, retention/quota + purge, "Recently deleted" restore UI; note trashed items hold disk until
purged (quota interaction).

## Branch K — Author & advanced surfaces (CL-ADV-01…04)

Status: **in progress** (opened 2026-07-25). The editor-distribution question — Branch B's deferred
"Copy / Edit + GUI campaign-editor integration", and the CL-ADV-04 player/author boundary — is
resolved below; CL-ADV-01/02/03 pending.

### Editor distribution & integration — resolved 2026-07-25 (revises Branch B "separable program")

**Prior art (researched 2026-07-25).** Every reference toolset ships the editor as a **separate
desktop app from the game the player runs**: FEBuilderGBA (standalone Windows ROM editor, dense
multi-panel, "15 submenus" deep), Lex Talionis / **LT-maker** (PyQt editor built *on top of* but
separate from the Python engine), Tactile (separate editor generating a C# game), and even **SRPG
Studio** — the closest to an "integrated editor+runtime", RPG-Maker-style — still **exports a
standalone game folder** that the player runs without ever opening the Studio. All are desktop,
mouse-and-keyboard, author-only. The universal invariant is *the editor never ships into the
player's hands*; the split is enforced at distribution.

**Decision — full integration in v1, gated at RUNTIME not at build time.** The editor ships in
**all** presets (Steam / Deck / web included); it is *not* stripped per-build. Rationale: "can I
edit here?" is a **runtime** property, not a platform. A **Steam Deck in desktop mode** and a **web
build on an iPad with a Bluetooth keyboard+mouse** are both good editing environments, and a
build-time strip would wrongly deny them. Gating on live signals (resolution + input mode) covers
exactly the edge cases a preset split cannot. This **revises** Branch B's "separable program"
default (which followed the prior art) in favour of integration + graceful degradation.

> **AMENDED 2026-08-14 by `[CEUI-S2]`** — the resolution axis below is **superseded**; the
> input-mode axis and the declutter row **survive**. `[CEUI-5]` (2026-08-14) set a hard editor
> floor of `1920×880`, and `[CEUI-S2]` made it measurable in **effective** pixels
> (`window ÷ editor scale`, the editor having gained its own scale knob under `[CEUI-S1]`). So
> below the floor the editor now shows an explanatory **minimum-size state naming the scale knob**
> — block-and-explain — rather than the dismissible "open anyway" warning described here, and the
> `1920×1080` number is no longer a threshold anywhere. **The input-mode half of the OR gate keeps
> its original behaviour and rationale**: it is the only mechanism that tells an author their input
> is wrong, and `[NMTE-S2]` made mouse-and-physical-keyboard a *stated* assumption rather than an
> enforced one. The iPad caveat below still binds it — key off keyboard/mouse presence, never off
> "touch absent". The **Settings declutter row is untouched**: it is about clutter for players who
> never author, not about capability. See
> [`ceui_precedence_diff_2026-08-14.md`](ceui_precedence_diff_2026-08-14.md) §3.1 for the
> three-way collision this resolves.

- **Non-blocking warning on editor entry**, fired when **either** axis is degraded (**OR** — owner
  call 2026-07-25): window **below 1920×1080**, *or* the current input mode is not keyboard+mouse.
  Each axis independently makes editing rough (a gamepad-only editor hurts on a 4K TV; a tiny window
  hurts with a great keyboard), so OR, not AND. Dismissible "open anyway"; matches the house
  non-blocking-warning pattern (Branch D/G "modified content").
- **Detect "kbm available / recently used", NOT "touch absent".** An iPad reports touch *and* kbm
  simultaneously, so a touch-present test would mis-warn a perfectly good iPad+keyboard setup. The
  input-mode read must key off keyboard/mouse presence, never off the existence of a touchscreen.
- **Settings declutter (data-driven row).** A player may (a) hide the editor entry by default and/or
  (b) auto-hide it below a resolution / on a non-kbm input mode. Default = **visible everywhere**;
  the toggle serves players who never author. One row in the existing data-driven `SettingsScreen`
  schema, not bespoke UI. "Hide" hides the *entry point* only, reversible in Settings — it never
  strips the capability.

**Reuses existing infra (Branch I).** Input mode comes from `InputModeManager` (already tracks
gamepad / kbm / touch), resolution from the window / `MenuScale`; the OR gate is a read on signals
Branch I already relies on, not new plumbing. The declutter toggle is one `SettingsScreen` schema row.

**Consequences.**
- Editor and player runtime share **one project and the same resource classes** (`PackManifest`,
  `CampaignTier2Validators`, `CampaignPackRegistry`) — full integration means no forked codebase.
- The player runtime keeps only the import/validation **summary + exportable report** (CL-SAFETY-01);
  the deep author validator is an editor surface (pending CL-ADV-02).
- Editing installed content still implies **unpack-to-editable working copy → re-export** (installed
  packs immutable, CL-ADV-01) — unchanged from Branch B.
- **Cost, accepted:** the editor's code/UI ships into web/Deck where most players won't use it (web
  download size the main concern). Weighed against the edge-case coverage and chosen; the
  superset/subset preset below is the escape hatch if it bites.

### CL-ADV-01 — unpacked development packs

**Decision (accept default).** Unpacked (loose-folder) development packs load **only under an explicit
developer mode**, visually **marked as a dev source**, and **never activate in a normal player
session**. Grounded: the registry today only scans installed packs under
`user://campaign_packs/<id>/<version>/` (`CampaignPackRegistry.gd`) — there is no loose-folder path, so
this is net-new and cleanly gateable. It is the author-loop counterpart to the integrated editor:
iterate on loose files, then install/export for real. Keeps fingerprints and the support boundary
intact (a dev-source pack is never mistaken for an installed, fingerprinted one). Editing *installed*
content still goes through unpack-to-editable working copy → re-export (installed packs immutable).

### CL-ADV-02 — validation report placement

**Decision (accept default).** The **player runtime** shows only the plain validation **summary +
exportable report** — this *is* the CL-SAFETY-01 "valid pack" signal, nothing new. The **deeper author
validator** (structured forensics, schema dumps, the CL-SAFETY-02 advanced malformed-content
diagnostics) is an **editor surface**, not a player one. With the editor now fully integrated (all
builds), "the author validator lives in the editor" no longer implies a separate download — it is the
editor's validation view, reachable only through developer mode / the editor entry.

### CL-ADV-03 — duplicate ids, local modifications, "unsigned" language

**Decision.** **Block** id+version collisions; **badge** dev / locally-modified packs; use **no
"unsigned" language** anywhere.

- **Block collisions** — already partly structural: `CampaignPackRegistry.gd:69` rejects a manifest
  whose `id`/`version` disagrees with its install directory, so two *installed* packs cannot share an
  id+version. The rule extends that to the *import* path: a second source claiming an installed
  id+version is refused, not silently overwritten.
- **Badge, don't block, dev / local modification** — a dev-source or locally-modified pack is allowed
  and simply marked; this is the CL-SAFETY-01 fingerprint-mismatch "modified" signal on the author side.
- **No "unsigned" language** — nothing in the codebase signs or verifies packs, so "unsigned build"
  wording would invent a signature threat model we do not implement. Only ever say "signature
  unavailable" *if* signing is added later.
- **Author guidance note in the editor (owner add 2026-07-25):** when an author edits a pack, the
  editor **surfaces a note suggesting they bump the version number** if edited copies may coexist with
  the prior version. Rationale: versioning is **manual with no migration engine** (Branch D), and
  identity is id+version — two coexisting builds at the *same* id+version are the exact case the block
  above and the "modified" fingerprint warning exist to catch. Nudging a version bump at edit time is
  the cheap, author-side prevention. It is a **non-blocking suggestion**, not enforced (an author may
  deliberately keep the version while iterating locally).

### Editor design — deferred to a dedicated pass

Branch K resolved only the editor's **distribution/integration** and the **author/player boundary**
(which surfaces live where). The editor's actual **UX** — panel layout, authoring workflows, the
encounter/balance **test environment** (its own fixtures, not the player save model), fixture
generation, developer-mode tooling surfaces — is **out of scope here and deferred to a dedicated
editor-design pass** (own research doc + owner-questions packet, like this one). Recorded as a tracker
row so it is not lost.

**Branch K resolved 2026-07-25 — this closes the last owner-question branch; next is implementation
planning.**

## Deferred / backlog (tracked, not dropped)

- **Full-library backup / restore** — out of v1; post-release candidate **gated on proven
  demand**. Recorded as a tracker backlog row (nothing lives only in a note).
- **Copy / Edit + GUI campaign-editor integration + author encounter/balance test environment**
  — Branch K (editor distribution resolved 2026-07-25: full integration + runtime OR-gated warning;
  the remaining editor *feature* build is what stays deferred).
- **Superset/subset editor export presets** (escape hatch, not v1) — the two-preset model (lean
  Player build + desktop Creator superset) that Godot itself and SRPG Studio effectively ship. v1
  ships the editor fully integrated in all builds; revisit this preset split only if web download
  size proves the integration cost too high. Demand/measurement-gated (Branch K).
- **Dedicated editor-design pass** (Branch K) — Branch K settled only editor *distribution* and the
  author/player boundary. The editor's UX (panel layout, authoring workflows, the encounter/balance
  test environment, fixture generation, developer-mode tooling surfaces) needs its own research doc +
  owner-questions packet. Tracker row created.
- **Cloud save backup & cross-device sync — third-party storage services** (investigation, owner ask
  2026-07-25) — feasibility of Google Drive / iCloud / OneDrive / GitHub as automatic-backup and
  cross-device targets for saves. Constraints to weigh: **Steam Cloud already covers the Steam target
  ~for free** (the baseline answer for a Steam game), the **web target is IndexedDB-bound** (no
  arbitrary filesystem), each service is a separate OAuth + API + token-refresh surface, and
  cross-platform coverage is uneven. Post-v1; tracker row. Related to the full-library-backup backlog.
- **Optional first-party server + database** (investigation, owner ask 2026-07-25) — a first-party
  backend for storing/backing up cloud saves **and potentially distributing campaign packs** (a
  workshop-style channel). Much larger commitment: hosting cost, auth/account system, uptime, and —
  for pack distribution — **moderation + licensing/legal exposure** (we would become a distributor;
  ties directly to the licensing decisions and the Pack_FE internal-only / terms-guard constraints).
  Post-v1; tracker row. Weigh against just leaning on Steam Cloud + per-pack export/import (v1) and,
  for distribution, Steam Workshop.
- **Configurable inbox/scan-folder path** — post-v1 (v1 folder is fixed/app-managed).
- **App-managed trash/recovery** (CL-SAFETY-04) — post-v1; v1 is confirm + hard delete (heavy
  deletes require a second, deliberate confirmation). Must be **cross-platform incl. web, NOT
  OS-trash** (`OS.move_to_trash()` no-ops on web); scope = storage + retention/quota + purge +
  "Recently deleted" restore UI (trashed items hold disk until purged).
- **Branded single-token extensions + OS file-association** (CL-TRANSFER-02) — v1 uses compound
  suffixes on generic containers; branded extensions (`.prompack`, …) and double-click OS
  association are a fast-follow bundled with the approval-gated Windows installer work. Brand token
  should match the shipped store title. Recorded as a tracker backlog row.
- **Run/save search + filter and run archive** (CL-SAVE-04/05) — deferred from v1; v1 is
  collapse + newest-first only. Demand-gated; recorded as a tracker backlog row. Within-run
  save search graduates first if playtest shows long save lists. **Also absorbs** the
  dedicated **"Missing content" filter view** (CL-MISSING-01) — v1 shows orphaned saves inline.

## Next session

**Branch K resolved 2026-07-25 — all owner-question branches (A–K) are now closed.** Editor
distribution = full integration in all builds, runtime-gated, OR warning; CL-ADV-01 dev-mode unpacked
packs; CL-ADV-02 player summary vs editor validator; CL-ADV-03 block collisions / badge dev+local-mod /
no "unsigned" wording + a non-blocking editor note nudging authors to bump the version between edits
when copies may coexist. Editor UX itself deferred to a dedicated design pass.

**Next is implementation planning** for the accepted campaign-library scope (the `PLAN-CAMPAIGN-DATA-
OWNERSHIP` line), plus three new tracked threads spun out this session: the **editor-design pass**, and
two **investigations** — third-party cloud sync/backup services and an optional first-party
server/DB (+ possible pack distribution). Create implementation tracker rows only for accepted scope. Branch E closed
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
deferred backup backlog. Branch I closed 2026-07-24: reuses existing infra
(`ModalScreen`/`SelectionCursor`/`MenuScale`/`InputDisplay`/`InputModeManager`/data-driven
`SettingsScreen` schema); stable controller mapping + brand-aware legend (with an input-map
double-bind defect found → playtest investigation); explicit focus, destructive never default;
filters + sortable headings, no search v1; 200% + long-label + missing-image stress; text+icon
redundancy (no colour-only, no palette mode v1); NAV-07 progress+cancel = threshold rule (bar+cancel
on scan/import, spinner-only on fast ops) implemented as a **web-safe cooperative chunked coroutine,
not threads** (web is a shipping target, single-threaded by default), cancel nearly free on the
existing `.staging`/`_promote` rollback. Three rows created: input-map investigation, async
progress/cancel infra, and a UI/UX-reuse pass scoping a shared list/detail/action-menu widget.
