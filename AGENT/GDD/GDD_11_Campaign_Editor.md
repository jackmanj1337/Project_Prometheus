---
Role: topic
Topic ID: GDD-11-CAMPAIGN-EDITOR
Last verified: 2026-09-08
---

# GDD_11 — Campaign Editor

**Status:** Target design — authority contract; implementation is tracked separately.
**Last verified:** 2026-09-08
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

Status: **Split** — the two entry points, the entry precondition, the imported working copy
and its distinct activation identity **Implemented**; export-to-library, export-to-file and
the manifest author field **Target design**

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

**Implemented:** `scripts/editor/EditorWorkingCopy.gd` imports a copy of one installed
build into `user://campaign_drafts/`, a root the library never touches, and rewrites the
copy's manifest with a forked id plus `forked_from`. That fork is what makes a Test launch
activate under the working copy's own identity rather than the installed pack's
(`[CEUI-S9]` call 1); the copy's content fingerprint is recomputed from the copy, so it
matches the source at import and moves on the first save. `EditorPackWriter.gd` is the only
thing that writes, and it refuses any path the working copy does not contain — which is why
*installed packs are immutable* is structural here rather than remembered. It never
deletes: a record absent from a saved set is not a deletion.

**Implemented:** `EditorEntry.precondition()` asserts that no package is active and
**refuses** when one is, rather than deactivating — deactivating would be the entry
transition `[CEUI-S13]` removed. `MainMenu` exposes the editor directly (`[CEUI-S13]`) and
enables *Edit a copy* on its own instance of Campaign Library and on no other
(`[CEUI-S22]`'s recommendation, unvetoed; `NewGameScreen`'s embedded instance leaves the
flag off). No in-run entry exists and `test_editor_working_copy.gd` scans the scene tree to
keep it that way. `EditorEntry.sandbox_saves()` points `SaveManager.save_dir` inside the
draft for a Test session and restores it afterwards, which is `[CEUI-S3]`'s autosave
sandboxing as `[CEUI-S9]` call 3 restates it.

**Chosen rather than ruled, and open to veto:** the main-menu entry opens the editor with
**no** working copy, with Test and Export gated on `has_working_copy()`; only *Edit a copy*
imports one. Neither ruling settles which the main-menu entry should be, and the shell's own
`NO_WORKING_COPY_REASON` is authored text that only means anything if the editor can be open
without one. The alternative — a pack picker behind the main-menu entry — is unruled UI.

---

## Display, Shell, And Navigation

Status: **Split** — the four-region composition, the left tree, the map layer list, the
minimum-size state, the tabbed document strip, the workspace bar, the header and the
status bar **Implemented**; the region CONTENTS (Inspector forms, canvases, grids,
tables, the embedded simulator) **Target design**

The editor has one Expanded layout: tree, central document region, Inspector, and a
bottom panel. Regions resize and collapse but are not rearrangeable in v1. Documents
open as tabs (`[CEUI-1]`, `[CEUI-3]`, `[CEUI-4]`).

**Implemented:** `scenes/ui/CampaignEditorScreen.tscn` and its script draw the four
regions with the left tree and the map layer list populated, a `[CEUI-3]` tab strip over
the centre, the seven-workspace bar, `[CEUI-S11]`'s header and `EW-6`'s status bar. The
region interiors are still empty: the Inspector is a frame and the centre draws only the
active document's identity, because `[CEUI-S14]`'s schema-generated forms are a separate
build. The shell reads `[CEUI-S50]`'s editor token column statically rather than switching
the global menu mode, and shows the minimum-size state below the effective floor rather
than reflowing — the floor arithmetic is `scripts/editor/EditorShellMetrics.gd`, shared
with the panel rule below. Both ruled entries are now wired (see §Product Boundary And
Entry): the main-menu entry opens the shell with no working copy, so `has_working_copy()`
is false and Test and Export are gated on it, and the library's *Edit a copy* opens it on
an imported one.

