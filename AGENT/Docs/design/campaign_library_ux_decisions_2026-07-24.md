---
Type: design decisions
Status: Accepted (partial) — Branches A–E resolved with the owner; F–K pending
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
| F | Runs & saves detail | CL-SAVE-02/03/04/05 | Pending |
| G | Missing / incompatible content | CL-MISSING-01…05 | Pending (CL-MISSING-03 direction + 04 fingerprint case pre-answered) |
| H | Transfers: import/export/backup/restore | CL-TRANSFER-01…06 | Pending (simplified — no migration engine; needs artifact names/extensions) |
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

## Deferred / backlog (tracked, not dropped)

- **Full-library backup / restore** — out of v1; post-release candidate **gated on proven
  demand**. Recorded as a tracker backlog row (nothing lives only in a note).
- **Copy / Edit + GUI campaign-editor integration + author encounter/balance test environment**
  — Branch K.
- **Configurable inbox/scan-folder path** — post-v1 (v1 folder is fixed/app-managed).
- **App-managed trash/recovery** — post-v1 (v1 is confirm + hard delete).

## Next session

Resume at **Branch F — Runs & saves detail** (CL-SAVE-02/03/04/05). Then G → K. When each
branch closes, copy its ids/answers here and create implementation tracker rows only for accepted
scope. Branch E closed 2026-07-24: launch = details-with-Continue/New-Run, source-labelled rule
controls, validate-before-commit, persist last-campaign + sort/filter.
