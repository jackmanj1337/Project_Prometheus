---
Role: topic
Topic ID: GDD-11-CAMPAIGN-EDITOR
Last verified: 2026-08-24
---

# GDD_11 — Campaign Editor

**Status:** Target design — authority contract; implementation is tracked separately.
**Last verified:** 2026-08-24
**Governance:** section template and status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This chapter owns the campaign editor's author-facing shell, document model,
validation surfaces, embedded testing, asset workflow, recovery, export, and desktop
filtering. It consolidates settled behaviour; it does not assert that the editor is
built. Runtime pack contracts remain in `GDD_01`, player-facing UI rules remain in
`GDD_07`, and map/objective semantics remain in `GDD_06`.

The evidence behind this contract remains in the `CEUI`, `CSA`, and `NMTE` registers
and the campaign-editor shell album. Those dated documents explain why; this chapter
is the authority for what the editor must do.

---

## Product Boundary And Entry

Status: **Target design**

- The editor is a separate application mode, not a screen inside a running campaign.
  Entering it requires no active player pack. The main menu exposes it directly, and
  Campaign Library may expose **Edit a copy**; no in-run entry is allowed
  (`[CEUI-6]`, `[CEUI-S9]`, `[CEUI-S13]`, `[CEUI-S22]`).
- Editing always operates on a working copy. Export-to-library and export-to-file are
  both v1 destinations, share one validation ceremony, and never mutate an installed
  source pack (`[CEUI-S10]`, `[CEUI-S41]`, `[CEUI-S51]`).
- A copied pack receives a new id, preserves its fork history, and carries an
  author-controlled manifest author. One active, self-contained pack remains the
  runtime rule; editor inheritance never introduces cross-pack dependencies
  (`[CEUI-S10]`, `[CEUI-S16]`).
- The editor is available on desktop and web, but web is explicitly weaker only in
  durability and live-disk integration. A persistent recommendation to export a file
  is part of the web surface (`[CEUI-S4]`).
- Shared shell availability applies unchanged: absent components hide; gated
  components remain disabled, focusable, and explain why (`[CEUI-S52]`).

The shell owns the precondition. Quitting play to the shell deactivates content, and
editor entry asserts that no campaign is active rather than assuming it (`[CSA-28]`,
`EW-10`).

---

## Display, Shell, And Navigation

Status: **Target design**

The editor has one Expanded layout: tree, central document region, Inspector, and a
bottom panel. Regions resize and collapse but are not rearrangeable in v1. Documents
open as tabs (`[CEUI-1]`, `[CEUI-3]`, `[CEUI-4]`).

- The effective viewport floor is `1920 × 880`, evaluated as window size divided by
  editor scale. Below it, show a minimum-size state; do not invent a compact editor
  (`[CEUI-5]`, `[CEUI-S2]`).
- Editor scale, font size, density, and reduced motion are editor-local. Density uses
  a fourth token column through the shared assembler; `min_target` is 24 px and the
  six editor-only tokens are `workspace_bar`, `tab_height`, `tree_width`,
  `inspector_width`, `form_measure`, and `split_threshold` (`[CEUI-S1]`,
  `[CEUI-S17]`, `[CEUI-S50]`, `EW-1`, `EW-9`).
- Header actions keep text labels and scroll on overflow. Extra room adds affordances
  but never relocates regions. A second document column above 2400 px is offered and
  remembered per workspace, never opened automatically (`[CEUI-7]`, `[CEUI-S11]`,
  `EW-2`, `EW-7`).
- The bottom panel spans only the centre column, defaults per workspace, and starts
  closed at the floor. A 22 px status bar carries keyboard ownership, active tool,
  validation freshness, and selection count (`EW-4`, `EW-5`, `EW-6`).
- Runtime gating measures the actual window; the 200 px chrome allowance is a design
  assumption only (`EW-3`).

The seven workspaces are Content, Maps, Graph, Assets, Localization, Test, and Release
(`[CEUI-8]`, `[CEUI-S12]`). Canvases fill available room, asset grids add fixed-size
columns, forms cap and centre, localization tables add locale columns, and the Test
simulator follows its simulated viewport rather than stretching with the editor.

Keyboard and mouse are the authoring assumption, not a reason to make controls
unreachable. All controls and splitters remain keyboard-operable, focus is visible,
meaning never depends on colour, and non-keyboard input produces a warning rather than
a second layout (`[CEUI-40]`, `[CEUI-S17]`, `[NMTE-S2]`, `EW-9`). Editor chrome and
embedded pack UI use separate themes; tests must prove a pack theme cannot affect
chrome metrics or paint (`EW-8`).