**Implemented:** saving is reached by Ctrl+S and is deliberately **not** a seventh header
action. `[CEUI-S11]` names the six that sit persistently in the header, and `[CEUI-S6]`
made saving a document operation; `[CEUI-40]` requires keyboard reachability of every
essential action regardless, so the shortcut is the affordance without amending a ruled
list. The shell publishes the records rather than writing them — it has no path, and call 1
kept file operations out of the transaction.

**Implemented:** regions collapse and never rearrange — a collapsed tree or Inspector
keeps its place in the composition and returns to it, which is why `CEUI-1` allows
collapse while `CEUI-4` forbids rearrangement. The bottom panel is not one of those
regions: its visibility is the workspace's, below.

**Implemented:** a non-keyboard-and-mouse author gets a warning strip and nothing else —
no grown targets, no reflow, no second layout. `min_target` stays 24 and the editor token
column is identical either way, which is EW-9's ruled option A and the reason option B was
rejected. The editor READS `InputModeManager` and never writes to it; that autoload
belongs to MOBILE-WEB-UX-GAPS-2026-08-03.

**Implemented:** the bottom panel spans the centre column, takes its default from the
workspace AND the height together (`EW-4` with `EW-5`), and an author's own toggle
outranks that default from then on. The second document column is offered only above the
`split_threshold` token measured against the CENTRE column, is off until asked for, and is
remembered per workspace across a width that takes the offer away — `EW-7`'s
offered-and-remembered, never automatic. `scripts/editor/EditorWorkspaces.gd` owns all of
it.

- The effective viewport floor is `1920 × 880`, evaluated as window size divided by
  editor scale. Below it, show a minimum-size state; do not invent a compact editor
  (`[CEUI-5]`, `[CEUI-S2]`).
- Editor scale, font size, density, and reduced motion are editor-local. Density uses
  a fourth token column through the shared assembler; `min_target` is 24 px and the
  six editor-only tokens are `workspace_bar`, `tab_height`, `tree_width`,
  `inspector_width`, `form_measure`, and `split_threshold` (`[CEUI-S1]`,
  `[CEUI-S17]`, `[CEUI-S50]`, `EW-1`, `EW-9`).

**Implemented:** `scripts/editor/EditorLocalSettings.gd` holds the four and persists them
to `user://editor_settings.cfg`. Editor-local is enforced in both directions the rulings
mean it: the object never reads or writes `SettingsManager` — the player's Menu Scale
reaching the editor is the case that gated the whole walk, because `2.0×` on `1920×880` is
an effective `960×440` and `[CEUI-S2]`'s floor never fires — and it never writes
`ResponsiveLayout`'s `menu_mode` or `info_density`, which are one global value each and
would stay flipped after the editor closed. The column is read statically with
`tokens_for_mode()` and only `body_font` is replaced, by the author's font size.

Scale is applied **once**, to the viewport, because `[CEUI-S2]` measures the floor as
window ÷ scale and the tokens are therefore already in effective space. `EW-1`'s knob is
warned, not clamped: any positive scale is accepted, and below `DPR × scale = 1.0` the
change goes behind the confirm-or-revert `[CEUI-S1]` inherits from `[UUI-18]` — applied
live, persisted only on keep. The class is `EditorLocalSettings` rather than
`EditorSettings` because the latter is a native Godot class and shadowing it is a parse
error. Density and reduced motion are carried and published but vary nothing yet: no
editor surface animates, and `EW-6` fixes what the status bar carries, so neither has a
ruled surface to vary — the settings exist so the first consumer finds them instead of
inventing a second preference key.
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

Status: **Split** — the tree descriptor, the staged transaction, Undo/Redo, the tab set,
external-change detection, the schema-generated Inspector form and the bulk table
**Implemented**; id rename and templates **Target design**

- Tree categories come from one generated descriptor over registered schema metadata;
  the editor must not hardcode a second content-family list (`[CEUI-2]`,
  `[CEUI-S21]`). **Implemented:** `ContentTreeDescriptor.build()` asks
  `EntitySchemaRegistry` and `RegistryCatalog` what exists and reads each family's
  presentation from `CONTENT_PRESENTATION` / `FAMILY_PRESENTATION`, declared beside the
  schemas and the family constants. It names no family itself, and a family registered
  only at runtime still gets a category, from its own id.
  `scripts/editor/CampaignEditorShell.gd` is its consumer: it drives the tree through a
  `RecordSelector`, derives the tree's top-level groups from the categories that claimed
  them, and names no family itself. Map layers reach the same shell as a second selector,
  where `[CEUI-23]`'s per-layer visibility never removes a layer from the list and
  per-layer lock makes it focusable but not activatable, with the reason returned.
