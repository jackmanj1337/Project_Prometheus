---
Type: plan
Status: Proposed
Last verified: 2026-08-11
---

# v0.7.3 Return — Text Entry, Web Transfer, and Pack Validation Programme

Track ownership remains in the
[`Project Control Plane`](project_control_plane_2026-06-29.md). The workspace
`coordination/tasks.json` row `PROGRAMME-V073-TEXT-WEB-PACK-2026-08-11` is the
execution-state source; this document owns the detailed session sequence and
acceptance boundaries.

## Outcome

Replace the failed v0.7.3 seams with one reusable single-value text-entry system,
browser-native upload/download adapters, export-aware campaign-pack validation, and a
test boundary that lets headless Godot and Playwright prove all platform-neutral
behaviour before a narrow Windows acceptance pass.

This is a multi-session programme. Each session below is deliberately bounded: read
only this plan, the named entry files, and the previous session's short handoff. Do not
reload the full v0.7.0–v0.7.3 history unless a named invariant is contradicted.

## Settled decisions and non-goals

- `TextEntryService` remains a general **single-value** service. It is not a form
  framework, file browser, rich-text editor, or autocomplete system.
- Filename entry is its first release-critical caller, not a separate subsystem.
- Game-owned text entry uses a `Control` in the caller's viewport. It does not use a
  `ConfirmationDialog`, `FileDialog` filename field, or another nested `Window`.
- Domain callers provide validation, normalization, labels, and submit behaviour.
  The generic service knows nothing about ZIPs, save files, or directories.
- Desktop uses a directory-only picker after naming. Web uses browser upload/download
  APIs. Headless tests use a deterministic capture adapter.
- The web test bridge remains read-only; Playwright drives real browser input.
- Physical Windows controller, native picker, OS focus, IME, and display behaviour
  remain final native acceptance seams.
- One active campaign pack remains completely self-contained. Pack-local ids do not
  collide with ids in other installed packs.

## Evidence that drives the plan

The v0.7.3 Windows build (`3f72688f`) passed source tests but rejected the supplied
replacement pack with `vocabulary_value_unknown`. The same ZIP installs from the
source checkout. The export preset excludes `data/**`, which also removes engine-owned
resources under `data/registries/**`; exported and source runtimes therefore validate
against different registry sets. The pack itself contains matching registry-entry
documents, but whole-pack schema validation does not first admit those declarations
into a pack-scoped vocabulary.

The filename redesign still creates a nested `ConfirmationDialog`, grabs its dynamic
`LineEdit` in the popup frame, and relies on built-in cancel behaviour. Windows reports
that ordinary typing needs a mouse click, Z/X behave specially, and one Escape reaches
the Main Menu. Headless tests directly call callbacks or signals instead of dispatching
the real event path, so they prove callback bodies rather than focus/input ownership.

## Programme invariants

1. One physical event causes at most one semantic transition.
2. The top text-entry/modal surface exclusively owns confirm, cancel, and navigation.
3. A failed or cancelled transfer never changes active package or campaign state.
4. Release tests exercise the exact exported resources and exact bundled ZIP.
5. Engine primitive handlers remain engine-owned; pack registry entries may name only
   admitted primitives, then extend pack-scoped author vocabularies.
6. Tests assert stable codes/state, not localized prose or fragile scene paths.
7. Every session finishes with focused tests, the appropriate full gate, and a handoff
   of at most: outcome, commits, tests, remaining risk, and next entry files.

## Session map

| Session | Deliverable | Depends on | Primary verification |
|---|---|---|---|
| 0 | Reject/intake v0.7.3 and freeze exact evidence | none | hashes, screenshot/log/ZIP correlation |
| 1 | Export-aware registry and bundled-pack gate | 0 | exported PCK inventory + exact ZIP install |
| 2 | Two-pass pack registry bootstrap | 1 | pack-defined IDs and invalid primitives |
| 3 | General text-entry request/result contract | 0 | pure headless contract tests |
| 4 | Same-viewport modal and input ownership | 3 | real dispatched keyboard events |
| 5 | Filename caller and desktop directory seam | 4 | headless capture + desktop structural tests |
| 6 | Browser upload/download adapter | 1 | browser upload and captured download |
| 7 | Bridge observability and stable test identities | 4 | fresh snapshots and consumer attribution |
| 8 | Playwright end-to-end regression matrix | 2, 5, 6, 7 | exact replacement ZIP and real browser input |
| 9 | Export candidate and narrow Windows acceptance | 8 | native picker/controller/focus checks |
| 10 | Reconcile docs, tracker, and release disposition | 9 | full suite, evidence links, clean lifecycle |

