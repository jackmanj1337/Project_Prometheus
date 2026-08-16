---
Type: design
Status: In progress — Branches A–D answered 2026-07-24; E–K open. Answers recorded in [decisions doc](campaign_library_ux_decisions_2026-07-24.md)
Last verified: 2026-07-24
Tracker: DISCUSS-CAMPAIGN-LIBRARY-UX-2026-07-23
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Campaign Library Owner Questions

Planning ownership and sequencing remain in the
[Project Control Plane](../plans/project_control_plane_2026-06-29.md).

Each stable id records one decision. “Default” is the temporary planning assumption if deferred,
not an owner answer. Consequences name the main downstream contracts.

## 1. Mental model

| ID | Question and why | Alternatives | Recommendation / default | Consequences |
|---|---|---|---|---|
| CL-MODEL-01 | What is the top-level player object? It controls hierarchy and save recovery. | Pack / campaign / version / saved run | Campaign grouped under pack; default same. | Library routes, index headers, terminology. |
| CL-MODEL-02 | Can a pack contain multiple campaigns? Catalogue already can. | Exactly one / many grouped / flatten all | Many grouped by pack; default many. | Manifest summaries, duplicate titles, navigation. |
| CL-MODEL-03 | Which player terms are official? Ambiguity makes transfer warnings unsafe. | Technical pack/profile ids / plain campaign-run-save terms / user aliases | Show Campaign, Run, Save, Backup; reserve Pack and Rule Profile for details; default same. | All UI copy, GDD glossary, localization. |
| CL-MODEL-04 | Is Library launcher, manager, or both? | Launcher only / manager only / progressive-disclosure hybrid | Hybrid with launch-first default and Manage section; default hybrid. | Main Menu, screen depth, advanced actions. |
| CL-MODEL-05 | What list metadata earns space? | Title only / compact status / dense technical card | Title, pack/author, status, last played, compatible-run count; details for version/licence/fingerprint; default compact. | Row height, scanning, thumbnail budget. |

## 2. First run and discovery

| ID | Question and why | Alternatives | Recommendation / default | Consequences |
|---|---|---|---|---|
| CL-FIRST-01 | What does zero-content boot lead with? It is the first usable experience. | Import / choose folder / bundled example / future catalogue | “Import Campaign Pack” primary, Choose Folder and Help secondary; default same. | Main Menu disabled states and onboarding. |
| CL-FIRST-02 | Which local discovery methods ship? | Single-file import / managed scan folders / open installed folder | File import + one configurable scan folder; default file import only for v1. | Permissions, rescan, moved-content repair. |
| CL-FIRST-03 | May engine distribution include templates/examples? Zero playable content does not answer author templates. | None / non-playable schema template / playable sample pack | Non-playable author template outside runtime install; default none in player UI. | Packaging and licensing gate. |
| CL-FIRST-04 | How do empty, scanning, denied, unreadable differ? | One empty state / explicit state messages | Explicit states with Retry/Choose Folder; default explicit. | Async model, diagnostics, accessibility announcements. |

## 3. Installation and lifecycle

| ID | Question and why | Alternatives | Recommendation / default | Consequences |
|---|---|---|---|---|
| CL-LIFE-01 | Is preview mandatory before install? It is the last read-only trust boundary. | Always / only warnings / never | Always; default always. | Installer UI, metadata parse, cancel semantics. |
| CL-LIFE-02 | Which identity/trust fields appear? | Title only / author+version+licence+compatibility / fingerprint/signature too | Summary plus author, version, licence, engine/schema compatibility; fingerprint in details; no signature claim; default same. | Manifest requirements and copy. |
| CL-LIFE-03 | Same id/version import behavior? | Replace / reject / compare and repair | Reject if identical; flag changed bytes and require advanced repair flow; default reject all. | Immutability and save fingerprints. |
| CL-LIFE-04 | Same id/new version behavior? | Replace / side-by-side / choose per run | Retain side-by-side until migrations and affected runs are reviewed; default never replace in place. | Storage layout, version selector, cleanup. |
| CL-LIFE-05 | Different id/same title behavior? | Reject / rename display / allow with identity badge | Allow, disambiguate author/id; default allow. | Search/sort and spoofing language. |
| CL-LIFE-06 | Are disable and uninstall separate? Saves may still need content. | One remove action / separate disable and uninstall / archive to trash | Separate; uninstall blocked or strongly warned when runs depend on version; default disable only until removal design lands. | Registry state, save dependency count, recovery. |
| CL-LIFE-07 | Can rollback/duplicate coexist? | One active version / multiple installed versions / manual copies | Multiple immutable versions, one selected per run; default newest compatible for new runs only. | Disk use, migration, version badges. |
| CL-LIFE-08 | How mention dependencies when v1 forbids them? | Hide / “unsupported” diagnostic / future placeholders | Hide controls; validator says pack is not self-contained; default same. | Avoid false load-order model. |
| CL-LIFE-09 | Which lifecycle actions confirm/reverse? | Confirm all / only destructive / trash undo | Preview imports; confirm uninstall/replace/rollback; prefer recoverable trash if adopted; default confirm irreversible actions. | Modal policy and storage cleanup. |