- The Inspector uses schema-generated forms. Defaults originate only in schema defaults
  or templates. The bulk table is the sole multi-edit surface and edits scalar and enum
  fields only (`[CEUI-9]`, `[CEUI-10]`, `[CEUI-12]`, `[CEUI-S14]`, `[CEUI-S16]`,
  `[CEUI-S23]`). **Implemented** as `scripts/editor/EditorFormModel.gd` and
  `EditorBulkTable.gd`. The form is generated from
  `EntitySchemaRegistry.schema_for(kind, version)` and holds no field list of its own, and
  a field's KIND is **derived**, not declared: a string property carrying a `vocabulary` is
  a **reference**, an inline `enum` is an **enum**, string/integer/number/boolean are
  **scalars**, and array/object are **structured**. That derivation is what enforces the
  restriction — a schema that adds a vocabulary to a field moves it out of the bulk table
  with no editor edit. Three kinds of field are refused by the table and **named on the
  surface with their reason** rather than silently dropped: references (one authoring path,
  because a reference is the only field type that can dangle), structured values, and the
  record's **identity** field, which is derived as the field mirroring the document's key —
  an id rename is `[CEUI-S8]`'s confirmed flow, and one id across a selection is an edit the
  document model cannot represent. A column whose selected records disagree is `mixed` with
  **no value**; writing a placeholder equal to one record's value would flatten the others
  on the next commit. One table edit stages across the whole selection and commits once, so
  it is one Undo unit and one validation pass.
- **Implemented:** `CampaignEditorShell` routes the record selection — exactly one record to
  the Inspector, two or more to the bulk table, and no form at all for a multi-selection.
  The status bar's selection count is the record selection, which is what an edit will touch.
- References use the shared typed selector, including browse-first discovery and
  focus restoration; raw ids are never the primary authoring path (`[CEUI-11]`,
  `[CEUI-S15]`). **Implemented:** `EditorFormModel.reference_selector()` returns a
  `RecordSelector` over the field's vocabulary — the shared selector, not a private picker —
  held per field so focus survives a repaint, and a value the vocabulary does not admit is
  refused **at the moment of choosing** with the reason, rather than one commit later by the
  validator. `EntitySchemaRegistry.vocabulary_values()` was added for it: `vocabulary_admits()`
  answers "is this allowed", which is all a validator needs, but a browse-first picker needs
  the set. **The selector's state model is implemented** as
  `scripts/shared/RecordSelector.gd` — stable opaque ids, focus, the selected set,
  eligibility with its reason, quantity, filters/sort and the detail payload, with
  hidden-versus-disabled decided by the shell and gated entries kept focusable but not
  activatable. It carries no domain vocabulary, and its Control layer is not built —
  the editor shell's layer list is its first adopter, supplying the lock gate and
  surfacing the refusal reason.
- Each open document owns a staged overlay, dirty state, and session-local Undo/Redo.
  Committing a staged edit is the atomic unit. File operations and cross-document
  rewrites are outside Undo (`[CEUI-13]`, `[CEUI-14]`, `[CEUI-15]`, `[CEUI-S6]`).
  **Implemented** as `scripts/editor/EditorDocument.gd`, in three layers rather than two:
  the saved state, the overlay of committed-but-unsaved edits, and the one edit in
  progress. The third exists because `[CEUI-S25]` validates on commit and **not** while
  the author types, which has no meaning if every keystroke is a commit. `commit_edit()`
  is the transaction's commit and the Undo unit; `save()` is the file operation the ruling
  excludes from Undo, and it returns the records rather than writing them, so a document
  has no side effect its own Undo cannot reach. An undo step records the **effective**
  value on either side, so the history keeps working across a save — session-scoped is
  not save-scoped — and undoing back to the start leaves the document clean rather than
  permanently dirty.