## Session 0 — return intake and rejection

**Read:** this plan; `Incoming/v0.7.3 return/`; the v0.7.3 build record; the v0.7.3
tracker row.

Record the return as rejected, preserve the exact build/ZIP identities, link the
incoming checklist/log/screenshot, and split implementation ownership onto branches
from `agent/integration`. Do not modify the frozen playtest branch's product code.

**Exit:** the tracker names the two blockers (exported registry mismatch and text-entry
modal/input ownership), their implementation rows, dependencies, and evidence paths.

## Session 1 — exported-runtime registry gate

**Read:** `export_presets.cfg`, `ResourceManifest.gd`, the registry root constants,
`install_check_archive.gd`, and the exact replacement ZIP.

Move engine-owned registry resources out of the campaign-content exclusion boundary
instead of broadly re-including `data/**`. Update registry roots and extraction tooling.
Add a gate that inventories the exported PCK, proves required engine registries exist,
proves built-in campaign catalogues do not, and validates the exact bundled ZIP using
the exported resource set.

**Exit:** source and exported runtimes report the same core registry ids; removing an
engine registry resource or shipping forbidden campaign data fails the gate.

## Session 2 — pack-scoped registry bootstrap

**Read:** `EntitySchemaRegistry.gd`, `CampaignTier2Validators.gd`,
`CampaignTier2RuntimeAdapter.gd`, `RegistryCatalog.gd`, and registry-entry fixtures.

Make whole-pack validation two-pass. First validate registry-entry document shape and
resolve each declared primitive against the engine catalogue. Then create a pack-scoped
schema registry, admit the valid declared ids by family, and validate dependent items,
objectives, and other documents. Never execute pack-provided code.

Cover valid pack-defined ids, unknown primitive handlers, duplicate ids within one
pack, dependency-free identity across separate packs, and atomic failure.

**Exit:** the supplied replacement pack validates for the correct architectural reason,
while invented primitives and invalid declarations fail with stable paths/codes.

## Session 3 — general single-value text-entry contract

**Read:** `TextEntryService.gd`; `scripts/ui/text_entry/**`; existing text-entry tests;
the text-entry design/research tracker rows.

Consolidate the request/result contract around purpose, title, prompt, initial value,
placeholder, allowed characters, length, normalization, validator, labels, and
dismissal policy. A result is submitted or cancelled and carries the validated value;
callers do not infer completion from hidden nodes or focus loss. Keep hardware, grid,
and future mobile presenters behind the service.

**Exit:** pure tests cover normalization, selection replacement, caret edits, invalid
submission, cancellation policy, session replacement, and one result per generation.

## Session 4 — same-viewport modal and one-event ownership

**Read:** `ModalScreen.gd`, `FocusNavigator.gd`, input-mode code, the new contract, and
current filename prompt code.

Build a reusable same-viewport `Control` surface with an echo/edit field, prompt,
validation feedback, Cancel, and Confirm. Introduce explicit top-modal/text-owner state
so underlying screens suspend navigation and cannot consume the same cancel event.
Focus must settle without a mouse click and restore deterministically on close.

Tests must dispatch real input events—Escape, mapped cancel, Enter, Z/X, WASD, arrows,
Tab, Backspace, and ordinary characters—and assert text, focus, owner, transition count,
and consumer. Do not directly call UI callbacks as the primary regression proof.

**Exit:** one Escape closes only text entry; navigation never inserts text unless a grid
character is explicitly activated; keyboard editing works immediately.

## Session 5 — filename adoption and desktop picker seam

**Read:** `FileDialogInputGuard.gd`, `TransferFileService.gd`, all save/export callers,
and their focused tests.

Replace the filename-specific `ConfirmationDialog` with a `TextEntryService` request.
The caller owns filename-safe normalization, reserved-name checks, extension policy,
and the `Choose Folder` label. Confirmation passes the value to a directory-only
desktop picker. Cancellation returns focus to the caller without opening a picker.

Use an injected capture adapter in headless tests. Keep desktop `FileDialog` limited to
directory choice; do not restore filename editing inside it.

**Exit:** every current save/export entry point preserves the chosen name through the
adapter, and no filename caller constructs its own text UI.