## 4. Launch and New Game

| ID | Question and why | Alternatives | Recommendation / default | Consequences |
|---|---|---|---|---|
| CL-LAUNCH-01 | What happens on campaign selection? | Immediate launch / details / action menu | Details with Continue/New Run; default details. | One-click speed versus safety/context. |
| CL-LAUNCH-02 | Where are rule profiles chosen? | Library row / details / New Run wizard | New Run step after campaign details; default same. | Screen ownership and validation. |
| CL-LAUNCH-03 | How show mandates/defaults/adjustable/locked rules? | Disabled controls / summary-only / source-labelled comparison | Source-labelled controls with lock text and changed-value summary; default same. | Rule schema UI metadata. |
| CL-LAUNCH-04 | When validate? | Scan only / selection / immediately before commit | Lightweight scan status plus full candidate validation before New Run/Resume; default same. | Latency, progress, stale mutation safety. |
| CL-LAUNCH-05 | What preferences persist? | None / last campaign / sort/filter/view | Last campaign and sort/filter; avoid view-mode proliferation in v1; default last campaign only. | Settings schema and first focus. |

## 5. Runs and saves

| ID | Question and why | Alternatives | Recommendation / default | Consequences |
|---|---|---|---|---|
| CL-SAVE-01 | Where are saves organized? | Global flat / campaign / run within campaign | Campaign → Run → Save; global Load deep-links to this grouping; default same. | Index schema and LoadGame replacement. |
| CL-SAVE-02 | Which save types are visible? | All checkpoints / player-facing only / filters | Manual, autosave, suspend, completed/imported records; hide rewind internals unless recovery mode; default same. | Labels and retention. |
| CL-SAVE-03 | What may players rename? | Save / run / campaign alias | Run label and manual-save label; immutable ids remain hidden/system; default manual-save label only. | Header fields and uniqueness. |
| CL-SAVE-04 | How handle many runs/saves? | Infinite list / pagination / collapse+search+archive | Collapsed runs, search/filter, archive; default collapse and newest-first. | Performance and controller navigation. |
| CL-SAVE-05 | Which actions ship per run/save? | Resume/delete only / inspect/rename/export/archive/duplicate | Resume, inspect, rename, export, archive, delete; duplicate deferred; default current resume/export/delete plus inspect. | Transaction APIs and menus. |

## 6. Missing or incompatible content

| ID | Question and why | Alternatives | Recommendation / default | Consequences |
|---|---|---|---|---|
| CL-MISSING-01 | Do saves remain visible without their pack? Visibility enables repair. | Hide / visible disabled / separate orphan view | Visible disabled in original group plus Missing Content filter; default visible disabled. | Header-only index and grouping. |
| CL-MISSING-02 | Which repair actions appear? | Locate/import / enable / inspect/export/delete | Contextual Locate or Import, Enable, Inspect, Export; Delete secondary; default same. | File picker and resolver. |
| CL-MISSING-03 | How categorize failure language? | One incompatible error / distinct stable categories | Missing, disabled, version mismatch, fingerprint changed, migration unavailable, invalid pack, corrupt save; default distinct. | Error codes, tests, support docs. |
| CL-MISSING-04 | When can warning override a block? | Never / fingerprint only / any advanced override | Never for invalid references/schema; owner must decide whether same-version fingerprint mismatch is always blocked; default blocked. | Integrity policy and unsafe-load risk. |
| CL-MISSING-05 | How much diagnostic detail is visible? | Full paths/log / plain summary only / expandable redacted report | Plain summary + expandable/copyable redacted report; default same. | Privacy scrubber and report format. |

## 7. Import, export, backup, restore