- **Implemented:** documents open as tabs, each an independent transaction with its own
  dirty state and its own history (`scripts/editor/EditorDocumentSet.gd`). Reopening an
  open id activates its tab instead of opening a second overlay over one file; closing a
  dirty tab refuses and returns an author-facing reason rather than discarding silently;
  closing the active tab activates its neighbour. There is deliberately no save-all and no
  cross-tab history.
- **Implemented:** external disk edits offer Reload or Keep mine with no merge, and Keep
  mine does not fold disk into the saved state — a document that read clean while
  differing from the file it is about to overwrite is the failure that shape prevents.
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

Status: **Split** — the severity/gate/quick-fix contract, the Issues panel and the
commit-time scheduling **Implemented**; the engine-side rule escalations and quick fixes
**Target design**

`scripts/validation/` holds the model: `ValidationGate` names the three gates,
`ValidationRules` is the open rule registry that resolves a severity per gate and carries
`[CEUI-S28]`'s optional fix slot, and `ValidationReport` makes the gate decision. It is
adopted at `Tier2Catalogue.load_campaign_pack_report()`, `RegistryCatalog`
`.validate_entry_report()` and `DataManager.content_report()`; the pre-existing flat
`Array[String]` results are unchanged beside it. `scripts/tests/test_validation_model.gd`
covers it. No engine rule registers a fix, and no rule escalates between gates yet —
`[CRD-9]`'s missing-notice check and `[L10N-14]`'s locale-completeness check are the two
that will, and neither validator is written.

Validation runs when a staged edit commits, on explicit request, and at activation or
export gates. Incremental validation is scoped to the committing document; the Issues
panel combines live open-document results with the latest pack-wide pass and visibly
marks stale results (`[CEUI-17]`, `[CEUI-18]`, `[CEUI-S25]`, `[CEUI-S26]`).

**Implemented** as `scripts/editor/EditorIssues.gd`. The panel holds the last full pass
and the live per-document reports; a live report supersedes the pack pass for its own
document, and a **new full pass discards the live reports**, because that pass revalidated
those documents too and its answer for them is the newer one. Any commit marks the pack
pass stale, and a pack nobody has validated reads as *not validated* rather than as clean.
Severity is resolved **per gate** at read time rather than stored, so a rule that warns in
a draft and errors at a release-complete export groups under Errors and names the gates it
blocks. The entry list is a `RecordSelector`, which is how `[CEUI-S26]`'s closing
requirement holds without new vocabulary: an entry whose document is not open stays in the
list, stays focusable, and returns its reason when activated. Entries carry severity and
staleness as text columns, never as colour alone (`[CEUI-S17]`).

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
  status bar (`[CEUI-23]`, `[CEUI-24]`, `[CEUI-S30]`, `[CEUI-S31]`). **The derivation is
  implemented:** a `map_data` property becomes a layer by declaring `map_layer`, and
  `EntitySchemaRegistry.map_layers()` returns them in order. Today that yields four —
  terrain, deployment, units, objectives — and two properties may share one layer.
  Map objects, regions, and annotations are absent because the schema has no collection
  for them yet, which is the behaviour a derived list is for.

**Implemented:** `scripts/editor/EditorMapCanvas.gd` draws what those layers hold and
derives the tools that act on them. A tool comes from the SHAPE of the property's schema —
an array of strings is a paint tool, an array of tiles is a mark tool, an array of objects
carrying a tile is a place tool, and an object of arrays of those places into an
author-named group — so a pack that authors a new spatial property gets a tool with no
editor edit, which is `[CEUI-S21]` one level down. Because a layer owns a LIST of
properties, a tool acts on a property and never on "the layer": `victory_conditions` and
`defeat_conditions` are both Objectives, and a helper that took the layer's property would
write to the wrong one of the two with every value correct and no error raised.

