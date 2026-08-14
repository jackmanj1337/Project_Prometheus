---
Type: design
Status: Research complete - owner decisions pending in CEUI-1..40
Last verified: 2026-08-12
---

# Campaign Editor UI — Comparative Research

**Research date:** 2026-08-12  
**Decision register:**
[`CEUI-1..40`](../registers/campaign_editor_ui_open_questions_2026-08-12.md)

## Scope and inherited decisions

This packet researches the author-facing campaign editor, not a Godot
`EditorPlugin`. The editor is integrated into Project Prometheus, hidden behind
the existing runtime/developer gate, and uses engine-owned chrome plus the UUI
semantic role API. It edits one active, completely self-contained campaign pack.
Pack data remains canonical JSON; extensible content families remain open
registries. There are no dependencies, cross-pack id collisions, load-order
controls, or built-in content palette.

The campaign library installs, selects, repairs, and removes finished packages.
The editor owns drafts, authoring, validation, test launch, and export. Asset
behavior settled in `[CSA-1..36]` remains binding: the editor includes a broad
asset manager; media is catalogued and provenanced; sprite cells, animation,
palette swaps, declarative rotate/mirror and baking are supported; no imported
licence is inferred or granted by the tool.

**Held dependency:** all search boxes, search syntax, result ranking, OS/on-screen
keyboard behavior, and focus restoration after search are explicitly **HELD on
the non-modal text-entry packet**. This packet may reserve a labelled search
slot in a wireframe, but does not decide how it behaves.

## Direct-source comparison

### Godot editor: stable spatial grammar, contextual property editing

Godot's stable editor documentation describes a centre workspace surrounded by
project/scene docks, a context-sensitive Inspector, and a collapsed bottom panel
for output and specialist tools. It also provides a distraction-free workspace,
resizable/repositionable docks, property categories, non-default/revert markers,
multi-property copy/paste, selection history, and documentation links. These are
strong patterns for an author tool because the same spatial grammar works across
maps, records, and assets without turning each content type into a separate app.

What to borrow:

- project/content tree left, primary canvas or form centre, Inspector right;
- collapsible validation/test output below;
- contextual toolbars rather than one enormous global toolbar;
- visible non-default state, per-property reset, and navigation history;
- a distraction-free canvas mode and saved layouts only as later convenience.

What not to borrow:

- Godot's node/resource vocabulary or its developer-level density;
- plugin architecture, `.tres` authoring, or raw filesystem-first workflows;
- unrestricted dock floating as a v1 requirement. Godot documents platform
  limits for multiple windows, so a dependable single-window layout comes first.