| ID | Question and why | Alternatives | Recommendation / default | Consequences |
|---|---|---|---|---|
| CL-TRANSFER-01 | Where do three artifact actions live? | One Export menu / contextual locations / Transfers hub | Context actions plus a Transfers hub explaining scopes; default contextual actions. | Navigation and discoverability. |
| CL-TRANSFER-02 | Names/extensions? Misidentification can leak saves into distributable packs. | Generic ZIP/JSON / branded distinct extensions | “Portable Save”, “Clean Campaign Pack”, “Full Library Backup”; distinct extensions if technically feasible; default explicit filename suffixes. | Format registration and copy. |
| CL-TRANSFER-03 | What does restore preview show? | Count only / additions, replacements, conflicts, versions, size | Full component/conflict/space summary; default full. | Preflight APIs and disk checks. |
| CL-TRANSFER-04 | Restore selection granularity? | All-or-nothing / selectable components / both | Select components, but commit selected set atomically; default entire backup atomically for v1. | Backup manifest and rollback. |
| CL-TRANSFER-05 | Rollback experience? | Silent / summary / retained recovery artifact | Restore prior state automatically, show stage/category, preserve source and exportable report; default same. | Transaction journal and UI. |
| CL-TRANSFER-06 | How explain clean pack vs user state? | Folder metaphor / explicit scope list / technical manifest | Explicit included/excluded summary at preview and success; default same. | Trust copy and tests. |

## 8. Navigation and accessibility

| ID | Question and why | Alternatives | Recommendation / default | Consequences |
|---|---|---|---|---|
| CL-NAV-01 | Primary layout? | Grid / list / tabs / split pane | List + details pane; collapse to sequential screens at narrow widths; default list. | Scene structure and responsive rules. |
| CL-NAV-02 | Controller action contract? | Context-dependent / stable global mapping | Confirm primary, Cancel back, context action menu, details toggle, shoulders change top sections; default stable mapping. | Input map/help legend/tests. |
| CL-NAV-03 | Exact focus policy? | Auto neighbors / explicit per state | Explicit initial/return focus and neighbors; destructive actions never default; default same. | Every scene and regression test. |
| CL-NAV-04 | Search/filter controller behavior? | Virtual keyboard / prefix jump / filters only | Filters and sortable headings first; search optional when OS text entry is reliable; default filters only v1. | Large-library usability. |
| CL-NAV-05 | Text/localization stress target? | 100% / 200% text / platform scaling | 200% text, long translated labels, missing images; default 200%. | Layout fixtures and minimum window. |
| CL-NAV-06 | Status redundancy? | Color/icon / icon+tooltip / text+icon+color | Text + icon, color supplementary; default same. | Theme and localization. |
| CL-NAV-07 | Which operations show progress/cancel? | All / threshold / import, scan, backup, restore, migration | Any filesystem or validation batch that may exceed a frame; cancel before commit only; default listed operations. | Async tasks and atomic boundary copy. |

## 9. Safety, trust, privacy

| ID | Question and why | Alternatives | Recommendation / default | Consequences |
|---|---|---|---|---|
| CL-SAFETY-01 | What trust claim is accurate? | “Safe” / “data-only, validated” / unsigned warning | “Data-only; no executable pack scripts; validated before activation,” never “safe”; default same. | Security copy and manifest display. |
| CL-SAFETY-02 | What happens to malformed content? | Delete / reject / quarantine / retain external path only | Reject install and retain source untouched; list installed corruption disabled; quarantine deferred; default reject. | Storage and threat model. |
| CL-SAFETY-03 | What paths may diagnostics expose? | Absolute / basename / logical ids with opt-in full path | Logical ids and safe relative paths; explicit action to copy local full path; default redacted. | Diagnostic formatter/privacy tests. |
| CL-SAFETY-04 | Trash/recovery policy? | Immediate delete / OS trash / app trash with retention | App-managed trash for packs/runs/saves if bounded recovery is feasible; default confirmation + immediate delete until implemented. | Storage quota and purge UX. |

## 10. Author and advanced-user surfaces

| ID | Question and why | Alternatives | Recommendation / default | Consequences |
|---|---|---|---|---|
| CL-ADV-01 | Can unpacked development packs coexist? | No / dev folder with explicit mode / ordinary scan | Explicit developer mode and visually marked source; default no player-mode unpacked activation. | Hot reload, fingerprints, support boundary. |
| CL-ADV-02 | Where do validation reports live? | Modal dump / expandable details / separate validator tool | Plain UI summary, exportable report, dedicated author validator; default summary+report. | Tooling and error schema. |
| CL-ADV-03 | How mark duplicate ids/local modifications/unsigned builds? | Hide / badges / block | Block identity collision; badge development/local modification; say “signature unavailable” only if signatures exist; default block collisions and avoid unsigned language. | Trust model and list status. |
| CL-ADV-04 | Which actions stay outside ordinary UI? | Everything visible / developer toggle / separate CLI/editor tool | Schema dumps, raw fingerprints, unpacked reload, fixture generation in developer tools; default separate. | Complexity and documentation. |

## Decision recording

When answered, copy each id and exact answer into a decision document, update this packet’s
status, and create implementation tracker rows only for accepted scope. Unanswered items retain
their stated defaults solely so downstream research remains coherent.