## Session 6 — centralized browser upload and download

**Read:** `TransferFileService.gd`, Campaign Library import callers, export callers, and
the existing web-transfer tracker row.

Add one asynchronous browser upload API backed by a hidden HTML file input created from
a direct user gesture. Read bytes with browser APIs, enforce an early size budget, copy
to controlled staging or pass bytes to the installer, preserve the untrusted display
filename separately, distinguish cancel/read failure, and always release callbacks and
temporary data. Route all web import callers through it.

Keep download centralized. Playwright must capture the download and verify suggested
name, non-empty bytes, content/hash, and single delivery. Browser downloads do not ask
for arbitrary directories and do not need filename text entry.

**Exit:** Playwright can upload the exact replacement ZIP through Campaign Library and
capture a real exported artifact without test-only filesystem shortcuts.

## Session 7 — trustworthy bridge and stable identities

**Read:** `WebTestBridge.gd`, `tools/playwright/lib/bridge.mjs`, existing bridge tasks,
and the web verification plan.

Land the version-locked publisher/consumer update already tracked: sequence/frame or
timestamp freshness, complete rect persistence, visible control text, truncation state,
and disabled processing when the bridge is absent. Add real modal stack/text owner,
focus history, active input mode, text-entry generation/value, last semantic input and
consumer, active package identity, and stable import diagnostic codes.

Give important controls stable semantic test ids such as `campaign.import`,
`text-entry.value`, `text-entry.cancel`, and `text-entry.confirm`. Keep the bridge
read-only and omit sensitive paths/raw imported content.

**Exit:** Playwright detects stale snapshots and can identify the exact owner and single
transition after every test input without relying on scene-tree layout.

## Session 8 — Playwright and headless regression matrix

**Read:** only the completed session handoffs, fixture manifest, Playwright README, and
screen/navigation definitions.

Drive the real browser canvas and upload input. Cover fresh install, valid replacement
pack, persistence after reload, failed activation rollback, malformed/oversized/path-
traversal archives, filename entry, Escape ownership, focus traversal, Z/X, WASD,
ordinary typing, grid entry, multiple resolutions/scales, and download capture.

Every failure artifact includes screenshot, fresh bridge snapshot, focus/modal history,
last input consumer, active package identity, diagnostic codes, viewport/scales, test
step, and fixture SHA-256.

**Exit:** all platform-neutral acceptance items pass against an exported web build and
the exact release fixture. Controller browser emulation, if added, is supplementary and
not native acceptance evidence.

## Session 9 — candidate and narrow Windows pass

**Read:** the Session 8 report and a newly generated checklist containing only native
seams.

Export a candidate only from an exact checked commit with a clean full-check receipt.
The Windows checklist verifies: immediate hardware typing; one Escape/one modal close;
directory picker open/cancel/selection; final file path and name; named physical
controller navigation/grid entry; IME/layout smoke; display scaling; exact ZIP import;
and save/relaunch package persistence.

**Exit:** accepted native evidence, or a failure packet whose telemetry identifies a
specific remaining platform seam rather than requiring broad re-triage.

## Session 10 — closeout

Update affected GDD and roadmap status in the same behaviour changes required by the
documentation DoD. Reconcile older text-entry/FileDialog/web-shim rows into completed,
superseded, or explicitly remaining work; regenerate indexes and the canonical tracker
view. Promote product work through the release line only after the native pass.

**Exit:** no open work exists only in this plan, no obsolete workaround is still called,
all artifacts and evidence are linked, and the next release disposition is explicit.

## Verification layers

| Layer | Owns | Does not claim |
|---|---|---|
| Pure/headless | contracts, validation, atomicity, intent decoding, capture adapters | OS focus or pixels |
| Export inspection | included/forbidden resources, exact fixture compatibility | interactive UI |
| Playwright | real browser keys/mouse/upload/download, focus/modal state, layouts | Windows native windows or physical pad |
| Windows | native picker/focus, physical controller, IME, scaling, final filesystem result | broad application logic already gated above |

## Compact handoff template

Each session writes no more than the following into its tracker reference or short
handoff:

```text
Outcome: <one paragraph>
Commits: <behaviour and docs SHAs>
Tests: <focused, full, export/Playwright evidence>
Remaining risk: <only unresolved facts>
Next entry: <session number and at most five files>
```

If a session discovers a new open task, add it to `coordination/tasks.json`; do not
leave it only in prose here or in a branch-local note.