Sources: [Godot editor overview](https://docs.godotengine.org/en/stable/getting_started/introduction/first_look_at_the_editor.html),
[Inspector dock](https://docs.godotengine.org/en/stable/tutorials/editor/inspector_dock.html),
[customizing the interface](https://docs.godotengine.org/en/stable/tutorials/editor/customizing_editor.html), and
[Godot application/window guidance](https://docs.godotengine.org/en/stable/tutorials/ui/creating_applications.html).

### Tiled: map-centred editing, typed properties, reusable templates

Tiled's current manual demonstrates a map-first editor with a Project view,
contextual Properties view, typed custom properties, object references with jump
navigation, reusable templates, inheritance, explicit overrides, and live template
updates. These patterns fit encounters: terrain and placements remain visual,
while content bindings and predicates remain structured and inspectable.

What to borrow:

- painting and selection tools stay close to the map;
- typed fields and reference pickers, never unvalidated magic strings;
- jump-to-reference and show-usage navigation;
- reusable encounter fixtures/templates with clearly displayed inherited versus
  overridden values;
- layers/groups for terrain, deployment, units, objectives, triggers, regions,
  and annotations.

What to avoid:

- exposing arbitrary custom enums as the engine's extension model; Project
  Prometheus content families use registered ids and predicates;
- silent live propagation that can change many maps without a reviewable diff;
- import/export formats the runtime does not consume.

Sources: [Tiled custom properties](https://doc.mapeditor.org/en/stable/manual/custom-properties/),
[templates](https://doc.mapeditor.org/en/stable/manual/using-templates/), and
[automapping](https://doc.mapeditor.org/en/stable/manual/automapping/).

### RPG Maker MZ: database/map separation and instant playtest

RPG Maker's current official help separates the map surface from its database,
switches map/event editing modes, provides context actions on maps and database
records, and makes playtest available throughout creation. Event pages combine
conditions with command sequences, while warnings explain author-created loops
that can lock play control.

Useful lessons:

- maps and reusable records need different primary workspaces but one project
  context;
- playtest must be a first-class action, not an export-only ceremony;
- structural validation should explain dangerous authoring patterns before test;
- event/trigger authoring benefits from a readable sequence plus conditions.

Project Prometheus should improve on the model with stable string ids, explicit
references, schema validation, full issue navigation, and open registries rather
than fixed numbered database slots.

Sources: [RPG Maker MZ basic editor controls](https://rpgmakerofficial.com/product/MZ_help-en/01_03.html),
[menu and playtest controls](https://rpgmakerofficial.com/product/MZ_help-en/01_04.html),
[map events](https://rpgmakerofficial.com/product/MZ_help-en/01_09_03.html), and
[aid tools](https://rpgmakerofficial.com/product/MZ_help-en/01_05.html).

### SRPG Studio: domain focus, but insufficient primary UX documentation

SRPG Studio remains a relevant direct comparator because it is purpose-built for
tactical-RPG maps and data. Its publicly indexed material confirms an ecosystem
of map, game-mode, character, item, and configuration guides, but the official
English interaction documentation available to this research pass was not
complete enough to treat detailed UI claims as authoritative. This packet
therefore uses SRPG Studio only as evidence that domain-focused authoring and
rapid test play are valuable, not as a source for copied screen structure.

Direct listing: [SRPG Studio guides hub](https://steamcommunity.com/app/857320/guides/).

## Recommended information architecture

Use four persistent regions and mode-specific centre workspaces:

1. **Application/header bar:** active draft identity, dirty/recovery state,
   Undo/Redo, Validate, Test, Export, and help.
2. **Content tree (left):** Pack, Campaign Graph, Maps, Units/Rosters, Classes,
   Items, Skills/Effects, Dialogue, Activities, Themes, Assets, Fixtures, and
   Release. Categories come from schema/registry metadata, not a UI enum.
3. **Workspace (centre):** record form/table, map canvas, graph, asset slicing
   canvas, theme preview, fixture runner, or release report.
4. **Inspector (right):** selected record/object properties, references, source
   and licence, inherited/default state, and contextual help.
5. **Bottom panel:** Issues, Test, Diff, Reference/usage, and task output. It is
   collapsed until useful and expands without replacing the workspace.

The tree represents semantic content, not arbitrary raw folders. An advanced
"Show file" action may reveal the pack-relative JSON/media path, but authors
should not need filesystem knowledge for normal work.

## Editing and transaction model

Every meaningful user gesture is an undoable action with a human-readable label.
Typing coalesces sensibly; paint strokes, drags, multi-selection edits, imports,
palette extraction, batch replacements, and generated changes each form atomic
transactions. Destructive or many-file operations first show a staged summary
and remain undoable where technically safe. Save writes a consistent draft
snapshot rather than a partially updated set of files.

Validation is continuous but non-blocking during ordinary editing. The Issues
panel groups errors, warnings, and information; selecting an issue navigates to
the object and field. Test launch is blocked only by runtime-invalid errors.
Export is stricter: it runs the complete validator, reference/provenance checks,
and package allow-list, then presents a deterministic report.

## Map, encounter, and balance workspaces

The map workspace uses explicit layers for terrain, regions, starting tiles,
units, objectives, triggers, and annotations. The canvas and Inspector operate on
the same selected objects. A scenario toolbar switches between authoring overlays
such as movement cost, threat, deployment legality, objective reachability, and
trigger regions without mutating the map.

Test launch should support:

- play from campaign start;
- play from selected node/map with an explicit fixture;
- validate only;
- deterministic encounter simulation/batch runs where the runtime exposes it;
- fixed seed, side, roster/loadout, state flags, and progression snapshot;
- return-to-editor report containing result, seed, turns, errors, and links to
  implicated content.

Fixtures are named editor-only launch contexts, never shipped save state. They
must declare their assumptions and become invalid when referenced content is
removed. The editor can offer generic starter fixtures, but cannot ship a hidden
default campaign or FE-derived data.

Balance results are evidence, not an automatic authority. Show distributions,
outliers, failure causes, and exact reproducible runs; do not silently tune
content or claim that simulation proves fun.

## Asset manager integration

Assets are a first-class content workspace inside the same editor. Import stages
files, detects duplicates and unsupported formats, then requires catalogue id,
group, display name, source, licence, attribution, and usage bindings as
applicable. The preview supports sprite cells, animation playback, pivots,
declarative rotation/mirroring, palette extraction with frequency, supported
swap definitions and tint fallbacks, theme slots, nine-slice margins, and
reference previews.

The source/licence fields are visible alongside the asset and included in
validation. The tool never infers permission from file presence. Batch import may
reuse explicitly chosen metadata, but must not silently stamp a licence across
unreviewed files. Deletion shows all usages and offers cancel, replace-reference,
or intentional broken-reference workflows; it must not silently cascade-delete
content.

## Draft safety, recovery, and external changes

Autosave writes versioned recovery snapshots separate from the explicit saved
draft. On clean exit, old recovery generations can be pruned; after a crash the
editor offers Restore, Inspect differences, or Discard. A failed save preserves
both the last good snapshot and the in-memory work. External file changes are
detected per file and resolved through Reload, Keep mine, or Inspect/merge where
the structured type safely supports it—never last-writer-wins silently.

## Release and versioning

Export is a deliberate release task:

1. run full validation and show blocking/non-blocking issues;
2. review changes since the last exported version;
3. choose/confirm semantic version bump; never silently infer compatibility;
4. verify manifest, provenance, allow-listed files, and generated reference data;
5. write the package atomically and report path, version, size, and SHA-256;
6. leave the draft editable and record the exported snapshot identity.

Version bump recommendations may be supplied from schema-aware changes, but the
author confirms them. Export never installs or activates the package implicitly.

## Accessibility, responsiveness, and onboarding

> **SUPERSEDED 2026-08-14 by the `[CEUI-5]` owner ruling.** The floor is **`1920×880`** — a
> maximized browser window on a 1920×1080 display, after browser chrome and taskbar. The
> paragraph below proposed `1024×768` with a one-side-panel compact desktop mode; **that mode
> does not exist.** The editor is Expanded-only with a single responsive state, and below the
> floor it shows the minimum-size state. Read the paragraph as research input, not as the
> supported range.

This is desktop-first. The recommended comfortable target is 1280×720 or larger;
1024×768 is the supported compact desktop floor using one side panel at a time.
Below that, provide a clear minimum-size explanation rather than a compromised
phone editor. Touch-only campaign creation is not a v1 objective. All essential
actions remain keyboard reachable; focus, selection, error state, and dirty state
cannot rely on color alone; splitters have keyboard alternatives; motion-heavy
previews respect reduced motion; map overlays have patterns/icons as needed.

Onboarding should open an existing/forked public pack, consistent with `[CSA-30]`
and `[CSA-31]`, and present a guided checklist: identity, first map, campaign node,
roster, validation, fixture test, provenance, export. Context help explains the
game concept and links to generated schema/reference documentation. It must not
seed a built-in content palette or imply the internal FE pack is redistributable.

## Dependency conclusion

The editor packet itself is ready for owner discussion. Only search-specific
interaction questions are held. Implementation should also consume, rather than
redefine, the transaction vocabulary, generated reference model, localization
scope, and UUI responsive/theme primitives as those foundations land.