Hiding a layer changes what the canvas draws and leaves the layer in the list, which is why
the two are separate objects; a hidden layer is also unselectable through a tile, so hiding
is not a visual nicety that still lets the author edit by accident. Locking refuses the
edit and keeps the layer activatable, with the reason returned rather than swallowed. Every
tool application is staged on the open document and committed through
`CampaignEditorShell.commit_active_edit()`, so `[CEUI-S25]`'s incremental pass runs and one
canvas edit stays one Undo step. A canvas selection is published for `[CEUI-S23]`'s bulk
table rather than growing a second multi-edit surface.

What the surface does **not** have is a value palette: mark tools edit on click because a
tile is either in the list or not, while paint and place need a value — which terrain
glyph, which unit — that no ruling names a picker for, so they select and say so.
- Trigger and objective order is authored in a canonical ordered outline. Any graph is
  a projection and cannot become a second source of truth (`[CEUI-25]`,
  `[CEUI-S32]`).

**Implemented:** `scripts/editor/EditorObjectiveOutline.gd` is that outline, and the Graph
workspace draws it. Which properties HAVE an outline is derived, not named: an outline
property is one whose items are identified by a REGISTRY — an item schema with a *required*
field carrying a `vocabulary`. That is `[CEUI-S32]`'s "backed by registered predicates"
read as a shape, and the word *required* is what separates a predicate from a mark: an
enemy placement carries `ai_profile`, which has a vocabulary too, but a placement's identity
is its unit and its tile, so it stays `[CEUI-S31]`'s canvas and never appears on the
outline. The predicate list itself is read from the registry on every rebuild, so a
condition registered by a pack is offered with no editor edit — a cached list would be
`CEUI-25` option C's fixed dropdown with a cache's alibi.

The graph is a projection in three checkable senses. It is **demand-gated** — nothing
produces one until the author asks. Its node ids **are** the outline's card ids (the
`EditorSubject` address), so it cannot mint an identity that could drift. And it stores
**no layout and no edges of its own**: the only edges are the grouping and the ordering the
outline already is, derived on every call. A graph that owned a position would own the one
piece of state the outline cannot reconstruct, and so the one that would have to be
migrated.

A card's link into the map is the canvas's own address, so selecting a card and clicking its
mark put the identical subject in front of the Inspector. Edits stage on the open document
and commit through `CampaignEditorShell.commit_active_edit()`, exactly as on the canvas.
Reordering is the one mutation `EditorSubject`'s length rule cannot see — a move keeps the
array's length while reassigning indices — so `move_card()` returns the card's new id and
the surface re-points the selection at it.

Campaign STRUCTURE — nodes and the edges between them — is graph-shaped data, so a graph is
its canonical presentation and it is deliberately not in this file:
`EDITOR-CAMPAIGN-STRUCTURE-GRAPH-2026-09-08`.
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
- Unit-sprite composition is one author-owned ordered layer stack. Authors determine
  every layer's draw order, anchor, transform, visibility, asset, and optional palette;
  the engine reserves no shadow/body/head/badge/halo slots and never reorders by type.
  Faction presentation may be a complete exact-mapping palette rather than a single
  colour. Recommended arrangements and palettes live as forkable authored presets in
  sample campaign packs, never as engine defaults. Inheritance resolves to the same
  ordered runtime array, so a per-class override does not create another rendering path
  (`TEAM-HALO-OPTION-2026-08-25`; `[CSA-18..21]`).
- Art imported from a GBA-era game carries hardware structure the editor cannot see,
  and the unit that structure is organised around is the **palette bank**, not the
  tile. A swap set authored against a bank covers every tile sharing it; one authored
  against a single tile silently misses that tile's siblings. The model, the checks
  that confirm a source really is a GBA framebuffer, and the import consequences —
  including why a fringe cannot be keyed off and why two source maps sharing no
  colours is not a reason they cannot be combined — are in
  [`gba_source_art_palette_model.md`](../Docs/guides/gba_source_art_palette_model.md).
  Measured 2026-08-26; it exists so the same three mistakes are not re-derived.

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
questions. As of 2026-09-07 the tree/layer descriptor, the severity/gate/quick-fix
model, the shared selector's state model, the editor density column, and the
deactivate-on-quit caller are built; the selector's Control layer and the isolated
embedded session are not.