---

## Records, Documents, And Transactions

Status: **Target design**

- Tree categories come from one generated descriptor over registered schema metadata;
  the editor must not hardcode a second content-family list (`[CEUI-2]`,
  `[CEUI-S21]`).
- The Inspector uses schema-generated forms. Defaults originate only in schema defaults
  or templates. The bulk table is the sole multi-edit surface and edits scalar and enum
  fields only (`[CEUI-9]`, `[CEUI-10]`, `[CEUI-12]`, `[CEUI-S14]`, `[CEUI-S16]`,
  `[CEUI-S23]`).
- References use the shared typed selector, including browse-first discovery and
  focus restoration; raw ids are never the primary authoring path (`[CEUI-11]`,
  `[CEUI-S15]`).
- Each open document owns a staged overlay, dirty state, and session-local Undo/Redo.
  Committing a staged edit is the atomic unit. File operations and cross-document
  rewrites are outside Undo (`[CEUI-13]`, `[CEUI-14]`, `[CEUI-15]`, `[CEUI-S6]`).
- An id rename offers a usage preview and rewrites references only after explicit
  confirmation, preceded by a recovery snapshot (`[CEUI-S8]`).
- External desktop edits offer **Reload** or **Keep mine**, never a merge UI. Web has no
  live-disk watcher (`[CEUI-16]`, `[CEUI-S24]`).
- Raw JSON is a plain text peer view on every platform, not an Advanced-mode feature
  and not a separate editor model (`[CEUI-22]`, `[CEUI-S5]`, `[CEUI-S29]`).

Advanced is one global editor setting. It reveals ids, paths, and schema versions
everywhere, but never hides required attribution or validation meaning
(`[CEUI-21]`, `[CEUI-S29]`).

---

## Validation And Issues

Status: **Target design**

Validation runs when a staged edit commits, on explicit request, and at activation or
export gates. Incremental validation is scoped to the committing document; the Issues
panel combines live open-document results with the latest pack-wide pass and visibly
marks stale results (`[CEUI-17]`, `[CEUI-18]`, `[CEUI-S25]`, `[CEUI-S26]`).

There are two severities and three gates (`[CEUI-19]`, `[CEUI-S27]`):

| Severity / gate | Contract |
|---|---|
| Error | Blocks whichever gate owns the violated rule. |
| Warning | Never blocks; remains reviewable in Issues. |
| Activation | Includes Test launch; blocks runtime-invalid content. |
| Export to library | Blocks release-invalid content, missing required notices, and declared localization incompleteness. |
| Export to file | Uses the same gate as export to library. |

Issue rules may register an optional document-local quick fix. The registration seam
ships in v1; no built-in fixes are promised, and any operation touching another
document is a confirmed cross-document write instead (`[CEUI-20]`, `[CEUI-S28]`).

---

## Maps, Graphs, Fixtures, And Testing

Status: **Target design**

- Map layers derive from authored collections in the map schema. The contextual toolbar
  derives tools from the active layer; mode is shown in the toolbar, canvas cursor, and
  status bar (`[CEUI-23]`, `[CEUI-24]`, `[CEUI-S30]`, `[CEUI-S31]`).
- Trigger and objective order is authored in a canonical ordered outline. Any graph is
  a projection and cannot become a second source of truth (`[CEUI-25]`,
  `[CEUI-S32]`).
- Templates expand as copies at authoring time across every workspace. There is no live
  template inheritance (`[CEUI-31]`, `[CEUI-S35]`).
- Test is an embedded playable session with strict theme and keyboard ownership. It
  runs from an isolated snapshot and never writes player save slots
  (`[CEUI-S3]`).
- V1 entry points are campaign start, selected node/map with a fixture, and
  validation-only. Pseudolocale captures launch from Localization through the same
  embedded runtime, not as a fourth Test entry (`[CEUI-26]`, `[CEUI-S18]`,
  `[CEUI-S51]`).
- A fixture is declarative starting state stored in the pack and shipped in its single
  export. It is not a second content model (`[CEUI-27]`, `[CEUI-28]`,
  `[CEUI-S19]`, `[CEUI-S20]`).
- Test return produces a report, not a release receipt. The batch balance runner is
  deferred beyond v1, while its fixture, launch, and report primitives remain the
  reusable foundation (`[CEUI-29]`, `[CEUI-30]`, `[CEUI-S33]`, `[CEUI-S34]`).

---

## Assets, Provenance, And Palette Work

Status: **Target design**

Assets live in one editor workspace with progressive disclosure from import and usage
to sprite, animation, and palette tools (`[CEUI-32]`, `[CEUI-35]`, `[CEUI-S38]`,
`[CSA-11]`, `[CSA-17]`).

- Import is a staged transaction. Unknown rights do not block import; activation and
  export enforce the ratified provenance rules (`[CEUI-33]`, `[CEUI-S36]`).
- Batch provenance editing uses the ordinary bulk table rather than another bespoke
  surface (`[CEUI-34]`, `[CEUI-S37]`).
- Deleting an asset first shows every usage, never cascades, and follows the same
  confirmed cross-document-write rule as id rename (`[CEUI-36]`, `[CEUI-S39]`).
- Required attribution is non-suppressible. Pack art never skins editor chrome, and an
  unskinned campaign remains usable through generated authoring affordances rather
  than hidden engine content (`[CSA-13]`, `[CSA-28]`, `[CEUI-S7]`).
- Palette swaps are authored pack data, use exact RGBA mappings with bounded entries,
  compose through keyed faction lookup, bake at export when required, and never replace
  the non-colour faction channel (`[CSA-18]`, `[CSA-19]`, `[CSA-20]`, `[CSA-21]`,
  `[CSA-22]`, `[CSA-24]`, `[CSA-25]`, `[CSA-27]`).

---

## Recovery, Release, And Onboarding

Status: **Target design**

- Recovery snapshots are periodic and taken before every risky operation, pruned by
  count, and separate from document Undo (`[CEUI-37]`, `[CEUI-S40]`).
- Export runs full validation, presents a content diff, handles version bump and
  authorship, and then targets library or file. Export-back defaults to draft
  (`[CEUI-38]`, `[CEUI-S10]`, `[CEUI-S41]`).
- V1 onboarding is **fork a public pack**. It ships no built-in tutorial, guided tour,
  or template-art bundle (`[CEUI-39]`, `[CEUI-S42]`, `[CSA-30]`, `[CSA-31]`).

---

## Desktop Filtering

Status: **Target design**

Editor filters are ordinary desktop text fields, not `TextEntryService` sessions and
not a player-facing text-entry mode (`[NMTE-1]`, `[NMTE-S1]`, `[NMTE-S4]`,
`[CEUI-S43]`). Filtering is debounced and incremental, preserves IME composition,
keeps edits intact if the viewport crosses the effective floor, and restores focus
through the shared selector rules (`[NMTE-5]`, `[NMTE-6]`, `[NMTE-13]`, `[NMTE-15]`,
`[CEUI-S44]`, `[CEUI-S45]`, `[CEUI-S46]`).

A query is not an identifier: it follows normal Unicode text semantics. Query text is
never logged, telemetered, snapshotted, or written to disk (`[NMTE-18]`, `[NMTE-19]`,
`[CEUI-S47]`, `[CEUI-S48]`). Enter, Escape, focus loss, and keyboard return use ordinary
desktop focus semantics; no controller or on-screen-keyboard dialect survives
(`[NMTE-2]`, `[NMTE-7]`, `[NMTE-8]`, `[NMTE-9]`, `[NMTE-10]`, `[NMTE-11]`,
`[NMTE-12]`, `[NMTE-14]`, `[CEUI-S49]`). Free-text search is never the sole discovery
path (`[NMTE-16]`). Invalid input is inline; no additional announcement channel was
promoted (`[NMTE-17]`). Filter lifetime remains session-bounded and must obey the
never-to-disk rule (`[NMTE-20]`).

---

## Evidence And Build Boundary

The authoritative shell reference is
`AGENT/Docs/wireframes/albums/campaign_editor_shell_album.html`; its frames show the
ruled layout and lifecycle, while interior implementation remains future work. The
source registers are evidence and rationale:

- `campaign_editor_ui_open_questions_2026-08-12.md`
- `campaign_sprite_authoring_open_questions_2026-07-30.md`
- `non_modal_text_entry_open_questions_2026-08-12.md`
- `campaign_editor_shell_wireframes_2026-08-14.md`

Building this contract requires registered schema/tree descriptors, the shared typed
selector, a two-severity validator model with three gates, a quick-fix registration
seam, isolated embedded sessions, editor density tokens, and a production
deactivate-on-quit caller. Those are implementation prerequisites, not open design
questions.
